/// Internal messages between `MeraWallet` and `OperationStorage` (proposal shard). Spec §6.3.

struct (0xA10001) ProposalInit {
    operationId: uint256
    epoch: uint32
    creator: address
    creatorRole: uint2
    createdAt: uint32
    executeAfter: uint32
    callsCell: cell
    salt: uint256
}

struct (0xA10002) ProposalVeto {
    senderAddr: address
    senderRole: uint2
}

struct (0xA10003) ProposalClearVeto {
    senderAddr: address
    senderRole: uint2
}

struct (0xA10004) ProposalCancel {
    senderAddr: address
    senderRole: uint2
}

struct (0xA10005) ProposalExecuteRequest {}

struct (0xA10006) ProposalVetoPrepare {
    vetoer: address
}

struct (0xA10010) ProposalExecutePayload {
    operationId: uint256
    epoch: uint32
    creator: address
    creatorRole: uint2
    executeAfter: uint32
    callsCell: cell
}

struct (0xA10011) ProposalAck {
    proposalId: uint64
    op: uint8
    ok: bool
}

struct (0xA10012) ProposalCancelAck {
    operationId: uint256
    epoch: uint32
    cancelledBy: address
}

struct (0xA10013) ProposalVetoPrepared {
    operationId: uint256
    creatorRole: uint2
    epoch: uint32
    vetoer: address
}

struct (0xA10014) ProposalVetoAck {
    operationId: uint256
    epoch: uint32
    vetoedBy: address
}

struct (0xA10015) ProposalClearVetoAck {
    operationId: uint256
    epoch: uint32
    clearedBy: address
}

/// External log emitted by `MeraWallet` after a proposal storage shard is deployed.
struct (0xE10001) ProposalRegistered {
    operationId: uint256
    epoch: uint32
    storageAddr: address
    details: Cell<ProposalRegisteredDetails>
}

struct ProposalRegisteredDetails {
    creator: address
    creatorRole: uint2
    createdAt: uint32
    executeAfter: uint32
    callCount: uint8
}

struct (0xE10002) PendingTransactionCancelled {
    operationId: uint256
    cancelledBy: address
}

struct (0xE10003) PendingTransactionVetoed {
    operationId: uint256
    vetoedBy: address
}

struct (0xE10004) PendingTransactionVetoCleared {
    operationId: uint256
    clearedBy: address
}

/// Only messages the wallet sends **to** OperationStorage.
type OperationStorageIncoming =
    | ProposalInit
    | ProposalVetoPrepare
    | ProposalVeto
    | ProposalClearVeto
    | ProposalCancel
    | ProposalExecuteRequest
