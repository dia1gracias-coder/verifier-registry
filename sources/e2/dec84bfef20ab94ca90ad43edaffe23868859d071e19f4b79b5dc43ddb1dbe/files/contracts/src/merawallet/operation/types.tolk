/// Call batch types and operation addressing helpers.

import "storage"

/// Single outgoing call from the wallet (`value` in nanotons).
struct Call {
    target: address
    value: coins
    body: cell
}

/// Serialized batch of opaque call cells. The batch size is derived on-chain from the array length.
type CallList = array<Cell<Call>>

fun computeOperationId(walletAddr: address, callsCell: cell, salt: uint256): uint256 {
    val (workchain, accountId) = walletAddr.getWorkchainAndHash();
    return beginCell()
        .storeInt(workchain, 8)
        .storeUint(accountId, 256)
        .storeRef(callsCell)
        .storeUint(salt, 256)
        .endCell()
        .hash();
}

/// Mirrors the jetton child-contract pattern: address = hash(code + initial data).
fun calcDeployedOperationStorage(
    walletAddr: address,
    operationId: uint256,
    operationStorageCode: cell,
): AutoDeployAddress {
    return AutoDeployAddress {
        stateInit: ContractState {
            code: operationStorageCode,
            data: operationStorageInitialState(walletAddr, operationId).toCell(),
        },
    };
}
