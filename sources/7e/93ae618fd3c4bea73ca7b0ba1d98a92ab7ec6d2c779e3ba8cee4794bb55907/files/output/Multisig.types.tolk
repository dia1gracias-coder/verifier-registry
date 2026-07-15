// Generated from the verified Tact contract ABI.
contract Multisig {
    storage: MultisigData
    incomingMessages: MultisigIncomingMessage
    thrownErrors: MultisigErrors
}

struct (0x946a98b6) MultisigDeploy {
    queryId: uint64
}

struct MultisigMsOrder {
    target: address
    value: coins
    body: cell
    submitter: address
    required: uint8
    mask: uint32
    approvals: uint8
    executed: bool
    rejected: bool
    expiresAt: uint64
    epoch: uint32
}

struct (0xd77c685a) MultisigMsSubmit {
    target: address
    value: coins
    body: cell
    required: int257
    expiresAt: uint64
}

struct (0xa72487b5) MultisigMsApprove {
    orderId: uint32
}

struct (0x73d2dd4d) MultisigMsReject {
    orderId: uint32
}

struct (0xa87f8e26) MultisigMsGovern {
    signers: map<int257, address>
    signersCount: int257
    minApprovals: int257
    proposer: address
}

struct MultisigMsInfo {
    minApprovals: int257
    signersCount: int257
    orderSeq: int257
    tactContinuation: Cell<MultisigMsInfoContinuation>
}

struct MultisigMsInfoContinuation {
    proposer: address
}

struct MultisigOrderView {
    exists: bool
    target: address
    value: coins
    submitter: address
    required: int257
    tactContinuation: Cell<MultisigOrderViewContinuation>
}

struct MultisigOrderViewContinuation {
    approvals: int257
    mask: int257
    executed: bool
    rejected: bool
    expiresAt: uint64
}

struct MultisigData {
    tactDeploymentCompleted: bool
    minApprovals: uint8
    signersCount: uint8
    proposer: address
    signers: map<int257, address>
    orderSeq: uint32
    orders: map<int257, Cell<MultisigMsOrder>>
    epoch: uint32
}

type MultisigIncomingMessage =
    | MultisigMsSubmit
    | MultisigMsApprove
    | MultisigMsReject
    | MultisigMsGovern
    | MultisigDeploy

enum MultisigErrors {
    /// Stack underflow
    StackUnderflow = 2
    /// Stack overflow
    StackOverflow = 3
    /// Integer overflow
    IntegerOverflow = 4
    /// Integer out of expected range
    IntegerOutOfExpectedRange = 5
    /// Invalid opcode
    InvalidOpcode = 6
    /// Type check error
    TypeCheckError = 7
    /// Cell overflow
    CellOverflow = 8
    /// Cell underflow
    CellUnderflow = 9
    /// Dictionary error
    DictionaryError = 10
    /// 'Unknown' error
    UnknownError = 11
    /// Fatal error
    FatalError = 12
    /// Out of gas error
    OutOfGasError = 13
    /// Virtualization error
    VirtualizationError = 14
    /// Action list is invalid
    ActionListIsInvalid = 32
    /// Action list is too long
    ActionListIsTooLong = 33
    /// Action is invalid or not supported
    ActionIsInvalidOrNotSupported = 34
    /// Invalid source address in outbound message
    InvalidSourceAddressInOutboundMessage = 35
    /// Invalid destination address in outbound message
    InvalidDestinationAddressInOutboundMessage = 36
    /// Not enough Toncoin
    NotEnoughToncoin = 37
    /// Not enough extra currencies
    NotEnoughExtraCurrencies = 38
    /// Outbound message does not fit into a cell after rewriting
    OutboundMessageDoesNotFitIntoACellAfterRewriting = 39
    /// Cannot process a message
    CannotProcessAMessage = 40
    /// Library reference is null
    LibraryReferenceIsNull = 41
    /// Library change action error
    LibraryChangeActionError = 42
    /// Exceeded maximum number of cells in the library or the maximum depth of the Merkle tree
    ExceededMaximumNumberOfCellsInTheLibraryOrTheMaximumDepthOfTheMerkleTree = 43
    /// Account state size exceeded limits
    AccountStateSizeExceededLimits = 50
    /// Null reference exception
    NullReferenceException = 128
    /// Invalid serialization prefix
    InvalidSerializationPrefix = 129
    /// Invalid incoming message
    InvalidIncomingMessage = 130
    /// Constraints error
    ConstraintsError = 131
    /// Access denied
    AccessDenied = 132
    /// Contract stopped
    ContractStopped = 133
    /// Invalid argument
    InvalidArgument = 134
    /// Code of a contract was not found
    CodeOfAContractWasNotFound = 135
    /// Invalid standard address
    InvalidStandardAddress = 136
    /// Not a basechain address
    NotABasechainAddress = 138
    /// bad signersCount
    BadSignersCount = 30287
    /// duplicate signer
    DuplicateSigner = 43321
    /// bad minApprovals
    BadMinApprovals = 43688
    /// missing signer
    MissingSigner = 51529
}

get fun msInfo(): MultisigMsInfo {
    throw 0;
}

get fun order(id: int257): MultisigMsOrder? {
    throw 0;
}

get fun orderView(id: int257): MultisigOrderView {
    throw 0;
}

get fun signer(i: int257): address? {
    throw 0;
}

get fun isSigner(a: address): bool {
    throw 0;
}
