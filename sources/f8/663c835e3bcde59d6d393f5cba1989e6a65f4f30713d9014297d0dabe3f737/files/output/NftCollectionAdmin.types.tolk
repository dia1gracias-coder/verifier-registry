// Generated from the verified Tact contract ABI.
contract NftCollectionAdmin {
    storage: NftCollectionAdminData
    incomingMessages: NftCollectionAdminIncomingMessage
    thrownErrors: NftCollectionAdminErrors
}

struct (0x946a98b6) NftCollectionAdminDeploy {
    queryId: uint64
}

struct NftCollectionAdminRoyaltyParams {
    royalty_factor: uint16
    royalty_base: uint16
    royalty_address: address
}

struct NftCollectionAdminCollectionData {
    next_item_index: int257
    collection_content: cell
    owner_address: address
}

struct (0x3d1659a8) NftCollectionAdminMintNftV2 {
    query_id: uint64
    individual_content: cell?
}

struct (0xddbeb3db) NftCollectionAdminUpdateAuthorizedMinter {
    query_id: uint64
    new_minter: address
}

struct (0xe781f884) NftCollectionAdminUpdateCollectionContent {
    query_id: uint64
    collection_content: cell
}

struct (0x7de6da0a) NftCollectionAdminWithdrawFunds {
    query_id: uint64
}

struct (0x6013ab95) NftCollectionAdminBurnById {
    query_id: uint64
    index: int257
}

struct NftCollectionAdminData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    next_item_index: uint32
    owner: address
    royalty_params: NftCollectionAdminRoyaltyParams?
    collection_content: cell
    authorized_minter: address
}

type NftCollectionAdminIncomingMessage =
    | NftCollectionAdminMintNftV2
    | NftCollectionAdminWithdrawFunds
    | NftCollectionAdminUpdateCollectionContent
    | NftCollectionAdminUpdateAuthorizedMinter
    | NftCollectionAdminBurnById
    | NftCollectionAdminDeploy

enum NftCollectionAdminErrors {
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
    /// Non-sequential NFTs
    NonSequentialNFTs = 24690
    /// Only owner or authorized minter
    OnlyOwnerOrAuthorizedMinter = 34087
    /// Only owner can transfer
    OnlyOwnerCanTransfer = 36952
    /// Only collection can update content
    OnlyCollectionCanUpdateContent = 41819
    /// Insufficient funds for transfer
    InsufficientFundsForTransfer = 48618
    /// Insufficient funds
    InsufficientFunds = 51754
    /// Only owner or collection can burn
    OnlyOwnerOrCollectionCanBurn = 53144
}

get fun get_collection_data(): NftCollectionAdminCollectionData {
    throw 0;
}

get fun get_nft_address_by_index(index: int257): address? {
    throw 0;
}

get fun royalty_params(): NftCollectionAdminRoyaltyParams? {
    throw 0;
}

get fun get_nft_content(index: int257, individual_content: cell): cell {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
