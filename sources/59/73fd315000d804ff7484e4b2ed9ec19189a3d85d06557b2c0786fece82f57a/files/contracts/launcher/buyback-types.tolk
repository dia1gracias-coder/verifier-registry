// BuybackVault: receives the 5 % buyback share of every coin's fees, buys $DESK on its own
// market (curve, then pool) under keeper-bounded quotes and burns everything it receives.
// Nothing can ever be withdrawn.

/// Market kinds.
const MARKET_NONE = 0
const MARKET_CURVE = 1
const MARKET_POOL = 2

struct BuybackRoles {
    admin: address
    keeper: address
    /// RewardMaster of $DESK.
    deskMaster: address
}

struct BuybackStats {
    totalTonIn: coins
    totalTonSpent: coins
    totalBurned: coins
    burns: uint32
}

const PENDING_BUY = 1
const PENDING_BURN = 2

/// One operation in flight: a buy (amount = TON spent) or a burn (amount = $DESK burned).
struct BuybackPending {
    kind: uint8
    queryId: uint64
    amount: coins
    startedAt: uint32
}

struct BuybackStorage {
    /// TON kept on the balance (storage + gas headroom).
    reserve: coins
    /// Upper bound of a single buy.
    maxPerBuy: coins
    pendingTimeout: uint32
    marketKind: uint8
    market: address?
    /// Our RewardWallet for $DESK, discovered through TEP-89.
    deskWallet: address?
    roles: Cell<BuybackRoles>
    stats: Cell<BuybackStats>
    pending: Cell<BuybackPending>?
}

fun BuybackStorage.load(): BuybackStorage {
    return BuybackStorage.fromCell(contract.getData());
}

fun BuybackStorage.save(self) {
    contract.setData(self.toCell());
}

struct BuybackDataReply {
    reserve: coins
    maxPerBuy: coins
    pendingTimeout: int
    marketKind: int
    market: address?
    deskWallet: address?
    roles: BuybackRoles
    stats: BuybackStats
    pending: BuybackPending?
}
