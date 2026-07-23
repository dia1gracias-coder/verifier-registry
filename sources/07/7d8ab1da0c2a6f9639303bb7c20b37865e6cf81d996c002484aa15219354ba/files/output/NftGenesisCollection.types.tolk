// Generated from the verified Tact contract ABI.
contract NftGenesisCollection {
    storage: NftGenesisCollectionData
    incomingMessages: NftGenesisCollectionIncomingMessage
    thrownErrors: NftGenesisCollectionErrors
}

struct NftGenesisCollectionNftCollectionData {
    next_item_index: uint256
    collection_content: cell
    owner_address: address
}

struct (0x693d3950) NftGenesisCollectionNFTGetRoyaltyParams {
    query_id: uint64
}

struct NftGenesisCollectionNFTRoyaltyParams {
    numerator: uint16
    denominator: uint16
    royalty_destination: address
}

struct (0x00000001) NftGenesisCollectionMintNft {
    query_id: uint64
    item_index: uint64
    content: cell
}

struct (0x00000002) NftGenesisCollectionChangeCollectionOwner {
    query_id: uint64
    owner: address
}

struct (0x00000003) NftGenesisCollectionChangeRoyaltyDestination {
    query_id: uint64
    royalty_destination: address
}

struct (0x00000004) NftGenesisCollectionUpdateCollectionContent {
    query_id: uint64
    collection_meta_content: cell
    common_content: cell
}

struct (0x00000005) NftGenesisCollectionCollectionUpdateItemContent {
    query_id: uint64
    item_index: uint64
    individual_content: cell
}

struct NftGenesisCollectionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    next_item_index: uint64
    content: cell
    royalty_numerator: uint16
    royalty_denominator: uint16
    royalty_destination: address
}

type NftGenesisCollectionIncomingMessage =
    | NftGenesisCollectionNFTGetRoyaltyParams
    | NftGenesisCollectionMintNft
    | NftGenesisCollectionChangeCollectionOwner
    | NftGenesisCollectionChangeRoyaltyDestination
    | NftGenesisCollectionUpdateCollectionContent
    | NftGenesisCollectionCollectionUpdateItemContent

enum NftGenesisCollectionErrors {
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
    /// Invalid royalty numerator
    InvalidRoyaltyNumerator = 8761
    /// Not Deployed
    NotDeployed = 11850
    /// Invalid royalty denominator
    InvalidRoyaltyDenominator = 14760
    /// Invalid Sender
    InvalidSender = 23263
    /// Invalid Amount
    InvalidAmount = 30404
    /// Invalid Owner
    InvalidOwner = 42491
    /// Invalid Index
    InvalidIndex = 44083
    /// Unknown op
    UnknownOp = 48532
    /// Invalid collection meta
    InvalidCollectionMeta = 58939
}

get fun get_collection_data(): NftGenesisCollectionNftCollectionData {
    throw 0;
}

get fun get_nft_address_by_index(index: int257): address {
    throw 0;
}

get fun royalty_params(): NftGenesisCollectionNFTRoyaltyParams {
    throw 0;
}

get fun get_nft_content(index: int257, individual_content: cell): cell {
    throw 0;
}
