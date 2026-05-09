// Generated from the verified Tact contract ABI.
contract Escrow0 {
    storage: Escrow0Data
    incomingMessages: Escrow0IncomingMessage
    thrownErrors: Escrow0Errors
}

struct (0x946a98b6) Escrow0Deploy {
    queryId: uint64
}

struct Escrow0EscrowData {
    buyer: address
    seller: address
    tokenType: uint8
    jettonWallet: address?
    tactContinuation: Cell<Escrow0EscrowDataContinuation>
}

struct Escrow0EscrowDataContinuation {
    jettonMaster: address?
    amount: coins
    fundedAmount: coins
    feeAmount: coins
    sellerAmount: coins
    createdAt: uint64
    fundedAt: uint64
    deadline: uint64
    adminApprovedAt: uint64
    tactContinuation: Cell<Escrow0EscrowDataContinuation2>
}

struct Escrow0EscrowDataContinuation2 {
    status: uint8
    adminApprovedRelease: bool
    buyerApprovedRelease: bool
    externalReference: string
}

struct (0xf993a660) Escrow0CreateEscrow {
    seller: address
    amount: coins
    deadline: uint64
    externalReference: string
}

struct (0xbe75124d) Escrow0CreateJettonEscrow {
    seller: address
    amount: coins
    deadline: uint64
    jettonWallet: address
    jettonMaster: address
    externalReference: string
}

struct (0xbc2de171) Escrow0FundEscrow {
    escrowId: uint64
}

struct (0x7f14db63) Escrow0ApproveReleaseByAdmin {
    escrowId: uint64
}

struct (0x3bf0cfaa) Escrow0ApproveReleaseByBuyer {
    escrowId: uint64
}

struct (0xf44aa630) Escrow0ClaimToAdminAfterTimeout {
    escrowId: uint64
}

struct (0x1f8ed482) Escrow0RefundBuyer {
    escrowId: uint64
    amount: coins
}

struct (0x4303be36) Escrow0ResolveDisputeSplit {
    escrowId: uint64
    buyerAmount: coins
    sellerAmount: coins
    feeAmount: coins
}

struct (0x123173f8) Escrow0CancelUnfunded {
    escrowId: uint64
}

struct (0xb1f2c2f9) Escrow0SetFeeRecipient {
    newFeeRecipient: address
}

struct (0x7362d09c) Escrow0JettonTransferNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct Escrow0Data {
    tactDeploymentCompleted: bool
    owner: address
    feeRecipient: address
    nextEscrowId: uint64
    escrows: map<int257, Cell<Escrow0EscrowData>>
}

type Escrow0IncomingMessage =
    | Escrow0CreateEscrow
    | Escrow0CreateJettonEscrow
    | Escrow0FundEscrow
    | Escrow0JettonTransferNotification
    | Escrow0ApproveReleaseByAdmin
    | Escrow0ApproveReleaseByBuyer
    | Escrow0ClaimToAdminAfterTimeout
    | Escrow0RefundBuyer
    | Escrow0ResolveDisputeSplit
    | Escrow0CancelUnfunded
    | Escrow0SetFeeRecipient
    | Escrow0Deploy

enum Escrow0Errors {
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
    /// Already approved by admin
    AlreadyApprovedByAdmin = 2543
    /// Amount must be > 0
    AmountMustBe0 = 6243
    /// Already approved by buyer
    AlreadyApprovedByBuyer = 8797
    /// Insufficient Jetton amount
    InsufficientJettonAmount = 12407
    /// Only buyer
    OnlyBuyer = 15821
    /// Invalid amount
    InvalidAmount = 17062
    /// No admin approval yet
    NoAdminApprovalYet = 20122
    /// Escrow not found
    EscrowNotFound = 22704
    /// Invalid status
    InvalidStatus = 27002
    /// Buyer cannot be seller
    BuyerCannotBeSeller = 33776
    /// Use Jetton transfer for token escrows
    UseJettonTransferForTokenEscrows = 38371
    /// Timeout not reached
    TimeoutNotReached = 40083
    /// Only buyer can fund
    OnlyBuyerCanFund = 45819
    /// Buyer already approved
    BuyerAlreadyApproved = 48243
    /// Insufficient TON sent
    InsufficientTONSent = 48341
    /// Not a Jetton escrow
    NotAJettonEscrow = 48671
    /// Invalid Jetton wallet
    InvalidJettonWallet = 50546
    /// Admin must approve first
    AdminMustApproveFirst = 53828
    /// Invalid split
    InvalidSplit = 59339
}

get fun getEscrow(escrowId: int257): Escrow0EscrowData? {
    throw 0;
}

get fun nextId(): int257 {
    throw 0;
}

get fun getFeeRecipient(): address {
    throw 0;
}

get fun contractBalance(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
