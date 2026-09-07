import "errors"
import "jetton-messages"

const RELEASE_PROTOCOL_VERSION = 1
const RELEASE_LOCK_SECONDS = 180 * 24 * 60 * 60

// Shared protocol states and query-id namespaces. Keep these declarations in the
// wire-schema module so contracts, wrappers and off-chain tests use one source of
// truth instead of copying magic numbers.
const RELEASE_STATUS_WAITING_INPUTS = 1
const RELEASE_STATUS_LEGS_DISPATCHED = 2
const RELEASE_STATUS_LP_LOCKED = 3
const RELEASE_STATUS_REFUNDING = 4
const RELEASE_STATUS_REFUNDED = 5
const RELEASE_STATUS_CANCELLED = 6

const RELEASE_ASSET_NEW = 1
const RELEASE_ASSET_PTON = 2

const OPERATION_REFUND_FLAG = 1 << 63
const REJECTED_RETURN_FLAG = 1 << 62
const EXTERNAL_ID_MASK = (1 << 62) - 1

struct ReleaseIntentPartiesA {
    beneficiary: address
    beneficiaryLpWallet: address
    tonPayer: address
}

struct ReleaseIntentPartiesB {
    tonRefundAddress: address
    diamondOwner: address
    diamondOwnerWallet: address
}

struct ReleaseIntentAmounts {
    diamondAmount: coins
    tonAmount: coins
    newAmount: coins
    minLpOut: coins
}

struct (0x8642c609) BindReleaseAssets {
    queryId: uint64
    oldControllerWallet: address
    collectorDiamondWallet: address
    newJetton: Cell<BoundNewJetton>
    dex: Cell<BoundReleaseDex>
}

struct BoundNewJetton {
    masterAddress: address
    expectedReserveSupply: coins
}

// Pool and LpAccount addresses cannot be part of Controller's initial state:
// both depend on the future NEW master while that master itself is deployed for
// Controller's deterministic address. They are therefore sealed once, together
// with the NEW master, after STON.fi creates the pool.
struct BoundReleaseDex {
    poolAddress: address
    lpAccountAddress: address
    newWalletIsToken0: bool
}

struct (0x95839085) BindLockerController {
    queryId: uint64
    controllerAddress: address
    asset: Cell<BoundLockerAsset>
}

struct BoundLockerAsset {
    lpJettonMaster: address
    poolAddress: address
    lockerLpWallet: address
}

struct (0x41349a16) CreateReleaseOperation {
    operationId: uint64
    deadline: uint64
    partiesA: Cell<ReleaseIntentPartiesA>
    partiesB: Cell<ReleaseIntentPartiesB>
    amounts: Cell<ReleaseIntentAmounts>
}

// A Pool transfer_notification authenticates the STON.fi Pool, but STON.fi
// deliberately lets every liquidity provider choose receiver_address and
// dex_custom_payload.  The Locker must therefore accept an operation id only
// after the immutable Controller has registered the exact expected intent.
struct LockIntentParties {
    beneficiary: address
    beneficiaryLpWallet: address
    controllerAddress: address
}

struct LockIntentTerms {
    protocolVersion: uint8
    minLpOut: coins
    deadline: uint64
    expiresAt: uint64
    lockSeconds: uint32
}

struct (0x75a85c31) RegisterLockIntent {
    queryId: uint64
    parties: Cell<LockIntentParties>
    terms: Cell<LockIntentTerms>
}

struct (0x2f021690) LockIntentRegistered {
    operationId: uint64
}

struct (0x45ca0f5d) RetryLockIntentRegistration {
    operationId: uint64
}

struct (0x73eb0e91) PruneExpiredLockIntent {
    operationId: uint64
}

struct (0x40430950) FundReleaseTon {
    operationId: uint64
}

struct (0x988a3b95) DepositDiamondPayload {
    operationId: uint64
}

struct (0x52455356) ReserveBootstrapPayload {
    protocolVersion: uint8
}

struct (0x42671380) LockerDepositPayload {
    protocolVersion: uint8
    operationId: uint64
    beneficiary: address
    beneficiaryLpWallet: address
    controllerAddress: address
    lockSeconds: uint32
}

struct (0x491d827d) LockConfirmed {
    operationId: uint64
    lpAmount: coins
    unlockAt: uint64
}

struct (0x65423bd2) ReconcileExpiredRelease {
    operationId: uint64
}

struct (0x26c8abd2) CancelUnfundedRelease {
    operationId: uint64
}

struct (0xe9c474f7) PruneTerminalRelease {
    operationId: uint64
}

struct (0xf10e258a) SweepDiamond {
    queryId: uint64
    diamondAmount: coins
}

struct (0x89d81e04) RefundAssetPayload {
    operationId: uint64
    assetKind: uint8
}

struct (0x147e12cd) ReturnTonPrincipal {
    operationId: uint64
}

struct (0x1e9e70c4) WithdrawSlot {
    slotId: uint64
}

// Slot ownership uses an explicit two-party handshake. The current beneficiary
// can only propose a basechain recipient; the recipient must then prove control
// of that address before the immutable withdrawal right moves.
struct (0xe794210e) ProposeSlotTransfer {
    slotId: uint64
    newBeneficiary: address
}

struct (0x08f4bd4e) AcceptSlotTransfer {
    slotId: uint64
}

struct (0xcf687f89) CancelSlotTransfer {
    slotId: uint64
}

struct (0x5dcb4c30) PruneExpiredSlotTransfer {
    slotId: uint64
}

struct (0x1f2c41f2) WithdrawConfirmed {
    slotId: uint64
    lpAmount: coins
}

struct (0x04c53199) ReplayLockAck {
    slotId: uint64
}

// Permissionless liveness path for the one-shot reserve handshake.  The
// Controller only emits this after it has authenticated the full reserve
// wallet notification, so the caller can never manufacture readiness or
// choose an amount/master.
struct (0x6baad5ae) ReplayReserveReady {
    queryId: uint64
}

// Permissionless recovery for the first half of the reserve handshake.  The
// Controller orders its own Jetton wallet to transfer the complete immutable
// reserve to itself, which cannot move tokens to another owner but recreates
// the authenticated transfer notification if the original one was lost.
struct (0x559bb7a1) RetryReserveBootstrap {
    queryId: uint64
}

// STON.fi Router v2.1 provide_lp payload.
struct StonProvideLiquidityDetails {
    minLpOut: coins
    receiverAddress: address
    bothPositive: bool
    dexCustomPayloadForwardGasAmount: coins
    dexCustomPayload: cell?
}

struct (0x37c096df) StonProvideLiquidity {
    routerWalletAddress: address
    refundAddress: address
    excessesAddress: address
    deadline: uint64
    details: Cell<StonProvideLiquidityDetails>
}

struct (0x01f3835d) PtonTonTransfer {
    queryId: uint64
    tonAmount: coins
    refundAddress: address
    forwardPayload: cell?
}

struct (0xae25d79e) PtonTonRefund {
    queryId: uint64
}

struct (0x132b9a2c) StonLpAccountRefund {
    queryId: uint64
    leftPayload: cell?
    rightPayload: cell?
}

fun ForwardPayloadRemainder.loadRequiredPayloadRef(mutate self): cell {
    val payload = self.loadMaybeRef();
    assert (payload != null) throw Errors.InvalidMessage;
    self.assertEnd();
    return payload!;
}

fun payloadInRef<T>(value: T): ForwardPayloadRemainder {
    return beginCell().storeMaybeRef(value.toCell()).endCell().beginParse();
}

fun payloadCellInRef(value: cell): ForwardPayloadRemainder {
    return beginCell().storeMaybeRef(value).endCell().beginParse();
}
