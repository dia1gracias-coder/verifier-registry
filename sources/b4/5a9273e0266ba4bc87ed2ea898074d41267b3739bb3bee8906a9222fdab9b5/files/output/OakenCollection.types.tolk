// Generated from the verified Tact contract ABI.
contract OakenCollection {
    storage: OakenCollectionData
    incomingMessages: OakenCollectionIncomingMessage
    thrownErrors: OakenCollectionErrors
}

struct (0x946a98b6) OakenCollectionDeploy {
    queryId: uint64
}

struct (0x4f6d4a01) OakenCollectionMint {
    queryId: uint64
}

struct (0x4f6d4a02) OakenCollectionChangeOwner {
    newOwner: address
}

struct (0x4f6d4a04) OakenCollectionSetBaseUrl {
    url: string
}

struct (0x4f6d4a05) OakenCollectionSetMintStatus {
    paused: bool
}

struct (0x4f6d4a06) OakenCollectionWithdraw {
    amount: int257
}

struct OakenCollectionCollectionData {
    next_index: int257
    content: cell
    owner: address
}

struct OakenCollectionRoyaltyParams {
    numerator: int257
    denominator: int257
    destination: address
}

struct OakenCollectionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    next_index: uint256
    collection_content: cell
    item_base_url: string
    paused: bool
}

type OakenCollectionIncomingMessage =
    | OakenCollectionMint
    | OakenCollectionChangeOwner
    | OakenCollectionSetMintStatus
    | OakenCollectionWithdraw
    | OakenCollectionSetBaseUrl
    | OakenCollectionDeploy

enum OakenCollectionErrors {
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
    /// Already initialized
    AlreadyInitialized = 2977
    /// Invalid sender
    InvalidSender = 4429
    /// Not enough funds
    NotEnoughFunds = 8086
    /// Only owner
    OnlyOwner = 35499
    /// Mint is paused
    MintIsPaused = 35644
    /// Item: Access denied
    ItemAccessDenied = 45530
}

get fun get_collection_data(): OakenCollectionCollectionData {
    throw 0;
}

get fun get_nft_address_by_index(item_index: int257): address {
    throw 0;
}

get fun get_nft_content(index: int257, individual_content: cell): cell {
    throw 0;
}

get fun royalty_params(): OakenCollectionRoyaltyParams {
    throw 0;
}
