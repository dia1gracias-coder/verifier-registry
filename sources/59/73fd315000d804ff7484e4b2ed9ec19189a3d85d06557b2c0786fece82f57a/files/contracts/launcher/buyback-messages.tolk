/// Keeper -> BuybackVault: spend `tonAmount` on the market, accept at least `minOut` $DESK.
struct (0x42420001) BuybackBuy {
    queryId: uint64
    tonAmount: coins
    minOut: coins
}

/// Keeper -> BuybackVault: drop a pending operation after the timeout.
struct (0x42420002) CancelBuyback {
    queryId: uint64
}

/// Keeper -> BuybackVault: burn `amount` of the $DESK sitting in the vault's wallet.
struct (0x42420003) BuybackBurn {
    queryId: uint64
    amount: coins
}

/// Admin/keeper -> BuybackVault: (re)learn the $DESK market from the RewardMaster itself
/// (curve while open, pool after graduation). Nobody can point the vault at an arbitrary address.
struct (0x42420010) SyncBuybackMarket {
    queryId: uint64
}

struct (0x42420011) SetBuybackLimits {
    queryId: uint64
    reserve: coins
    maxPerBuy: coins
    pendingTimeout: uint32
}

struct (0x42420012) SetBuybackRoles {
    queryId: uint64
    admin: address
    keeper: address
}

const EVENT_TOPIC_BUYBACK = 0x4242E001

struct BuybackEvent {
    queryId: uint64
    tonSpent: coins
    burned: coins
}
