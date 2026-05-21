/// Business logic for MeraWallet (heartbeats, transactions, proposals — not role/config setters).

import "incoming-messages"
import "consts"
import "errors"
import "guards"
import "internal-messages"
import "storage"
import "types"
import "types"
import "operation/types"

fun executeTransaction(senderAddress: address, msg: ExecuteTransaction) {
    val storage = lazy MeraWalletRootStorage.load();
    requireLifeAliveForStateChanges(storage);

    val callerRole = coreRole(senderAddress, storage);
    assert (callerRole != RoleLevel.None) throw MeraErrors.NotCoreController;
    requireControllerCoreAvailable(storage, callerRole);
    assertCallCountForBatch(msg.calls.size() as uint32);

    val requiredDelay = requiredDelay(storage, callerRole, msg.calls);
    assert (requiredDelay == 0) throw MeraErrors.PolicyDelayNotZero;

    executeCalls(msg.calls, callerRole);
}

/// Mirrors `MERAWalletNative.transferNative`: one outgoing message with empty body.
fun transferNative(senderAddress: address, msg: TransferNative) {
    val storage = lazy MeraWalletRootStorage.load();
    requireLifeAliveForStateChanges(storage);

    val callerRole = coreRole(senderAddress, storage);
    assert (callerRole != RoleLevel.None) throw MeraErrors.NotCoreController;
    requireControllerCoreAvailable(storage, callerRole);
    assert (msg.to != ADDRESS_ZERO) throw MeraErrors.InvalidAddress;
    assert (msg.checker == ADDRESS_ZERO) throw MeraErrors.InvalidMessage;

    var calls: CallList = [];
    calls.push(
        Call {
            target: msg.to,
            value: msg.amount,
            body: beginCell().endCell(),
        }.toCell(),
    );

    assertCallCountForBatch(1);
    val requiredDelay = requiredDelay(storage, callerRole, calls);
    assert (requiredDelay == 0) throw MeraErrors.PolicyDelayNotZero;

    executeCalls(calls, callerRole);
}

fun executeCalls(calls: CallList, contextRole: RoleLevel) {
    assertCallValuesMin(calls);

    var i = 0;
    repeat (calls.size()) {
        val call = Call.fromCell(calls.get(i));
        if (call.target == contract.getAddress()) {
            assertSelfCallContextRole(call.body, contextRole);
        }
        val out = createMessage({
            bounce: true,
            value: call.value,
            dest: call.target,
            body: call.body,
        });
        out.send(
            SEND_MODE_PAY_FEES_SEPARATELY,
        );                                       //тут надо подумать: поменять на SEND_MODE_REGULAR, не надо чтобы списывались бабки с контракта, но тогда надо запрещать нулевые велью?
        i += 1;
    }
}

fun proposeTransaction(senderAddress: address, msg: ProposeTransaction) {
    var storage = lazy MeraWalletRootStorage.load();
    requireLifeAliveForStateChanges(storage);

    val callerRole = coreRole(senderAddress, storage);
    assert (callerRole != RoleLevel.None) throw MeraErrors.NotCoreController;
    requireControllerCoreAvailable(storage, callerRole);
    val callCount = msg.calls.size() as uint8;
    assertCallCountForBatch(callCount as uint32);

    val requiredDelay = requiredDelay(storage, callerRole, msg.calls);
    assert (requiredDelay != 0) throw MeraErrors.ZeroDelayNotProposable;

    val createdAt = blockchain.now();
    val executeAfter = createdAt + (requiredDelay as uint32);
    val rest = lazy storage.rest.load();
    val callsCell = msg.calls.toCell();
    val operationId = computeOperationId(contract.getAddress(), callsCell, msg.salt);
    val operationStorage = calcDeployedOperationStorage(
        contract.getAddress(),
        operationId,
        rest.operationStorageCode,
    );
    val storageAddr = operationStorage.calculateAddress();

    storage.pendingTransactionsCount += 1;
    storage.save();

    val deployMsg = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: operationStorage,
        value: PROPOSAL_STORAGE_TOPUP,
        body: ProposalInit {
            operationId,
            epoch: storage.proposalEpoch,
            creator: senderAddress,
            creatorRole: callerRole as uint2,
            createdAt,
            executeAfter,
            callsCell,
            salt: msg.salt,
        },
    });
    deployMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);

    val eventMsg = createExternalLogMessage({
        dest: ExtOutLogBucket { topic: PROPOSAL_REGISTERED_TOPIC },
        body: ProposalRegistered {
            operationId,
            epoch: storage.proposalEpoch,
            storageAddr,
            details: ProposalRegisteredDetails {
                creator: senderAddress,
                creatorRole: callerRole as uint2,
                createdAt,
                executeAfter,
                callCount,
            }.toCell(),
        },
    });
    eventMsg.send(SEND_MODE_REGULAR);
}

fun executePending(senderAddress: address, msg: ExecutePending) {
    val storage = lazy MeraWalletRootStorage.load();
    requireLifeAliveForStateChanges(storage);

    val callerRole = coreRole(senderAddress, storage);
    assert (callerRole != RoleLevel.None) throw MeraErrors.NotCoreController;
    requireControllerCoreAvailable(storage, callerRole);

    val rest = lazy storage.rest.load();
    val operationStorage = calcDeployedOperationStorage(
        contract.getAddress(),
        msg.operationId,
        rest.operationStorageCode,
    );

    val request = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: operationStorage,
        value: PROPOSAL_STORAGE_TOPUP,
        body: ProposalExecuteRequest {},
    });
    request.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun vetoPending(senderAddress: address, msg: VetoPending) {
    val storage = lazy MeraWalletRootStorage.load();

    val rest = lazy storage.rest.load();
    val operationStorage = calcDeployedOperationStorage(
        contract.getAddress(),
        msg.operationId,
        rest.operationStorageCode,
    );

    val prepare = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: operationStorage,
        value: PROPOSAL_STORAGE_TOPUP,
        body: ProposalVetoPrepare { vetoer: senderAddress },
    });
    prepare.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun handleProposalVetoPrepared(senderAddress: address, msg: ProposalVetoPrepared) {
    var storage = lazy MeraWalletRootStorage.load();

    val rest = lazy storage.rest.load();
    val expectedStorage = calcDeployedOperationStorage(
        contract.getAddress(),
        msg.operationId,
        rest.operationStorageCode,
    ).calculateAddress();
    assert (senderAddress == expectedStorage) throw MeraErrors.ProposalPayloadFromWrongStorage;

    assert (
        isRankedRoleActionAllowed(
            msg.vetoer,
            storage,
            parseCoreRole(msg.creatorRole),
            true,
            RoleLevel.None,
        )
    ) throw MeraErrors.CannotVetoOperation;

    var restMut = lazy storage.rest.load();
    restMut = startEmergencyAgentLifetimeIfNeeded(msg.vetoer, restMut);
    storage.rest = restMut.toCell();
    storage.save();

    val operationStorage = calcDeployedOperationStorage(
        contract.getAddress(),
        msg.operationId,
        rest.operationStorageCode,
    );

    val commit = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: operationStorage,
        value: PROPOSAL_STORAGE_TOPUP,
        body: ProposalVeto {
            senderAddr: msg.vetoer,
            senderRole: 0,
        },
    });
    commit.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun handleProposalVetoAck(senderAddress: address, msg: ProposalVetoAck) {
    val storage = lazy MeraWalletRootStorage.load();
    assert (msg.epoch == storage.proposalEpoch) throw MeraErrors.ProposalEpochMismatch;

    val rest = lazy storage.rest.load();
    val expectedStorage = calcDeployedOperationStorage(
        contract.getAddress(),
        msg.operationId,
        rest.operationStorageCode,
    ).calculateAddress();
    assert (senderAddress == expectedStorage) throw MeraErrors.ProposalPayloadFromWrongStorage;

    val eventMsg = createExternalLogMessage({
        dest: ExtOutLogBucket { topic: PENDING_TRANSACTION_VETOED_TOPIC },
        body: PendingTransactionVetoed {
            operationId: msg.operationId,
            vetoedBy: msg.vetoedBy,
        },
    });
    eventMsg.send(SEND_MODE_REGULAR);
}

fun clearVeto(senderAddress: address, msg: ClearVeto) {
    val storage = lazy MeraWalletRootStorage.load();
    requireLifeAliveForStateChanges(storage);

    val callerRole = coreRole(senderAddress, storage);
    assert (callerRole != RoleLevel.None) throw MeraErrors.NotCoreController;
    requireControllerCoreAvailable(storage, callerRole);

    val rest = lazy storage.rest.load();
    val operationStorage = calcDeployedOperationStorage(
        contract.getAddress(),
        msg.operationId,
        rest.operationStorageCode,
    );

    val request = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: operationStorage,
        value: PROPOSAL_STORAGE_TOPUP,
        body: ProposalClearVeto {
            senderAddr: senderAddress,
            senderRole: callerRole as uint2,
        },
    });
    request.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun handleProposalClearVetoAck(senderAddress: address, msg: ProposalClearVetoAck) {
    val storage = lazy MeraWalletRootStorage.load();
    requireLifeAliveForStateChanges(storage);
    assert (msg.epoch == storage.proposalEpoch) throw MeraErrors.ProposalEpochMismatch;

    val rest = lazy storage.rest.load();
    val expectedStorage = calcDeployedOperationStorage(
        contract.getAddress(),
        msg.operationId,
        rest.operationStorageCode,
    ).calculateAddress();
    assert (senderAddress == expectedStorage) throw MeraErrors.ProposalPayloadFromWrongStorage;

    val eventMsg = createExternalLogMessage({
        dest: ExtOutLogBucket { topic: PENDING_TRANSACTION_VETO_CLEARED_TOPIC },
        body: PendingTransactionVetoCleared {
            operationId: msg.operationId,
            clearedBy: msg.clearedBy,
        },
    });
    eventMsg.send(SEND_MODE_REGULAR);
}

fun cancelPending(senderAddress: address, msg: CancelPending) {
    val storage = lazy MeraWalletRootStorage.load();
    requireLifeAliveForStateChanges(storage);

    val callerRole = coreRole(senderAddress, storage);
    assert (callerRole != RoleLevel.None) throw MeraErrors.NotCoreController;

    val rest = lazy storage.rest.load();
    val operationStorage = calcDeployedOperationStorage(
        contract.getAddress(),
        msg.operationId,
        rest.operationStorageCode,
    );

    val request = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: operationStorage,
        value: PROPOSAL_STORAGE_TOPUP,
        body: ProposalCancel {
            senderAddr: senderAddress,
            senderRole: callerRole as uint2,
        },
    });
    request.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun handleProposalExecutePayload(senderAddress: address, msg: ProposalExecutePayload) {
    var storage = lazy MeraWalletRootStorage.load();
    requireLifeAliveForStateChanges(storage);
    assert (msg.epoch == storage.proposalEpoch) throw MeraErrors.ProposalEpochMismatch;
    assert (blockchain.now() >= msg.executeAfter) throw MeraErrors.ProposalTooEarly;

    val rest = lazy storage.rest.load();
    val expectedStorage = calcDeployedOperationStorage(
        contract.getAddress(),
        msg.operationId,
        rest.operationStorageCode,
    ).calculateAddress();
    assert (senderAddress == expectedStorage) throw MeraErrors.ProposalPayloadFromWrongStorage;

    val calls = CallList.fromCell(msg.callsCell);
    assertCallCountForBatch(calls.size() as uint32);
    assert (storage.pendingTransactionsCount > 0) throw MeraErrors.InvalidMessage;

    assertCreatorRoleMatchesAddress(msg.creator, msg.creatorRole, storage);
    val executionContextRole = coreRole(msg.creator, storage);

    storage.pendingTransactionsCount -= 1;
    storage.save();
    executeCalls(calls, executionContextRole);
}

fun handleProposalCancelAck(senderAddress: address, msg: ProposalCancelAck) {
    var storage = lazy MeraWalletRootStorage.load();
    requireLifeAliveForStateChanges(storage);
    assert (msg.epoch == storage.proposalEpoch) throw MeraErrors.ProposalEpochMismatch;

    val rest = lazy storage.rest.load();
    val expectedStorage = calcDeployedOperationStorage(
        contract.getAddress(),
        msg.operationId,
        rest.operationStorageCode,
    ).calculateAddress();
    assert (senderAddress == expectedStorage) throw MeraErrors.ProposalPayloadFromWrongStorage;
    assert (storage.pendingTransactionsCount > 0) throw MeraErrors.InvalidMessage;

    storage.pendingTransactionsCount -= 1;
    storage.save();

    val eventMsg = createExternalLogMessage({
        dest: ExtOutLogBucket { topic: PENDING_TRANSACTION_CANCELLED_TOPIC },
        body: PendingTransactionCancelled {
            operationId: msg.operationId,
            cancelledBy: msg.cancelledBy,
        },
    });
    eventMsg.send(SEND_MODE_REGULAR);
}

fun requiredDelay(
    storage: MeraWalletRootStorage,
    callerRole: RoleLevel,
    calls: CallList,
): uint256 {
    var requiredDelay: uint256 = 0;
    var i = 0;
    repeat (calls.size()) {
        val call = Call.fromCell(calls.get(i));
        val callDelay = callDelay(storage, callerRole, call);
        if (callDelay > requiredDelay) {
            requiredDelay = callDelay;
        }
        i += 1;
    }
    return requiredDelay;
}

fun callDelay(
    storage: MeraWalletRootStorage,
    callerRole: RoleLevel,
    call: Call,
): uint256 {
    val selector = callSelector(call.body);
    val policies = lazy storage.policies.load();
    val pairKey = targetSelectorPolicyKey(call.target, selector);
    val pairLookup = policies.callByTargetSelector.get(pairKey);
    if (pairLookup.isFound) {
        val pairPolicy = pairLookup.loadValue();
        assert (!policyForbidden(pairPolicy, callerRole)) throw MeraErrors.PolicyForbidden;
        return policyDelay(pairPolicy, callerRole);
    }

    val targetLookup = policies.callByTarget.get(call.target);
    val selectorLookup = policies.callBySelector.get(selector);
    if (!targetLookup.isFound && !selectorLookup.isFound) {
        val rest = lazy storage.rest.load();
        val timelocks = lazy rest.roleTimelocks.load();
        assert (callerRole != RoleLevel.None) throw MeraErrors.InvalidRole;
        return getRoleTimelockFromState(timelocks, callerRole);
    }

    var targetPolicy = emptyCallPathPolicy();
    if (targetLookup.isFound) {
        targetPolicy = targetLookup.loadValue();
    }
    var selectorPolicy = emptyCallPathPolicy();
    if (selectorLookup.isFound) {
        selectorPolicy = selectorLookup.loadValue();
    }
    assert (!policyForbidden(targetPolicy, callerRole)) throw MeraErrors.PolicyForbidden;
    assert (!policyForbidden(selectorPolicy, callerRole)) throw MeraErrors.PolicyForbidden;
    val targetDelay = policyDelay(targetPolicy, callerRole);
    val selectorDelay = policyDelay(selectorPolicy, callerRole);
    if (targetDelay > selectorDelay) {
        return targetDelay;
    }
    return selectorDelay;
}

fun emptyCallPathPolicy(): CallPathPolicy {
    return CallPathPolicy {
        flags: 0,
        primaryDelay: 0,
        backupDelay: 0,
        emergencyDelay: 0,
        exists: false,
    };
}

fun policyForbidden(policy: CallPathPolicy, role: RoleLevel): bool {
    if (role == RoleLevel.Primary) {
        return policy.flags % 2 != 0;
    }
    if (role == RoleLevel.Backup) {
        return (policy.flags / 2) % 2 != 0;
    }
    return false;
}

fun policyDelay(policy: CallPathPolicy, role: RoleLevel): uint256 {
    if (role == RoleLevel.Primary) {
        return policy.primaryDelay as uint256;
    }
    if (role == RoleLevel.Backup) {
        return policy.backupDelay as uint256;
    }
    if (role == RoleLevel.Emergency) {
        return policy.emergencyDelay as uint256;
    }
    throw MeraErrors.InvalidRole;
}

fun callSelector(body: cell): uint32 {
    var bodySlice = body.beginParse();
    if (bodySlice.remainingBitsCount() < 32) {
        return 0;
    }
    return bodySlice.loadUint(32);
}

fun assertSelfCallContextRole(body: cell, callerRole: RoleLevel) {
    val inner = lazy MeraWalletIncoming.fromSlice(body.beginParse());
    match (inner) {
        SetPrimary => {
            assert (inner.contextRole == callerRole) throw MeraErrors.UnauthorizedRole;
        }
        SetBackup => {
            assert (inner.contextRole == callerRole) throw MeraErrors.UnauthorizedRole;
        }
        SetEmergency => {
            assert (inner.contextRole == callerRole) throw MeraErrors.UnauthorizedRole;
        }
        SetGuardian => {
            assert (inner.contextRole == callerRole) throw MeraErrors.UnauthorizedRole;
        }
        SetEmergencyAgentLifetime => {
            assert (inner.contextRole == callerRole) throw MeraErrors.UnauthorizedRole;
        }
        SetRoleTimelock => {
            assert (inner.contextRole == callerRole) throw MeraErrors.UnauthorizedRole;
        }
        SetTargetCallPolicies => {
            assert (inner.contextRole == callerRole) throw MeraErrors.UnauthorizedRole;
        }
        SetSelectorCallPolicies => {
            assert (inner.contextRole == callerRole) throw MeraErrors.UnauthorizedRole;
        }
        SetTargetSelectorCallPolicies => {
            assert (inner.contextRole == callerRole) throw MeraErrors.UnauthorizedRole;
        }
        SetAgents => {
            assert (inner.contextRole == callerRole) throw MeraErrors.UnauthorizedRole;
        }
        SetLifeControl => {}
        SetLifeControllers => {}
        ExecuteTransaction => {}
        ProposeTransaction => {}
        ExecutePending => {}
        TransferNative => {}
        VetoPending => {}
        ClearVeto => {}
        CancelPending => {}
        SetFrozenPrimary => {
            assert (inner.contextRole == callerRole) throw MeraErrors.UnauthorizedRole;
        }
        SetFrozenBackup => {
            assert (inner.contextRole == callerRole) throw MeraErrors.UnauthorizedRole;
        }
        EnterSafeMode => {}
        ResetSafeMode => {
            assert (inner.contextRole == callerRole) throw MeraErrors.UnauthorizedRole;
        }
        ConfirmAlive => {}
        SetDirectForTest => {}
    }
}

/// Mirrors `confirmAlive`: any registered life controller may refresh `lastAlive`.
fun confirmAlive(senderAddress: address) {
    var storage = lazy MeraWalletRootStorage.load();
    requireSenderIsLifeController(senderAddress, storage);
    var rest = lazy storage.rest.load();
    var lc = lazy rest.lifeControl.load();
    lc.lastAlive = blockchain.now();
    rest.lifeControl = lc.toCell();
    storage.rest = rest.toCell();
    storage.save();
}

fun enterSafeMode(senderAddress: address, msg: EnterSafeMode) {
    var storage = lazy MeraWalletRootStorage.load();
    assertEnterSafeModeAuthorized(senderAddress, storage);
    assert (
        !(storage.safeModeUsed && storage.safeModeBefore != 0)
    ) throw MeraErrors.SafeModeAlreadyUsed;
    assert (
        msg.duration >= SAFE_MODE_MIN_DURATION && msg.duration <= SAFE_MODE_MAX_DURATION
    ) throw MeraErrors.SafeModeDurationOutOfRange;

    val sumLifetime = storage.emergencyAgentLifetime + msg.duration;
    assert (
        sumLifetime >= storage.emergencyAgentLifetime
    ) throw MeraErrors.EmergencyAgentLifetimeOverflow;
    storage.emergencyAgentLifetime = sumLifetime;

    var rest = lazy storage.rest.load();
    rest = startEmergencyAgentLifetimeIfNeeded(senderAddress, rest);
    storage.rest = rest.toCell();

    storage.safeModeUsed = true;
    storage.safeModeBefore = blockchain.now() + msg.duration;
    storage.save();
}

fun resetSafeMode(senderAddress: address, msg: ResetSafeMode) {
    onlySelf(senderAddress);
    var storage = lazy MeraWalletRootStorage.load();
    onlySelfAsEmergency(senderAddress, storage, msg.contextRole);
    assert (storage.safeModeUsed) throw MeraErrors.SafeModeNotUsed;
    assert (blockchain.now() > storage.safeModeBefore) throw MeraErrors.SafeModeStillActive;
    storage.safeModeUsed = false;
    storage.safeModeBefore = 0;
    storage.save();
}
