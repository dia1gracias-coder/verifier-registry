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

struct (0x693d3950) NftCollectionGetRoyaltyParams {
    query_id: uint64
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

struct (0xa065e0f2) NftCollectionMintableChange {
    status: bool
}

struct (0xddc2d2d6) NftCollectionLocalMintableChange {
    status: bool
}

struct (0xbe355b00) NftCollectionPriceForMintChange {
    value: coins
}

struct (0x4685b449) NftCollectionMaxTotalNftChange {
    value: uint32
}

struct (0x0ba69751) NftCollectionWithdraw {
    amount: coins
}

struct (0x0da281cf) NftCollectionRouteMintNFT {
    receiver: address
}

struct (0x893afb23) NftCollectionChangeRoute {
    new_route: address
}

struct (0xd9ae38fe) NftCollectionChangeOwner {
    new_owner: address
}

struct (0x871c5039) NftCollectionProvideNFTAddress {
    query_id: uint64
    nft_index: uint64
}

struct NftCollectionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    next_item_index: uint32
    owner_address: address
    tactContinuation: Cell<NftCollectionDataContinuation>
}

struct NftCollectionDataContinuation {
    royalty_params: NftCollectionRoyaltyParams?
    collection_content: cell
    price_for_mint: coins
    mintable: bool
    local_mintable: bool
    max_total_nft: uint32
    isDeployed: bool
    tactContinuation: Cell<NftCollectionDataContinuation2>
}

struct NftCollectionDataContinuation2 {
    route_address: address
}

type NftCollectionIncomingMessage =
    | NftCollectionRouteMintNFT
    | NftCollectionChangeRoute
    | NftCollectionChangeOwner
    | NftCollectionMintableChange
    | NftCollectionLocalMintableChange
    | NftCollectionPriceForMintChange
    | NftCollectionMaxTotalNftChange
    | NftCollectionWithdraw
    | NftCollectionProvideNFTAddress
    | NftCollectionGetRoyaltyParams

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
    /// Only the owner is allowed to use the function!
    OnlyTheOwnerIsAllowedToUseTheFunction = 11509
    /// There are not enough funds for the transaction!
    ThereAreNotEnoughFundsForTheTransaction = 12577
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Insufficient funds to pay for MINT NFT!
    InsufficientFundsToPayForMINTNFT = 20672
    /// initialized tx need from collection
    InitializedTxNeedFromCollection = 27499
    /// The maximum NFT limit has been exceeded!
    TheMaximumNFTLimitHasBeenExceeded = 41917
    /// Only the ROUTE is allowed to use the function!
    OnlyTheROUTEIsAllowedToUseTheFunction = 47379
    /// Insufficient funds for a mint!
    InsufficientFundsForAMint = 48556
    /// not owner
    NotOwner = 49280
    /// not from collection
    NotFromCollection = 49469
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

get fun get_nft_mint_price(): int257 {
    throw 0;
}

get fun get_nft_min_mint_price(): int257 {
    throw 0;
}
