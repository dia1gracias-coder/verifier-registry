// RewardVault v2 storage. Holds the holders' TON share of a coin, converts it to reward jettons
// through a whitelisted DEX (keeper-triggered, bounded) and pays claims sent by the coin's wallets.

/// Payouts whose jetton transfer is still in flight are remembered (ring of this size) so a bounced
/// transfer can give the reward back to the holder's wallet.
const VAULT_PAYOUT_RING = 64

struct RewardVaultRoles {
    admin: address
    keeper: address
    master: address
    /// RewardWallet code of the coin: lets the vault check that a PayRewardReq comes from a real wallet.
    walletCode: cell
}

struct RewardSlot {
    /// Jetton master of the reward asset.
    rewardMaster: address
    /// The vault's own wallet for that asset, discovered through TEP-89 (null until answered).
    vaultWallet: address?
    /// Reward received while nobody could earn it (circulating == 0); folded into the next bump.
    carry: coins
    /// Reward paid out so far.
    paid: coins
}

struct VaultPending {
    rewardId: uint8
    spend: coins
    minOut: coins
    startedAt: uint32
    queryId: uint64
}

struct PayoutInFlight {
    owner: address
    rewardId: uint8
    amount: coins
}

/// Delay between a vault change proposal and its application (same as the Factory's).
const VAULT_DELAY = 172800

const VAULT_PROPOSAL_DEX = 1
const VAULT_PROPOSAL_ROLES = 2

struct VaultProposal {
    kind: uint8
    payload: cell
    readyAt: uint32
}

/// Sub-cell: DEX whitelist, payouts in flight and the pending governance proposal (the root cell is limited to 4 refs).
struct VaultExtra {
    /// Pools a ConvertReward may route through.
    dexPools: map<address, bool>
    payouts: map<uint64, PayoutInFlight>
    proposal: Cell<VaultProposal>?
}

struct RewardVaultStorage {
    rewardCount: uint8
    cycleNext: uint8
    totalTonIn: coins
    totalTonSpent: coins
    reserve: coins
    pendingTimeout: uint32
    /// queryId of the last payout transfer, key of `extra.payouts`.
    payoutNonce: uint64
    roles: Cell<RewardVaultRoles>
    rewards: map<uint8, RewardSlot>
    /// DeDust native vault (only TON destination).
    dexVault: address
    pending: Cell<VaultPending>?
    extra: Cell<VaultExtra>
}

fun RewardVaultStorage.load(): RewardVaultStorage {
    return RewardVaultStorage.fromCell(contract.getData());
}

fun RewardVaultStorage.save(self) {
    contract.setData(self.toCell());
}

struct RewardVaultDataReply {
    rewardCount: int
    cycleNext: int
    totalTonIn: coins
    totalTonSpent: coins
    reserve: coins
    payoutNonce: int
    roles: RewardVaultRoles
    rewards: map<uint8, RewardSlot>
    pending: VaultPending?
    proposal: VaultProposal?
}
