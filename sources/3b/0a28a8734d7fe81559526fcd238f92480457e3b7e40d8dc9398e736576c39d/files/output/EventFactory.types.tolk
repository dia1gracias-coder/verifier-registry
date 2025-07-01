// Generated from the verified Tact contract ABI.
contract EventFactory {
    storage: EventFactoryData
    incomingMessages: EventFactoryCreateEvent
    thrownErrors: EventFactoryErrors
}

struct EventFactoryEventsResponse {
    nextId: int257
    eventsCount: int257
}

struct (0x25eddb6a) EventFactoryCreateEvent {
    deadline: int257
    description: string
}

struct EventFactoryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    admin: address
    feeReceiver: address
    feeAmount: int257
    events: map<int257, address>
    tactContinuation: Cell<EventFactoryDataContinuation>
}

struct EventFactoryDataContinuation {
    nextId: int257
}

enum EventFactoryErrors {
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
    /// Wrong side
    WrongSide = 3685
    /// Betting closed
    BettingClosed = 10687
    /// Only admin
    OnlyAdmin = 16461
    /// Only mainAdmin can resolve
    OnlyMainAdminCanResolve = 19484
    /// Cannot bet both Yes and No
    CannotBetBothYesAndNo = 20895
    /// Already resolved
    AlreadyResolved = 31038
    /// Min value = fee + deploy amount
    MinValueFeeDeployAmount = 33745
    /// Only owner
    OnlyOwner = 35499
    /// No bet
    NoBet = 45156
    /// Factory already deployed
    FactoryAlreadyDeployed = 45408
    /// Not resolved
    NotResolved = 58169
    /// Amount must be positive
    AmountMustBePositive = 61135
}

get fun get_events(): EventFactoryEventsResponse {
    throw 0;
}

get fun get_event_address(id: int257): address? {
    throw 0;
}
