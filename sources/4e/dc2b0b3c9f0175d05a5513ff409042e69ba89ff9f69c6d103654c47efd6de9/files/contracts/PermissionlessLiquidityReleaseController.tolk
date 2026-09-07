import "@stdlib/gas-payments"
import "errors"
import "jetton-messages"
import "jetton-utils"
import "permissionless-release-messages"
import "permissionless-release-storage"
import "release-messages"
import "ston-lp-utils"

contract PermissionlessLiquidityReleaseController {
    author: "Diamond Club"
    version: "3.0.0"
    description: "Immutable permissionless market-priced NEW/TON liquidity release controller with protocol fee"
    incomingMessages: AllowedPermissionlessControllerMessage
    storage: PermissionlessLiquidityReleaseControllerStorage
}

type AllowedPermissionlessControllerMessage =
    | BindPermissionlessReleaseAssets
    | TransferNotificationForRecipient
    | JettonTransferFailed
    | StonPoolDataResponse
    | ResponseWalletAddress
    | RequestSecondPriceObservation
    | RetryPriceObservation
    | RetryDiamondWalletDiscovery
    | LockIntentRegistered
    | RetryLockIntentRegistration
    | PtonTonTransfer
    | PtonTonRefund
    | LockConfirmed
    | ReturnExcessesBack
    | RetryReserveBootstrap
    | ReplayReserveReady
    | ReconcileExpiredRelease
    | PruneTerminalRelease
    | SweepDiamond
    | FlushProtocolTonFees
    | TopUpTons

fun permissionlessLoadConfig(
    storage: PermissionlessLiquidityReleaseControllerStorage,
): (
    PermissionlessControllerConfig,
    PermissionlessControllerAuthorities,
    PermissionlessAssetConfig,
    PermissionlessDexConfig,
    PermissionlessExecutionDexConfig,
    PermissionlessPricePoolConfig,
    PermissionlessReleaseRules,
    PermissionlessGasConfig,
) {
    val config = storage.config.load();
    val dex = config.dex.load();
    val limits = config.limits.load();
    return (
        config,
        config.authorities.load(),
        config.assets.load(),
        dex,
        dex.execution.load(),
        dex.diamondPricePool.load(),
        limits.rules.load(),
        limits.gas.load(),
    );
}

fun permissionlessSaveDynamic(
    mutate storage: PermissionlessLiquidityReleaseControllerStorage,
    dynamic: PermissionlessControllerDynamic,
) {
    storage.dynamic = dynamic.toCell();
    storage.save();
}

fun permissionlessSaveBoundConfig(
    mutate storage: PermissionlessLiquidityReleaseControllerStorage,
    config: PermissionlessControllerConfig,
    assets: PermissionlessAssetConfig,
    dex: PermissionlessDexConfig,
    execution: PermissionlessExecutionDexConfig,
) {
    var updatedDex = dex;
    updatedDex.execution = execution.toCell();
    var updatedConfig = config;
    updatedConfig.assets = assets.toCell();
    updatedConfig.dex = updatedDex.toCell();
    storage.config = updatedConfig.toCell();
    storage.save();
}

fun permissionlessSaveAuthorities(
    mutate storage: PermissionlessLiquidityReleaseControllerStorage,
    config: PermissionlessControllerConfig,
    authorities: PermissionlessControllerAuthorities,
) {
    var updatedConfig = config;
    updatedConfig.authorities = authorities.toCell();
    storage.config = updatedConfig.toCell();
    storage.save();
}

fun permissionlessAssetMasters(
    assets: PermissionlessAssetConfig,
): PermissionlessAssetMasters {
    return assets.masters.load();
}

fun permissionlessAssetWallets(
    assets: PermissionlessAssetConfig,
): PermissionlessAssetWallets {
    return assets.wallets.load();
}

fun permissionlessExecutionRouter(
    execution: PermissionlessExecutionDexConfig,
): PermissionlessExecutionRouterConfig {
    return execution.router.load();
}

fun permissionlessExecutionLiquidity(
    execution: PermissionlessExecutionDexConfig,
): PermissionlessExecutionLiquidityConfig {
    return execution.liquidity.load();
}

fun permissionlessPriceAddresses(
    pool: PermissionlessPricePoolConfig,
): PermissionlessPricePoolAddresses {
    return pool.addresses.load();
}

fun permissionlessObservationGas(
    gas: PermissionlessGasConfig,
): PermissionlessObservationGasConfig {
    return gas.observation.load();
}

fun permissionlessProtocolFeeConfig(
    rules: PermissionlessReleaseRules,
): PermissionlessProtocolFeeConfig {
    return rules.protocolFee.load();
}

fun permissionlessProtocolFeeAccounting(
    dynamic: PermissionlessControllerDynamic,
): PermissionlessProtocolFeeAccounting {
    return dynamic.protocolFees.load();
}

fun permissionlessDexGas(gas: PermissionlessGasConfig): PermissionlessDexGasConfig {
    return gas.dex.load();
}

fun permissionlessConfigSane(
    assets: PermissionlessAssetConfig,
    rules: PermissionlessReleaseRules,
    gas: PermissionlessGasConfig,
): bool {
    val masters = permissionlessAssetMasters(assets);
    val poolDepths = rules.poolDepths.load();
    val protocolFee = permissionlessProtocolFeeConfig(rules);
    val observationGas = permissionlessObservationGas(gas);
    val dexGas = permissionlessDexGas(gas);
    val explicitOperationBudget = observationGas.poolQueryMessageValue * 2 +
    observationGas.walletDiscoveryMessageValue +
    observationGas.lockIntentMessageValue +
    dexGas.newWalletMessageValue +
    dexGas.ptonForwardTonValue +
    dexGas.ptonFeeValue +
    observationGas.refundMessageValue * 2;
    return rules.minTonContribution > 0 && protocolFee.recipient != contract.getAddress() &&
    protocolFee.feeBps > 0 &&
    protocolFee.feeBps <= PERMISSIONLESS_PROTOCOL_FEE_DENOMINATOR_BPS &&
    poolDepths.minDiamondPoolTonReserve > 0 &&
    poolDepths.minNewPoolTonReserve > 0 &&
    rules.bootstrapTonAmount >= rules.minTonContribution &&
    rules.bootstrapNewAmount > 0 &&
    rules.bootstrapNewAmount <= masters.expectedReserveSupply &&
    rules.bootstrapMinLpOut > 0 &&
    rules.maxStoredOperations > 0 &&
    rules.maxPendingSweeps > 0 &&
    rules.observationWindowSeconds > 0 &&
    rules.maxSnapshotSkewSeconds > 0 &&
    rules.maxPriceDeviationBps <= 10_000 &&
    rules.maxInputImbalanceBps <= 10_000 &&
    rules.lpSlippageBps <
    10_000 &&
    rules.maxIntentLifetime > rules.observationWindowSeconds &&
    rules.terminalRetention > 0 &&
    observationGas.operationGasDeposit > explicitOperationBudget &&
    observationGas.feeFlushGasDeposit > 0 &&
    observationGas.poolQueryMessageValue > 0 &&
    observationGas.walletDiscoveryMessageValue > 0 &&
    observationGas.lockIntentMessageValue > 0 &&
    observationGas.refundMessageValue > 0 &&
    dexGas.newWalletMessageValue > dexGas.newForwardTonValue &&
    dexGas.newForwardTonValue > dexGas.dexPayloadForwardTonValue &&
    dexGas.ptonForwardTonValue > dexGas.dexPayloadForwardTonValue &&
    dexGas.ptonFeeValue > 0;
}

fun permissionlessPartiesPrimary(
    operation: PermissionlessReleaseOperation,
): PermissionlessReleasePartiesPrimary {
    return operation.parties.load().primary.load();
}

fun permissionlessPartiesRefund(
    operation: PermissionlessReleaseOperation,
): PermissionlessReleasePartiesRefund {
    return operation.parties.load().refund.load();
}

fun permissionlessIsBound(
    assets: PermissionlessAssetConfig,
    execution: PermissionlessExecutionDexConfig,
): bool {
    val masters = permissionlessAssetMasters(assets);
    val wallets = permissionlessAssetWallets(assets);
    val liquidity = permissionlessExecutionLiquidity(execution);
    return wallets.controllerDiamondWallet != null && wallets.collectorDiamondWallet != null &&
    masters.newJettonMaster != null &&
    liquidity.newTonPoolAddress != null &&
    liquidity.lpAccountAddress != null;
}

fun permissionlessIsReady(
    authorities: PermissionlessControllerAuthorities,
    assets: PermissionlessAssetConfig,
    execution: PermissionlessExecutionDexConfig,
    dynamic: PermissionlessControllerDynamic,
): bool {
    return permissionlessIsBound(assets, execution) && authorities.bootstrapAdmin == null &&
    dynamic.reserveReady &&
    dynamic.initialLiquidityReady;
}

fun permissionlessReserveWallet(assets: PermissionlessAssetConfig): address {
    val masters = permissionlessAssetMasters(assets);
    assert (masters.newJettonMaster != null) throw Errors.NotSealed;
    return calcAddressOfStandardJettonWallet(
        contract.getAddress(),
        masters.newJettonMaster!,
        masters.standardNewWalletCode,
    );
}

fun permissionlessRouterNewWallet(
    assets: PermissionlessAssetConfig,
    execution: PermissionlessExecutionDexConfig,
): address {
    val masters = permissionlessAssetMasters(assets);
    val router = permissionlessExecutionRouter(execution);
    assert (masters.newJettonMaster != null) throw Errors.NotSealed;
    return calcAddressOfStandardJettonWallet(
        router.routerAddress,
        masters.newJettonMaster!,
        masters.standardNewWalletCode,
    );
}

fun permissionlessPoolAddress(execution: PermissionlessExecutionDexConfig): address {
    val liquidity = permissionlessExecutionLiquidity(execution);
    assert (liquidity.newTonPoolAddress != null) throw Errors.NotSealed;
    return liquidity.newTonPoolAddress!;
}

fun permissionlessLpAccount(execution: PermissionlessExecutionDexConfig): address {
    val liquidity = permissionlessExecutionLiquidity(execution);
    assert (liquidity.lpAccountAddress != null) throw Errors.NotSealed;
    return liquidity.lpAccountAddress!;
}

fun loadPermissionlessOperation(
    dynamic: PermissionlessControllerDynamic,
    operationId: uint64,
): PermissionlessReleaseOperation {
    val lookup = dynamic.operations.get(operationId);
    assert (lookup.isFound) throw Errors.OperationNotFound;
    return lookup.loadValue().load();
}

fun permissionlessTerminal(status: uint8): bool {
    return status == PERMISSIONLESS_STATUS_LP_LOCKED || status == PERMISSIONLESS_STATUS_REFUNDED ||
    status == PERMISSIONLESS_STATUS_CANCELLED;
}

fun ceilDiv(numerator: int, denominator: int): int {
    assert (denominator > 0) throw Errors.InvalidAmount;
    return numerator / denominator + ((numerator % denominator) == 0 ? 0 : 1);
}

fun absoluteDifference(left: int, right: int): int {
    return left >= right ? left - right : right - left;
}

fun ratioWithinBps(
    firstAsset: coins,
    firstTon: coins,
    secondAsset: coins,
    secondTon: coins,
    maxDeviationBps: uint16,
): bool {
    if (firstAsset <= 0 || firstTon <= 0 || secondAsset <= 0 || secondTon <= 0) {
        return false;
    }
    val baseline = firstAsset * secondTon;
    val observed = secondAsset * firstTon;
    return absoluteDifference(baseline, observed) * 10_000 <= baseline * maxDeviationBps;
}

fun fundedAmountWithinBps(actual: coins, expected: coins, maxOverpaymentBps: uint16): bool {
    if (actual <= 0 || expected <= 0) {
        return false;
    }
    // The tolerance absorbs quote movement only on the user's overfunded
    // side. Accepting even a small underpayment would release the same NEW
    // against less DIAMOND and could be repeated without an economic cap.
    return actual >= expected && (actual - expected) * 10_000 <= expected * maxOverpaymentBps;
}

fun snapshotsWithinSkew(
    left: PermissionlessPoolSnapshot,
    right: PermissionlessPoolSnapshot,
    maxSkew: uint32,
): bool {
    return absoluteDifference(left.observedAt, right.observedAt) <= maxSkew;
}

fun parsePermissionlessDeposit(payloadCell: cell): PermissionlessReleaseDepositPayload? {
    try {
        return PermissionlessReleaseDepositPayload.fromCell(payloadCell);
    } catch (_) {
        return null;
    }
}

fun sendPoolDataQuery(poolAddress: address, queryId: uint64, value: coins) {
    val request = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: poolAddress,
        value,
        body: buildStonPoolDataRequest(queryId),
    });
    request.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
}

fun sendDiamondWalletDiscovery(
    operationId: uint64,
    diamondOwner: address,
    oldDiamondMaster: address,
    value: coins,
) {
    val request = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: oldDiamondMaster,
        value,
        body: RequestWalletAddress {
            queryId: walletDiscoveryQueryId(operationId),
            ownerAddress: diamondOwner,
            includeOwnerAddress: true,
        },
    });
    request.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
}

fun sendObservationQueries(
    operationId: uint64,
    second: bool,
    bootstrap: bool,
    execution: PermissionlessExecutionDexConfig,
    diamondPool: PermissionlessPricePoolConfig,
    gas: PermissionlessGasConfig,
) {
    val priceAddresses = permissionlessPriceAddresses(diamondPool);
    val observationGas = permissionlessObservationGas(gas);
    sendPoolDataQuery(
        priceAddresses.poolAddress,
        priceQueryId(operationId, second, true),
        observationGas.poolQueryMessageValue,
    );
    if (!bootstrap) {
        sendPoolDataQuery(
            permissionlessPoolAddress(execution),
            priceQueryId(operationId, second, false),
            observationGas.poolQueryMessageValue,
        );
    }
}

fun rejectedQueryId(queryId: uint64): uint64 {
    return REJECTED_RETURN_FLAG | (queryId & EXTERNAL_ID_MASK);
}

// Invalid or under-minimum atomic deposits are returned using only the value
// carried by their own transfer_notification. The Controller's standing TON
// balance can therefore never subsidize malformed or spam deposits.
fun rejectAtomicDeposit(
    notificationQueryId: uint64,
    diamondAmount: coins,
    diamondOwner: address,
    tonRefundAddress: address,
    controllerDiamondWallet: address,
) {
    val transfer = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: controllerDiamondWallet,
        value: 0,
        body: AskToTransfer {
            queryId: rejectedQueryId(notificationQueryId),
            jettonAmount: diamondAmount,
            transferRecipient: diamondOwner,
            sendExcessesTo: tonRefundAddress,
            customPayload: null,
            forwardTonAmount: 0,
            forwardPayload: beginCell().storeUint(0, 1).endCell().beginParse(),
        },
    });
    transfer.send(
        SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_BOUNCE_ON_ACTION_FAIL,
    );
}

fun sendReleaseAccepted(
    operationId: uint64,
    operation: PermissionlessReleaseOperation,
    observationWindowSeconds: uint32,
) {
    val parties = permissionlessPartiesPrimary(operation);
    val refundParties = permissionlessPartiesRefund(operation);
    val lifecycle = operation.lifecycle.load();
    val accepted = createMessage({
        bounce: BounceMode.NoBounce,
        dest: refundParties.diamondOwner,
        value: 0,
        body: PermissionlessReleaseAccepted {
            clientQueryId: parties.clientQueryId,
            operationId,
            protocolFeeTon: operation.amounts.load().protocolFeeTon,
            secondObservationAfter: lifecycle.createdAt + observationWindowSeconds,
            deadline: lifecycle.deadline,
        },
    });
    accepted.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_IGNORE_ERRORS);
}

fun buildPermissionlessStonProvidePayload(
    operationId: uint64,
    routerOtherWallet: address,
    operation: PermissionlessReleaseOperation,
    execution: PermissionlessExecutionDexConfig,
    gas: PermissionlessGasConfig,
): cell {
    val parties = permissionlessPartiesPrimary(operation);
    val refundParties = permissionlessPartiesRefund(operation);
    val liquidity = permissionlessExecutionLiquidity(execution);
    val dexGas = permissionlessDexGas(gas);
    val amounts = operation.amounts.load();
    val lifecycle = operation.lifecycle.load();
    val lockerPayload: cell = LockerDepositPayload {
        protocolVersion: RELEASE_PROTOCOL_VERSION,
        operationId,
        beneficiary: parties.beneficiary,
        beneficiaryLpWallet: parties.beneficiaryLpWallet,
        controllerAddress: contract.getAddress(),
        lockSeconds: RELEASE_LOCK_SECONDS,
    }.toCell();
    return StonProvideLiquidity {
        routerWalletAddress: routerOtherWallet,
        refundAddress: contract.getAddress(),
        excessesAddress: refundParties.tonRefundAddress,
        deadline: lifecycle.deadline,
        details: StonProvideLiquidityDetails {
            minLpOut: amounts.minLpOut,
            receiverAddress: liquidity.lockerAddress,
            bothPositive: true,
            dexCustomPayloadForwardGasAmount: dexGas.dexPayloadForwardTonValue,
            dexCustomPayload: lockerPayload,
        }.toCell(),
    }.toCell();
}

fun sendPermissionlessLockIntent(
    operationId: uint64,
    operation: PermissionlessReleaseOperation,
    execution: PermissionlessExecutionDexConfig,
    rules: PermissionlessReleaseRules,
    gas: PermissionlessGasConfig,
) {
    val parties = permissionlessPartiesPrimary(operation);
    val liquidity = permissionlessExecutionLiquidity(execution);
    val observationGas = permissionlessObservationGas(gas);
    val amounts = operation.amounts.load();
    val lifecycle = operation.lifecycle.load();
    val registration = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: liquidity.lockerAddress,
        value: observationGas.lockIntentMessageValue,
        body: RegisterLockIntent {
            queryId: operationId,
            parties: LockIntentParties {
                beneficiary: parties.beneficiary,
                beneficiaryLpWallet: parties.beneficiaryLpWallet,
                controllerAddress: contract.getAddress(),
            }.toCell(),
            terms: LockIntentTerms {
                protocolVersion: RELEASE_PROTOCOL_VERSION,
                minLpOut: amounts.minLpOut,
                deadline: lifecycle.deadline,
                expiresAt: lifecycle.deadline + rules.terminalRetention,
                lockSeconds: RELEASE_LOCK_SECONDS,
            }.toCell(),
        },
    });
    registration.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
}

fun dispatchPermissionlessRelease(
    mutate storage: PermissionlessLiquidityReleaseControllerStorage,
    mutate dynamic: PermissionlessControllerDynamic,
    operationId: uint64,
    mutate operation: PermissionlessReleaseOperation,
    assets: PermissionlessAssetConfig,
    execution: PermissionlessExecutionDexConfig,
    gas: PermissionlessGasConfig,
) {
    var lifecycle = operation.lifecycle.load();
    assert (
        lifecycle.status == PERMISSIONLESS_STATUS_REGISTERING_LOCK
    ) throw Errors.InvalidOperationState;
    assert (lifecycle.lockIntentRegistered) throw Errors.LockIntentNotRegistered;
    assert (blockchain.now() <= lifecycle.deadline) throw Errors.Expired;

    val amounts = operation.amounts.load();
    val refundParties = permissionlessPartiesRefund(operation);
    val router = permissionlessExecutionRouter(execution);
    val dexGas = permissionlessDexGas(gas);
    lifecycle.status = PERMISSIONLESS_STATUS_LEGS_DISPATCHED;
    lifecycle.newRecovered = false;
    lifecycle.tonRecovered = false;
    operation.lifecycle = lifecycle.toCell();
    dynamic.operations.set(operationId, operation.toCell());
    permissionlessSaveDynamic(mutate storage, dynamic);

    val reserveWallet = permissionlessReserveWallet(assets);
    val routerNewWallet = permissionlessRouterNewWallet(assets, execution);
    val newLegPayload = buildPermissionlessStonProvidePayload(
        operationId,
        router.routerPtonWallet,
        operation,
        execution,
        gas,
    );
    val tonLegPayload = buildPermissionlessStonProvidePayload(
        operationId,
        routerNewWallet,
        operation,
        execution,
        gas,
    );

    val sendNewLeg = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: reserveWallet,
        value: dexGas.newWalletMessageValue,
        body: AskToTransfer {
            queryId: operationId,
            jettonAmount: amounts.newAmount,
            transferRecipient: router.routerAddress,
            sendExcessesTo: refundParties.tonRefundAddress,
            customPayload: null,
            forwardTonAmount: dexGas.newForwardTonValue,
            forwardPayload: payloadCellInRef(newLegPayload),
        },
    });
    sendNewLeg.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);

    val sendTonLeg = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: router.routerPtonWallet,
        value: amounts.tonAmount + dexGas.ptonForwardTonValue + dexGas.ptonFeeValue,
        body: PtonTonTransfer {
            queryId: operationId,
            tonAmount: amounts.tonAmount,
            refundAddress: contract.getAddress(),
            forwardPayload: tonLegPayload,
        },
    });
    sendTonLeg.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
}

fun sendPermissionlessDiamondBack(
    operationId: uint64,
    operation: PermissionlessReleaseOperation,
    assets: PermissionlessAssetConfig,
    gas: PermissionlessGasConfig,
) {
    val wallets = permissionlessAssetWallets(assets);
    val parties = permissionlessPartiesRefund(operation);
    val observationGas = permissionlessObservationGas(gas);
    assert (wallets.controllerDiamondWallet != null) throw Errors.NotSealed;
    val amounts = operation.amounts.load();
    val transfer = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: wallets.controllerDiamondWallet!,
        value: observationGas.refundMessageValue,
        body: AskToTransfer {
            queryId: OPERATION_REFUND_FLAG | operationId,
            jettonAmount: amounts.diamondAmount,
            transferRecipient: parties.diamondOwner,
            sendExcessesTo: contract.getAddress(),
            customPayload: null,
            forwardTonAmount: 0,
            forwardPayload: beginCell().storeUint(0, 1).endCell().beginParse(),
        },
    });
    transfer.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
}

fun sendPermissionlessTonBack(
    operationId: uint64,
    operation: PermissionlessReleaseOperation,
) {
    val parties = permissionlessPartiesRefund(operation);
    val amounts = operation.amounts.load();
    val refund = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: parties.tonRefundAddress,
        value: amounts.tonAmount + amounts.protocolFeeTon,
        body: ReturnTonPrincipal { operationId },
    });
    refund.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
}

fun releasePendingNewIfRecovered(
    mutate dynamic: PermissionlessControllerDynamic,
    mutate lifecycle: PermissionlessReleaseLifecycle,
    amounts: PermissionlessReleaseAmounts,
) {
    if (lifecycle.newCommitted && lifecycle.newRecovered && lifecycle.tonRecovered) {
        assert (dynamic.pendingReleasedNew >= amounts.newAmount) throw Errors.InvalidAmount;
        dynamic.pendingReleasedNew -= amounts.newAmount;
        lifecycle.newCommitted = false;
    }
}

fun progressPermissionlessRefund(
    mutate dynamic: PermissionlessControllerDynamic,
    operationId: uint64,
    mutate operation: PermissionlessReleaseOperation,
    assets: PermissionlessAssetConfig,
    gas: PermissionlessGasConfig,
) {
    var lifecycle = operation.lifecycle.load();
    val parties = permissionlessPartiesRefund(operation);
    val amounts = operation.amounts.load();
    lifecycle.status = PERMISSIONLESS_STATUS_REFUNDING;
    releasePendingNewIfRecovered(mutate dynamic, mutate lifecycle, amounts);

    if (lifecycle.newRecovered && lifecycle.tonRecovered) {
        if (!lifecycle.tonReturned) {
            lifecycle.tonReturned = true;
            sendPermissionlessTonBack(operationId, operation);
        }
        if (
            parties.diamondOwnerWallet != null && !lifecycle.diamondReturnPending &&
            !lifecycle.diamondReturned
        ) {
            lifecycle.diamondReturnPending = true;
            sendPermissionlessDiamondBack(operationId, operation, assets, gas);
        }
    }

    if (
        lifecycle.newRecovered && lifecycle.tonRecovered && lifecycle.tonReturned &&
        lifecycle.diamondReturned
    ) {
        lifecycle.status = PERMISSIONLESS_STATUS_REFUNDED;
        lifecycle.terminalAt = blockchain.now() as uint64;
    }
    operation.lifecycle = lifecycle.toCell();
}

fun beginPermissionlessRefund(
    mutate dynamic: PermissionlessControllerDynamic,
    operationId: uint64,
    mutate operation: PermissionlessReleaseOperation,
    failureCode: uint16,
    assets: PermissionlessAssetConfig,
    gas: PermissionlessGasConfig,
) {
    var lifecycle = operation.lifecycle.load();
    val wasDispatched = lifecycle.status == PERMISSIONLESS_STATUS_LEGS_DISPATCHED;
    lifecycle.failureCode = failureCode;
    lifecycle.status = PERMISSIONLESS_STATUS_REFUNDING;
    if (!wasDispatched) {
        lifecycle.newRecovered = true;
        lifecycle.tonRecovered = true;
    }
    operation.lifecycle = lifecycle.toCell();
    progressPermissionlessRefund(
        mutate dynamic,
        operationId,
        mutate operation,
        assets,
        gas,
    );
}

fun sendPermissionlessDexRefundRequest(
    operationId: uint64,
    execution: PermissionlessExecutionDexConfig,
) {
    val liquidity = permissionlessExecutionLiquidity(execution);
    val newPayload: cell = RefundAssetPayload {
        operationId,
        assetKind: RELEASE_ASSET_NEW,
    }.toCell();
    val tonPayload: cell = RefundAssetPayload {
        operationId,
        assetKind: RELEASE_ASSET_PTON,
    }.toCell();
    val leftPayload = liquidity.newWalletIsToken0 ? newPayload : tonPayload;
    val rightPayload = liquidity.newWalletIsToken0 ? tonPayload : newPayload;
    val refund = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: permissionlessLpAccount(execution),
        value: 0,
        body: StonLpAccountRefund {
            queryId: operationId,
            leftPayload,
            rightPayload,
        },
    });
    refund.send(
        SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_BOUNCE_ON_ACTION_FAIL,
    );
}

fun parsePoolSnapshot(
    msg: StonPoolDataResponse,
    expectedRouter: address,
    expectedAssetWallet: address,
    expectedPtonWallet: address,
    assetIsToken0: bool,
): PermissionlessPoolSnapshot {
    assert (!msg.isLocked) throw Errors.PoolLocked;
    assert (msg.reserve0 > 0 && msg.reserve1 > 0) throw Errors.InvalidPoolResponse;
    val expectedToken0 = assetIsToken0 ? expectedAssetWallet : expectedPtonWallet;
    val expectedToken1 = assetIsToken0 ? expectedPtonWallet : expectedAssetWallet;
    assert (
        msg.token0Address == expectedToken0 && msg.token1Address == expectedToken1
    ) throw Errors.InvalidPoolResponse;
    val additional = StonPoolDataAdditional.fromCell(msg.additionalData);
    assert (additional.routerAddress == expectedRouter) throw Errors.InvalidPoolResponse;
    assert (additional.totalLpSupply > 0) throw Errors.InvalidPoolResponse;
    return {
        assetReserve: assetIsToken0 ? msg.reserve0 : msg.reserve1,
        tonReserve: assetIsToken0 ? msg.reserve1 : msg.reserve0,
        totalLpSupply: additional.totalLpSupply,
        observedAt: blockchain.now() as uint64,
    };
}

fun permissionlessRoundComplete(
    observations: PermissionlessReleaseObservations,
    second: bool,
    bootstrap: bool,
): bool {
    if (second) {
        return observations.secondDiamond != null && (bootstrap || observations.secondNew != null);
    }
    return observations.firstDiamond != null && (bootstrap || observations.firstNew != null);
}

fun assertPermissionlessRoundSkew(
    observations: PermissionlessReleaseObservations,
    second: bool,
    bootstrap: bool,
    maxSkew: uint32,
) {
    if (bootstrap) {
        return;
    }
    if (second) {
        assert (
            snapshotsWithinSkew(
                observations.secondDiamond!.load(),
                observations.secondNew!.load(),
                maxSkew,
            )
        ) throw Errors.InvalidPoolResponse;
    } else {
        assert (
            snapshotsWithinSkew(
                observations.firstDiamond!.load(),
                observations.firstNew!.load(),
                maxSkew,
            )
        ) throw Errors.InvalidPoolResponse;
    }
}

fun finalizePermissionlessQuote(
    mutate storage: PermissionlessLiquidityReleaseControllerStorage,
    mutate dynamic: PermissionlessControllerDynamic,
    operationId: uint64,
    mutate operation: PermissionlessReleaseOperation,
    assets: PermissionlessAssetConfig,
    execution: PermissionlessExecutionDexConfig,
    rules: PermissionlessReleaseRules,
    gas: PermissionlessGasConfig,
) {
    var lifecycle = operation.lifecycle.load();
    var amounts = operation.amounts.load();
    val observations = operation.observations.load();
    val firstDiamond = observations.firstDiamond!.load();
    val secondDiamond = observations.secondDiamond!.load();

    if (
        !ratioWithinBps(
            firstDiamond.assetReserve,
            firstDiamond.tonReserve,
            secondDiamond.assetReserve,
            secondDiamond.tonReserve,
            rules.maxPriceDeviationBps,
        )
    ) {
        beginPermissionlessRefund(
            mutate dynamic,
            operationId,
            mutate operation,
            Errors.PriceDeviation,
            assets,
            gas,
        );
        dynamic.operations.set(operationId, operation.toCell());
        permissionlessSaveDynamic(mutate storage, dynamic);
        return;
    }

    val expectedDiamond = ceilDiv(
        amounts.tonAmount * secondDiamond.assetReserve,
        secondDiamond.tonReserve,
    );
    if (
        !fundedAmountWithinBps(
            amounts.diamondAmount,
            expectedDiamond,
            rules.maxInputImbalanceBps,
        )
    ) {
        beginPermissionlessRefund(
            mutate dynamic,
            operationId,
            mutate operation,
            Errors.InputImbalance,
            assets,
            gas,
        );
        dynamic.operations.set(operationId, operation.toCell());
        permissionlessSaveDynamic(mutate storage, dynamic);
        return;
    }

    if (lifecycle.bootstrap) {
        amounts.newAmount = rules.bootstrapNewAmount;
        amounts.minLpOut = rules.bootstrapMinLpOut;
    } else {
        val firstNew = observations.firstNew!.load();
        val secondNew = observations.secondNew!.load();
        if (
            !ratioWithinBps(
                firstNew.assetReserve,
                firstNew.tonReserve,
                secondNew.assetReserve,
                secondNew.tonReserve,
                rules.maxPriceDeviationBps,
            )
        ) {
            beginPermissionlessRefund(
                mutate dynamic,
                operationId,
                mutate operation,
                Errors.PriceDeviation,
                assets,
                gas,
            );
            dynamic.operations.set(operationId, operation.toCell());
            permissionlessSaveDynamic(mutate storage, dynamic);
            return;
        }

        amounts.newAmount = amounts.tonAmount * secondNew.assetReserve / secondNew.tonReserve;
        val lpFromNew = amounts.newAmount * secondNew.totalLpSupply / secondNew.assetReserve;
        val lpFromTon = amounts.tonAmount * secondNew.totalLpSupply / secondNew.tonReserve;
        val expectedLp = min(lpFromNew, lpFromTon);
        amounts.minLpOut = expectedLp * (10_000 - rules.lpSlippageBps) / 10_000;
    }

    if (amounts.newAmount <= 0 || amounts.minLpOut <= 0) {
        beginPermissionlessRefund(
            mutate dynamic,
            operationId,
            mutate operation,
            Errors.InvalidAmount,
            assets,
            gas,
        );
        dynamic.operations.set(operationId, operation.toCell());
        permissionlessSaveDynamic(mutate storage, dynamic);
        return;
    }

    val availableNew = permissionlessAssetMasters(assets).expectedReserveSupply -
    dynamic.totalReleasedNew -
    dynamic.pendingReleasedNew;
    if (amounts.newAmount > availableNew) {
        beginPermissionlessRefund(
            mutate dynamic,
            operationId,
            mutate operation,
            Errors.ReserveExhausted,
            assets,
            gas,
        );
        dynamic.operations.set(operationId, operation.toCell());
        permissionlessSaveDynamic(mutate storage, dynamic);
        return;
    }

    dynamic.pendingReleasedNew += amounts.newAmount;
    lifecycle.newCommitted = true;
    lifecycle.status = PERMISSIONLESS_STATUS_REGISTERING_LOCK;
    operation.amounts = amounts.toCell();
    operation.lifecycle = lifecycle.toCell();
    dynamic.operations.set(operationId, operation.toCell());
    permissionlessSaveDynamic(mutate storage, dynamic);
    sendPermissionlessLockIntent(operationId, operation, execution, rules, gas);
}

fun handleCompletedObservationRound(
    mutate storage: PermissionlessLiquidityReleaseControllerStorage,
    mutate dynamic: PermissionlessControllerDynamic,
    operationId: uint64,
    mutate operation: PermissionlessReleaseOperation,
    second: bool,
    assets: PermissionlessAssetConfig,
    execution: PermissionlessExecutionDexConfig,
    rules: PermissionlessReleaseRules,
    gas: PermissionlessGasConfig,
) {
    var lifecycle = operation.lifecycle.load();
    val observations = operation.observations.load();
    assertPermissionlessRoundSkew(
        observations,
        second,
        lifecycle.bootstrap,
        rules.maxSnapshotSkewSeconds,
    );
    if (!second) {
        lifecycle.firstCompletedAt = blockchain.now() as uint64;
        lifecycle.status = PERMISSIONLESS_STATUS_WAITING_SECOND;
        operation.lifecycle = lifecycle.toCell();
        dynamic.operations.set(operationId, operation.toCell());
        permissionlessSaveDynamic(mutate storage, dynamic);
        return;
    }
    finalizePermissionlessQuote(
        mutate storage,
        mutate dynamic,
        operationId,
        mutate operation,
        assets,
        execution,
        rules,
        gas,
    );
}

fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();
    if (in.bouncedBody.remainingBitsCount() < 96) {
        return;
    }
    val opcode = in.bouncedBody.loadUint(32);
    val queryId = in.bouncedBody.loadUint(64);

    var storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
    val (
        _,
        _,
        assets,
        _,
        execution,
        _,
        _,
        gas,
    ) = permissionlessLoadConfig(storage);
    val masters = permissionlessAssetMasters(assets);
    val wallets = permissionlessAssetWallets(assets);
    val router = permissionlessExecutionRouter(execution);
    val liquidity = permissionlessExecutionLiquidity(execution);
    var dynamic = storage.dynamic.load();

    if (opcode == 0x0f8a7ea5) {
        if (
            wallets.controllerDiamondWallet != null &&
            in.senderAddress == wallets.controllerDiamondWallet!
        ) {
            val sweep = dynamic.pendingSweeps.get(queryId);
            if (sweep.isFound) {
                val record = sweep.loadValue().load();
                dynamic.pendingSweeps.delete(queryId);
                dynamic.pendingSweepsCount -= 1;
                dynamic.sweepableDiamond += record.diamondAmount;
                permissionlessSaveDynamic(mutate storage, dynamic);
                return;
            }
            if ((queryId & OPERATION_REFUND_FLAG) != 0) {
                val operationId = queryId & EXTERNAL_ID_MASK;
                if (dynamic.operations.exists(operationId)) {
                    var operation = loadPermissionlessOperation(dynamic, operationId);
                    var lifecycle = operation.lifecycle.load();
                    lifecycle.diamondReturnPending = false;
                    lifecycle.diamondReturned = false;
                    lifecycle.status = PERMISSIONLESS_STATUS_REFUNDING;
                    operation.lifecycle = lifecycle.toCell();
                    dynamic.operations.set(operationId, operation.toCell());
                    permissionlessSaveDynamic(mutate storage, dynamic);
                }
                return;
            }
            return;
        }

        if (
            masters.newJettonMaster != null &&
            in.senderAddress == permissionlessReserveWallet(assets) &&
            dynamic.operations.exists(queryId)
        ) {
            var operation = loadPermissionlessOperation(dynamic, queryId);
            var lifecycle = operation.lifecycle.load();
            if (
                lifecycle.status == PERMISSIONLESS_STATUS_LEGS_DISPATCHED ||
                lifecycle.status == PERMISSIONLESS_STATUS_REFUNDING
            ) {
                lifecycle.newRecovered = true;
                lifecycle.status = PERMISSIONLESS_STATUS_REFUNDING;
                operation.lifecycle = lifecycle.toCell();
                progressPermissionlessRefund(
                    mutate dynamic,
                    queryId,
                    mutate operation,
                    assets,
                    gas,
                );
                dynamic.operations.set(queryId, operation.toCell());
                permissionlessSaveDynamic(mutate storage, dynamic);
            }
            return;
        }
    }

    if (
        opcode == 0x01f3835d && in.senderAddress == router.routerPtonWallet &&
        dynamic.operations.exists(queryId)
    ) {
        var operation = loadPermissionlessOperation(dynamic, queryId);
        var lifecycle = operation.lifecycle.load();
        if (
            lifecycle.status == PERMISSIONLESS_STATUS_LEGS_DISPATCHED ||
            lifecycle.status == PERMISSIONLESS_STATUS_REFUNDING
        ) {
            lifecycle.tonRecovered = true;
            lifecycle.status = PERMISSIONLESS_STATUS_REFUNDING;
            operation.lifecycle = lifecycle.toCell();
            progressPermissionlessRefund(
                mutate dynamic,
                queryId,
                mutate operation,
                assets,
                gas,
            );
            dynamic.operations.set(queryId, operation.toCell());
            permissionlessSaveDynamic(mutate storage, dynamic);
        }
        return;
    }

    if (opcode == 0x147e12cd && dynamic.operations.exists(queryId)) {
        var operation = loadPermissionlessOperation(dynamic, queryId);
        val parties = permissionlessPartiesRefund(operation);
        if (in.senderAddress == parties.tonRefundAddress) {
            var lifecycle = operation.lifecycle.load();
            lifecycle.tonReturned = false;
            lifecycle.status = PERMISSIONLESS_STATUS_REFUNDING;
            operation.lifecycle = lifecycle.toCell();
            dynamic.operations.set(queryId, operation.toCell());
            permissionlessSaveDynamic(mutate storage, dynamic);
        }
        return;
    }

    if (
        opcode == 0x132b9a2c && liquidity.lpAccountAddress != null &&
        in.senderAddress == liquidity.lpAccountAddress! &&
        dynamic.operations.exists(queryId)
    ) {
        var operation = loadPermissionlessOperation(dynamic, queryId);
        var lifecycle = operation.lifecycle.load();
        if (
            lifecycle.status == PERMISSIONLESS_STATUS_REFUNDING && lifecycle.refundRequestedAt != 0
        ) {
            lifecycle.refundRequestedAt = 0;
            operation.lifecycle = lifecycle.toCell();
            dynamic.operations.set(queryId, operation.toCell());
            permissionlessSaveDynamic(mutate storage, dynamic);
        }
    }
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedPermissionlessControllerMessage.fromSlice(in.body);

    match (msg) {
        BindPermissionlessReleaseAssets => {
            var storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
            val (
                config,
                authorities,
                assetsLoaded,
                dex,
                executionLoaded,
                _,
                rules,
                gas,
            ) = permissionlessLoadConfig(storage);
            var assets = assetsLoaded;
            var execution = executionLoaded;
            var masters = assets.masters.load();
            var wallets = assets.wallets.load();
            var liquidity = execution.liquidity.load();
            assert (authorities.bootstrapAdmin != null) throw Errors.AlreadySealed;
            assert (in.senderAddress == authorities.bootstrapAdmin!) throw Errors.NotBootstrapAdmin;
            assert (!permissionlessIsBound(assets, execution)) throw Errors.AlreadySealed;
            assert (wallets.controllerDiamondWallet == null) throw Errors.AlreadySealed;
            assert (wallets.collectorDiamondWallet == null) throw Errors.AlreadySealed;
            assert (masters.newJettonMaster == null) throw Errors.AlreadySealed;
            assert (liquidity.newTonPoolAddress == null) throw Errors.AlreadySealed;
            assert (liquidity.lpAccountAddress == null) throw Errors.AlreadySealed;

            val boundNew = msg.newJetton.load();
            val boundDex = msg.dex.load();
            assert (boundNew.expectedReserveSupply > 0) throw Errors.InvalidSupply;
            assert (
                boundNew.expectedReserveSupply == masters.expectedReserveSupply
            ) throw Errors.InvalidSupply;
            wallets.controllerDiamondWallet = msg.oldControllerWallet;
            wallets.collectorDiamondWallet = msg.collectorDiamondWallet;
            masters.newJettonMaster = boundNew.masterAddress;
            liquidity.newTonPoolAddress = boundDex.newTonPoolAddress;
            liquidity.lpAccountAddress = boundDex.lpAccountAddress;
            liquidity.newWalletIsToken0 = boundDex.newWalletIsToken0;
            assets.masters = masters.toCell();
            assets.wallets = wallets.toCell();
            execution.liquidity = liquidity.toCell();
            assert (permissionlessConfigSane(assets, rules, gas)) throw Errors.InvalidMessage;
            permissionlessSaveBoundConfig(
                mutate storage,
                config,
                assets,
                dex,
                execution,
            );
        }

        TransferNotificationForRecipient => {
            var storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
            val (
                _,
                authorities,
                assets,
                _,
                execution,
                diamondPool,
                rules,
                gas,
            ) = permissionlessLoadConfig(storage);
            assert (permissionlessIsBound(assets, execution)) throw Errors.NotSealed;
            val masters = permissionlessAssetMasters(assets);
            val wallets = permissionlessAssetWallets(assets);
            val router = permissionlessExecutionRouter(execution);
            val liquidity = permissionlessExecutionLiquidity(execution);
            val observationGas = permissionlessObservationGas(gas);
            assert (permissionlessConfigSane(assets, rules, gas)) throw Errors.InvalidMessage;
            var dynamic = storage.dynamic.load();
            var forwardPayload = msg.forwardPayload;
            var payloadCell: cell? = null;
            try {
                payloadCell = forwardPayload.loadRequiredPayloadRef();
            } catch (_) {}

            val reserveWallet = permissionlessReserveWallet(assets);
            if (in.senderAddress == reserveWallet) {
                assert (payloadCell != null) throw Errors.InvalidMessage;
                if (!dynamic.reserveReady) {
                    val bootstrap = ReserveBootstrapPayload.fromCell(payloadCell!);
                    assert (
                        bootstrap.protocolVersion == RELEASE_PROTOCOL_VERSION
                    ) throw Errors.InvalidMessage;
                    assert (msg.transferInitiator == null) throw Errors.InvalidMessage;
                    assert (
                        msg.jettonAmount == masters.expectedReserveSupply
                    ) throw Errors.InvalidSupply;
                    dynamic.reserveReady = true;
                    permissionlessSaveDynamic(mutate storage, dynamic);
                    val ready = createMessage({
                        bounce: BounceMode.NoBounce,
                        dest: masters.newJettonMaster!,
                        value: 0,
                        body: ReserveReady {
                            queryId: msg.queryId,
                            reserveAmount: msg.jettonAmount,
                        },
                    });
                    ready.send(
                        SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS,
                    );
                    return;
                }

                val refund = RefundAssetPayload.fromCell(payloadCell!);
                assert (refund.assetKind == RELEASE_ASSET_NEW) throw Errors.InvalidMessage;
                assert (refund.operationId == msg.queryId) throw Errors.InvalidMessage;
                assert (
                    msg.transferInitiator != null && msg.transferInitiator! == router.routerAddress
                ) throw Errors.WrongInputSource;
                var operation = loadPermissionlessOperation(dynamic, refund.operationId);
                var lifecycle = operation.lifecycle.load();
                assert (
                    lifecycle.status == PERMISSIONLESS_STATUS_LEGS_DISPATCHED ||
                    lifecycle.status == PERMISSIONLESS_STATUS_REFUNDING
                ) throw Errors.InvalidOperationState;
                assert (
                    msg.jettonAmount == operation.amounts.load().newAmount
                ) throw Errors.InvalidAmount;
                lifecycle.newRecovered = true;
                lifecycle.status = PERMISSIONLESS_STATUS_REFUNDING;
                operation.lifecycle = lifecycle.toCell();
                progressPermissionlessRefund(
                    mutate dynamic,
                    refund.operationId,
                    mutate operation,
                    assets,
                    gas,
                );
                dynamic.operations.set(refund.operationId, operation.toCell());
                permissionlessSaveDynamic(mutate storage, dynamic);
                return;
            }

            assert (wallets.controllerDiamondWallet != null) throw Errors.NotSealed;
            assert (
                in.senderAddress == wallets.controllerDiamondWallet!
            ) throw Errors.NotValidWallet;
            assert (msg.transferInitiator != null) throw Errors.InvalidMessage;
            val diamondOwner = msg.transferInitiator!;
            val parsed = payloadCell == null ? null : parsePermissionlessDeposit(payloadCell!);
            val fallbackRefund = parsed == null ? diamondOwner : parsed!.tonRefundAddress;
            val bootstrap = !dynamic.initialLiquidityReady;
            val bootstrapAllowed = bootstrap && dynamic.reserveReady &&
            authorities.bootstrapAdmin != null &&
            diamondOwner == authorities.bootstrapAdmin! &&
            dynamic.bootstrapOperationId == 0;
            val publicAllowed = !bootstrap &&
            permissionlessIsReady(
                authorities,
                assets,
                execution,
                dynamic,
            );
            val validPayload = parsed != null &&
            parsed!.protocolVersion == PERMISSIONLESS_RELEASE_PROTOCOL_VERSION;
            val protocolFee = permissionlessProtocolFeeConfig(rules);
            val protocolFeeTon = bootstrap || !validPayload
                ? 0 as coins
                : calculatePermissionlessProtocolFeeTon(
                    parsed!.tonAmount,
                    protocolFee.feeBps,
                );
            val validTon = validPayload && parsed!.tonAmount >= rules.minTonContribution &&
            in.valueCoins >=
            parsed!.tonAmount + protocolFeeTon + observationGas.operationGasDeposit;
            val validBootstrapAmount = !bootstrap ||
            (validPayload && parsed!.tonAmount == rules.bootstrapTonAmount &&
            parsed!.beneficiary == rules.bootstrapBeneficiary);
            val capacityAvailable = dynamic.storedOperations < rules.maxStoredOperations &&
            dynamic.nextOperationId <= PERMISSIONLESS_OPERATION_ID_MASK;

            if (
                !validPayload || !validTon || !validBootstrapAmount ||
                (!bootstrapAllowed && !publicAllowed) ||
                !capacityAvailable ||
                msg.jettonAmount <= 0
            ) {
                dynamic.totalRejectedDiamond += msg.jettonAmount;
                permissionlessSaveDynamic(mutate storage, dynamic);
                rejectAtomicDeposit(
                    msg.queryId,
                    msg.jettonAmount,
                    diamondOwner,
                    fallbackRefund,
                    wallets.controllerDiamondWallet!,
                );
                return;
            }

            val operationId = dynamic.nextOperationId;
            val now = blockchain.now() as uint64;
            val beneficiaryLpWallet = calcAddressOfStonLpWallet(
                parsed!.beneficiary,
                permissionlessPoolAddress(execution),
                liquidity.stonLpWalletCode,
            );
            val operation = PermissionlessReleaseOperation {
                parties: PermissionlessReleaseParties {
                    primary: PermissionlessReleasePartiesPrimary {
                        clientQueryId: parsed!.clientQueryId,
                        beneficiary: parsed!.beneficiary,
                        beneficiaryLpWallet,
                    }.toCell(),
                    refund: PermissionlessReleasePartiesRefund {
                        tonRefundAddress: parsed!.tonRefundAddress,
                        diamondOwner,
                        diamondOwnerWallet: null,
                    }.toCell(),
                }.toCell(),
                amounts: PermissionlessReleaseAmounts {
                    diamondAmount: msg.jettonAmount,
                    tonAmount: parsed!.tonAmount,
                    protocolFeeTon,
                    newAmount: 0,
                    minLpOut: 0,
                }.toCell(),
                observations: PermissionlessReleaseObservations {
                    firstNew: null,
                    firstDiamond: null,
                    secondNew: null,
                    secondDiamond: null,
                }.toCell(),
                lifecycle: PermissionlessReleaseLifecycle {
                    createdAt: now,
                    firstCompletedAt: 0,
                    secondRequestedAt: 0,
                    deadline: now + rules.maxIntentLifetime,
                    terminalAt: 0,
                    refundRequestedAt: 0,
                    failureCode: 0,
                    status: PERMISSIONLESS_STATUS_OBSERVING_FIRST,
                    bootstrap,
                    lockIntentRegistered: false,
                    newCommitted: false,
                    newRecovered: true,
                    tonRecovered: true,
                    diamondReturnPending: false,
                    diamondReturned: false,
                    tonReturned: false,
                }.toCell(),
                lpAmount: 0,
            };
            dynamic.operations.set(operationId, operation.toCell());
            dynamic.nextOperationId += 1;
            dynamic.storedOperations += 1;
            if (bootstrap) {
                dynamic.bootstrapOperationId = operationId;
            }
            permissionlessSaveDynamic(mutate storage, dynamic);
            sendDiamondWalletDiscovery(
                operationId,
                diamondOwner,
                masters.oldDiamondMaster,
                observationGas.walletDiscoveryMessageValue,
            );
            sendObservationQueries(
                operationId,
                false,
                bootstrap,
                execution,
                diamondPool,
                gas,
            );
            sendReleaseAccepted(operationId, operation, rules.observationWindowSeconds);
        }

        JettonTransferFailed => {
            var storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
            val (
                _,
                _,
                assets,
                _,
                _,
                _,
                _,
                gas,
            ) = permissionlessLoadConfig(storage);
            val wallets = permissionlessAssetWallets(assets);
            var dynamic = storage.dynamic.load();

            if (in.senderAddress == permissionlessReserveWallet(assets)) {
                var operation = loadPermissionlessOperation(dynamic, msg.queryId);
                val amounts = operation.amounts.load();
                var lifecycle = operation.lifecycle.load();
                assert (
                    lifecycle.status == PERMISSIONLESS_STATUS_LEGS_DISPATCHED ||
                    lifecycle.status == PERMISSIONLESS_STATUS_REFUNDING
                ) throw Errors.InvalidOperationState;
                assert (!lifecycle.newRecovered) throw Errors.UnexpectedConfirmation;
                assert (msg.jettonAmount == amounts.newAmount) throw Errors.InvalidAmount;
                lifecycle.newRecovered = true;
                lifecycle.status = PERMISSIONLESS_STATUS_REFUNDING;
                operation.lifecycle = lifecycle.toCell();
                progressPermissionlessRefund(
                    mutate dynamic,
                    msg.queryId,
                    mutate operation,
                    assets,
                    gas,
                );
                dynamic.operations.set(msg.queryId, operation.toCell());
                permissionlessSaveDynamic(mutate storage, dynamic);
                return;
            }

            assert (wallets.controllerDiamondWallet != null) throw Errors.NotSealed;
            assert (
                in.senderAddress == wallets.controllerDiamondWallet!
            ) throw Errors.WrongInputSource;

            val sweep = dynamic.pendingSweeps.get(msg.queryId);
            if (sweep.isFound) {
                val record = sweep.loadValue().load();
                assert (msg.jettonAmount == record.diamondAmount) throw Errors.InvalidAmount;
                dynamic.pendingSweeps.delete(msg.queryId);
                dynamic.pendingSweepsCount -= 1;
                dynamic.sweepableDiamond += record.diamondAmount;
                permissionlessSaveDynamic(mutate storage, dynamic);
                return;
            }

            assert ((msg.queryId & OPERATION_REFUND_FLAG) != 0) throw Errors.UnexpectedConfirmation;
            val operationId = msg.queryId & EXTERNAL_ID_MASK;
            var operation = loadPermissionlessOperation(dynamic, operationId);
            val amounts = operation.amounts.load();
            var lifecycle = operation.lifecycle.load();
            assert (
                lifecycle.status == PERMISSIONLESS_STATUS_REFUNDING
            ) throw Errors.InvalidOperationState;
            assert (lifecycle.diamondReturnPending) throw Errors.UnexpectedConfirmation;
            assert (msg.jettonAmount == amounts.diamondAmount) throw Errors.InvalidAmount;
            lifecycle.diamondReturnPending = false;
            lifecycle.diamondReturned = false;
            operation.lifecycle = lifecycle.toCell();
            dynamic.operations.set(operationId, operation.toCell());
            permissionlessSaveDynamic(mutate storage, dynamic);
        }

        StonPoolDataResponse => {
            var storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
            val (
                _,
                _,
                assets,
                _,
                execution,
                diamondPool,
                rules,
                gas,
            ) = permissionlessLoadConfig(storage);
            val priceAddresses = permissionlessPriceAddresses(diamondPool);
            val router = permissionlessExecutionRouter(execution);
            val liquidity = permissionlessExecutionLiquidity(execution);
            val poolDepths = rules.poolDepths.load();
            assert ((msg.queryId & PRICE_QUERY_MARK) != 0) throw Errors.InvalidPoolResponse;
            val operationId = priceQueryOperationId(msg.queryId);
            var dynamic = storage.dynamic.load();
            if (!dynamic.operations.exists(operationId)) {
                return;
            }
            var operation = loadPermissionlessOperation(dynamic, operationId);
            val lifecycle = operation.lifecycle.load();
            val second = (msg.queryId & PRICE_QUERY_SECOND_MARK) != 0;
            val diamond = (msg.queryId & PRICE_QUERY_DIAMOND_MARK) != 0;
            if (
                (!second && lifecycle.status != PERMISSIONLESS_STATUS_OBSERVING_FIRST) ||
                (second && lifecycle.status != PERMISSIONLESS_STATUS_OBSERVING_SECOND)
            ) {
                return;
            }
            if (lifecycle.bootstrap && !diamond) {
                return;
            }

            var observations = operation.observations.load();
            if (diamond) {
                assert (
                    in.senderAddress == priceAddresses.poolAddress
                ) throw Errors.InvalidPoolSource;
                val snapshot = parsePoolSnapshot(
                    msg,
                    diamondPool.routerAddress,
                    priceAddresses.assetRouterWallet,
                    priceAddresses.ptonRouterWallet,
                    diamondPool.assetIsToken0,
                );
                assert (
                    snapshot.tonReserve >= poolDepths.minDiamondPoolTonReserve
                ) throw Errors.PoolTooShallow;
                if (second) {
                    if (observations.secondDiamond != null) {
                        return;
                    }
                    observations.secondDiamond = snapshot.toCell();
                } else {
                    if (observations.firstDiamond != null) {
                        return;
                    }
                    observations.firstDiamond = snapshot.toCell();
                }
            } else {
                assert (
                    in.senderAddress == permissionlessPoolAddress(execution)
                ) throw Errors.InvalidPoolSource;
                val snapshot = parsePoolSnapshot(
                    msg,
                    router.routerAddress,
                    permissionlessRouterNewWallet(assets, execution),
                    router.routerPtonWallet,
                    liquidity.newWalletIsToken0,
                );
                assert (
                    snapshot.tonReserve >= poolDepths.minNewPoolTonReserve
                ) throw Errors.PoolTooShallow;
                if (second) {
                    if (observations.secondNew != null) {
                        return;
                    }
                    observations.secondNew = snapshot.toCell();
                } else {
                    if (observations.firstNew != null) {
                        return;
                    }
                    observations.firstNew = snapshot.toCell();
                }
            }
            operation.observations = observations.toCell();
            dynamic.operations.set(operationId, operation.toCell());
            if (
                permissionlessRoundComplete(
                    observations,
                    second,
                    lifecycle.bootstrap,
                )
            ) {
                handleCompletedObservationRound(
                    mutate storage,
                    mutate dynamic,
                    operationId,
                    mutate operation,
                    second,
                    assets,
                    execution,
                    rules,
                    gas,
                );
            } else {
                permissionlessSaveDynamic(mutate storage, dynamic);
            }
        }

        ResponseWalletAddress => {
            var storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
            val (
                _,
                _,
                assets,
                _,
                _,
                _,
                _,
                gas,
            ) = permissionlessLoadConfig(storage);
            val masters = permissionlessAssetMasters(assets);
            assert (in.senderAddress == masters.oldDiamondMaster) throw Errors.WrongInputSource;
            assert ((msg.queryId & WALLET_DISCOVERY_QUERY_MARK) != 0) throw Errors.InvalidMessage;
            val operationId = msg.queryId & PERMISSIONLESS_OPERATION_ID_MASK;
            var dynamic = storage.dynamic.load();
            if (!dynamic.operations.exists(operationId)) {
                return;
            }
            var operation = loadPermissionlessOperation(dynamic, operationId);
            var partiesContainer = operation.parties.load();
            var parties = partiesContainer.refund.load();
            assert (msg.ownerAddress != null) throw Errors.InvalidMessage;
            assert (
                msg.ownerAddress!.beginParse().loadAddress() == parties.diamondOwner
            ) throw Errors.InvalidMessage;
            assert (msg.jettonWalletAddress != null) throw Errors.NotValidWallet;
            if (parties.diamondOwnerWallet != null) {
                assert (
                    parties.diamondOwnerWallet! == msg.jettonWalletAddress!
                ) throw Errors.NotValidWallet;
                return;
            }
            parties.diamondOwnerWallet = msg.jettonWalletAddress;
            partiesContainer.refund = parties.toCell();
            operation.parties = partiesContainer.toCell();
            val lifecycle = operation.lifecycle.load();
            if (lifecycle.status == PERMISSIONLESS_STATUS_REFUNDING) {
                progressPermissionlessRefund(
                    mutate dynamic,
                    operationId,
                    mutate operation,
                    assets,
                    gas,
                );
            }
            dynamic.operations.set(operationId, operation.toCell());
            permissionlessSaveDynamic(mutate storage, dynamic);
        }

        RequestSecondPriceObservation => {
            var storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
            val (
                _,
                _,
                _,
                _,
                execution,
                diamondPool,
                rules,
                gas,
            ) = permissionlessLoadConfig(storage);
            val observationGas = permissionlessObservationGas(gas);
            var dynamic = storage.dynamic.load();
            var operation = loadPermissionlessOperation(dynamic, msg.operationId);
            var lifecycle = operation.lifecycle.load();
            assert (
                lifecycle.status == PERMISSIONLESS_STATUS_WAITING_SECOND
            ) throw Errors.InvalidOperationState;
            assert (
                blockchain.now() >= lifecycle.firstCompletedAt + rules.observationWindowSeconds
            ) throw Errors.ObservationTooEarly;
            assert (blockchain.now() <= lifecycle.deadline) throw Errors.Expired;
            val queryCount = lifecycle.bootstrap ? 1 : 2;
            assert (
                in.valueCoins > observationGas.poolQueryMessageValue * queryCount
            ) throw Errors.NotEnoughGas;
            lifecycle.secondRequestedAt = blockchain.now() as uint64;
            lifecycle.status = PERMISSIONLESS_STATUS_OBSERVING_SECOND;
            operation.lifecycle = lifecycle.toCell();
            dynamic.operations.set(msg.operationId, operation.toCell());
            permissionlessSaveDynamic(mutate storage, dynamic);
            sendObservationQueries(
                msg.operationId,
                true,
                lifecycle.bootstrap,
                execution,
                diamondPool,
                gas,
            );
        }

        RetryPriceObservation => {
            var storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
            val (
                _,
                _,
                _,
                _,
                execution,
                diamondPool,
                rules,
                gas,
            ) = permissionlessLoadConfig(storage);
            val observationGas = permissionlessObservationGas(gas);
            val priceAddresses = permissionlessPriceAddresses(diamondPool);
            var dynamic = storage.dynamic.load();
            var operation = loadPermissionlessOperation(dynamic, msg.operationId);
            val lifecycle = operation.lifecycle.load();
            val first = msg.round == 1;
            val second = msg.round == 2;
            assert (first || second) throw Errors.InvalidMessage;
            assert (
                (first && lifecycle.status == PERMISSIONLESS_STATUS_OBSERVING_FIRST) ||
                (second && lifecycle.status == PERMISSIONLESS_STATUS_OBSERVING_SECOND)
            ) throw Errors.InvalidOperationState;
            assert (blockchain.now() <= lifecycle.deadline) throw Errors.Expired;
            var observations = operation.observations.load();
            var clearedStalePartial = false;
            if (first) {
                val firstSnapshot = observations.firstDiamond != null
                    ? observations.firstDiamond!.load()
                    : (observations.firstNew != null ? observations.firstNew!.load() : null);
                if (
                    firstSnapshot != null &&
                    blockchain.now() > firstSnapshot!.observedAt + rules.maxSnapshotSkewSeconds
                ) {
                    observations.firstDiamond = null;
                    observations.firstNew = null;
                    clearedStalePartial = true;
                }
            } else {
                val secondSnapshot = observations.secondDiamond != null
                    ? observations.secondDiamond!.load()
                    : (observations.secondNew != null ? observations.secondNew!.load() : null);
                if (
                    secondSnapshot != null &&
                    blockchain.now() > secondSnapshot!.observedAt + rules.maxSnapshotSkewSeconds
                ) {
                    observations.secondDiamond = null;
                    observations.secondNew = null;
                    clearedStalePartial = true;
                }
            }
            if (clearedStalePartial) {
                operation.observations = observations.toCell();
                dynamic.operations.set(msg.operationId, operation.toCell());
                permissionlessSaveDynamic(mutate storage, dynamic);
            }
            var queryCount = 0;
            if (
                (first && observations.firstDiamond == null) ||
                (second && observations.secondDiamond == null)
            ) {
                queryCount += 1;
            }
            if (
                !lifecycle.bootstrap &&
                ((first && observations.firstNew == null) ||
                (second && observations.secondNew == null))
            ) {
                queryCount += 1;
            }
            assert (queryCount > 0) throw Errors.DuplicateInput;
            assert (
                in.valueCoins > observationGas.poolQueryMessageValue * queryCount
            ) throw Errors.NotEnoughGas;
            if (
                (first && observations.firstDiamond == null) ||
                (second && observations.secondDiamond == null)
            ) {
                sendPoolDataQuery(
                    priceAddresses.poolAddress,
                    priceQueryId(msg.operationId, second, true),
                    observationGas.poolQueryMessageValue,
                );
            }
            if (
                !lifecycle.bootstrap &&
                ((first && observations.firstNew == null) ||
                (second && observations.secondNew == null))
            ) {
                sendPoolDataQuery(
                    permissionlessPoolAddress(execution),
                    priceQueryId(msg.operationId, second, false),
                    observationGas.poolQueryMessageValue,
                );
            }
        }

        RetryDiamondWalletDiscovery => {
            val storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
            val (
                _,
                _,
                assets,
                _,
                _,
                _,
                _,
                gas,
            ) = permissionlessLoadConfig(storage);
            val masters = permissionlessAssetMasters(assets);
            val observationGas = permissionlessObservationGas(gas);
            val dynamic = storage.dynamic.load();
            val operation = loadPermissionlessOperation(dynamic, msg.operationId);
            val parties = permissionlessPartiesRefund(operation);
            val lifecycle = operation.lifecycle.load();
            assert (!permissionlessTerminal(lifecycle.status)) throw Errors.InvalidOperationState;
            assert (parties.diamondOwnerWallet == null) throw Errors.DuplicateInput;
            assert (
                in.valueCoins > observationGas.walletDiscoveryMessageValue
            ) throw Errors.NotEnoughGas;
            sendDiamondWalletDiscovery(
                msg.operationId,
                parties.diamondOwner,
                masters.oldDiamondMaster,
                observationGas.walletDiscoveryMessageValue,
            );
        }

        LockIntentRegistered => {
            var storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
            val (
                _,
                _,
                assets,
                _,
                execution,
                _,
                _,
                gas,
            ) = permissionlessLoadConfig(storage);
            val liquidity = permissionlessExecutionLiquidity(execution);
            assert (in.senderAddress == liquidity.lockerAddress) throw Errors.WrongInputSource;
            var dynamic = storage.dynamic.load();
            var operation = loadPermissionlessOperation(dynamic, msg.operationId);
            var lifecycle = operation.lifecycle.load();
            if (lifecycle.status != PERMISSIONLESS_STATUS_REGISTERING_LOCK) {
                return;
            }
            lifecycle.lockIntentRegistered = true;
            operation.lifecycle = lifecycle.toCell();
            dispatchPermissionlessRelease(
                mutate storage,
                mutate dynamic,
                msg.operationId,
                mutate operation,
                assets,
                execution,
                gas,
            );
        }

        RetryLockIntentRegistration => {
            val storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
            val (
                _,
                _,
                _,
                _,
                execution,
                _,
                rules,
                gas,
            ) = permissionlessLoadConfig(storage);
            val observationGas = permissionlessObservationGas(gas);
            val dynamic = storage.dynamic.load();
            val operation = loadPermissionlessOperation(dynamic, msg.operationId);
            val lifecycle = operation.lifecycle.load();
            assert (
                lifecycle.status == PERMISSIONLESS_STATUS_REGISTERING_LOCK
            ) throw Errors.InvalidOperationState;
            assert (!lifecycle.lockIntentRegistered) throw Errors.DuplicateInput;
            assert (blockchain.now() <= lifecycle.deadline) throw Errors.Expired;
            assert (
                in.valueCoins > observationGas.lockIntentMessageValue
            ) throw Errors.NotEnoughGas;
            sendPermissionlessLockIntent(
                msg.operationId,
                operation,
                execution,
                rules,
                gas,
            );
        }

        PtonTonTransfer => {
            var storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
            val (
                _,
                _,
                assets,
                _,
                execution,
                _,
                _,
                gas,
            ) = permissionlessLoadConfig(storage);
            val router = permissionlessExecutionRouter(execution);
            assert (in.senderAddress == router.routerPtonWallet) throw Errors.WrongInputSource;
            assert (msg.refundAddress == router.routerAddress) throw Errors.WrongInputSource;
            assert (msg.forwardPayload != null) throw Errors.InvalidMessage;
            val refund = RefundAssetPayload.fromCell(msg.forwardPayload!);
            assert (refund.assetKind == RELEASE_ASSET_PTON) throw Errors.InvalidMessage;
            assert (msg.queryId == refund.operationId) throw Errors.InvalidMessage;
            var dynamic = storage.dynamic.load();
            var operation = loadPermissionlessOperation(dynamic, refund.operationId);
            var lifecycle = operation.lifecycle.load();
            assert (
                lifecycle.status == PERMISSIONLESS_STATUS_LEGS_DISPATCHED ||
                lifecycle.status == PERMISSIONLESS_STATUS_REFUNDING
            ) throw Errors.InvalidOperationState;
            assert (
                msg.tonAmount == operation.amounts.load().tonAmount &&
                in.valueCoins >= msg.tonAmount
            ) throw Errors.InvalidAmount;
            lifecycle.tonRecovered = true;
            lifecycle.status = PERMISSIONLESS_STATUS_REFUNDING;
            operation.lifecycle = lifecycle.toCell();
            progressPermissionlessRefund(
                mutate dynamic,
                refund.operationId,
                mutate operation,
                assets,
                gas,
            );
            dynamic.operations.set(refund.operationId, operation.toCell());
            permissionlessSaveDynamic(mutate storage, dynamic);
        }

        PtonTonRefund => {
            var storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
            val (
                _,
                _,
                assets,
                _,
                execution,
                _,
                _,
                gas,
            ) = permissionlessLoadConfig(storage);
            val router = permissionlessExecutionRouter(execution);
            assert (in.senderAddress == router.routerPtonWallet) throw Errors.WrongInputSource;
            var dynamic = storage.dynamic.load();
            var operation = loadPermissionlessOperation(dynamic, msg.queryId);
            var lifecycle = operation.lifecycle.load();
            assert (
                lifecycle.status == PERMISSIONLESS_STATUS_LEGS_DISPATCHED ||
                lifecycle.status == PERMISSIONLESS_STATUS_REFUNDING
            ) throw Errors.InvalidOperationState;
            assert (in.valueCoins >= operation.amounts.load().tonAmount) throw Errors.InvalidAmount;
            lifecycle.tonRecovered = true;
            lifecycle.status = PERMISSIONLESS_STATUS_REFUNDING;
            operation.lifecycle = lifecycle.toCell();
            progressPermissionlessRefund(
                mutate dynamic,
                msg.queryId,
                mutate operation,
                assets,
                gas,
            );
            dynamic.operations.set(msg.queryId, operation.toCell());
            permissionlessSaveDynamic(mutate storage, dynamic);
        }

        LockConfirmed => {
            var storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
            val (
                config,
                authoritiesLoaded,
                _,
                _,
                execution,
                _,
                _,
                _,
            ) = permissionlessLoadConfig(storage);
            val liquidity = permissionlessExecutionLiquidity(execution);
            assert (in.senderAddress == liquidity.lockerAddress) throw Errors.WrongInputSource;
            var dynamic = storage.dynamic.load();
            var operation = loadPermissionlessOperation(dynamic, msg.operationId);
            var lifecycle = operation.lifecycle.load();
            val amounts = operation.amounts.load();
            if (lifecycle.status == PERMISSIONLESS_STATUS_LP_LOCKED) {
                assert (msg.lpAmount >= operation.lpAmount) throw Errors.InvalidAmount;
                val added = msg.lpAmount - operation.lpAmount;
                operation.lpAmount = msg.lpAmount;
                dynamic.totalLockedLp += added;
                dynamic.operations.set(msg.operationId, operation.toCell());
                permissionlessSaveDynamic(mutate storage, dynamic);
                return;
            }
            val canResolve = lifecycle.status == PERMISSIONLESS_STATUS_LEGS_DISPATCHED ||
            (lifecycle.status == PERMISSIONLESS_STATUS_REFUNDING && !lifecycle.newRecovered &&
            !lifecycle.tonRecovered &&
            !lifecycle.diamondReturnPending &&
            !lifecycle.diamondReturned &&
            !lifecycle.tonReturned);
            assert (canResolve) throw Errors.InvalidOperationState;
            assert (msg.lpAmount >= amounts.minLpOut) throw Errors.InvalidAmount;
            assert (
                msg.unlockAt >= lifecycle.createdAt + RELEASE_LOCK_SECONDS
            ) throw Errors.InvalidMessage;
            assert (lifecycle.newCommitted) throw Errors.InvalidOperationState;
            assert (dynamic.pendingReleasedNew >= amounts.newAmount) throw Errors.InvalidAmount;

            dynamic.pendingReleasedNew -= amounts.newAmount;
            lifecycle.newCommitted = false;
            lifecycle.status = PERMISSIONLESS_STATUS_LP_LOCKED;
            lifecycle.terminalAt = blockchain.now() as uint64;
            operation.lifecycle = lifecycle.toCell();
            operation.lpAmount = msg.lpAmount;
            dynamic.sweepableDiamond += amounts.diamondAmount;
            dynamic.totalLockedDiamond += amounts.diamondAmount;
            dynamic.totalReleasedNew += amounts.newAmount;
            dynamic.totalLockedLp += msg.lpAmount;
            var protocolFees = permissionlessProtocolFeeAccounting(dynamic);
            protocolFees.accruedTon += amounts.protocolFeeTon;
            protocolFees.totalAccruedTon += amounts.protocolFeeTon;
            dynamic.protocolFees = protocolFees.toCell();
            if (lifecycle.bootstrap) {
                var authorities = authoritiesLoaded;
                assert (authorities.bootstrapAdmin != null) throw Errors.BootstrapComplete;
                authorities.bootstrapAdmin = null;
                dynamic.initialLiquidityReady = true;
                dynamic.bootstrapOperationId = 0;
                permissionlessSaveAuthorities(mutate storage, config, authorities);
            }
            dynamic.operations.set(msg.operationId, operation.toCell());
            permissionlessSaveDynamic(mutate storage, dynamic);
        }

        ReturnExcessesBack => {
            var storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
            val (
                _,
                _,
                assets,
                _,
                _,
                _,
                _,
                gas,
            ) = permissionlessLoadConfig(storage);
            val wallets = permissionlessAssetWallets(assets);
            var dynamic = storage.dynamic.load();
            val sweep = dynamic.pendingSweeps.get(msg.queryId);
            if (sweep.isFound) {
                assert (wallets.collectorDiamondWallet != null) throw Errors.NotSealed;
                assert (
                    in.senderAddress == wallets.collectorDiamondWallet!
                ) throw Errors.UnexpectedConfirmation;
                dynamic.pendingSweeps.delete(msg.queryId);
                dynamic.pendingSweepsCount -= 1;
                permissionlessSaveDynamic(mutate storage, dynamic);
                return;
            }

            assert ((msg.queryId & OPERATION_REFUND_FLAG) != 0) throw Errors.UnexpectedConfirmation;
            val operationId = msg.queryId & EXTERNAL_ID_MASK;
            var operation = loadPermissionlessOperation(dynamic, operationId);
            val parties = permissionlessPartiesRefund(operation);
            var lifecycle = operation.lifecycle.load();
            assert (parties.diamondOwnerWallet != null) throw Errors.WalletDiscoveryPending;
            assert (
                in.senderAddress == parties.diamondOwnerWallet!
            ) throw Errors.UnexpectedConfirmation;
            assert (
                lifecycle.status == PERMISSIONLESS_STATUS_REFUNDING
            ) throw Errors.InvalidOperationState;
            assert (lifecycle.diamondReturnPending) throw Errors.UnexpectedConfirmation;
            lifecycle.diamondReturnPending = false;
            lifecycle.diamondReturned = true;
            operation.lifecycle = lifecycle.toCell();
            progressPermissionlessRefund(
                mutate dynamic,
                operationId,
                mutate operation,
                assets,
                gas,
            );
            if (
                operation.lifecycle.load().status == PERMISSIONLESS_STATUS_REFUNDED &&
                operation.lifecycle.load().bootstrap
            ) {
                dynamic.bootstrapOperationId = 0;
            }
            dynamic.operations.set(operationId, operation.toCell());
            permissionlessSaveDynamic(mutate storage, dynamic);
        }

        RetryReserveBootstrap => {
            val storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
            val (
                _,
                _,
                assets,
                _,
                execution,
                _,
                _,
                gas,
            ) = permissionlessLoadConfig(storage);
            val masters = permissionlessAssetMasters(assets);
            val dexGas = permissionlessDexGas(gas);
            val dynamic = storage.dynamic.load();
            assert (permissionlessIsBound(assets, execution)) throw Errors.NotSealed;
            assert (!dynamic.reserveReady) throw Errors.DuplicateInput;
            assert (in.valueCoins > dexGas.newWalletMessageValue) throw Errors.NotEnoughGas;
            val bootstrapPayload: cell = ReserveBootstrapPayload {
                protocolVersion: RELEASE_PROTOCOL_VERSION,
            }.toCell();
            val retry = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: permissionlessReserveWallet(assets),
                value: 0,
                body: AskToTransfer {
                    queryId: msg.queryId,
                    jettonAmount: masters.expectedReserveSupply,
                    transferRecipient: contract.getAddress(),
                    sendExcessesTo: contract.getAddress(),
                    customPayload: null,
                    forwardTonAmount: dexGas.newForwardTonValue,
                    forwardPayload: payloadCellInRef(bootstrapPayload),
                },
            });
            retry.send(
                SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_BOUNCE_ON_ACTION_FAIL,
            );
        }

        ReplayReserveReady => {
            val storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
            val (
                _,
                _,
                assets,
                _,
                _,
                _,
                _,
                gas,
            ) = permissionlessLoadConfig(storage);
            val masters = permissionlessAssetMasters(assets);
            val observationGas = permissionlessObservationGas(gas);
            val dynamic = storage.dynamic.load();
            assert (dynamic.reserveReady) throw Errors.NotSealed;
            assert (masters.newJettonMaster != null) throw Errors.NotSealed;
            assert (
                in.valueCoins > observationGas.lockIntentMessageValue
            ) throw Errors.NotEnoughGas;
            val ready = createMessage({
                bounce: BounceMode.NoBounce,
                dest: masters.newJettonMaster!,
                value: 0,
                body: ReserveReady {
                    queryId: msg.queryId,
                    reserveAmount: masters.expectedReserveSupply,
                },
            });
            ready.send(
                SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS,
            );
        }

        ReconcileExpiredRelease => {
            var storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
            val (
                _,
                _,
                assets,
                _,
                execution,
                _,
                _,
                gas,
            ) = permissionlessLoadConfig(storage);
            val observationGas = permissionlessObservationGas(gas);
            var dynamic = storage.dynamic.load();
            var operation = loadPermissionlessOperation(dynamic, msg.operationId);
            var lifecycle = operation.lifecycle.load();
            assert (blockchain.now() > lifecycle.deadline) throw Errors.NotRefundable;

            if (lifecycle.status == PERMISSIONLESS_STATUS_REFUNDING) {
                if (!lifecycle.newRecovered || !lifecycle.tonRecovered) {
                    assert (
                        in.valueCoins > observationGas.refundMessageValue
                    ) throw Errors.NotEnoughGas;
                    lifecycle.refundRequestedAt = blockchain.now() as uint64;
                    operation.lifecycle = lifecycle.toCell();
                    dynamic.operations.set(msg.operationId, operation.toCell());
                    permissionlessSaveDynamic(mutate storage, dynamic);
                    sendPermissionlessDexRefundRequest(msg.operationId, execution);
                    return;
                }
                progressPermissionlessRefund(
                    mutate dynamic,
                    msg.operationId,
                    mutate operation,
                    assets,
                    gas,
                );
                dynamic.operations.set(msg.operationId, operation.toCell());
                permissionlessSaveDynamic(mutate storage, dynamic);
                return;
            }

            if (lifecycle.status == PERMISSIONLESS_STATUS_LEGS_DISPATCHED) {
                assert (
                    in.valueCoins > observationGas.refundMessageValue
                ) throw Errors.NotEnoughGas;
                lifecycle.status = PERMISSIONLESS_STATUS_REFUNDING;
                lifecycle.failureCode = Errors.Expired;
                lifecycle.refundRequestedAt = blockchain.now() as uint64;
                operation.lifecycle = lifecycle.toCell();
                dynamic.operations.set(msg.operationId, operation.toCell());
                permissionlessSaveDynamic(mutate storage, dynamic);
                sendPermissionlessDexRefundRequest(msg.operationId, execution);
                return;
            }

            assert (!permissionlessTerminal(lifecycle.status)) throw Errors.InvalidOperationState;
            beginPermissionlessRefund(
                mutate dynamic,
                msg.operationId,
                mutate operation,
                Errors.Expired,
                assets,
                gas,
            );
            dynamic.operations.set(msg.operationId, operation.toCell());
            permissionlessSaveDynamic(mutate storage, dynamic);
        }

        PruneTerminalRelease => {
            var storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
            val (
                _,
                _,
                _,
                _,
                _,
                _,
                rules,
                _,
            ) = permissionlessLoadConfig(storage);
            var dynamic = storage.dynamic.load();
            val operation = loadPermissionlessOperation(dynamic, msg.operationId);
            val lifecycle = operation.lifecycle.load();
            assert (permissionlessTerminal(lifecycle.status)) throw Errors.NotPrunable;
            assert (
                blockchain.now() >= lifecycle.terminalAt + rules.terminalRetention
            ) throw Errors.NotPrunable;
            dynamic.operations.delete(msg.operationId);
            dynamic.storedOperations -= 1;
            permissionlessSaveDynamic(mutate storage, dynamic);
        }

        SweepDiamond => {
            var storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
            val (
                _,
                authorities,
                assets,
                _,
                execution,
                _,
                rules,
                gas,
            ) = permissionlessLoadConfig(storage);
            val wallets = permissionlessAssetWallets(assets);
            val observationGas = permissionlessObservationGas(gas);
            val dynamicLoaded = storage.dynamic.load();
            assert (
                permissionlessIsReady(authorities, assets, execution, dynamicLoaded)
            ) throw Errors.NotSealed;
            assert (in.senderAddress == authorities.diamondCollector) throw Errors.NotCollector;
            assert (msg.queryId <= EXTERNAL_ID_MASK) throw Errors.InvalidOperationId;
            assert (msg.diamondAmount > 0) throw Errors.InvalidAmount;
            assert (in.valueCoins > observationGas.refundMessageValue) throw Errors.NotEnoughGas;
            var dynamic = dynamicLoaded;
            assert (!dynamic.pendingSweeps.exists(msg.queryId)) throw Errors.SweepPending;
            assert (dynamic.pendingSweepsCount < rules.maxPendingSweeps) throw Errors.HardCap;
            assert (dynamic.sweepableDiamond >= msg.diamondAmount) throw Errors.SweepBalance;
            assert (wallets.controllerDiamondWallet != null) throw Errors.NotSealed;

            dynamic.sweepableDiamond -= msg.diamondAmount;
            dynamic
                .pendingSweeps
                .set(
                    msg.queryId,
                    PermissionlessDiamondSweepRecord {
                        diamondAmount: msg.diamondAmount,
                        createdAt: blockchain.now() as uint64,
                    }.toCell(),
                );
            dynamic.pendingSweepsCount += 1;
            permissionlessSaveDynamic(mutate storage, dynamic);

            val transfer = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: wallets.controllerDiamondWallet!,
                value: observationGas.refundMessageValue,
                body: AskToTransfer {
                    queryId: msg.queryId,
                    jettonAmount: msg.diamondAmount,
                    transferRecipient: authorities.diamondCollector,
                    sendExcessesTo: contract.getAddress(),
                    customPayload: null,
                    forwardTonAmount: 0,
                    forwardPayload: beginCell().storeUint(0, 1).endCell().beginParse(),
                },
            });
            transfer.send(
                SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL,
            );
        }

        FlushProtocolTonFees => {
            var storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
            val (
                _,
                _,
                _,
                _,
                _,
                _,
                rules,
                gas,
            ) = permissionlessLoadConfig(storage);
            val observationGas = permissionlessObservationGas(gas);
            var dynamic = storage.dynamic.load();
            var protocolFees = permissionlessProtocolFeeAccounting(dynamic);
            val protocolFee = permissionlessProtocolFeeConfig(rules);
            val feeAmount = protocolFees.accruedTon;
            assert (feeAmount > 0) throw Errors.NoProtocolFees;
            assert (in.valueCoins >= observationGas.feeFlushGasDeposit) throw Errors.NotEnoughGas;

            // The fee principal existed before this caller-funded message and
            // may never subsidize the flush. Reserve every pre-existing TON
            // except the exact accrued fee; the caller's value pays execution
            // and forwarding, and any remainder is returned below.
            val balanceBeforeIncoming = contract.getOriginalBalance() - in.valueCoins +
            contract.getStorageDuePayment();
            assert (balanceBeforeIncoming >= feeAmount) throw Errors.InvalidAmount;
            reserveToncoinsOnBalance(
                balanceBeforeIncoming - feeAmount,
                RESERVE_MODE_AT_MOST,
            );

            protocolFees.accruedTon = 0;
            protocolFees.totalFlushedTon += feeAmount;
            dynamic.protocolFees = protocolFees.toCell();
            permissionlessSaveDynamic(mutate storage, dynamic);

            val payout = createMessage({
                bounce: BounceMode.NoBounce,
                dest: protocolFee.recipient,
                value: feeAmount,
                body: ProtocolTonFeePayout {
                    queryId: msg.queryId,
                    feeAmount,
                },
            });
            // NoBounce deliberately makes delivery to a wallet/uninitialized
            // cold address final. A source action failure rolls this entire
            // transaction and its accounting back, so a retry is idempotent.
            payout.send(
                SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL,
            );

            val flushed = createMessage({
                bounce: BounceMode.NoBounce,
                dest: in.senderAddress,
                value: 0,
                body: ProtocolTonFeesFlushed {
                    queryId: msg.queryId,
                    feeAmount,
                },
            });
            // SAFETY: the reserve action protects every pre-existing nanotON except the exact
            // fee, so carry-all can return only caller-funded gas remainder; IGNORE_ERRORS
            // cannot affect the already-final NoBounce fee payout or protocol accounting.
            flushed.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
        }

        TopUpTons => {}
        else => throw Errors.UnknownOp,
    }
}

get fun get_permissionless_controller_summary(): PermissionlessControllerSummaryReply {
    val storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
    val (
        _,
        authorities,
        assets,
        _,
        execution,
        _,
        rules,
        _,
    ) = permissionlessLoadConfig(storage);
    val dynamic = storage.dynamic.load();
    val protocolFee = permissionlessProtocolFeeConfig(rules);
    val protocolFees = permissionlessProtocolFeeAccounting(dynamic);
    val remaining = permissionlessAssetMasters(assets).expectedReserveSupply -
    dynamic.totalReleasedNew -
    dynamic.pendingReleasedNew;
    return {
        bound: permissionlessIsBound(assets, execution),
        permissionlessReady: permissionlessIsReady(
            authorities,
            assets,
            execution,
            dynamic,
        ),
        reserveReady: dynamic.reserveReady,
        initialLiquidityReady: dynamic.initialLiquidityReady,
        nextOperationId: dynamic.nextOperationId,
        storedOperations: dynamic.storedOperations,
        pendingSweepsCount: dynamic.pendingSweepsCount,
        bootstrapOperationId: dynamic.bootstrapOperationId,
        pendingReleasedNew: dynamic.pendingReleasedNew,
        remainingNew: remaining,
        sweepableDiamond: dynamic.sweepableDiamond,
        totalLockedDiamond: dynamic.totalLockedDiamond,
        totalReleasedNew: dynamic.totalReleasedNew,
        totalLockedLp: dynamic.totalLockedLp,
        totalRejectedDiamond: dynamic.totalRejectedDiamond,
        protocolFeeBps: protocolFee.feeBps,
        protocolFeeRecipient: protocolFee.recipient,
        accruedProtocolFeeTon: protocolFees.accruedTon,
        totalAccruedProtocolFeeTon: protocolFees.totalAccruedTon,
        totalFlushedProtocolFeeTon: protocolFees.totalFlushedTon,
    };
}

get fun get_permissionless_release_operation(
    operationId: uint64,
): PermissionlessReleaseOperationReply {
    val storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
    val dynamic = storage.dynamic.load();
    val lookup = dynamic.operations.get(operationId);
    if (!lookup.isFound) {
        return {
            exists: false,
            status: 0,
            bootstrap: false,
            clientQueryId: 0,
            beneficiary: null,
            diamondOwner: null,
            diamondOwnerWallet: null,
            tonRefundAddress: null,
            diamondAmount: 0,
            tonAmount: 0,
            protocolFeeTon: 0,
            newAmount: 0,
            minLpOut: 0,
            createdAt: 0,
            firstCompletedAt: 0,
            secondRequestedAt: 0,
            deadline: 0,
            terminalAt: 0,
            failureCode: 0,
            lockIntentRegistered: false,
            newCommitted: false,
            newRecovered: false,
            tonRecovered: false,
            diamondReturnPending: false,
            diamondReturned: false,
            tonReturned: false,
            refundRequestedAt: 0,
            lpAmount: 0,
        };
    }
    val operation = lookup.loadValue().load();
    val parties = permissionlessPartiesPrimary(operation);
    val refundParties = permissionlessPartiesRefund(operation);
    val amounts = operation.amounts.load();
    val lifecycle = operation.lifecycle.load();
    return {
        exists: true,
        status: lifecycle.status,
        bootstrap: lifecycle.bootstrap,
        clientQueryId: parties.clientQueryId,
        beneficiary: parties.beneficiary,
        diamondOwner: refundParties.diamondOwner,
        diamondOwnerWallet: refundParties.diamondOwnerWallet,
        tonRefundAddress: refundParties.tonRefundAddress,
        diamondAmount: amounts.diamondAmount,
        tonAmount: amounts.tonAmount,
        protocolFeeTon: amounts.protocolFeeTon,
        newAmount: amounts.newAmount,
        minLpOut: amounts.minLpOut,
        createdAt: lifecycle.createdAt,
        firstCompletedAt: lifecycle.firstCompletedAt,
        secondRequestedAt: lifecycle.secondRequestedAt,
        deadline: lifecycle.deadline,
        terminalAt: lifecycle.terminalAt,
        failureCode: lifecycle.failureCode,
        lockIntentRegistered: lifecycle.lockIntentRegistered,
        newCommitted: lifecycle.newCommitted,
        newRecovered: lifecycle.newRecovered,
        tonRecovered: lifecycle.tonRecovered,
        diamondReturnPending: lifecycle.diamondReturnPending,
        diamondReturned: lifecycle.diamondReturned,
        tonReturned: lifecycle.tonReturned,
        refundRequestedAt: lifecycle.refundRequestedAt,
        lpAmount: operation.lpAmount,
    };
}

get fun get_permissionless_controller_config(): PermissionlessControllerConfig {
    return PermissionlessLiquidityReleaseControllerStorage.load().config.load();
}

get fun get_permissionless_protocol_fee_quote(
    tonAmount: coins,
): PermissionlessProtocolFeeQuoteReply {
    val storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
    val (
        _,
        _,
        _,
        _,
        _,
        _,
        rules,
        gas,
    ) = permissionlessLoadConfig(storage);
    assert (tonAmount >= rules.minTonContribution) throw Errors.InvalidAmount;
    val protocolFee = permissionlessProtocolFeeConfig(rules);
    val protocolFeeTon = calculatePermissionlessProtocolFeeTon(
        tonAmount,
        protocolFee.feeBps,
    );
    val operationGasDeposit = permissionlessObservationGas(gas).operationGasDeposit;
    return {
        tonAmount,
        protocolFeeBps: protocolFee.feeBps,
        protocolFeeTon,
        operationGasDeposit,
        requiredAttachedTon: tonAmount + protocolFeeTon + operationGasDeposit,
    };
}

get fun get_permissionless_reserve_wallet_address(): address {
    val storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
    val (
        _,
        _,
        assets,
        _,
        _,
        _,
        _,
        _,
    ) = permissionlessLoadConfig(storage);
    return permissionlessReserveWallet(assets);
}

get fun get_permissionless_router_new_wallet_address(): address {
    val storage = lazy PermissionlessLiquidityReleaseControllerStorage.load();
    val (
        _,
        _,
        assets,
        _,
        execution,
        _,
        _,
        _,
    ) = permissionlessLoadConfig(storage);
    return permissionlessRouterNewWallet(assets, execution);
}
