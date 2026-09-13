// Launcher v2 — Curve (bonding curve) and Pool (constant-product AMM) storage.
// ---------------------------------------------------------------------------
// Pool
// ---------------------------------------------------------------------------

/// Recent buys whose delivery is still in flight are remembered so a bounced delivery can refund
/// the buyer. A ring of this size is kept (older entries are dropped: a bounce comes back within
/// seconds, far before that many buys happened).
const POOL_INFLIGHT_RING = 64

struct PoolRoles {
    master: address
    splitter: address
    /// RewardWallet code: lets the pool recognise its own coin wallet (coins sent to the pool by mistake — e.g. the v1
    /// sell path, a jetton transfer — are returned to their sender; the pool itself never holds coins in a wallet).
    walletCode: cell
}

/// TON kept from a buy (net + LP fee) and coins sent, keyed by the delivery nonce.
struct PoolInFlight {
    to: address
    ton: coins
    coin: coins
}

struct PoolStorage {
    reserveTon: coins
    /// Coins owned by the pool: mirrored by `master.poolReserve` (the pool has no wallet).
    reserveCoin: coins
    /// Share of every trade kept in the pool (locked liquidity grows forever).
    lpFeeBps: uint16
    /// Share of every trade sent to the FeeSplitter (perpetual creator fee).
    protocolFeeBps: uint16
    volumeTon: coins
    /// Delivery nonce: queryId of every PoolOut, key of `inFlight`.
    nonce: uint64
    roles: Cell<PoolRoles>
    inFlight: map<uint64, PoolInFlight>
}

fun PoolStorage.load(): PoolStorage {
    return PoolStorage.fromCell(contract.getData());
}

fun PoolStorage.save(self) {
    contract.setData(self.toCell());
}

struct PoolDataReply {
    reserveTon: coins
    reserveCoin: coins
    lpFeeBps: int
    protocolFeeBps: int
    volumeTon: coins
    nonce: int
    master: address
    splitter: address
}

struct Quote {
    amountOut: coins
    fee: coins
}

// ---------------------------------------------------------------------------
// Curve
// ---------------------------------------------------------------------------

const CURVE_INIT = 0
const CURVE_OPEN = 1
const CURVE_GRADUATED = 2

struct CurveRoles {
    factory: address
    master: address
    splitter: address
}

struct CurveParams {
    /// Receives the graduation fee (minus gas).
    protocol: address
    /// Trade fee (bps of the TON side) sent to the FeeSplitter.
    feeBps: uint16
    /// Coins sold through the curve before graduation.
    curveSupply: coins
    /// Coins credited to the Pool at graduation.
    poolSupply: coins
    /// Real TON collected that triggers graduation (the curve also graduates when sold out).
    graduationTon: coins
    /// Taken from the collected TON at graduation: covers pool deployment gas, rest to protocol.
    graduationFee: coins
    /// Smallest TON amount accepted for a buy.
    minBuy: coins
    /// Pool fee parameters passed at deployment.
    poolLpFeeBps: uint16
    poolProtocolFeeBps: uint16
    /// RewardWallet code handed to the Pool (PoolRoles.walletCode).
    walletCode: cell
}

struct CurveStorage {
    state: uint8
    /// Virtual reserves (x·y = k). Real TON is a subset of `virtualTon`.
    virtualTon: coins
    virtualToken: coins
    realTon: coins
    sold: coins
    pool: address?
    roles: Cell<CurveRoles>
    params: Cell<CurveParams>
}

fun CurveStorage.load(): CurveStorage {
    return CurveStorage.fromCell(contract.getData());
}

fun CurveStorage.save(self) {
    contract.setData(self.toCell());
}

struct CurveDataReply {
    state: int
    virtualTon: coins
    virtualToken: coins
    realTon: coins
    sold: coins
    pool: address?
    roles: CurveRoles
    params: CurveParams
}
