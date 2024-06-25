// Generated from the verified Tact contract ABI.
contract NftCollection {
    storage: NftCollectionData
    incomingMessages: NftCollectionIncomingMessage
    thrownErrors: NftCollectionErrors
}

struct NftCollectionStateInit {
    code: cell
    data: cell
}

struct (0x946a98b6) NftCollectionDeploy {
    queryId: uint64
}

struct (0x819dbe99) NftCollectionChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x81e8aac3) NftCollectionMintWithContent {
    query_id: uint64
    nftOffchainId: string
}

struct (0xd4ebbbf0) NftCollectionUpdateCollectionContent {
    query_id: uint64
    new_content: cell
    numerator: uint16
    denominator: uint16
    destination: address
    collectionContentUrl: cell
    commonContentUrl: cell
}

struct (0x693d3950) NftCollectionGetRoyaltyParams {
    query_id: uint64
}

struct NftCollectionCollectionData {
    next_item_index: uint32
    collection_content: cell
    owner: address
}

struct NftCollectionRoyaltyParams {
    numerator: uint16
    denominator: uint16
    destination: address
}

struct NftCollectionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    next_item_index: uint32
    owner: address
    royalty_params: NftCollectionRoyaltyParams
    collectionContentUrl: cell
    commonContentUrl: cell
}

type NftCollectionIncomingMessage =
    | NftCollectionMintWithContent
    | NftCollectionGetRoyaltyParams
    | NftCollectionUpdateCollectionContent
    | NftCollectionDeploy
    | NftCollectionChangeOwner

enum NftCollectionErrors {
    /// Stack undeflow
    StackUndeflow = 2
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
    /// Out of gas error
    OutOfGasError = 13
    /// Method ID not found
    MethodIDNotFound = 32
    /// Action is invalid or not supported
    ActionIsInvalidOrNotSupported = 34
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
    NotEnoughExtraCurrencies = 38
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
    /// invalid amount
    InvalidAmount = 54178
    /// access denied
    AccessDenied2 = 61686
    /// non-sequential NFTs
    NonSequentialNFTs = 62742
}

get fun get_collection_data(): NftCollectionCollectionData {
    throw 0;
}

get fun get_nft_address_by_index(item_index: int257): address? {
    throw 0;
}

get fun getNftItemInit(item_index: int257): NftCollectionStateInit {
    throw 0;
}

get fun get_nft_content(index: int257, individual_content: cell): cell {
    throw 0;
}

get fun royalty_params(): NftCollectionRoyaltyParams {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
