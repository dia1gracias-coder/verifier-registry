// Generated from the verified Tact contract ABI.
contract NftCollection {
    storage: NftCollectionData
    thrownErrors: NftCollectionErrors
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

struct NftCollectionSupplyInfo {
    total_supply: int257
    minted: int257
    remaining: int257
}

struct NftCollectionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    next_item_index: uint32
    owner_address: address
    creator_address: address
    collection_content: cell
    nft_price: int257
    tactContinuation: Cell<NftCollectionDataContinuation>
}

struct NftCollectionDataContinuation {
    authority_address: address
    paused: bool
}

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
    /// Collection sold out
    CollectionSoldOut = 14248
    /// Not owner
    NotOwner = 14534
    /// Initialized tx need from collection
    InitializedTxNeedFromCollection = 17481
    /// Not from collection
    NotFromCollection = 23386
    /// Price must be > 0
    PriceMustBe0 = 23732
    /// Only owner can withdraw
    OnlyOwnerCanWithdraw = 26825
    /// No TON to withdraw
    NoTONToWithdraw = 31066
    /// Only owner can transfer
    OnlyOwnerCanTransfer = 36952
    /// Insufficient funds
    InsufficientFunds = 51754
    /// Contract paused
    ContractPaused = 53793
    /// Not for sale
    NotForSale = 54288
    /// Insufficient TON for creator fee
    InsufficientTONForCreatorFee = 56053
}

get fun get_collection_data(): NftCollectionCollectionData {
    throw 0;
}

get fun royalty_params(): NftCollectionRoyaltyParams {
    throw 0;
}

get fun get_supply_info(): NftCollectionSupplyInfo {
    throw 0;
}

get fun get_nft_mint_total_cost(): int257 {
    throw 0;
}

get fun get_nft_address_by_index(item_index: int257): address? {
    throw 0;
}

get fun get_nft_content(index: int257, individual_content: cell): cell {
    throw 0;
}
