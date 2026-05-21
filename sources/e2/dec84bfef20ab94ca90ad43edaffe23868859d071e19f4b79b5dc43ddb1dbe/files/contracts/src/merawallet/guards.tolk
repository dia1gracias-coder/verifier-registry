/// Permission checks and small validators for `MeraWallet` and related contracts.

import "consts"
import "errors"
import "storage"
import "types"
import "operation/types"

/// Composite dict key: `sha256(workchain ‖ account_id ‖ selector)` per spec §7.1.
fun targetSelectorPolicyKey(target: address, selector: uint32): uint256 {
    val (workchain, accountId) = target.getWorkchainAndHash();
    return beginCell()
        .storeInt(workchain, 8)
        .storeUint(accountId, 256)
        .storeUint(selector, 32)
        .toSlice()
        .bitsHash();
}

fun onlySelf(senderAddress: address) {
    assert (senderAddress == contract.getAddress()) throw MeraErrors.NotSelfCall;
}

/// Mirrors `require(msg.sender == emergency, NotEmergency())` on direct external calls.
fun requireSenderIsEmergency(senderAddress: address, root: MeraWalletRootStorage) {
    assert (senderAddress == root.emergency) throw MeraErrors.NotEmergency;
}

/// Mirrors `require(_isLifeController[msg.sender], NotLifeController())`.
fun requireSenderIsLifeController(senderAddress: address, root: MeraWalletRootStorage) {
    val rest = root.rest.load();
    val lc = rest.lifeControl.load();
    val lookup = lc.controllers.get(senderAddress);
    assert (lookup.isFound && lookup.loadValue() != 0) throw MeraErrors.NotLifeController;
}

/// Mirrors `_onlySelfAsEmergency` (self-call + not safe mode + effective role Emergency).
fun onlySelfAsEmergency(
    senderAddress: address,
    root: MeraWalletRootStorage,
    contextRole: RoleLevel,
) {
    onlySelf(senderAddress);
    requireNotSafeMode(root);
    assert (contextRole == RoleLevel.Emergency) throw MeraErrors.NotEmergency;
}

fun requireLifeAliveForStateChanges(root: MeraWalletRootStorage) {
    val rest = lazy root.rest.load();
    val lc = lazy rest.lifeControl.load();
    if (!lc.enabled) {
        return;
    }
    val now = blockchain.now();
    assert (
        lc.lastAlive != 0 && now <= lc.lastAlive + lc.timeout
    ) throw MeraErrors.LifeControlExpired;
}

/// Mirrors `_requireNotSafeMode` (safeModeBefore = active-until timestamp when non-zero).
fun requireNotSafeMode(root: MeraWalletRootStorage) {
    if (root.safeModeBefore != 0) {
        assert (blockchain.now() > root.safeModeBefore) throw MeraErrors.SafeModeActive;
    }
}

/// Mirrors `_requireControllerCoreAvailable` (safe mode off + core role not frozen).
fun requireControllerCoreAvailable(root: MeraWalletRootStorage, contextRole: RoleLevel) {
    requireNotSafeMode(root);
    requireCoreNotFrozen(root, contextRole);
}

/// Mirrors `_roleRank` (Primary=1 .. Emergency=3).
fun roleRank(role: RoleLevel): uint32 {
    if (role == RoleLevel.Emergency) {
        return ROLE_RANK_EMERGENCY;
    }
    if (role == RoleLevel.Backup) {
        return ROLE_RANK_BACKUP;
    }
    if (role == RoleLevel.Primary) {
        return ROLE_RANK_PRIMARY;
    }
    return ROLE_RANK_NONE;
}

fun getRoleTimelockFromState(timelocks: RoleTimelocks, role: RoleLevel): uint256 {
    if (role == RoleLevel.Emergency) {
        return timelocks.emergencyDelay;
    }
    if (role == RoleLevel.Backup) {
        return timelocks.backupDelay;
    }
    if (role == RoleLevel.Primary) {
        return timelocks.primaryDelay;
    }
    return 0;
}

fun setRoleTimelockField(timelocks: RoleTimelocks, role: RoleLevel, delay: uint256): RoleTimelocks {
    if (role == RoleLevel.Emergency) {
        return RoleTimelocks {
            primaryDelay: timelocks.primaryDelay,
            backupDelay: timelocks.backupDelay,
            emergencyDelay: delay,
        };
    }
    if (role == RoleLevel.Backup) {
        return RoleTimelocks {
            primaryDelay: timelocks.primaryDelay,
            backupDelay: delay,
            emergencyDelay: timelocks.emergencyDelay,
        };
    }
    if (role == RoleLevel.Primary) {
        return RoleTimelocks {
            primaryDelay: delay,
            backupDelay: timelocks.backupDelay,
            emergencyDelay: timelocks.emergencyDelay,
        };
    }
    assert (false) throw MeraErrors.InvalidRole;
    return timelocks;
}

/// Mirrors `_requireCoreRoleNotFrozen` for Primary / Backup.
fun requireCoreNotFrozen(root: MeraWalletRootStorage, role: RoleLevel) {
    if (role == RoleLevel.Primary) {
        assert (!root.frozenPrimary) throw MeraErrors.RoleFrozen;
    } else if (role == RoleLevel.Backup) {
        assert (!root.frozenBackup) throw MeraErrors.RoleFrozen;
    }
}

/// Enforces [1, MAX_CALLS_PER_BATCH] for `ExecuteTransaction` / `ProposeTransaction` / proposal payloads.
fun assertCallCountForBatch(callCount: uint32): void {
    assert (callCount >= 1) throw MeraErrors.InvalidMessage;
    assert (callCount <= MAX_CALLS_PER_BATCH) throw MeraErrors.BatchTooLarge;
}

/// Every outgoing call in a batch must carry at least `MIN_CALL_VALUE`.
fun assertCallValuesMin(calls: CallList): void {
    var i = 0;
    repeat (calls.size()) {
        val call = Call.fromCell(calls.get(i));
        assert (call.value >= MIN_CALL_VALUE) throw MeraErrors.CallValueTooSmall;
        i += 1;
    }
}

/// Mirrors `_setLifeController`. Returns updated `rest` (structs are passed by value in Tolk).
fun setLifeController(
    rest: WalletRestStorage,
    controller: address,
    enabled: bool,
): WalletRestStorage {
    var lc = rest.lifeControl.load();
    val lookup = lc.controllers.get(controller);
    val currentEnabled = lookup.isFound && lookup.loadValue() != 0;
    if (currentEnabled == enabled) {
        return rest;
    }
    if (enabled) {
        lc.controllers.set(controller, 1 as uint8);
    } else {
        lc.controllers.delete(controller);
    }
    rest.lifeControl = lc.toCell();
    return rest;
}

fun parseCoreRole(roleBits: uint2): RoleLevel {
    if (roleBits == 1) {
        return RoleLevel.Primary;
    }
    if (roleBits == 2) {
        return RoleLevel.Backup;
    }
    if (roleBits == 3) {
        return RoleLevel.Emergency;
    }
    throw MeraErrors.InvalidRole;
}

/// At execute time, `creator` must still hold the core role recorded at propose.
fun assertCreatorRoleMatchesAddress(
    creator: address,
    storedCreatorRole: uint2,
    root: MeraWalletRootStorage,
) {
    val currentRole = coreRole(creator, root);
    assert (currentRole == parseCoreRole(storedCreatorRole)) throw MeraErrors.CreatorRoleMismatch;
}

/// `_coreRole(account)`: fixed primary / backup / emergency addresses only.
fun coreRole(account: address, root: MeraWalletRootStorage): RoleLevel {
    if (account == root.emergency) {
        return RoleLevel.Emergency;
    }
    if (account == root.backup) {
        return RoleLevel.Backup;
    }
    if (account == root.primary) {
        return RoleLevel.Primary;
    }
    return RoleLevel.None;
}

/// `_effectiveCoreRole` for freeze paths: external sender → `coreRole`; self-call → `contextRole` (must be non-`None`).
fun effectiveCoreForFreeze(
    senderAddress: address,
    root: MeraWalletRootStorage,
    contextRole: RoleLevel,
): RoleLevel {
    if (senderAddress == contract.getAddress()) {
        assert (contextRole != RoleLevel.None) throw MeraErrors.UnauthorizedRole;
        return contextRole;
    }
    return coreRole(senderAddress, root);
}

/// `_agentRole` for freeze checks; reverts when emergency agent is past lifetime.
fun agentRoleForFreeze(sender: address, root: MeraWalletRootStorage): RoleLevel {
    val rest = root.rest.load();
    val agentsState = rest.agents.load();
    val lookup = agentsState.agents.get(sender);
    if (!lookup.isFound) {
        return RoleLevel.None;
    }
    val agentRow = lookup.loadValue();
    val role = parseCoreRole(agentRow.roleLevel);
    if (role == RoleLevel.Emergency && agentRow.activeFrom != 0) {
        val now = blockchain.now();
        val expiresAt = agentRow.activeFrom + root.emergencyAgentLifetime;
        assert (now <= expiresAt) throw MeraErrors.AgentExpired;
    }
    return role;
}

/// Solidity `_isRankedRoleActionAllowed`.
/// `isBlockingAction=true` covers veto/freeze; `false` covers clear/unfreeze.
fun isRankedRoleActionAllowed(
    senderAddress: address,
    root: MeraWalletRootStorage,
    targetRole: RoleLevel,
    isBlockingAction: bool,
    contextRole: RoleLevel,
): bool {
    val callerCore = effectiveCoreForFreeze(senderAddress, root, contextRole);
    if (callerCore != RoleLevel.None) {
        requireControllerCoreAvailable(root, callerCore);
        if (isBlockingAction) {
            if (callerCore == RoleLevel.Emergency && targetRole == RoleLevel.Emergency) {
                return false;
            }
            return roleRank(callerCore) >= roleRank(targetRole);
        }
        return roleRank(callerCore) > roleRank(targetRole);
    }

    val agentRole = agentRoleForFreeze(senderAddress, root);
    if (agentRole != RoleLevel.None) {
        return isBlockingAction && roleRank(agentRole) >= roleRank(targetRole);
    }

    return false;
}

/// `_setFrozenRole` authorization (`_isRankedRoleActionAllowed` + guardian freeze-only).
fun assertFreezeAuthorized(
    senderAddress: address,
    root: MeraWalletRootStorage,
    targetRole: RoleLevel,
    frozen: bool,
    contextRole: RoleLevel,
) {
    assert (
        targetRole == RoleLevel.Primary || targetRole == RoleLevel.Backup
    ) throw MeraErrors.InvalidRole;

    val rest = root.rest.load();
    if (rest.guardian != ADDRESS_ZERO && senderAddress == rest.guardian && frozen) {
        return;
    }

    assert (
        isRankedRoleActionAllowed(senderAddress, root, targetRole, frozen, contextRole)
    ) throw MeraErrors.FreezeActionNotAuthorized;
}

/// `_startEmergencyAgentLifetimeIfNeeded`
fun startEmergencyAgentLifetimeIfNeeded(
    senderAddress: address,
    rest: WalletRestStorage,
): WalletRestStorage {
    var agentsState = rest.agents.load();
    val lookup = agentsState.agents.get(senderAddress);
    if (!lookup.isFound) {
        return rest;
    }
    val agentRow = lookup.loadValue();
    if (parseCoreRole(agentRow.roleLevel) != RoleLevel.Emergency || agentRow.activeFrom != 0) {
        return rest;
    }
    agentsState
        .agents
        .set(
            senderAddress,
            Agent {
                roleLevel: agentRow.roleLevel,
                activeFrom: blockchain.now(),
            },
        );
    rest.agents = agentsState.toCell();
    return rest;
}

/// `enterSafeMode`: emergency core, guardian, or emergency-level agent.
fun assertEnterSafeModeAuthorized(sender: address, root: MeraWalletRootStorage) {
    if (sender == root.emergency) {
        return;
    }
    val rest = root.rest.load();
    if (rest.guardian != ADDRESS_ZERO && sender == rest.guardian) {
        return;
    }
    val agentRole = agentRoleForFreeze(sender, root);
    assert (agentRole == RoleLevel.Emergency) throw MeraErrors.SafeModeNotAuthorized;
}
