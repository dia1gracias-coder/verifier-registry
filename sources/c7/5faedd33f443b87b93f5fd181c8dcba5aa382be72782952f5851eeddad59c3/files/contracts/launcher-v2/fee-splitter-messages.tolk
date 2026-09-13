import "fee-splitter-types"

// ---------------------------------------------------------------------------
// FeeSplitter v2 messages (FeeIn / RewardIn / BuybackIn keep their v1 opcodes and layouts)
// ---------------------------------------------------------------------------

/// Fee deposit from a Curve or a Pool. `amount` is the fee; the rest of the value is gas that
/// may trigger a split right away.
struct (0x46530001) FeeIn {
    queryId: uint64
    amount: coins
}

/// Anyone: split `accrued` if it reached `minSplit`.
struct (0x46530002) Distribute {
    queryId: uint64
}

/// Admin: set the RewardVault (one-shot) and activate the holders share. Activating releases `locked`.
struct (0x46530003) SetSplitterVault {
    queryId: uint64
    vault: address
    active: bool
}

/// Admin: hand the admin role to another address (e.g. Ledger -> multisig migration).
struct (0x46530004) ChangeSplitterAdmin {
    queryId: uint64
    newAdmin: address
}

/// Admin: (de)activate the holders share without touching the vault. Activating releases `locked`.
struct (0x46530005) SetSplitterActive {
    queryId: uint64
    active: bool
}

/// Admin: propose new splits; they can be applied after SPLITS_DELAY. A new proposal replaces the
/// previous one (and restarts the delay).
struct (0x46530006) ProposeSplits {
    queryId: uint64
    splits: FeeSplits
}

/// Admin: apply the pending proposal once its delay elapsed.
struct (0x46530007) ApplySplits {
    queryId: uint64
}

/// Holders share arriving at a RewardVault (labelled so the vault can account it).
struct (0x46530010) RewardIn {
    queryId: uint64
}

/// Buyback share arriving at the BuybackVault.
struct (0x46530011) BuybackIn {
    queryId: uint64
}

const EVENT_TOPIC_FEE_SPLIT = 0x4653E001
const EVENT_TOPIC_SPLITS_CHANGED = 0x4653E002

struct FeeSplitEvent {
    amount: coins
    holders: coins
    protocol: coins
    pot: coins
    buyback: coins
    lockedHolders: bool
}

/// Emitted when new splits are proposed (applied = false) and when they are applied.
struct SplitsChangedEvent {
    splits: FeeSplits
    applied: bool
    readyAt: uint32
}
