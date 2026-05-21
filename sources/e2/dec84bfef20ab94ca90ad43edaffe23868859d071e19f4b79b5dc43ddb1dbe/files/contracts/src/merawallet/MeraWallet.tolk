import "incoming-messages"
import "actions"
import "errors"
import "getters"
import "internal-messages"
import "setters"
import "storage"
import "types"
import "types"

contract MeraWallet {
    author: "Acton User"
    version: "0.0.1"
    description: "Mera smart-wallet"
    storage: MeraWalletRootStorage
    incomingMessages: MeraWalletAnyIncoming
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy MeraWalletAnyIncoming.fromSlice(in.body);

    match (msg) {
        SetPrimary => {
            setPrimary(in.senderAddress, msg);
        }
        SetBackup => {
            setBackup(in.senderAddress, msg);
        }
        SetEmergency => {
            setEmergency(in.senderAddress, msg);
        }
        SetGuardian => {
            setGuardian(in.senderAddress, msg);
        }
        SetEmergencyAgentLifetime => {
            setEmergencyAgentLifetime(in.senderAddress, msg);
        }
        SetRoleTimelock => {
            setRoleTimelock(in.senderAddress, msg);
        }
        SetTargetCallPolicies => {
            setTargetCallPolicies(in.senderAddress, msg);
        }
        SetSelectorCallPolicies => {
            setSelectorCallPolicies(in.senderAddress, msg);
        }
        SetTargetSelectorCallPolicies => {
            setTargetSelectorCallPolicies(in.senderAddress, msg);
        }
        SetAgents => {
            setAgents(in.senderAddress, msg);
        }
        SetLifeControl => {
            setLifeControl(in.senderAddress, msg);
        }
        SetLifeControllers => {
            setLifeControllers(in.senderAddress, msg);
        }
        ExecuteTransaction => {
            //это прямое выполнение без записи в сторадж, оперейшн ид тут не используется
            executeTransaction(in.senderAddress, msg);
        }
        ProposeTransaction => {
            proposeTransaction(in.senderAddress, msg);
        }
        ExecutePending => {
            executePending(in.senderAddress, msg);
        }
        TransferNative => {
            transferNative(in.senderAddress, msg);
        }
        VetoPending => {
            vetoPending(in.senderAddress, msg);
        }
        ClearVeto => {
            clearVeto(in.senderAddress, msg);
        }
        CancelPending => {
            cancelPending(in.senderAddress, msg);
        }
        SetFrozenPrimary => {
            setFrozenPrimary(in.senderAddress, msg);
        }
        SetFrozenBackup => {
            setFrozenBackup(in.senderAddress, msg);
        }
        EnterSafeMode => {
            enterSafeMode(in.senderAddress, msg);
        }
        ResetSafeMode => {
            resetSafeMode(in.senderAddress, msg);
        }
        ConfirmAlive => {
            confirmAlive(in.senderAddress);
        }
        SetDirectForTest => {
            setDirectForTest(in.senderAddress, msg);
        }
        ProposalExecutePayload => {
            handleProposalExecutePayload(in.senderAddress, msg);
        }
        ProposalVetoPrepared => {
            handleProposalVetoPrepared(in.senderAddress, msg);
        }
        ProposalVetoAck => {
            handleProposalVetoAck(in.senderAddress, msg);
        }
        ProposalClearVetoAck => {
            handleProposalClearVetoAck(in.senderAddress, msg);
        }
        ProposalCancelAck => {
            handleProposalCancelAck(in.senderAddress, msg);
        }
        ProposalAck => {}
        else => {
            assert (in.body.isEmpty()) throw MeraErrors.InvalidMessage;
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {}

/// `get fun` must stay in this file (Acton). Bodies: `MeraWalletGetters.tolk`.

get fun targetCallPolicy(target: address): CallPathPolicy {
    return getTargetCallPolicy(target);
}

get fun selectorCallPolicy(selector: uint32): CallPathPolicy {
    return getSelectorCallPolicy(selector);
}

get fun targetSelectorCallPolicy(target: address, selector: uint32): CallPathPolicy {
    return getTargetSelectorCallPolicy(target, selector);
}

get fun primary(): address {
    return getPrimary();
}

get fun backup(): address {
    return getBackup();
}

get fun emergency(): address {
    return getEmergency();
}

get fun frozenPrimary(): bool {
    return getFrozenPrimary();
}

get fun frozenBackup(): bool {
    return getFrozenBackup();
}

get fun emergencyAgentLifetime(): uint32 {
    return getEmergencyAgentLifetime();
}

get fun guardian(): address {
    return getGuardian();
}

get fun roleTimelock(role: RoleLevel): uint256 {
    return getRoleTimelock(role);
}

get fun roleTimelockDelay(role: RoleLevel): uint256 {
    return getRoleTimelock(role);
}

get fun proposalEpoch(): uint32 {
    return getProposalEpoch();
}

get fun pendingTransactionsCount(): uint32 {
    return getPendingTransactionsCount();
}

get fun operationStorageAddress(operationId: uint256): address {
    return getOperationStorageAddress(operationId);
}

get fun isLifeController(controller: address): bool {
    return getIsLifeController(controller);
}

get fun agentRoleLevel(agent: address): uint32 {
    return getAgentRoleLevel(agent);
}

get fun agentActiveFrom(agent: address): uint32 {
    return getAgentActiveFrom(agent);
}

get fun safeModeBefore(): uint32 {
    return getSafeModeBefore();
}

get fun safeModeUsed(): bool {
    return getSafeModeUsed();
}

get fun lifeControlEnabled(): bool {
    return getLifeControlEnabled();
}

get fun lifeControlTimeout(): uint32 {
    return getLifeControlTimeout();
}

get fun lifeControlLastAlive(): uint32 {
    return getLifeControlLastAlive();
}
