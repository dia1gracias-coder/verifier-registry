struct PermissionlessControllerAuthorities {
    bootstrapAdmin: address?
    diamondCollector: address
}

struct PermissionlessAssetMasters {
    oldDiamondMaster: address
    newJettonMaster: address?
    expectedReserveSupply: coins
    standardNewWalletCode: cell
}

struct PermissionlessAssetWallets {
    controllerDiamondWallet: address?
    collectorDiamondWallet: address?
}

struct PermissionlessAssetConfig {
    masters: Cell<PermissionlessAssetMasters>
    wallets: Cell<PermissionlessAssetWallets>
}

struct PermissionlessExecutionRouterConfig {
    routerAddress: address
    routerPtonWallet: address
    ptonMasterAddress: address
}

struct PermissionlessExecutionLiquidityConfig {
    lockerAddress: address
    newTonPoolAddress: address?
    lpAccountAddress: address?
    newWalletIsToken0: bool
    stonLpWalletCode: cell
}

struct PermissionlessExecutionDexConfig {
    router: Cell<PermissionlessExecutionRouterConfig>
    liquidity: Cell<PermissionlessExecutionLiquidityConfig>
}

struct PermissionlessPricePoolAddresses {
    poolAddress: address
    assetRouterWallet: address
    ptonRouterWallet: address
}

struct PermissionlessPricePoolConfig {
    addresses: Cell<PermissionlessPricePoolAddresses>
    routerAddress: address
    assetIsToken0: bool
}

struct PermissionlessDexConfig {
    execution: Cell<PermissionlessExecutionDexConfig>
    diamondPricePool: Cell<PermissionlessPricePoolConfig>
}

struct PermissionlessPoolDepthRules {
    minDiamondPoolTonReserve: coins
    minNewPoolTonReserve: coins
}

struct PermissionlessProtocolFeeConfig {
    feeBps: uint16
    recipient: address
}

struct PermissionlessReleaseRules {
    minTonContribution: coins
    protocolFee: Cell<PermissionlessProtocolFeeConfig>
    poolDepths: Cell<PermissionlessPoolDepthRules>
    bootstrapTonAmount: coins
    bootstrapNewAmount: coins
    bootstrapMinLpOut: coins
    bootstrapBeneficiary: address
    maxStoredOperations: uint32
    maxPendingSweeps: uint32
    observationWindowSeconds: uint32
    maxSnapshotSkewSeconds: uint32
    maxPriceDeviationBps: uint16
    maxInputImbalanceBps: uint16
    lpSlippageBps: uint16
    maxIntentLifetime: uint32
    terminalRetention: uint32
}

struct PermissionlessObservationGasConfig {
    operationGasDeposit: coins
    feeFlushGasDeposit: coins
    poolQueryMessageValue: coins
    walletDiscoveryMessageValue: coins
    lockIntentMessageValue: coins
    refundMessageValue: coins
}

struct PermissionlessDexGasConfig {
    newWalletMessageValue: coins
    newForwardTonValue: coins
    ptonForwardTonValue: coins
    ptonFeeValue: coins
    dexPayloadForwardTonValue: coins
}

struct PermissionlessGasConfig {
    observation: Cell<PermissionlessObservationGasConfig>
    dex: Cell<PermissionlessDexGasConfig>
}

struct PermissionlessLimitsConfig {
    rules: Cell<PermissionlessReleaseRules>
    gas: Cell<PermissionlessGasConfig>
}

struct PermissionlessControllerConfig {
    authorities: Cell<PermissionlessControllerAuthorities>
    assets: Cell<PermissionlessAssetConfig>
    dex: Cell<PermissionlessDexConfig>
    limits: Cell<PermissionlessLimitsConfig>
}

struct PermissionlessReleasePartiesPrimary {
    clientQueryId: uint64
    beneficiary: address
    beneficiaryLpWallet: address
}

struct PermissionlessReleasePartiesRefund {
    tonRefundAddress: address
    diamondOwner: address
    diamondOwnerWallet: address?
}

struct PermissionlessReleaseParties {
    primary: Cell<PermissionlessReleasePartiesPrimary>
    refund: Cell<PermissionlessReleasePartiesRefund>
}

struct PermissionlessReleaseAmounts {
    diamondAmount: coins
    tonAmount: coins
    protocolFeeTon: coins
    newAmount: coins
    minLpOut: coins
}

struct PermissionlessPoolSnapshot {
    assetReserve: coins
    tonReserve: coins
    totalLpSupply: coins
    observedAt: uint64
}

struct PermissionlessReleaseObservations {
    firstNew: Cell<PermissionlessPoolSnapshot>?
    firstDiamond: Cell<PermissionlessPoolSnapshot>?
    secondNew: Cell<PermissionlessPoolSnapshot>?
    secondDiamond: Cell<PermissionlessPoolSnapshot>?
}

struct PermissionlessReleaseLifecycle {
    createdAt: uint64
    firstCompletedAt: uint64
    secondRequestedAt: uint64
    deadline: uint64
    terminalAt: uint64
    refundRequestedAt: uint64
    failureCode: uint16
    status: uint8
    bootstrap: bool
    lockIntentRegistered: bool
    newCommitted: bool
    newRecovered: bool
    tonRecovered: bool
    diamondReturnPending: bool
    diamondReturned: bool
    tonReturned: bool
}

struct PermissionlessReleaseOperation {
    parties: Cell<PermissionlessReleaseParties>
    amounts: Cell<PermissionlessReleaseAmounts>
    observations: Cell<PermissionlessReleaseObservations>
    lifecycle: Cell<PermissionlessReleaseLifecycle>
    lpAmount: coins
}

struct PermissionlessDiamondSweepRecord {
    diamondAmount: coins
    createdAt: uint64
}

struct PermissionlessProtocolFeeAccounting {
    accruedTon: coins
    totalAccruedTon: coins
    totalFlushedTon: coins
}

struct PermissionlessControllerDynamic {
    operations: map<uint64, Cell<PermissionlessReleaseOperation>>
    pendingSweeps: map<uint64, Cell<PermissionlessDiamondSweepRecord>>
    nextOperationId: uint64
    storedOperations: uint32
    pendingSweepsCount: uint32
    bootstrapOperationId: uint64
    pendingReleasedNew: coins
    sweepableDiamond: coins
    totalLockedDiamond: coins
    totalReleasedNew: coins
    totalLockedLp: coins
    totalRejectedDiamond: coins
    protocolFees: Cell<PermissionlessProtocolFeeAccounting>
    reserveReady: bool
    initialLiquidityReady: bool
}

struct PermissionlessLiquidityReleaseControllerStorage {
    config: Cell<PermissionlessControllerConfig>
    dynamic: Cell<PermissionlessControllerDynamic>
}

fun PermissionlessLiquidityReleaseControllerStorage.load(): PermissionlessLiquidityReleaseControllerStorage {
    return PermissionlessLiquidityReleaseControllerStorage.fromCell(contract.getData());
}

fun PermissionlessLiquidityReleaseControllerStorage.save(self) {
    contract.setData(self.toCell());
}

struct PermissionlessControllerSummaryReply {
    bound: bool
    permissionlessReady: bool
    reserveReady: bool
    initialLiquidityReady: bool
    nextOperationId: uint64
    storedOperations: uint32
    pendingSweepsCount: uint32
    bootstrapOperationId: uint64
    pendingReleasedNew: coins
    remainingNew: coins
    sweepableDiamond: coins
    totalLockedDiamond: coins
    totalReleasedNew: coins
    totalLockedLp: coins
    totalRejectedDiamond: coins
    protocolFeeBps: uint16
    protocolFeeRecipient: address
    accruedProtocolFeeTon: coins
    totalAccruedProtocolFeeTon: coins
    totalFlushedProtocolFeeTon: coins
}

struct PermissionlessReleaseOperationReply {
    exists: bool
    status: uint8
    bootstrap: bool
    clientQueryId: uint64
    beneficiary: address?
    diamondOwner: address?
    diamondOwnerWallet: address?
    tonRefundAddress: address?
    diamondAmount: coins
    tonAmount: coins
    protocolFeeTon: coins
    newAmount: coins
    minLpOut: coins
    createdAt: uint64
    firstCompletedAt: uint64
    secondRequestedAt: uint64
    deadline: uint64
    terminalAt: uint64
    failureCode: uint16
    lockIntentRegistered: bool
    newCommitted: bool
    newRecovered: bool
    tonRecovered: bool
    diamondReturnPending: bool
    diamondReturned: bool
    tonReturned: bool
    refundRequestedAt: uint64
    lpAmount: coins
}

struct PermissionlessProtocolFeeQuoteReply {
    tonAmount: coins
    protocolFeeBps: uint16
    protocolFeeTon: coins
    operationGasDeposit: coins
    requiredAttachedTon: coins
}
