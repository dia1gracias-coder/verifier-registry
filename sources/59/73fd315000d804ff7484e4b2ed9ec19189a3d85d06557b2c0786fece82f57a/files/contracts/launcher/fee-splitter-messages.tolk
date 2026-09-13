// ---------------------------------------------------------------------------
// FeeSplitter messages
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

/// Admin: set the RewardVault and (de)activate the holders share. Activating releases `locked`.
struct (0x46530003) SetSplitterVault {
    queryId: uint64
    vault: address
    active: bool
}

/// Admin: hand the admin role to another address (e.g. Ledger → multisig migration).
struct (0x46530004) ChangeSplitterAdmin {
    queryId: uint64
    newAdmin: address
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

struct FeeSplitEvent {
    amount: coins
    holders: coins
    protocol: coins
    pot: coins
    buyback: coins
    lockedHolders: bool
}
