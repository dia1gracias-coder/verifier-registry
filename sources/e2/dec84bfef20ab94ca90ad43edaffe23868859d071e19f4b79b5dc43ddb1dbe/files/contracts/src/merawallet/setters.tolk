/// Self-call setters for MeraWallet (role / config updates).

import "incoming-messages"
import "consts"
import "errors"
import "guards"
import "storage"
import "types"

fun setPrimary(senderAddress: address, msg: SetPrimary) {
    onlySelf(senderAddress);
    var storage = lazy MeraWalletRootStorage.load();
    requireLifeAliveForStateChanges(storage);
    val role = msg.contextRole;
    requireControllerCoreAvailable(storage, role);
    assert (
        role == RoleLevel.Primary || role == RoleLevel.Backup || role == RoleLevel.Emergency
    ) throw MeraErrors.InvalidRole;
    assert (msg.newPrimary != ADDRESS_ZERO) throw MeraErrors.InvalidAddress;
    storage.primary = msg.newPrimary;
    storage.save();
}

fun setBackup(senderAddress: address, msg: SetBackup) {
    onlySelf(senderAddress);
    var storage = lazy MeraWalletRootStorage.load();
    requireLifeAliveForStateChanges(storage);
    val role = msg.contextRole;
    requireControllerCoreAvailable(storage, role);
    assert (
        role == RoleLevel.Backup || role == RoleLevel.Emergency
    ) throw MeraErrors.NotAllowedRoleChange;
    assert (msg.newBackup != ADDRESS_ZERO) throw MeraErrors.InvalidAddress;
    storage.backup = msg.newBackup;
    storage.save();
}

fun setEmergency(senderAddress: address, msg: SetEmergency) {
    var storage = lazy MeraWalletRootStorage.load();
    var rest = storage.rest.load();
    val calledByGuardian = rest.guardian != ADDRESS_ZERO && senderAddress == rest.guardian;
    if (!calledByGuardian) {
        onlySelfAsEmergency(senderAddress, storage, msg.contextRole);
    }
    assert (msg.newEmergency != ADDRESS_ZERO) throw MeraErrors.InvalidAddress;

    val previousEmergency = storage.emergency;
    val emergencyChanged = previousEmergency != msg.newEmergency;
    storage.emergency = msg.newEmergency;

    if (emergencyChanged) {
        rest = setLifeController(rest, previousEmergency, false);
        rest = setLifeController(rest, msg.newEmergency, true);
        storage.proposalEpoch += 1;
        storage.rest = rest.toCell();
    }
    if (calledByGuardian && emergencyChanged) {
        if (storage.safeModeUsed || storage.safeModeBefore != 0) {
            storage.safeModeBefore = 0;
        }
    }
    storage.save();
}

/// Testnet helper: patch roles in place; `ADDRESS_ZERO` fields are left unchanged.
fun setDirectForTest(_senderAddress: address, msg: SetDirectForTest) {
    var storage = lazy MeraWalletRootStorage.load();
    if (msg.primary != ADDRESS_ZERO) {
        storage.primary = msg.primary;
    }
    if (msg.backup != ADDRESS_ZERO) {
        storage.backup = msg.backup;
    }
    if (msg.guardian != ADDRESS_ZERO) {
        var rest = storage.rest.load();
        rest.guardian = msg.guardian;
        storage.rest = rest.toCell();
    }
    storage.save();
}

/// `newGuardian` may be zero (disables guardian-only paths).
fun setGuardian(senderAddress: address, msg: SetGuardian) {
    var storage = lazy MeraWalletRootStorage.load();
    requireLifeAliveForStateChanges(storage);
    onlySelfAsEmergency(senderAddress, storage, msg.contextRole);
    var rest = storage.rest.load();
    rest.guardian = msg.guardian;
    storage.rest = rest.toCell();
    storage.save();
}

fun setEmergencyAgentLifetime(senderAddress: address, msg: SetEmergencyAgentLifetime) {
    onlySelf(senderAddress);
    var storage = lazy MeraWalletRootStorage.load();
    requireLifeAliveForStateChanges(storage);
    assert (
        msg.lifetime <= MAX_EMERGENCY_AGENT_LIFETIME
    ) throw MeraErrors.EmergencyAgentLifetimeTooLarge;
    onlySelfAsEmergency(senderAddress, storage, msg.contextRole);
    storage.emergencyAgentLifetime = msg.lifetime;
    storage.save();
}

fun setLifeControl(senderAddress: address, msg: SetLifeControl) {
    var storage = lazy MeraWalletRootStorage.load();
    requireSenderIsEmergency(senderAddress, storage);
    var rest = lazy storage.rest.load();
    var lc = lazy rest.lifeControl.load();
    val wasEnabled = lc.enabled;
    if (msg.enabled) {
        assert (msg.timeout != 0) throw MeraErrors.LifeHeartbeatTimeoutZero;
        rest = setLifeController(rest, storage.emergency, true);
        lc = rest.lifeControl.load();
        if (!wasEnabled) {
            lc.lastAlive = blockchain.now();
        }
    }
    lc.enabled = msg.enabled;
    lc.timeout = msg.timeout;
    rest.lifeControl = lc.toCell();
    storage.rest = rest.toCell();
    storage.save();
}

fun setLifeControllers(senderAddress: address, msg: SetLifeControllers) {
    var storage = lazy MeraWalletRootStorage.load();
    requireSenderIsEmergency(senderAddress, storage);
    var rest = lazy storage.rest.load();
    var i = 0;
    repeat (msg.controllers.size()) {
        val controller = msg.controllers.get(i);
        assert (controller != ADDRESS_ZERO) throw MeraErrors.InvalidAddress;
        if (msg.enabled) {
            rest = setLifeController(rest, controller, true);
        } else {
            assert (
                controller != storage.emergency
            ) throw MeraErrors.EmergencyMustStayLifeController;
            rest = setLifeController(rest, controller, false);
        }
        i += 1;
    }
    storage.rest = rest.toCell();
    storage.save();
}

fun setTargetCallPolicies(senderAddress: address, msg: SetTargetCallPolicies) {
    onlySelf(senderAddress);
    var storage = lazy MeraWalletRootStorage.load();
    requireLifeAliveForStateChanges(storage);
    onlySelfAsEmergency(senderAddress, storage, msg.contextRole);
    var policies = lazy storage.policies.load();
    var i = 0;
    repeat (msg.entries.size()) {
        val entry = msg.entries.get(i);
        policies.callByTarget.set(entry.target, callPathPolicyStored(entry.policy));
        i += 1;
    }
    storage.policies = policies.toCell();
    storage.save();
}

fun setSelectorCallPolicies(senderAddress: address, msg: SetSelectorCallPolicies) {
    onlySelf(senderAddress);
    var storage = lazy MeraWalletRootStorage.load();
    requireLifeAliveForStateChanges(storage);
    onlySelfAsEmergency(senderAddress, storage, msg.contextRole);
    var policies = lazy storage.policies.load();
    var i = 0;
    repeat (msg.entries.size()) {
        val entry = msg.entries.get(i);
        policies.callBySelector.set(entry.selector, callPathPolicyStored(entry.policy));
        i += 1;
    }
    storage.policies = policies.toCell();
    storage.save();
}

fun setTargetSelectorCallPolicies(senderAddress: address, msg: SetTargetSelectorCallPolicies) {
    onlySelf(senderAddress);
    var storage = lazy MeraWalletRootStorage.load();
    requireLifeAliveForStateChanges(storage);
    onlySelfAsEmergency(senderAddress, storage, msg.contextRole);
    var policies = lazy storage.policies.load();
    var i = 0;
    repeat (msg.entries.size()) {
        val entry = msg.entries.get(i);
        val key = targetSelectorPolicyKey(entry.target, entry.selector);
        if (!entry.policy.exists) {
            val lookup = policies.callByTargetSelector.get(key);
            assert (lookup.isFound) throw MeraErrors.NoopTargetSelectorCallPolicy;
            policies.callByTargetSelector.delete(key);
        } else {
            policies.callByTargetSelector.set(key, callPathPolicyStored(entry.policy));
        }
        i += 1;
    }
    storage.policies = policies.toCell();
    storage.save();
}

fun setAgents(senderAddress: address, msg: SetAgents) {
    onlySelf(senderAddress);
    var storage = lazy MeraWalletRootStorage.load();
    requireLifeAliveForStateChanges(storage);
    val callerRole = msg.contextRole;
    assert (callerRole != RoleLevel.None) throw MeraErrors.NotCoreController;
    requireControllerCoreAvailable(storage, callerRole);

    var rest = lazy storage.rest.load();
    var agentsState = lazy rest.agents.load();
    var i = 0;
    repeat (msg.entries.size()) {
        val entry = msg.entries.get(i);
        if (entry.roleLevelBits == 0) {
            val lookup = agentsState.agents.get(entry.agent);
            assert (lookup.isFound) throw MeraErrors.NoopAgent;
            val stored = lookup.loadValue();
            val storedRole = parseCoreRole(stored.roleLevel);
            assert (
                roleRank(callerRole) >= roleRank(storedRole)
            ) throw MeraErrors.AgentRemovalNotAuthorized;
            agentsState.agents.delete(entry.agent);
        } else {
            assert (entry.agent != ADDRESS_ZERO) throw MeraErrors.InvalidAddress;
            assert (entry.agent != contract.getAddress()) throw MeraErrors.WalletCannotBeAgent;
            val entryRole = parseCoreRole(entry.roleLevelBits);
            assert (
                entryRole == RoleLevel.Primary || entryRole == RoleLevel.Backup ||
                entryRole == RoleLevel.Emergency
            ) throw MeraErrors.InvalidRole;
            assert (
                roleRank(entryRole) <= roleRank(callerRole)
            ) throw MeraErrors.AgentRemovalNotAuthorized;
            agentsState
                .agents
                .set(
                    entry.agent,
                    Agent {
                        roleLevel: entry.roleLevelBits,
                        activeFrom: 0,
                    },
                );
        }
        i += 1;
    }
    rest.agents = agentsState.toCell();
    storage.rest = rest.toCell();
    storage.save();
}

/// Stored policies always have `exists == true` (pair map uses `exists == false` to delete).
fun callPathPolicyStored(policy: CallPathPolicy): CallPathPolicy {
    return CallPathPolicy {
        flags: policy.flags,
        primaryDelay: policy.primaryDelay,
        backupDelay: policy.backupDelay,
        emergencyDelay: policy.emergencyDelay,
        exists: true,
    };
}

fun setRoleTimelock(senderAddress: address, msg: SetRoleTimelock) {
    onlySelf(senderAddress);
    var storage = lazy MeraWalletRootStorage.load();
    requireLifeAliveForStateChanges(storage);
    val callerRole = msg.contextRole;
    requireControllerCoreAvailable(storage, callerRole);
    val targetRole = parseCoreRole(msg.role);
    assert (msg.delay <= MAX_TIMELOCK_DELAY) throw MeraErrors.TimelockDelayTooLarge;
    assert (
        roleRank(callerRole) >= roleRank(targetRole)
    ) throw MeraErrors.RoleTimelockChangeNotAuthorized;

    var rest = lazy storage.rest.load();
    var timelocks = lazy rest.roleTimelocks.load();
    timelocks = setRoleTimelockField(timelocks, targetRole, msg.delay as uint256);
    rest.roleTimelocks = timelocks.toCell();
    storage.rest = rest.toCell();
    storage.save();
}

fun setFrozenPrimary(senderAddress: address, msg: SetFrozenPrimary) {
    var storage = lazy MeraWalletRootStorage.load();
    assertFreezeAuthorized(senderAddress, storage, RoleLevel.Primary, msg.value, msg.contextRole);
    var rest = storage.rest.load();
    rest = startEmergencyAgentLifetimeIfNeeded(senderAddress, rest);
    storage.frozenPrimary = msg.value;
    storage.rest = rest.toCell();
    storage.save();
}

fun setFrozenBackup(senderAddress: address, msg: SetFrozenBackup) {
    var storage = lazy MeraWalletRootStorage.load();
    assertFreezeAuthorized(senderAddress, storage, RoleLevel.Backup, msg.value, msg.contextRole);
    var rest = storage.rest.load();
    rest = startEmergencyAgentLifetimeIfNeeded(senderAddress, rest);
    if (storage.frozenBackup == msg.value) {
        storage.rest = rest.toCell();
        storage.save();
        return;
    }
    storage.frozenBackup = msg.value;
    storage.rest = rest.toCell();
    storage.save();
}
