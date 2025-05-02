// Generated from the verified Tact contract ABI.
contract MarketMaster {
    storage: MarketMasterData
    incomingMessages: MarketMasterIncomingMessage
    thrownErrors: MarketMasterErrors
}

struct MarketMasterStateInit {
    code: cell
    data: cell
}

struct (0x95d21749) MarketMasterCreateMarketItemFromOther {
    query_id: uint64
    nft_sale_address: address
    nft_address: address
    prev_owner: address
    full_price: coins
}

struct (0x05138d91) MarketMasterOwnershipAssigned {
    query_id: uint64
    prev_owner: address
    forward_payload: RemainingBitsAndRefs
}

struct MarketMasterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    next_item_index: int257
    created_at: int257
}

type MarketMasterIncomingMessage =
    | MarketMasterCreateMarketItemFromOther
    | MarketMasterOwnershipAssigned

enum MarketMasterErrors {
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
    /// Need more TON
    NeedMoreTON = 4759
    /// Dont have NFT
    DontHaveNFT = 16374
    /// Only nft method
    OnlyNftMethod = 20144
    /// Owner inited
    OwnerInited = 24814
    /// Only owner
    OnlyOwner = 35499
    /// Only the collection can initialize the NFT item
    OnlyTheCollectionCanInitializeTheNFTItem = 41017
    /// You not owner
    YouNotOwner = 50880
    /// Only nft collection method
    OnlyNftCollectionMethod = 53070
    /// Market only
    MarketOnly = 57788
}

get fun get_market_item_state(index: int257): MarketMasterStateInit {
    throw 0;
}

get fun get_market_item_address(index: int257): address {
    throw 0;
}

get fun get_current_index(): int257 {
    throw 0;
}
