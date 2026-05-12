const HOO_MASTER = address("EQDLUAaiceftUgbqR3UJND2Anbl1-U8g7qbF0TB9N8PGK_SD")
const USDT_TON_MASTER = address("EQCxE6mUtQJKFnGfaROTKOt1lZbDiiX1kCixRv7Nw2Id_sDs")
const TREASURY_WALLET = address("UQAb44ErsVonYj0F64bEvQiB_dnXdDJW2dJ9PkwXe72LW-4z")

const PRESALE_PRICE_USDT_MICRO = 300000
const TARGET_PRICE_USDT_MICRO = 2000000
const SALE_ALLOCATION_HOO_NANO = 500000000000000
const MIN_PURCHASE_USDT_MICRO = 10000000
const HARD_CAP_USDT_MICRO = 150000000000
const HOO_UNIT_NANO = 1000000000
const HOO_TRANSFER_TON_VALUE = ton("0.08")
const USDT_FORWARD_TON_VALUE = ton("0.06")

// TON payment and treasury flush
const GAS_RESERVE_TON       = ton("2")
const TON_PURCHASE_GAS_COST = ton("0.1")   // HOO transfer (0.08) + processing overhead
const FLUSH_USDT_THRESHOLD  = 100_000_000   // 100 USDT in micro-USDT
const FLUSH_TON_THRESHOLD   = ton("20")

enum Errors {
    JettonWalletsNotSet  = 6061
    OnlyUnsold           = 24903
    DuplicateQuery       = 30841
    BelowMinPurchase     = 35855
    SoldOut              = 36305
    OnlyOwner            = 37469
    InvalidUsdtWallet    = 47168
    ZeroHoo              = 51223
    ZeroUsdt             = 51224
    SalePaused           = 62929
    MissingBuyer         = 63520
    HardCapReached       = 63521
    TonPriceNotSet       = 11001
    BelowFlushThreshold  = 11002
    InsufficientTon      = 11003
}

struct PresaleStorage {
    admin: cell
    jettons: cell
    jettonWalletsConfigured: bool
    raisedUsdt: coins
    issuedHoo: coins
    paused: bool
    pendingPurchases: map<uint64, PendingPurchase>
    accumulatedUsdt: coins       // confirmed USDT waiting for FlushToTreasury
    accumulatedTon: coins        // net buyer TON waiting for FlushToTreasury
    tonPriceUsdtMicro: coins     // price of 1 TON in micro-USDT (0 = TON payments disabled)
}

struct PresaleAdminAddresses {
    owner: address
    treasury: address
}

struct PresaleJettonWallets {
    usdtWallet: address
    hooWallet: address
}

struct PendingPurchase {
    buyer: address
    usdtAmount: coins    // >0 for USDT purchases; 0 for TON purchases
    hooAmount: coins
    tonAmount: coins     // net TON credited (>0 for TON purchases; 0 for USDT)
}

struct SaleData {
    hooMaster: address
    usdtMaster: address
    treasury: address
    priceUsdtMicro: uint64
    targetPriceUsdtMicro: uint64
    usdtWallet: address
    hooWallet: address
    jettonWalletsConfigured: bool
    allocationHooNano: coins
    hardCapUsdtMicro: coins
    minPurchaseUsdtMicro: coins
    raisedUsdt: coins
    issuedHoo: coins
    paused: bool
    accumulatedUsdt: coins
    accumulatedTon: coins
    tonPriceUsdtMicro: coins
}

fun PresaleStorage.load(): PresaleStorage {
    return PresaleStorage.fromCell(contract.getData());
}

fun PresaleStorage.save(self) {
    contract.setData(self.toCell());
}

fun PresaleStorage.adminAddresses(self): PresaleAdminAddresses {
    return PresaleAdminAddresses.fromCell(self.admin);
}

fun PresaleStorage.jettonWallets(self): PresaleJettonWallets {
    return PresaleJettonWallets.fromCell(self.jettons);
}
