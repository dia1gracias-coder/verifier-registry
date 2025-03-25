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

struct (0x693d3950) NftCollectionGetRoyaltyParams {
    query_id: uint64
}

struct (0x871c5039) NftCollectionProvideNFTAddress {
    query_id: uint64
    nft_index: uint64
}

struct (0x0da281cf) NftCollectionRouteMintNFT {
    receiver: address
}

struct (0x893afb23) NftCollectionChangeRoute {
    new_route: address
}

struct (0xc7624ed0) NftCollectionChangePrice {
    value: coins
}

struct (0x0f474d03) NftCollectionChangeOwner {
    newOwner: address
}

struct (0x0ba69751) NftCollectionWithdraw {
    amount: coins
}

struct (0xa91ffea9) NftCollectionChangeMaxTotal {
    value: uint32
}

struct NftCollectionCollectionData {
    next_item_index: int257
    collection_content: cell
    owner_address: address
}

struct NftCollectionRoyaltyParams {
    numerator: int257
    denominator: int257
    destination: address
}

struct NftCollectionData {
    tactDeploymentCompleted: bool
    next_item_index: uint32
    owner_address: address
    tactContinuation: Cell<NftCollectionDataContinuation>
}

struct NftCollectionDataContinuation {
    royalty_params: NftCollectionRoyaltyParams?
    collection_content: cell
    nft_item_code: cell
    price_for_mint: coins
    mintable: bool
    public_mintable: bool
    max_total_nft: uint32
    tactContinuation: Cell<NftCollectionDataContinuation2>
}

struct NftCollectionDataContinuation2 {
    route_address: address
    json_list: map<int257, cell>
    json_list_index: uint32
    json_list_max_index: uint32
    json_list_change_index: uint32
}

type NftCollectionIncomingMessage =
    | NftCollectionRouteMintNFT
    | NftCollectionChangeRoute
    | NftCollectionChangePrice
    | NftCollectionChangeMaxTotal
    | NftCollectionWithdraw
    | NftCollectionProvideNFTAddress
    | NftCollectionChangeOwner
    | NftCollectionGetRoyaltyParams
    | NftCollectionDeploy

enum NftCollectionErrors {
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
    /// Only the owner is allowed to use the function!
    OnlyTheOwnerIsAllowedToUseTheFunction = 11509
    /// There are not enough funds for the transaction!
    ThereAreNotEnoughFundsForTheTransaction = 12577
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Insufficient funds to pay for MINT NFT!
    InsufficientFundsToPayForMINTNFT = 20672
    /// The maximum NFT limit has been exceeded!
    TheMaximumNFTLimitHasBeenExceeded = 41917
    /// Only the ROUTE is allowed to use the function!
    OnlyTheROUTEIsAllowedToUseTheFunction = 47379
    /// Insufficient balance
    InsufficientBalance = 54615
    /// non-sequential NFTs
    NonSequentialNFTs = 62742
    /// Mint NFT is currently disabled!
    MintNFTIsCurrentlyDisabled = 63025
}

get fun get_collection_data(): NftCollectionCollectionData {
    throw 0;
}

get fun get_nft_address_by_index(item_index: int257): address {
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

get fun get_nft_mintable(): bool {
    throw 0;
}

get fun get_nft_mintable_public(): bool {
    throw 0;
}

get fun get_nft_min_mint_price(): int257 {
    throw 0;
}
