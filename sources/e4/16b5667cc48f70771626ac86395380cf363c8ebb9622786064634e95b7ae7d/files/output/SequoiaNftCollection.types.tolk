// Generated from the verified Tact contract ABI.
contract SequoiaNftCollection {
    storage: SequoiaNftCollectionData
    incomingMessages: SequoiaNftCollectionIncomingMessage
    thrownErrors: SequoiaNftCollectionErrors
}

struct (0x693d3950) SequoiaNftCollectionGetRoyaltyParams {
    queryId: uint64
}

struct (0x073a786d) SequoiaNftCollectionMintNftItem {
}

struct (0x0524499e) SequoiaNftCollectionMintNftItemAdmin {
    destination: address
}

struct (0x352b00aa) SequoiaNftCollectionSetRoyaltyParams {
    royaltyParams: SequoiaNftCollectionRoyaltyParams
}

struct (0xdbbb64e2) SequoiaNftCollectionSetMintPrice {
    mintPrice: coins
}

struct (0x741c37fb) SequoiaNftCollectionInitializeCollection {
    baseUrl: string
}

struct (0x5279fb19) SequoiaNftCollectionSetBaseUrl {
    baseUrl: string
}

struct SequoiaNftCollectionRoyaltyParams {
    numerator: uint16
    denominator: uint16
    destination: address
}

struct SequoiaNftCollectionCollectionData {
    nextItemIndex: uint64
    content: cell
    owner: address
}

struct SequoiaNftCollectionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    nextItemIndex: uint64
    baseUrl: string?
    initialized: bool
    owner: address
    royaltyParams: SequoiaNftCollectionRoyaltyParams?
    mintPrice: coins
}

type SequoiaNftCollectionIncomingMessage =
    | SequoiaNftCollectionInitializeCollection
    | SequoiaNftCollectionSetBaseUrl
    | SequoiaNftCollectionMintNftItem
    | SequoiaNftCollectionMintNftItemAdmin
    | SequoiaNftCollectionGetRoyaltyParams
    | SequoiaNftCollectionSetRoyaltyParams
    | SequoiaNftCollectionSetMintPrice

enum SequoiaNftCollectionErrors {
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
    /// NFT item is already initialized
    NFTItemIsAlreadyInitialized = 8333
    /// Not enough value to mint
    NotEnoughValueToMint = 25791
    /// Only the owner can transfer the NFT
    OnlyTheOwnerCanTransferTheNFT = 26088
    /// Only the owner can set the mint price
    OnlyTheOwnerCanSetTheMintPrice = 28112
    /// Only the owner can mint
    OnlyTheOwnerCanMint = 30489
    /// Collection is already initialized
    CollectionIsAlreadyInitialized = 30657
    /// Only the owner can set the base URL
    OnlyTheOwnerCanSetTheBaseURL = 37326
    /// Only the collection can initialize the NFT item
    OnlyTheCollectionCanInitializeTheNFTItem = 41017
    /// Collection is not initialized
    CollectionIsNotInitialized = 48138
    /// Only the owner can set the royalty params
    OnlyTheOwnerCanSetTheRoyaltyParams = 49573
    /// Royalty params are not set
    RoyaltyParamsAreNotSet = 51012
    /// Only the owner can initialize the collection
    OnlyTheOwnerCanInitializeTheCollection = 51754
    /// Only the collection can change the base URL
    OnlyTheCollectionCanChangeTheBaseURL = 54528
    /// NFT item is not initialized
    NFTItemIsNotInitialized = 60000
    /// No enough value to forward
    NoEnoughValueToForward = 60157
}

get fun get_collection_data(): SequoiaNftCollectionCollectionData {
    throw 0;
}

get fun get_nft_address_by_index(index: int257): address {
    throw 0;
}

get fun get_nft_content(index: int257, _: string): cell {
    throw 0;
}

get fun royalty_params(): SequoiaNftCollectionRoyaltyParams? {
    throw 0;
}
