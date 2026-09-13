// FeeSplitter v2 (coin): split of every TON fee earned by a launched coin. Shares are basis points
// and must sum to 10000; the protocol share can never go below `minProtocolBps`. Changing the splits
// takes SPLITS_DELAY (48 h) between the proposal and its application so holders can see it coming.

/// Delay between ProposeSplits and ApplySplits.
const SPLITS_DELAY = 172800

struct FeeSplits {
    holdersBps: uint16
    protocolBps: uint16
    potBps: uint16
    buybackBps: uint16
}

/// Fixed destinations (sub-cell: addresses do not fit the root cell).
struct FeeRoutes {
    protocol: address
    pot: address
    buyback: address
}

/// Holders destination + shares (sub-cell, rewritten on activation / splits change).
struct RewardRoute {
    /// RewardVault receiving the holders share. Null until wired (one-shot).
    vault: address?
    splits: FeeSplits
}

struct SplitsProposal {
    splits: FeeSplits
    readyAt: uint32
}

struct FeeSplitterStorage {
    /// Protocol admin: wires the vault, toggles `active`, proposes / applies splits.
    admin: address
    /// While false the holders share is kept here (`locked`) — "Locked for pre-stocks".
    active: bool
    /// Holders TON kept until the reward is activated.
    locked: coins
    /// Fee TON received and not yet split (below `minSplit`).
    accrued: coins
    /// Lifetime fee TON received.
    totalIn: coins
    /// Minimum accrued TON before a split is executed (keeps 4 outgoing messages worth it).
    minSplit: coins
    /// Floor for `splits.protocolBps` in any proposal (set at deployment).
    minProtocolBps: uint16
    routes: Cell<FeeRoutes>
    reward: Cell<RewardRoute>
    proposal: Cell<SplitsProposal>?
}

fun FeeSplitterStorage.load(): FeeSplitterStorage {
    return FeeSplitterStorage.fromCell(contract.getData());
}

fun FeeSplitterStorage.save(self) {
    contract.setData(self.toCell());
}

struct FeeSplitterDataReply {
    admin: address
    active: bool
    locked: coins
    accrued: coins
    totalIn: coins
    minSplit: coins
    minProtocolBps: int
    routes: FeeRoutes
    reward: RewardRoute
    proposal: SplitsProposal?
}

fun FeeSplits.isValid(self, minProtocolBps: int): bool {
    return self.holdersBps + self.protocolBps + self.potBps + self.buybackBps == 10000 &&
    self.protocolBps >= minProtocolBps;
}
