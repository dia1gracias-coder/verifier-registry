// CouncilGate storage schema. Spec: docs/spec/council-gate.md.
// ChainProof itself is defined in title-item-types.tolk (the walk's terminating message;
// shared verbatim between TitleItem, the sender, and CouncilGate, one of its consumers).

import "shared"
import "title-item-types"

// The gate carries its own copy of the item code cell (captured at deploy time) so it can
// reconstruct `item(topOwner)` independently — it cannot call back into the Registry.
struct StaticGateCodes {
    itemCode: cell
}

struct GateStorage {
    registry: address
    codes: Cell<StaticGateCodes>
    quorum: uint8
    minRank: uint8
    expiry: uint32
    maxProofAge: uint32
    executed: bool
    approvalCount: uint8
    approvals: map<address, bool>
    actions: Cell<ActionNode>?
    treasury: address
    verificationFee: coins
    salt: uint64
}

fun GateStorage.load(): GateStorage {
    return GateStorage.fromCell(contract.getData());
}

fun GateStorage.save(self) {
    contract.setData(self.toCell());
}

type GateMessage = ChainProof
