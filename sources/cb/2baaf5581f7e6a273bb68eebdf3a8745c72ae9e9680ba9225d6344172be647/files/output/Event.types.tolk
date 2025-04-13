// Generated from the verified Tact contract ABI.
contract Event {
    storage: EventData
    incomingMessages: EventIncomingMessage
    thrownErrors: EventErrors
}

struct EventStateInit {
    code: cell
    data: cell
}

struct EventCollectionData {
    next_item_index: int257
    collection_content: cell
    owner_address: address
}

struct EventRoyaltyParams {
    numerator: int257
    denominator: int257
    destination: address
}

struct (0x1e247889) EventEntranceGuard {
    guardAddress: address
}

struct (0x54d705a8) EventTicketDataForPunch {
    visitor: address
    index: int257
}

struct (0x946a98b6) EventDeploy {
    queryId: uint64
}

struct EventData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    next_item_index: uint32
    owner_address: address
    tactContinuation: Cell<EventDataContinuation>
}

struct EventDataContinuation {
    royalty_params: EventRoyaltyParams?
    collection_content: cell
    ticketContent: cell
    tactContinuation: Cell<EventDataContinuation2>
}

struct EventDataContinuation2 {
    ticketCost: int257
    guardAddress: address
    tickets_amount: int257
}

type EventIncomingMessage =
    | EventTicketDataForPunch
    | EventEntranceGuard
    | EventDeploy

enum EventErrors {
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
    /// Only guard can punch
    OnlyGuardCanPunch = 23275
    /// initialized tx need from collection
    InitializedTxNeedFromCollection = 27499
    /// Only host are allowed to change guard
    OnlyHostAreAllowedToChangeGuard = 28284
    /// Only Guard is allowed
    OnlyGuardIsAllowed = 29280
    /// Sold out
    SoldOut = 30667
    /// not owner
    NotOwner = 49280
    /// not from collection
    NotFromCollection = 49469
    /// Insufficient funds
    InsufficientFunds = 51754
    /// non-sequential NFTs
    NonSequentialNFTs = 62742
}

get fun get_collection_data(): EventCollectionData {
    throw 0;
}

get fun get_tickets_amount(): int257 {
    throw 0;
}

get fun get_nft_address_by_index(item_index: int257): address? {
    throw 0;
}

get fun getNftItemInit(item_index: int257): EventStateInit {
    throw 0;
}

get fun get_nft_content(index: int257, individual_content: cell): cell {
    throw 0;
}
