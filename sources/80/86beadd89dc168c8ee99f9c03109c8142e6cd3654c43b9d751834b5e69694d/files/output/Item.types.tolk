// Generated from the verified Tact contract ABI.
contract Item {
    storage: ItemData
    incomingMessages: ItemIncomingMessage
    thrownErrors: ItemErrors
}

struct (0x5fcc3d14) ItemTransfer {
    queryId: uint64
    newOwner: address
    responseDestination: address?
    customPayload: cell?
    forwardAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x2fcb26a2) ItemGetStaticData {
    queryId: uint64
}

struct ItemNftData {
    init: int257
    index: uint64
    collectionAddress: address
    owner: address?
    individualContent: cell?
}

struct ItemCollectorData {
    collectorPoints: uint16
    rarity: string?
}

struct ItemData {
    tactDeploymentCompleted: bool
    nftCollectionAddress: address
    nftItemIndex: uint64
    isInitialized: bool
    owner: address?
    individualContent: cell?
    collectorData: ItemCollectorData?
}

type ItemIncomingMessage =
    | ItemTransfer
    | ItemGetStaticData

enum ItemErrors {
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
    /// Query already processed
    QueryAlreadyProcessed = 3280
    /// Only owner can change payment key
    OnlyOwnerCanChangePaymentKey = 17765
    /// Invalid bit number
    InvalidBitNumber = 26710
    /// initialized tx need from collection
    InitializedTxNeedFromCollection = 27499
    /// Only owner can change ownership
    OnlyOwnerCanChangeOwnership = 38113
    /// Invalid shift value
    InvalidShiftValue = 39737
    /// Token index must be greater than 0
    TokenIndexMustBeGreaterThan0 = 48099
    /// Invalid signature
    InvalidSignature = 48401
    /// not owner
    NotOwner = 49280
    /// Timeout too short
    TimeoutTooShort = 52384
    /// Token index already minted
    TokenIndexAlreadyMinted = 56526
}

get fun get_nft_data(): ItemNftData {
    throw 0;
}

get fun get_collector_data(): ItemCollectorData? {
    throw 0;
}
