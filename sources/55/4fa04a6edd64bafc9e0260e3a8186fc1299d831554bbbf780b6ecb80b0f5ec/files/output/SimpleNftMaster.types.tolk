// Generated from the verified Tact contract ABI.
contract SimpleNftMaster {
    storage: SimpleNftMasterData
    incomingMessages: SimpleNftMasterIncomingMessage
    thrownErrors: SimpleNftMasterErrors
}

struct SimpleNftMasterStateInit {
    code: cell
    data: cell
}

struct (0x946a98b6) SimpleNftMasterDeploy {
    queryId: uint64
}

struct SimpleNftMasterRoyaltyParams {
    numerator: int257
    denominator: int257
    destination: address
}

struct (0xaa44db9a) SimpleNftMasterCollectionMintParams {
    queryId: int257
    owner_address: address
    collection_content: cell
    nft_individual_content_url: cell
    tactContinuation: Cell<SimpleNftMasterCollectionMintParamsContinuation>
}

struct SimpleNftMasterCollectionMintParamsContinuation {
    royalty_params: SimpleNftMasterRoyaltyParams
    tactContinuation: Cell<SimpleNftMasterCollectionMintParamsContinuation2>
}

struct SimpleNftMasterCollectionMintParamsContinuation2 {
    mint_limit: int257
    mint_time_limit: int257
    is_sbt: int257
    tactContinuation: Cell<SimpleNftMasterCollectionMintParamsContinuation3>
}

struct SimpleNftMasterCollectionMintParamsContinuation3 {
    nft_price: int257
}

struct (0x31d628f0) SimpleNftMasterTransferOwner {
    new_owner: address
}

struct (0x4e96e420) SimpleNftMasterWithdraw {
    to: address
}

struct SimpleNftMasterMasterData {
    master: address
    next_collection_index: int257
    collection_creation_price: int257
}

struct SimpleNftMasterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    next_collection_index: int257
    collection_creation_price: uint32
}

type SimpleNftMasterIncomingMessage =
    | SimpleNftMasterCollectionMintParams
    | SimpleNftMasterWithdraw
    | SimpleNftMasterTransferOwner
    | SimpleNftMasterDeploy

enum SimpleNftMasterErrors {
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
    /// NFT creation underpriced
    NFTCreationUnderpriced = 1139
    /// Not from master
    NotFromMaster = 2575
    /// Mint time limit reached
    MintTimeLimitReached = 4183
    /// Token price too low
    TokenPriceTooLow = 5887
    /// Not from owner
    NotFromOwner = 15074
    /// non-sequential Collections
    NonSequentialCollections = 16095
    /// initialized tx need from collection
    InitializedTxNeedFromCollection = 27499
    /// Creation underpriced
    CreationUnderpriced = 31551
    /// Collection settings is not setup
    CollectionSettingsIsNotSetup = 34877
    /// Collection settings is already setup
    CollectionSettingsIsAlreadySetup = 39515
    /// not owner
    NotOwner = 49280
    /// not from collection
    NotFromCollection = 49469
    /// Sbt transfer for init only
    SbtTransferForInitOnly = 53651
    /// Collection must have time to mint
    CollectionMustHaveTimeToMint = 56768
    /// Mint limit reached
    MintLimitReached = 57324
    /// non-sequential NFTs
    NonSequentialNFTs = 62742
}

get fun getCollectionItemInit(item_index: int257): SimpleNftMasterStateInit {
    throw 0;
}

get fun get_master_data(): SimpleNftMasterMasterData {
    throw 0;
}

get fun get_collection_address_by_index(collection_index: int257): address? {
    throw 0;
}

get fun get_next_collection_index(): int257 {
    throw 0;
}
