// Generated from the verified Tact contract ABI.
contract SecureTon {
    storage: SecureTonData
    incomingMessages: SecureTonIncomingMessage
    thrownErrors: SecureTonErrors
}

struct (0x946a98b6) SecureTonDeploy {
    queryId: uint64
}

struct SecureTonEvent {
    id: int257
    creator: address
    name: string
    date: int257
    tactContinuation: Cell<SecureTonEventContinuation>
}

struct SecureTonEventContinuation {
    ticketPrice: int257
    maxTickets: int257
    ticketsSold: int257
    isActive: bool
}

struct SecureTonTicket {
    id: int257
    eventId: int257
    owner: address
    tactContinuation: Cell<SecureTonTicketContinuation>
}

struct SecureTonTicketContinuation {
    purchaseDate: int257
    isUsed: bool
}

struct (0xac75e3cd) SecureTonCreateEvent {
    name: string
    date: int257
    ticketPrice: int257
    maxTickets: int257
}

struct (0xa22057a9) SecureTonBuyTicket {
    eventId: int257
}

struct (0xb64272f5) SecureTonUseTicket {
    ticketId: int257
}

struct (0x5fe85273) SecureTonDeactivateEvent {
    eventId: int257
}

struct SecureTonData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    events: map<int257, Cell<SecureTonEvent>>
    tickets: map<int257, Cell<SecureTonTicket>>
    nextEventId: int257
    nextTicketId: int257
}

type SecureTonIncomingMessage =
    | SecureTonCreateEvent
    | SecureTonBuyTicket
    | SecureTonUseTicket
    | SecureTonDeactivateEvent
    | SecureTonDeploy

enum SecureTonErrors {
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
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
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
    /// Invalid address
    InvalidAddress = 136
    /// Masterchain support is not enabled for this contract
    MasterchainSupportIsNotEnabledForThisContract = 137
    /// Only creator can deactivate
    OnlyCreatorCanDeactivate = 13052
    /// Event is sold out
    EventIsSoldOut = 19291
    /// Max tickets must be > 0
    MaxTicketsMustBe0 = 23199
    /// Ticket already used
    TicketAlreadyUsed = 30443
    /// Event is not active
    EventIsNotActive = 31395
    /// Event date must be in future
    EventDateMustBeInFuture = 41497
    /// Insufficient payment
    InsufficientPayment = 46647
    /// Ticket price must be >= 0
    TicketPriceMustBe0 = 57770
}

get fun event(eventId: int257): SecureTonEvent {
    throw 0;
}

get fun ticket(ticketId: int257): SecureTonTicket {
    throw 0;
}

get fun verifyTicket(ticketId: int257, userAddress: address): bool {
    throw 0;
}

get fun getActiveEvents(): map<int257, Cell<SecureTonEvent>> {
    throw 0;
}
