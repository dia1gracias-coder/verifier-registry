// Generated from the verified Tact contract ABI.
contract DeDustSwapContract {
    storage: DeDustSwapContractData
    incomingMessages: DeDustSwapContractIncomingMessage
    thrownErrors: DeDustSwapContractErrors
}

struct (0x946a98b6) DeDustSwapContractDeploy {
    queryId: uint64
}

struct (0x819dbe99) DeDustSwapContractChangeOwner {
    queryId: uint64
    newOwner: address
}

struct DeDustSwapContractData {
    tactDeploymentCompleted: bool
    owner: address
    totalDeposited: coins
    lastConversionTime: uint64
    conversionInterval: uint64
}

type DeDustSwapContractIncomingMessage =
    | DeDustSwapContractDeploy
    | DeDustSwapContractChangeOwner

enum DeDustSwapContractErrors {
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
    /// Insufficient balance for swap after fees
    InsufficientBalanceForSwapAfterFees = 22935
    /// Only owner
    OnlyOwner = 35499
    /// Too early for next conversion
    TooEarlyForNextConversion = 58683
}

get fun getTotalDeposited(): int257 {
    throw 0;
}

get fun getLastConversionTime(): int257 {
    throw 0;
}

get fun contractBalance(): int257 {
    throw 0;
}

get fun getOwner(): address {
    throw 0;
}

get fun dedustTonVault(): address {
    throw 0;
}

get fun dedustPool(): address {
    throw 0;
}

get fun getNextConversionTime(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
