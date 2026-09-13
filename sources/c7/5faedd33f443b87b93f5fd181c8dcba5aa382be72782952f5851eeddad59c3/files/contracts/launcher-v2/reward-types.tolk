// Launcher v2 — reward-bearing jetton (TEP-74 + TEP-89 compatible) with on-chain dividend indices.
//
// Same accounting model as v1 (docs/10-launcher-v2.md §1-2), with three structural changes:
//   * the master never spends its own balance: every handler lives on the incoming value and the
//     last message of a handler carries the remainder (`128 | 16`) — no mode 64 after a fixed send;
//   * the Pool owns coins without a wallet (`poolReserve`), so buyers are delivered straight from
//     the master and never race on a shared `pending`;
//   * every wallet `pending` has an exit: bounceable ack with retry, and `CancelPending` after
//     PENDING_TIMEOUT. Balance mutations are optimistic at send and restored on bounce.
//
// Payout for a reward id = accrued[id] + balance * (index[id] - stamps[id]) / INDEX_SCALE.

/// Fixed point scale of reward indices (reward units per token unit).
const INDEX_SCALE = 1000000000000

/// Maximum reward ids per coin (single reward = 1, cycle = 2..5).
const MAX_REWARDS = 5

/// Reported by `get_code_version` on every v2 contract so the app selects decoders and builders.
const LAUNCHER_CODE_VERSION = 2

/// A wallet `pending` older than this may be cancelled by its owner (the ack never came).
const PENDING_TIMEOUT = 600

// v2-only exit codes (shared enum `Errors` keeps the v1 codes; 494+ are launcher v2)
const ERR_PENDING_MISMATCH = 494
const ERR_POOL_RESERVE = 496

// ---------------------------------------------------------------------------
// Master
// ---------------------------------------------------------------------------

struct RewardMasterRoles {
    factory: address
    /// Launch sequence number: makes the master address unique per launch.
    seq: uint64
    /// Only the Curve may mint (and it is the only party that learns of burns while the curve is open).
    curve: address?
    /// Only the RewardVault may bump indices.
    vault: address?
}

struct RewardMasterStorage {
    /// Coins held by wallets or in flight towards a wallet: the reward-earning supply.
    totalSupply: coins
    /// Coins owned by the Pool (no wallet, never earn). `totalSupply + poolReserve` is the jetton supply.
    poolReserve: coins
    /// True while the bonding curve accepts sells.
    curveOpen: bool
    /// Pool (set at graduation): sells go there, buys come from `poolReserve`.
    pool: address?
    roles: Cell<RewardMasterRoles>
    indices: map<uint8, uint128>
    /// rewardId -> scaled units not yet reflected in the index (`< circulating`), carried to the next bump.
    remainders: map<uint8, coins>
    metadata: cell
}

fun RewardMasterStorage.load(): RewardMasterStorage {
    return RewardMasterStorage.fromCell(contract.getData());
}

fun RewardMasterStorage.save(self) {
    contract.setData(self.toCell());
}

struct RewardMasterDataReply {
    totalSupply: coins
    poolReserve: coins
    curveOpen: bool
    pool: address?
    roles: RewardMasterRoles
    indices: map<uint8, uint128>
    remainders: map<uint8, coins>
}

// ---------------------------------------------------------------------------
// Wallet
// ---------------------------------------------------------------------------

/// What the wallet does once the master has answered its sync.
const ACTION_SYNC = 0
const ACTION_CLAIM = 1
const ACTION_BURN = 2

struct PendingTransfer {
    queryId: uint64
    amount: coins
    recipient: address
    sendExcessesTo: address?
    forwardTonAmount: coins
    forwardPayload: cell
}

/// Operation waiting for the master's SettleAck. `amount` already left `balance` (SYNC / BURN) and
/// comes back if the Settle bounces or the owner cancels a SYNC after PENDING_TIMEOUT.
struct PendingOp {
    action: uint8
    queryId: uint64
    amount: coins
    startedAt: uint32
    transfer: Cell<PendingTransfer>?
}

struct RewardWalletStorage {
    balance: coins
    owner: address
    master: address
    stamps: map<uint8, uint128>
    accrued: map<uint8, coins>
    /// Operation in flight (transfer, claim or burn). Blocks any other action while set.
    pending: Cell<PendingOp>?
}

fun RewardWalletStorage.load(): RewardWalletStorage {
    return RewardWalletStorage.fromCell(contract.getData());
}

fun RewardWalletStorage.save(self) {
    contract.setData(self.toCell());
}

struct RewardWalletDataReply {
    balance: coins
    owner: address
    master: address
    stamps: map<uint8, uint128>
    accrued: map<uint8, coins>
    pending: PendingOp?
}

fun calcDeployedRewardWallet(owner: address, master: address, walletCode: cell): AutoDeployAddress {
    val init: RewardWalletStorage = {
        balance: 0,
        owner,
        master,
        stamps: [],
        accrued: [],
        pending: null,
    };
    return {
        workchain: BASECHAIN,
        stateInit: { code: walletCode, data: init.toCell() },
        toShard: { fixedPrefixLength: 8, closeTo: owner },
    };
}

fun calcRewardWalletAddress(owner: address, master: address, walletCode: cell): address {
    return calcDeployedRewardWallet(owner, master, walletCode).calculateAddress();
}

fun indexOf(m: map<uint8, uint128>, id: uint8): int {
    val found = m.get(id);
    return found.isFound ? (found.loadValue() as int) : 0;
}

fun amountOf(m: map<uint8, coins>, id: uint8): int {
    val found = m.get(id);
    return found.isFound ? (found.loadValue() as int) : 0;
}

/// Reward owed for one id given a position (balance, stamp, accrued) and the current index.
fun owedFor(balance: coins, index: int, stamp: int, accrued: int): int {
    return index > stamp ? accrued + (balance * (index - stamp)) / INDEX_SCALE : accrued;
}

/// Freezes the position of `balance` coins at `indices`: earned rewards move into `accrued`, stamps
/// advance. `balance` is passed explicitly because a settling wallet has already taken the lot in
/// flight out of `self.balance` while that lot still earned until the master processed the Settle.
fun RewardWalletStorage.freezeAt(mutate self, indices: map<uint8, uint128>, balance: coins) {
    var r = indices.findFirst();
    while (r.isFound) {
        val id = r.getKey();
        val index = r.loadValue() as int;
        val stamp = indexOf(self.stamps, id);
        if (index > stamp) {
            if (balance > 0) {
                val earned = (balance * (index - stamp)) / INDEX_SCALE;
                self.accrued.set(id, (amountOf(self.accrued, id) + earned) as coins);
            }
            self.stamps.set(id, index as uint128);
        }
        r = indices.iterateNext(r);
    }
}

/// Merges an incoming lot of `amount` coins whose position was frozen at `indices` (the sender's
/// settle snapshot). Two cases per reward: the snapshot is ahead of us -> freeze our balance up to
/// it; we are ahead of the snapshot (an index bump landed while the lot was in flight) -> the lot
/// earned `amount * (stamp - snapshot)` that nobody else holds, credit it here.
fun RewardWalletStorage.receiveLot(mutate self, amount: coins, indices: map<uint8, uint128>) {
    self.freezeAt(indices, self.balance);
    var r = indices.findFirst();
    while (r.isFound) {
        val id = r.getKey();
        val snapshot = r.loadValue() as int;
        val stamp = indexOf(self.stamps, id);
        if (stamp > snapshot) {
            val earned = (amount * (stamp - snapshot)) / INDEX_SCALE;
            self.accrued.set(id, (amountOf(self.accrued, id) + earned) as coins);
        }
        r = indices.iterateNext(r);
    }
    self.balance += amount;
}
