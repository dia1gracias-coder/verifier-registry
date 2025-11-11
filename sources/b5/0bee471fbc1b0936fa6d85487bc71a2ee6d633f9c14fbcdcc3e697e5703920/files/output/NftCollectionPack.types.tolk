// Generated from the verified Tact contract ABI.
contract NftCollectionPack {
    storage: NftCollectionPackData
    incomingMessages: NftCollectionPackIncomingMessage
    thrownErrors: NftCollectionPackErrors
}

struct NftCollectionPackStateInit {
    code: cell
    data: cell
}

struct (0x693d3950) NftCollectionPackGetRoyaltyParams {
    query_id: uint64
}

struct NftCollectionPackCollectionData {
    next_item_index: int257
    collection_content: cell
    owner_address: address
}

struct NftCollectionPackRoyaltyParams {
    numerator: int257
    denominator: int257
    destination: address
}

struct (0x00000001) NftCollectionPackMintNFT {
}

struct (0x00000002) NftCollectionPackAirdropNFT {
    to_address: address
}

struct (0x00000003) NftCollectionPackWithdraw {
}

struct NftCollectionPackData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    next_item_index: uint32
    owner: address
    tactContinuation: Cell<NftCollectionPackDataContinuation>
}

struct NftCollectionPackDataContinuation {
    royalty_params: NftCollectionPackRoyaltyParams?
    collection_content: cell
    is_testnet: bool
}

type NftCollectionPackIncomingMessage =
    | NftCollectionPackMintNFT
    | NftCollectionPackAirdropNFT
    | NftCollectionPackWithdraw
    | NftCollectionPackGetRoyaltyParams

enum NftCollectionPackErrors {
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
    /// Airdrop would exceed max supply
    AirdropWouldExceedMaxSupply = 9175
    /// Not enough TON for gas
    NotEnoughTONForGas = 23376
    /// Not enough TON sent
    NotEnoughTONSent = 28284
    /// Mint has ended
    MintHasEnded = 36994
    /// Mint must come from collection
    MintMustComeFromCollection = 38255
    /// Not the owner
    NotTheOwner = 54727
    /// non-sequential NFTs
    NonSequentialNFTs = 62742
}

get fun get_collection_data(): NftCollectionPackCollectionData {
    throw 0;
}

get fun get_nft_address_by_index(item_index: int257): address? {
    throw 0;
}

get fun getNftItemInit(item_index: int257): NftCollectionPackStateInit {
    throw 0;
}

get fun get_nft_content(index: int257, individual_content: cell): cell {
    throw 0;
}

get fun royalty_params(): NftCollectionPackRoyaltyParams {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
