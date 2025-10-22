// Generated from the verified Tact contract ABI.
contract Registry {
    storage: RegistryData
    incomingMessages: RegistryIncomingMessage
    thrownErrors: RegistryErrors
}

struct (0x946a98b6) RegistryDeploy {
    queryId: uint64
}

struct RegistryArray {
    array: map<uint8, uint64>
    length: uint8
}

struct RegistryRoyaltyCollector {
    collectorAddress: address
    royaltyFee: int16
}

struct RegistryRoyaltyCollectorArray {
    royaltyCollectors: map<uint8, Cell<RegistryRoyaltyCollector>>
    length: uint8
}

struct (0x52ff86dd) RegistryCreateEvent {
    eventName: string
    eventUri: string
    tactContinuation: Cell<RegistryCreateEventContinuation>
}

struct RegistryCreateEventContinuation {
    ticketAmounts: RegistryArray
    ticketPrices: RegistryArray
    endTimestamp: uint64
    sellRoyaltyCollectors: RegistryRoyaltyCollectorArray
    resellRoyaltyCollectors: RegistryRoyaltyCollectorArray
}

struct RegistryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    nextEventId: uint32
}

type RegistryIncomingMessage =
    | RegistryCreateEvent
    | RegistryDeploy

enum RegistryErrors {
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
    /// No items in the array!
    NoItemsInTheArray = 6947
    /// Underflow
    Underflow = 9946
    /// Index of the item cannot be negative!
    IndexOfTheItemCannotBeNegative = 19333
    /// Index is out of array bounds!
    IndexIsOutOfArrayBounds = 24006
}

get fun priceForEventStorage(amountOfSeconds: int257): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
