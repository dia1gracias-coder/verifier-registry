// Pot storage. Root cell holds scalars; addresses and code live in sub-cells (1023-bit limit).

struct PotRoles {
    admin: address
    keeper: address
    collection: address
    deskItemCode: cell
}

struct PotWhitelist {
    /// DeDust native (TON) vault: the only destination a Convert may send TON to.
    dexVault: address
    /// DeDust pools a Convert may route through (TON/USDT); the swap body is built on-chain.
    dexPools: map<address, bool>
    /// Omniston escrow minter: recipient of the USDT transfer that opens a position.
    escrowMinter: address
    /// Expected opcode of the escrow forward payload.
    escrowOp: uint32
    /// Bit offset (from the start of the forward payload) where the position owner address begins.
    escrowOwnerBitOffset: uint16
    /// Where the escrow payload stores the minimum stock the resolver must deliver:
    /// index of the payload ref holding it (255 = root cell) and bit offset inside that cell (Coins encoding).
    escrowMinOutRef: uint8
    escrowMinOutBitOffset: uint16
}

struct PotParams {
    /// Pot's own USDT jetton wallet. Round/Convert are disabled while null.
    usdtWallet: address?
    /// TON never spent (storage + gas headroom).
    reserve: coins
    /// Minimum TON (above reserve) before a Convert can run.
    threshold: coins
    /// Maximum TON swapped by a single Convert.
    maxConvertTon: coins
    /// Price floor for Convert: micro-USDT the Pot must receive per 1 TON at minimum (0 = converts disabled).
    floorUsdtPerTon: coins
    /// Maximum USDT spent per Round.
    maxRoundUsdt: coins
    /// Seconds after which a pending operation may be cancelled by the keeper.
    pendingTimeout: uint32
    whitelist: Cell<PotWhitelist>
}

struct Slot {
    master: address
    potWallet: address
    enabled: bool
    /// Cumulative per-desk share, COUNTER_SCALE fixed point.
    counter: uint128
    /// Price floor for Round: stock units the escrow must deliver per 1 USDT (1e6 units) at minimum (0 = rounds disabled).
    floorPerUsdt: coins
}

/// Kind of in-flight operation.
const PENDING_CONVERT = 1
const PENDING_ROUND = 2

struct Pending {
    kind: uint8
    slot: uint8
    spend: coins
    minOut: coins
    startedAt: uint32
    advance: bool
}

struct PotStorage {
    liveDesks: uint32
    rotationNext: uint8
    slotCount: uint8
    roundNo: uint32
    totalTonIn: coins
    totalTonSpent: coins
    usdtBudget: coins
    roles: Cell<PotRoles>
    params: Cell<PotParams>
    slots: map<uint8, Slot>
    pending: Cell<Pending>?
}

fun PotStorage.load(): PotStorage {
    return PotStorage.fromCell(contract.getData());
}

fun PotStorage.save(self) {
    contract.setData(self.toCell());
}

struct PotDataReply {
    liveDesks: int
    rotationNext: int
    slotCount: int
    roundNo: int
    totalTonIn: coins
    totalTonSpent: coins
    usdtBudget: coins
    pending: Pending?
}

/// USDT has 6 decimals: floors are expressed per 1 USDT = 1e6 units.
const USDT_ONE = 1000000
/// 1 TON in nanoTON.
const TON_ONE = 1000000000

/// Cell the escrow min-out lives in: root (255) or one of the payload refs.
fun escrowMinOutCell(payload: cell, refIndex: uint8): cell {
    if (refIndex == 255) {
        return payload;
    }
    var s = payload.beginParse();
    repeat (refIndex) {
        s.loadRef();
    }
    return s.loadRef();
}
