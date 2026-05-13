// Bonding-launchpad protocol op-codes.
// Distinct from TEP-74 (0x0f8a7ea5, 0x7362d09c, etc.) defined in messages.tolk.
// === Sent TO BondingCurveMaster ===

struct (0xa0a0a001) CreateLaunch {
    queryId: uint64
    metadata: cell
    salt: uint64
}

struct (0xa0a0a002) ChangeMasterAdmin {
    queryId: uint64
    newAdmin: address
}

struct (0xa0a0a003) ClaimMasterAdmin {
    queryId: uint64
}

struct (0xa0a0a004) ChangeTreasury {
    queryId: uint64
    newTreasury: address
}

struct (0xa0a0a005) WithdrawProtocolFees {
    queryId: uint64
    amount: coins
}

// Sent by a BondingCurve to the master to push accumulated fees. The master verifies the
// sender's address against the deterministic launch address derived from (creator, salt).
// `amount` carries the exact fee amount the curve flushed (so a bounce can restore it precisely
// instead of relying on in.valueCoins which differs after forward-fee deductions).
struct (0xa0a0a006) DepositProtocolFees {
    queryId: uint64
    creator: address
    salt: uint64
    amount: coins
}

// Admin-only kick to re-run InitializeCurve on a curve whose init mint bounced
// (state == INITIALIZING && jettonMinter == null after MintNewJettons bounce).
struct (0xa0a0a014) ReinitializeCurve {
    queryId: uint64
    creator: address
    salt: uint64
    metadata: cell
}

// Body of the master's outgoing TON payout to the treasury on WithdrawProtocolFees.
// Carries `amount` so a bounce can restore feesBalance precisely.
struct (0xa0a0a015) TreasuryPayout {
    queryId: uint64
    amount: coins
}

// === Sent TO BondingCurve ===

// Initial kick from master, immediately after deploy, asking the curve to self-mint.
struct (0xa0a0a010) InitializeCurve {
    queryId: uint64
    jettonMinter: address
}

// Buy with TON attached. Curve sends Jettons back.
struct (0xa0a0a011) BuyJettons {
    queryId: uint64
    minJettonsOut: coins
}

// Anyone can flush the curve's accumulated TON fees to the master treasury. Caller pays gas.
struct (0xa0a0a013) FlushFees {
    queryId: uint64
}

// Permissionless: anyone can trigger graduation once threshold is met. The curve recomputes
// the CPMM v2 pool's deterministic address on-chain (from the jetton minter + canonical
// PoolConfig), deploys the pool atomically via stateInit on the first Init message, then
// fires the two-sided deposit (PayNative + AskToTransfer with PayJetton forwardPayload).
// LP is locked atomically inside the pool via DepositPayload.lockedLiquidityShare = 100%;
// the curve never receives an LP token.
struct (0xa0a0a012) Graduate {
    queryId: uint64
}

// === Forward-payload markers (used when user sends Jettons back to the curve) ===

// When a user transfers Jettons to the curve via TEP-74 AskToTransfer, the forwardPayload
// carries this struct to signal it's a SELL with slippage protection.
struct (0xa0a0a020) SellPayload {
    queryId: uint64
    minTonOut: coins
}

// === DeDust CPMM v2 raw message bodies ===
//
// These structs mirror the cell layout DeDust's CPMM v2 contracts expect. Op-codes belong to
// DeDust (0xde8402ce, 0xa5a7cbf8, ...), not our 0xa0a0a0xx namespace. Defined here so Tolk's
// struct encoder can serialize them via `createMessage({..., body: ...})`.

// Sent to a CPMM v2 Pool. If sent with stateInit attached, deploys the pool. Otherwise no-op.
// Layout: TAG (32) + queryId (64) + maybeRef(customPayload).
// customPayload is intentionally opaque pass-through (we always send null in v1).
struct (0xde8402ce) DedustInit {
    queryId: uint64
    customPayload: cell?
}

// Inner deposit instructions for CPMM v2. Wrapped as a ref inside PayNative and inside
// PayJetton's forwardPayload. Tells the pool target reserves + LP-lock policy.
// Layout per /tmp/dedust-kit/src/cpmm-v2/abi/messages/DepositPayload.ts:
//   TAG (32) + amountX (coins) + amountY (coins) + minimalLiquidity (coins) + lockedShare (uint16)
struct (0xc9a015da) DedustDepositPayload {
    amountX: coins
    amountY: coins
    minimalLiquidity: coins
    lockedLiquidityShare: uint16
}

// Sent to a CPMM v2 Pool with TON attached. `amount` is the TON side of the deposit/swap.
// Layout: TAG (32) + queryId (64) + amount (coins) + ref{DedustDepositPayload} + ref{payoutConfig}.
// `payoutConfig` stays `cell` (opaque pass-through): we always build an empty ExtendedPayoutConfig
// via buildEmptyExtendedPayoutConfig, whose internal layout is DeDust-owned and dictated by their
// PayoutOptions+MaybeAddress nesting — not worth fully typing in Tolk.
struct (0xa5a7cbf8) DedustPayNative {
    queryId: uint64
    amount: coins
    paymentPayload: Cell<DedustDepositPayload>
    payoutConfig: cell
}

// Sent by the launch creator to the CPMM v2 Pool to withdraw accumulated creator fees
// (the 1% creatorFeeBPS the pool charges per swap). Pool checks sender == creatorAddress
// (set in PoolConfig at deploy = the user who called CreateLaunch on master).
// Layout: TAG (32) + queryId (64) + to (addr_std 267) + excessesTo (addr_std 267).
// Reference: /tmp/dedust-kit/src/cpmm-v2/abi/messages/ClaimCreatorFees.ts
struct (0xbe3e3179) DedustClaimCreatorFees {
    queryId: uint64
    to: address
    excessesTo: address
}

// === Event-style external logs (TVM external_out messages, no destination) ===
//
// Topic = originating opcode (matches the protocol op-code for easy mental model).
// Indexers filter by topic in the destination address (ExtOutLogBucket) without parsing body.
// Cost ~0.001 TON per event. Reference:
//   https://docs.ton.org/v3/documentation/smart-contracts/messages/sending-messages

const TOPIC_BUY: int = 0xa0a0a011
const TOPIC_SELL: int = 0xa0a0a020
const TOPIC_GRADUATE: int = 0xa0a0a012
const TOPIC_LAUNCH_CREATED: int = 0xa0a0a001

struct BuyEvent {
    buyer: address
    tonInNet: coins       // post-fee, post-CURVE_TRANSFER_VALUE
    jettonsOut: coins
    feeAccrued: coins     // 1% protocol fee credited this buy
    realTonReserve: coins // post-buy state (cumulative)
    curveJettonBalance: coins
}

struct SellEvent {
    seller: address
    jettonsIn: coins      // accepted (post-maxSafe clamp)
    tonOut: coins         // net to seller (post-fee)
    feeAccrued: coins     // 1% protocol fee credited this sell
    realTonReserve: coins // post-sell state
    curveJettonBalance: coins
}

struct GraduateEvent {
    poolAddress: address
    poolSeedTon: coins
    poolSeedJettons: coins
    migrationFee: coins
    strandedJettons: coins // permanently locked in curve
}

struct LaunchCreatedEvent {
    creator: address
    salt: uint64
    curveAddress: address
    minterAddress: address
}
