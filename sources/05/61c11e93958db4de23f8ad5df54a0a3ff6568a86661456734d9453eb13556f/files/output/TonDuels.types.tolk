// Generated from the verified Tact contract ABI.
contract TonDuels {
    storage: TonDuelsData
    incomingMessages: TonDuelsIncomingMessage
    thrownErrors: TonDuelsErrors
}

struct (0x00123456) TonDuelsInit {
}

struct (0x4b860a4d) TonDuelsDeposit {
    userId: uint32
    paymentType: uint8
}

struct TonDuelsData {
    tactDeploymentCompleted: bool
    serverKey: uint256
    adminKey: uint256
    userNonces: map<address, uint64>
    adminNonce: uint64
    vanityAddressNonce: uint64
}

type TonDuelsIncomingMessage =
    | TonDuelsInit
    | TonDuelsDeposit

enum TonDuelsErrors {
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
    /// Invalid nonce
    InvalidNonce = 23767
    /// Invalid signature
    InvalidSignature = 48401
    /// Insufficient balance
    InsufficientBalance = 54615
}

get fun serverKey(): int257 {
    throw 0;
}

get fun adminKey(): int257 {
    throw 0;
}

get fun userNonce(addr: address): int257 {
    throw 0;
}

get fun adminNonce(): int257 {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}
