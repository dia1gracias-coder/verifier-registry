// Generated from the verified Tact contract ABI.
contract Collection {
    storage: CollectionData2
    incomingMessages: CollectionIncomingMessage
    thrownErrors: CollectionErrors
}

struct CollectionStateInit {
    code: cell
    data: cell
}

struct (0x946a98b6) CollectionDeploy {
    queryId: uint64
}

struct (0x693d3950) CollectionGetRoyaltyParams {
    query_id: uint64
}

struct CollectionData {
    next_item_index: int257
    collection_content: cell
    owner_address: address
}

struct CollectionRoyaltyParams {
    numerator: int257
    denominator: int257
    destination: address
}

struct (0x00000322) CollectionMintType {
    amount: uint64
}

struct CollectionData2 {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    next_item_index: uint256
    owner_address: address
    content: cell
    daytona: address
    tactContinuation: Cell<CollectionDataContinuation>
}

struct CollectionDataContinuation {
    numerator: int257
    denominator: int257
    destination: address
    destroyed: bool
    price: coins
}

type CollectionIncomingMessage =
    | CollectionMintType
    | CollectionGetRoyaltyParams
    | CollectionDeploy

enum CollectionErrors {
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
    /// Access denied. Not owner.
    AccessDeniedNotOwner = 47495
    /// not from collection
    NotFromCollection = 49469
    /// Not enough coins to mint nft
    NotEnoughCoinsToMintNft = 55474
    /// only from collection
    OnlyFromCollection = 56815
}

get fun get_collection_data(): CollectionData {
    throw 0;
}

get fun get_nft_address_by_index(item_index: int257): address? {
    throw 0;
}

get fun getNftItemInit(item_index: int257): CollectionStateInit {
    throw 0;
}

get fun get_nft_content(index: int257, individual_content: cell): cell {
    throw 0;
}

get fun royalty_params(): CollectionRoyaltyParams {
    throw 0;
}
