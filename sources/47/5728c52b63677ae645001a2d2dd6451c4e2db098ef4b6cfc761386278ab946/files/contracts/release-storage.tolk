import "release-messages"

// Controller immutable configuration is split into cells to stay below TON cell limits.
struct ControllerAuthorities {
    bootstrapAdmin: address?
    releaseExecutor: address
    diamondCollector: address
}

struct ControllerOldAssetConfig {
    oldDiamondMaster: address
    controllerDiamondWallet: address?
    collectorDiamondWallet: address?
}

struct ControllerNewAssetConfig {
    newJettonMaster: address?
    expectedReserveSupply: coins
    standardWalletCode: cell
}

struct ControllerAssetConfig {
    oldAsset: Cell<ControllerOldAssetConfig>
    newAsset: Cell<ControllerNewAssetConfig>
}

struct ControllerDexPrimary {
    routerAddress: address
    routerPtonWallet: address
    lpAccountAddress: address?
}

struct ControllerDexSecondary {
    lockerAddress: address
    poolAddress: address?
    ptonMasterAddress: address
    newWalletIsToken0: bool
}

struct ControllerDexConfig {
    primary: Cell<ControllerDexPrimary>
    secondary: Cell<ControllerDexSecondary>
}

struct ControllerHardLimits {
    maxNewPerOperation: coins
    maxNewPerEpoch: coins
    epochSeconds: uint32
    maxStoredOperations: uint32
    maxPendingSweeps: uint32
    minDiamondPerNewNumerator: uint64
    minDiamondPerNewDenominator: uint64
    minTonPerNewNumerator: uint64
    minTonPerNewDenominator: uint64
    minLpPerNewNumerator: uint64
    minLpPerNewDenominator: uint64
    maxIntentLifetime: uint32
    terminalRetention: uint32
}

struct ControllerGasConfig {
    lockIntentMessageValue: coins
    newWalletMessageValue: coins
    newForwardTonValue: coins
    ptonForwardTonValue: coins
    ptonFeeValue: coins
    dexPayloadForwardTonValue: coins
    refundMessageValue: coins
}

struct ControllerLimitConfig {
    hard: Cell<ControllerHardLimits>
    gas: Cell<ControllerGasConfig>
}

struct ControllerConfig {
    authorities: Cell<ControllerAuthorities>
    assets: Cell<ControllerAssetConfig>
    dex: Cell<ControllerDexConfig>
    limits: Cell<ControllerLimitConfig>
}

struct ReleaseOperation {
    partiesA: Cell<ReleaseIntentPartiesA>
    partiesB: Cell<ReleaseIntentPartiesB>
    amounts: Cell<ReleaseIntentAmounts>
    createdAt: uint64
    deadline: uint64
    terminalAt: uint64
    refundRequestedAt: uint64
    status: uint8
    lockIntentRegistered: bool
    diamondReceived: bool
    tonFunded: bool
    newRecovered: bool
    tonRecovered: bool
    diamondReturnPending: bool
    diamondReturned: bool
    tonReturned: bool
    lpAmount: coins
}

struct DiamondSweepRecord {
    diamondAmount: coins
    createdAt: uint64
}

struct ControllerDynamicState {
    operations: map<uint64, Cell<ReleaseOperation>>
    pendingSweeps: map<uint64, Cell<DiamondSweepRecord>>
    nextOperationId: uint64
    storedOperations: uint32
    pendingSweepsCount: uint32
    epochStartedAt: uint64
    epochReleasedNew: coins
    sweepableDiamond: coins
    totalLockedDiamond: coins
    totalReleasedNew: coins
    totalLockedLp: coins
    totalRejectedDiamond: coins
    reserveReady: bool
}

struct LiquidityReleaseControllerStorage {
    config: Cell<ControllerConfig>
    dynamic: Cell<ControllerDynamicState>
}

fun LiquidityReleaseControllerStorage.load(): LiquidityReleaseControllerStorage {
    return LiquidityReleaseControllerStorage.fromCell(contract.getData());
}

fun LiquidityReleaseControllerStorage.save(self) {
    contract.setData(self.toCell());
}

// Locker configuration and state.
struct LockerAuthorities {
    bootstrapAdmin: address?
    controllerAddress: address?
}

struct LockerAssetConfig {
    lpJettonMaster: address?
    poolAddress: address?
    lpWalletCode: cell
    lockerLpWallet: address?
}

struct LockerConfig {
    authorities: Cell<LockerAuthorities>
    asset: Cell<LockerAssetConfig>
    withdrawWalletMessageValue: coins
    slotTransferMessageValue: coins
    slotStorageDeposit: coins
    maxSlots: uint32
}

struct LockSlot {
    // Immutable origin keeps delayed authenticated LP chunks attributable even
    // after the withdrawal right has been transferred to another beneficiary.
    originBeneficiary: address
    beneficiary: address
    lpAmount: coins
    createdAt: uint64
    unlockAt: uint64
    // Stored with the slot instead of in a second growing dictionary. This
    // keeps the worst-case Locker cell count below the account storage limit.
    pendingTransfer: Cell<PendingSlotTransfer>?
}

struct LockIntent {
    beneficiary: address
    beneficiaryLpWallet: address
    minLpOut: coins
    deadline: uint64
    expiresAt: uint64
}

struct PendingWithdrawal {
    slotId: uint64
    beneficiaryLpWallet: address
    lpAmount: coins
    initiatedAt: uint64
}

struct PendingSlotTransfer {
    newBeneficiary: address
    expiresAt: uint64
}

struct LockerDynamicState {
    lockIntents: map<uint64, Cell<LockIntent>>
    slots: map<uint64, Cell<LockSlot>>
    pendingWithdrawals: map<uint64, Cell<PendingWithdrawal>>
    lockIntentsCount: uint32
    slotsCount: uint32
    pendingSlotTransfersCount: uint32
    totalLockedLp: coins
    totalWithdrawnLp: coins
}

struct ReleaseLpLockerStorage {
    config: Cell<LockerConfig>
    dynamic: Cell<LockerDynamicState>
}

fun ReleaseLpLockerStorage.load(): ReleaseLpLockerStorage {
    return ReleaseLpLockerStorage.fromCell(contract.getData());
}

fun ReleaseLpLockerStorage.save(self) {
    contract.setData(self.toCell());
}

struct ControllerSummaryReply {
    sealed: bool
    reserveReady: bool
    nextOperationId: uint64
    storedOperations: uint32
    pendingSweepsCount: uint32
    epochStartedAt: uint64
    epochReleasedNew: coins
    sweepableDiamond: coins
    totalLockedDiamond: coins
    totalReleasedNew: coins
    totalLockedLp: coins
    totalRejectedDiamond: coins
}

struct LockerSummaryReply {
    sealed: bool
    lockIntentsCount: uint32
    slotsCount: uint32
    pendingSlotTransfersCount: uint32
    totalLockedLp: coins
    totalWithdrawnLp: coins
    lockSeconds: uint32
    slotTransferAcceptanceSeconds: uint32
}

struct LockIntentReply {
    exists: bool
    beneficiary: address?
    beneficiaryLpWallet: address?
    minLpOut: coins
    deadline: uint64
    expiresAt: uint64
}

struct LockSlotReply {
    exists: bool
    originBeneficiary: address?
    beneficiary: address?
    beneficiaryLpWallet: address?
    lpAmount: coins
    createdAt: uint64
    unlockAt: uint64
    withdrawPending: bool
}

struct SlotTransferReply {
    exists: bool
    newBeneficiary: address?
    expiresAt: uint64
}

struct LockerConfigReply {
    bootstrapAdmin: address?
    controllerAddress: address?
    lpJettonMaster: address?
    poolAddress: address?
    lpWalletCode: cell
    lockerLpWallet: address?
    withdrawWalletMessageValue: coins
    slotTransferMessageValue: coins
    slotStorageDeposit: coins
    maxSlots: uint32
}

struct ReleaseOperationReply {
    exists: bool
    status: uint8
    diamondAmount: coins
    tonAmount: coins
    newAmount: coins
    minLpOut: coins
    createdAt: uint64
    deadline: uint64
    terminalAt: uint64
    refundRequestedAt: uint64
    lockIntentRegistered: bool
    diamondReceived: bool
    tonFunded: bool
    newRecovered: bool
    tonRecovered: bool
    diamondReturnPending: bool
    diamondReturned: bool
    tonReturned: bool
    lpAmount: coins
}
