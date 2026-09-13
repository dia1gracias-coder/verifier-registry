// ---------------------------------------------------------------------------
// Curve
// ---------------------------------------------------------------------------

/// Factory -> Curve, once: start accepting trades.
struct (0x43550001) OpenCurve {
    queryId: uint64
}

/// Anyone -> Curve. Buy coin with the attached TON (minus BUY_GAS). Coins go to `recipient`
/// (the sender when null — the Factory uses it for the creator's first buy).
struct (0x43550002) Buy {
    queryId: uint64
    minOut: coins
    recipient: address?
}

const EVENT_TOPIC_CURVE_TRADE = 0x4355E001
const EVENT_TOPIC_CURVE_GRADUATED = 0x4355E002

struct CurveTradeEvent {
    isBuy: bool
    trader: address
    ton: coins
    coin: coins
    fee: coins
    virtualTon: coins
    virtualToken: coins
    realTon: coins
}

struct CurveGraduatedEvent {
    pool: address
    liquidityTon: coins
    liquidityCoin: coins
    protocolFee: coins
}

// ---------------------------------------------------------------------------
// Pool
// ---------------------------------------------------------------------------

/// Anyone -> Pool. Swap the attached TON (minus SWAP_GAS) for coin.
struct (0x504F0001) SwapTonForCoin {
    queryId: uint64
    minOut: coins
}

const EVENT_TOPIC_POOL_SWAP = 0x504FE001
const EVENT_TOPIC_POOL_REFUND = 0x504FE002

struct PoolSwapEvent {
    isBuy: bool
    trader: address
    ton: coins
    coin: coins
    lpFee: coins
    protocolFee: coins
    reserveTon: coins
    reserveCoin: coins
}

/// A delivery bounced: the buyer got `ton` back (or the pool kept it if the entry had been dropped).
struct PoolRefundEvent {
    nonce: uint64
    coin: coins
    ton: coins
    refunded: bool
}
