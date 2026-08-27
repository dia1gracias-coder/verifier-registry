// Generated from the verified Tact contract ABI.
contract PaymentSplitter {
    storage: PaymentSplitterData
    incomingMessages: PaymentSplitterIncomingMessage
    thrownErrors: PaymentSplitterErrors
}

struct (0x946a98b6) PaymentSplitterDeploy {
    queryId: uint64
}

struct (0xc78a87f7) PaymentSplitterPayMessage {
    seller: address
    groupOwner: address
    orderId: string
    billAmount: int257
}

struct (0x06b8be79) PaymentSplitterChangePlatformAddress {
    newAddress: address
}

struct (0x135f6a4d) PaymentSplitterSetActive {
    active: bool
}

struct PaymentSplitterData {
    tactDeploymentCompleted: bool
    owner: address
    platformFeeAddress: address
    isActive: bool
    platformFeeNumerator: int257
    tactContinuation: Cell<PaymentSplitterDataContinuation>
}

struct PaymentSplitterDataContinuation {
    groupOwnerFeeNumerator: int257
    feeDenominator: int257
}

type PaymentSplitterIncomingMessage =
    | PaymentSplitterPayMessage
    | PaymentSplitterChangePlatformAddress
    | PaymentSplitterSetActive
    | PaymentSplitterDeploy

enum PaymentSplitterErrors {
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
    /// Invalid bill amount
    InvalidBillAmount = 45166
    /// Contract is temporarily disabled, please try again later
    ContractIsTemporarilyDisabledPleaseTryAgainLater = 48354
    /// Insufficient payment for bill and gas
    InsufficientPaymentForBillAndGas = 50115
}

get fun isActive(): bool {
    throw 0;
}

get fun platformFeeAddress(): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
