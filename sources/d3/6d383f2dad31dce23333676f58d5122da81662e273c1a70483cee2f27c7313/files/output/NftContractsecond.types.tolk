// Generated from the verified Tact contract ABI.
contract NftContractsecond {
    storage: NftContractsecondData
    incomingMessages: NftContractsecondIncomingMessage
    thrownErrors: NftContractsecondErrors
}

struct NftContractsecondStateInit {
    code: cell
    data: cell
}

struct (0xee394c8f) NftContractsecondInitDeployedTrue {
    query_id: int257
    nft_address: address
    sender: address
    individual_content: cell
}

struct (0x693d3950) NftContractsecondGetRoyaltyParams {
    query_id: uint64
}

struct (0x00000001) NftContractsecondMint {
    query_id: uint64
    custom_payload: cell
}

struct NftContractsecondCollectionData {
    next_item_index: int257
    collection_content: cell
    owner_address: address
}

struct NftContractsecondRoyaltyParams {
    numerator: int257
    denominator: int257
    destination: address
}

struct (0x946a98b6) NftContractsecondDeploy {
    queryId: uint64
}

struct NftContractsecondData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    next_item_index: uint16
    owner_address: address
    tactContinuation: Cell<NftContractsecondDataContinuation>
}

struct NftContractsecondDataContinuation {
    royalty_params: NftContractsecondRoyaltyParams?
    collection_content: cell
    tactContinuation: Cell<NftContractsecondDataContinuation2>
}

struct NftContractsecondDataContinuation2 {
    nonce: int257
    nft_contents: map<int257, cell>
}

type NftContractsecondIncomingMessage =
    | NftContractsecondMint
    | NftContractsecondInitDeployedTrue
    | NftContractsecondGetRoyaltyParams
    | NftContractsecondDeploy

enum NftContractsecondErrors {
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
    /// Invalid sender
    InvalidSender = 4429
    /// Invalid nonce
    InvalidNonce = 23767
    /// Already deployed
    AlreadyDeployed = 24123
    /// initialized tx need from collection
    InitializedTxNeedFromCollection = 27499
    /// Insufficient funds for NFT deployment
    InsufficientFundsForNFTDeployment = 28670
    /// Invalid content prefix
    InvalidContentPrefix = 37870
    /// Invalid signature
    InvalidSignature = 48401
    /// Invalid NFT address
    InvalidNFTAddress = 49178
    /// not owner
    NotOwner = 49280
    /// not from collection
    NotFromCollection = 49469
    /// Content too long
    ContentTooLong = 49507
    /// Insufficient funds
    InsufficientFunds = 51754
    /// non-sequential NFTs
    NonSequentialNFTs = 62742
}

get fun get_collection_data(): NftContractsecondCollectionData {
    throw 0;
}

get fun get_nft_address_by_index(item_index: int257): address {
    throw 0;
}

get fun getNftItemInit(item_index: int257): NftContractsecondStateInit {
    throw 0;
}

get fun get_nft_content(index: int257, individual_content: cell): cell {
    throw 0;
}

get fun royalty_params(): NftContractsecondRoyaltyParams {
    throw 0;
}
