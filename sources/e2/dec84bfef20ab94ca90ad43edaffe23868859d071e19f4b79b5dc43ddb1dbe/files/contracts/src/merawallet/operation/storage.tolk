/// Persistent state of the per-proposal Operation shard. Spec §4.2 (`ProposalStorage`).

import "../consts"
import "../types"

/// Call batch + salt; stored in a ref to keep `OperationStorageState` under the 1023-bit limit.
struct OperationProposalPayload {
    callsCell: cell
    salt: uint256
}

/// Relay execution metadata (Solidity `MERAWalletTypes.RelayOperation`).
struct RelayOperation {
    relayPolicy: RelayExecutorPolicy
    relayReward: coins
    designatedExecutor: address
    executorSetHash: uint256
    relayExecuteBefore: uint32
}

struct OperationStorageState {
    walletAddr: address
    operationId: uint256
    status: ProposalStatus
    creator: address
    creatorRole: uint2
    epoch: uint32
    createdAt: uint32
    executeAfter: uint32
    /// Batch persisted at `ProposalInit`; used on execute without resending calls.
    proposal: Cell<OperationProposalPayload>
    /// Filled on relay propose; zeroed/default on non-relay path until wired in `ProposalInit`.
    relay: Cell<RelayOperation>
}

fun OperationStorageState.load(): OperationStorageState {
    return OperationStorageState.fromCell(contract.getData());
}

fun OperationStorageState.save(self) {
    contract.setData(self.toCell());
}

fun defaultOperationProposalPayload(): OperationProposalPayload {
    return OperationProposalPayload {
        callsCell: beginCell().endCell(),
        salt: 0,
    };
}

fun defaultRelayOperation(): RelayOperation {
    return RelayOperation {
        relayPolicy: RelayExecutorPolicy.CoreExecute,
        relayReward: 0 as coins,
        designatedExecutor: ADDRESS_ZERO,
        executorSetHash: 0,
        relayExecuteBefore: 0,
    };
}

/// Initial data used in StateInit; mutable proposal payload is set by `ProposalInit`.
fun operationStorageInitialState(
    walletAddr: address,
    operationId: uint256,
): OperationStorageState {
    return OperationStorageState {
        walletAddr,
        operationId,
        status: ProposalStatus.None,
        creator: ADDRESS_ZERO,
        creatorRole: 0,
        epoch: 0,
        createdAt: 0,
        executeAfter: 0,
        proposal: defaultOperationProposalPayload().toCell(),
        relay: defaultRelayOperation().toCell(),
    };
}
