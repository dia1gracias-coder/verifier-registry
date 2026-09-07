const PERMISSIONLESS_RELEASE_PROTOCOL_VERSION = 3
const PERMISSIONLESS_PROTOCOL_FEE_DENOMINATOR_BPS = 10_000

const PERMISSIONLESS_STATUS_OBSERVING_FIRST = 1
const PERMISSIONLESS_STATUS_WAITING_SECOND = 2
const PERMISSIONLESS_STATUS_OBSERVING_SECOND = 3
const PERMISSIONLESS_STATUS_REGISTERING_LOCK = 4
const PERMISSIONLESS_STATUS_LEGS_DISPATCHED = 5
const PERMISSIONLESS_STATUS_LP_LOCKED = 6
const PERMISSIONLESS_STATUS_REFUNDING = 7
const PERMISSIONLESS_STATUS_REFUNDED = 8
const PERMISSIONLESS_STATUS_CANCELLED = 9

const PRICE_QUERY_MARK = 1 << 63
const PRICE_QUERY_SECOND_MARK = 1 << 62
const PRICE_QUERY_DIAMOND_MARK = 1 << 61
const WALLET_DISCOVERY_QUERY_MARK = 1 << 60
const PERMISSIONLESS_OPERATION_ID_MASK = (1 << 60) - 1

struct PermissionlessBoundNewJetton {
    masterAddress: address
    expectedReserveSupply: coins
}

struct PermissionlessBoundDex {
    newTonPoolAddress: address
    lpAccountAddress: address
    newWalletIsToken0: bool
}

struct (0x8642c60a) BindPermissionlessReleaseAssets {
    queryId: uint64
    oldControllerWallet: address
    collectorDiamondWallet: address
    newJetton: Cell<PermissionlessBoundNewJetton>
    dex: Cell<PermissionlessBoundDex>
}

// Payload of the authenticated old-DIAMOND transfer_notification. The same
// Jetton transfer forwards both the native TON principal and the execution gas.
struct (0x504c5232) PermissionlessReleaseDepositPayload {
    protocolVersion: uint8
    clientQueryId: uint64
    tonAmount: coins
    beneficiary: address
    tonRefundAddress: address
}

struct (0x51a77d01) RequestSecondPriceObservation {
    operationId: uint64
}

struct (0x51a77d02) RetryPriceObservation {
    operationId: uint64
    round: uint8
}

struct (0x51a77d03) RetryDiamondWalletDiscovery {
    operationId: uint64
}

struct (0x51a77d04) PermissionlessReleaseAccepted {
    clientQueryId: uint64
    operationId: uint64
    protocolFeeTon: coins
    secondObservationAfter: uint64
    deadline: uint64
}

struct (0x51a77d05) PermissionlessQuoteFinalized {
    operationId: uint64
    diamondAmount: coins
    tonAmount: coins
    protocolFeeTon: coins
    newAmount: coins
    minLpOut: coins
}

// Anyone may fund the gas for flushing all accrued protocol fees. The
// Controller always chooses the immutable recipient and exact accrued amount.
struct (0x51a77d06) FlushProtocolTonFees {
    queryId: uint64
}

struct (0x51a77d07) ProtocolTonFeePayout {
    queryId: uint64
    feeAmount: coins
}

struct (0x51a77d08) ProtocolTonFeesFlushed {
    queryId: uint64
    feeAmount: coins
}

// Official STON.fi v2 on-chain getter response. The request has the same opcode
// and only op + query_id; it is built manually at the external TL-B boundary.
struct (0x26df39fc) StonPoolDataResponse {
    queryId: uint64
    isLocked: bool
    reserve0: coins
    reserve1: coins
    token0Address: address
    token1Address: address
    additionalData: cell
}

struct StonPoolDataAdditional {
    lpFee: uint16
    protocolFee: uint16
    routerAddress: address
    protocolFeeAddress: address?
    totalLpSupply: coins
    collectedToken0ProtocolFee: coins
    collectedToken1ProtocolFee: coins
}

fun buildStonPoolDataRequest(queryId: uint64): cell {
    // STON.fi: getter_pool_data#26df39fc query_id:uint64 = InternalMsgBody.
    return beginCell().storeUint(0x26df39fc, 32).storeUint(queryId, 64).endCell();
}

fun priceQueryId(operationId: uint64, second: bool, diamondPool: bool): uint64 {
    var queryId = PRICE_QUERY_MARK | operationId;
    if (second) {
        queryId |= PRICE_QUERY_SECOND_MARK;
    }
    if (diamondPool) {
        queryId |= PRICE_QUERY_DIAMOND_MARK;
    }
    return queryId;
}

fun priceQueryOperationId(queryId: uint64): uint64 {
    return queryId & PERMISSIONLESS_OPERATION_ID_MASK;
}

fun walletDiscoveryQueryId(operationId: uint64): uint64 {
    return WALLET_DISCOVERY_QUERY_MARK | operationId;
}

fun calculatePermissionlessProtocolFeeTon(tonAmount: coins, feeBps: uint16): coins {
    val numerator = tonAmount * 2 * feeBps;
    return numerator / PERMISSIONLESS_PROTOCOL_FEE_DENOMINATOR_BPS +
    ((numerator % PERMISSIONLESS_PROTOCOL_FEE_DENOMINATOR_BPS) == 0 ? 0 : 1);
}
