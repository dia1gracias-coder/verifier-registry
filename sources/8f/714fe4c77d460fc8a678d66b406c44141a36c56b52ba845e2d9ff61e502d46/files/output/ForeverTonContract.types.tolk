// Generated from the verified Tact contract ABI.
contract ForeverTonContract {
    storage: ForeverTonContractData
    thrownErrors: ForeverTonContractErrors
}

struct ForeverTonContractArray {
    m: map<uint10, address>
    length: int257
}

struct ForeverTonContractPoolInfo {
    balance: coins
    timer: uint32
    lastSender: address
    winner: address
    currentVipNumber: uint8
    winnerPrize: coins
    isCounterReset: bool
}

struct ForeverTonContractData {
    tactDeploymentCompleted: bool
    counter: uint35
    owner: address
    vipAddress: ForeverTonContractArray
    vipNumber: uint8
    lastSender: address
    tactContinuation: Cell<ForeverTonContractDataContinuation>
}

struct ForeverTonContractDataContinuation {
    winner: address
    startTime: int257
    winnerPrize: coins
}

enum ForeverTonContractErrors {
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
    /// At least 1 TON is required
    AtLeast1TONIsRequired = 19783
}

get fun timer(): int257 {
    throw 0;
}

get fun vipAddress(): map<uint10, address> {
    throw 0;
}

get fun poolInfo(): ForeverTonContractPoolInfo {
    throw 0;
}
