// Generated from the verified Tact contract ABI.
contract MyNFTCollection {
    storage: MyNFTCollectionData
    incomingMessages: MyNFTCollectionIncomingMessage
    thrownErrors: MyNFTCollectionErrors
}

struct (0x946a98b6) MyNFTCollectionDeploy {
    queryId: uint64
}

struct (0xc53970ad) MyNFTCollectionMint {
    query_id: uint64
    metadata_index: uint16
    item_owner: address
    item_content: cell
}

struct (0x4c58fca8) MyNFTCollectionSetAgentMinter {
    query_id: uint64
    agent: address
    enabled: bool
}

struct MyNFTCollectionCollectionData {
    next_item_index: int257
    collection_content: cell
    owner_address: address
}

struct MyNFTCollectionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    next_item_index: uint64
    owner: address
    collection_content: cell
    tactContinuation: Cell<MyNFTCollectionDataContinuation>
}

struct MyNFTCollectionDataContinuation {
    agent_minters: map<address, bool>
    minted_metadata: map<int257, bool>
}

type MyNFTCollectionIncomingMessage =
    | MyNFTCollectionMint
    | MyNFTCollectionSetAgentMinter
    | MyNFTCollectionDeploy

enum MyNFTCollectionErrors {
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
    /// Invalid sender
    InvalidSender = 4429
    /// Invalid metadata index
    InvalidMetadataIndex = 8398
    /// NFT not initialized
    NFTNotInitialized = 9679
    /// Collection sold out
    CollectionSoldOut = 14248
    /// Insufficient mint fee: 0.5 TON required
    InsufficientMintFee05TONRequired = 28954
    /// NFT already initialized
    NFTAlreadyInitialized = 48912
    /// Only collection can deploy item
    OnlyCollectionCanDeployItem = 52082
    /// Only owner can manage agents
    OnlyOwnerCanManageAgents = 54219
    /// Metadata already minted
    MetadataAlreadyMinted = 56860
}

get fun get_collection_data(): MyNFTCollectionCollectionData {
    throw 0;
}

get fun get_nft_address_by_index(index: int257): address {
    throw 0;
}

get fun get_nft_content(index: int257, individual_content: cell): cell {
    throw 0;
}

get fun is_agent_minter(agent: address): bool {
    throw 0;
}

get fun is_metadata_minted(metadata_index: int257): bool {
    throw 0;
}

get fun get_mint_price(): int257 {
    throw 0;
}

get fun get_max_supply(): int257 {
    throw 0;
}
