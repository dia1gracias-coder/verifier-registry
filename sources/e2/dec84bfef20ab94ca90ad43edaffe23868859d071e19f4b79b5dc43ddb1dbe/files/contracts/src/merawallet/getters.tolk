/// Read helpers for `MeraWallet` get-methods. Uses `lazy MeraWalletRootStorage.load()` per
/// https://docs.ton.org/tolk/features/lazy-loading
///
/// Acton requires `get fun` to live in `MeraWallet.tolk`; this file holds the real read logic.

import "guards"
import "storage"
import "types"
import "types"
import "operation/types"

/// Returns stored per-target policy; default zeros if the key is absent.
fun getTargetCallPolicy(target: address): CallPathPolicy {
    val storage = lazy MeraWalletRootStorage.load();
    val policies = lazy storage.policies.load();
    val lookup = policies.callByTarget.get(target);
    if (lookup.isFound) {
        return lookup.loadValue();
    }
    return meraWalletDefaultCallPathPolicy();
}

/// Returns stored per-selector policy; default zeros if the key is absent.
fun getSelectorCallPolicy(selector: uint32): CallPathPolicy {
    val storage = lazy MeraWalletRootStorage.load();
    val policies = lazy storage.policies.load();
    val lookup = policies.callBySelector.get(selector);
    if (lookup.isFound) {
        return lookup.loadValue();
    }
    return meraWalletDefaultCallPathPolicy();
}

/// Returns stored per-(target, selector) policy; default zeros / `exists == false` if absent.
fun getTargetSelectorCallPolicy(target: address, selector: uint32): CallPathPolicy {
    val storage = lazy MeraWalletRootStorage.load();
    val policies = lazy storage.policies.load();
    val key = targetSelectorPolicyKey(target, selector);
    val lookup = policies.callByTargetSelector.get(key);
    if (lookup.isFound) {
        return lookup.loadValue();
    }
    return meraWalletDefaultCallPathPolicy();
}

fun meraWalletDefaultCallPathPolicy(): CallPathPolicy {
    return CallPathPolicy {
        flags: 0,
        primaryDelay: 0,
        backupDelay: 0,
        emergencyDelay: 0,
        exists: false,
    };
}

fun getPrimary(): address {
    val storage = lazy MeraWalletRootStorage.load();

    return storage.primary;
}

fun getBackup(): address {
    val storage = lazy MeraWalletRootStorage.load();

    return storage.backup;
}

fun getEmergency(): address {
    val storage = lazy MeraWalletRootStorage.load();

    return storage.emergency;
}

fun getFrozenPrimary(): bool {
    val storage = lazy MeraWalletRootStorage.load();

    return storage.frozenPrimary;
}

fun getFrozenBackup(): bool {
    val storage = lazy MeraWalletRootStorage.load();

    return storage.frozenBackup;
}

fun getEmergencyAgentLifetime(): uint32 {
    val storage = lazy MeraWalletRootStorage.load();

    return storage.emergencyAgentLifetime;
}

fun getGuardian(): address {
    val storage = lazy MeraWalletRootStorage.load();
    val rest = lazy storage.rest.load();

    return rest.guardian;
}

/// Timelock delay for `role` (seconds); `0` if the key is absent. Mirrors Solidity `roleTimelock(role)`.
fun getRoleTimelock(role: RoleLevel): uint256 {
    val storage = lazy MeraWalletRootStorage.load();
    val rest = lazy storage.rest.load();
    val timelocks = lazy rest.roleTimelocks.load();
    return getRoleTimelockFromState(timelocks, role);
}

fun getRoleTimelockDelay(role: RoleLevel): uint256 {
    return getRoleTimelock(role);
}

fun getIsLifeController(controller: address): bool {
    val storage = lazy MeraWalletRootStorage.load();
    val rest = lazy storage.rest.load();
    val lc = lazy rest.lifeControl.load();
    val lookup = lc.controllers.get(controller);
    return lookup.isFound && lookup.loadValue() != 0;
}

/// Stored agent `roleLevel` (`0` if not registered). See `agentActiveFrom`.
fun getAgentRoleLevel(agent: address): uint32 {
    val storage = lazy MeraWalletRootStorage.load();
    val rest = lazy storage.rest.load();
    val agentsState = lazy rest.agents.load();
    val lookup = agentsState.agents.get(agent);
    if (lookup.isFound) {
        val row = lookup.loadValue();
        return row.roleLevel as uint32;
    }
    return 0;
}

fun getAgentActiveFrom(agent: address): uint32 {
    val storage = lazy MeraWalletRootStorage.load();
    val rest = lazy storage.rest.load();
    val agentsState = lazy rest.agents.load();
    val lookup = agentsState.agents.get(agent);
    if (lookup.isFound) {
        val row = lookup.loadValue();
        return row.activeFrom;
    }
    return 0;
}

fun getProposalEpoch(): uint32 {
    val storage = lazy MeraWalletRootStorage.load();

    return storage.proposalEpoch;
}

fun getPendingTransactionsCount(): uint32 {
    val storage = lazy MeraWalletRootStorage.load();

    return storage.pendingTransactionsCount;
}

fun getOperationStorageAddress(operationId: uint256): address {
    val storage = lazy MeraWalletRootStorage.load();
    val rest = lazy storage.rest.load();
    return calcDeployedOperationStorage(
        contract.getAddress(),
        operationId,
        rest.operationStorageCode,
    ).calculateAddress();
}

fun getSafeModeBefore(): uint32 {
    val storage = lazy MeraWalletRootStorage.load();

    return storage.safeModeBefore;
}

fun getSafeModeUsed(): bool {
    val storage = lazy MeraWalletRootStorage.load();

    return storage.safeModeUsed;
}

fun getLifeControlEnabled(): bool {
    val storage = lazy MeraWalletRootStorage.load();
    val rest = lazy storage.rest.load();
    val life = lazy rest.lifeControl.load();

    return life.enabled;
}

fun getLifeControlTimeout(): uint32 {
    val storage = lazy MeraWalletRootStorage.load();
    val rest = lazy storage.rest.load();
    val life = lazy rest.lifeControl.load();

    return life.timeout;
}

fun getLifeControlLastAlive(): uint32 {
    val storage = lazy MeraWalletRootStorage.load();
    val rest = lazy storage.rest.load();
    val life = lazy rest.lifeControl.load();

    return life.lastAlive;
}
