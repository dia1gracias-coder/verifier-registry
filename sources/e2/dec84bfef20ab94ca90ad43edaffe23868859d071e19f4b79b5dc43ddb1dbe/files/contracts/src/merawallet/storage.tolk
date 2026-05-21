/// Root persistent data for `MeraWallet`. Spec §5 + §4.4.
/// Nested into two `Cell` buckets so the root cell stays within the ≤4 refs limit.
/// Test / tooling helpers: `MeraWalletDeployHelper.tolk`.

import "types"

struct WalletRestStorage {
    guardian: address
    roleTimelocks: Cell<RoleTimelocks>
    agents: Cell<AgentsState>
    lifeControl: Cell<LifeControl>
    operationStorageCode: cell
}

struct MeraWalletRootStorage {
    primary: address
    backup: address
    emergency: address
    frozenPrimary: bool
    frozenBackup: bool
    emergencyAgentLifetime: uint32
    proposalEpoch: uint32
    pendingTransactionsCount: uint32
    safeModeBefore: uint32
    safeModeUsed: bool
    policies: Cell<Policies>
    rest: Cell<WalletRestStorage>
}

fun MeraWalletRootStorage.load(): MeraWalletRootStorage {
    return MeraWalletRootStorage.fromCell(contract.getData());
}

fun MeraWalletRootStorage.save(self) {
    contract.setData(self.toCell());
}
