// Generated from the verified Tact contract ABI.
contract NftCollection {
    storage: NftCollectionData
    incomingMessages: NftCollectionIncomingMessage
    thrownErrors: NftCollectionErrors
}

struct (0x946a98b6) NftCollectionDeploy {
    queryId: uint64
}

struct (0x669ccac9) NftCollectionOwnerMint {
    query_id: uint64
    new_owner: address
    content: cell
}

struct (0x00000001) NftCollectionPublicMint {
    query_id: uint64
    content: cell
}

struct (0x00ab650b) NftCollectionMintConfirmation {
    query_id: uint64
    item_index: uint64
}

struct (0x4eeff21c) NftCollectionWithdrawFunds {
}

struct (0xe9ec264e) NftCollectionTogglePublicMinting {
}

struct (0xaf4083c0) NftCollectionSetMintPrice {
    new_price: coins
}

struct (0x90a59e84) NftCollectionCleanupPendingMints {
}

struct NftCollectionRoyaltyParams {
    numerator: uint16
    denominator: uint16
    destination: address
}

struct NftCollectionGetCollectionData {
    next_item_index: uint64
    collection_content: cell
    owner_address: address
}

struct NftCollectionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    next_item_index: uint64
    collection_content: cell
    tactContinuation: Cell<NftCollectionDataContinuation>
}

struct NftCollectionDataContinuation {
    nft_item_code: cell
    royalty_params: NftCollectionRoyaltyParams
    mint_price: coins
    public_minting_enabled: bool
    pending_mints: map<uint64, address>
}

type NftCollectionIncomingMessage =
    | NftCollectionOwnerMint
    | NftCollectionPublicMint
    | NftCollectionMintConfirmation
    | NftCollectionWithdrawFunds
    | NftCollectionTogglePublicMinting
    | NftCollectionSetMintPrice
    | NftCollectionCleanupPendingMints
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
    /// Invalid index
    InvalidIndex = 1173
    /// NFT not initialized
    NFTNotInitialized = 9679
    /// Only owner can set price
    OnlyOwnerCanSetPrice = 11789
    /// Only owner can cleanup
    OnlyOwnerCanCleanup = 12648
    /// Insufficient gas for mint operation
    InsufficientGasForMintOperation = 22120
    /// Public minting disabled
    PublicMintingDisabled = 23900
    /// Only owner can withdraw
    OnlyOwnerCanWithdraw = 26825
    /// Only owner can toggle
    OnlyOwnerCanToggle = 28262
    /// Only collection can mint
    OnlyCollectionCanMint = 33815
    /// Only owner can transfer
    OnlyOwnerCanTransfer = 36952
    /// Insufficient gas for mint
    InsufficientGasForMint = 37629
    /// Index out of range
    IndexOutOfRange = 41046
    /// Insufficient value for transfer
    InsufficientValueForTransfer = 42377
    /// Insufficient value for minting
    InsufficientValueForMinting = 43019
    /// Insufficient payment
    InsufficientPayment = 46647
    /// Already minted
    AlreadyMinted = 51687
    /// Only owner can mint
    OnlyOwnerCanMint = 57579
}

get fun get_collection_data(): NftCollectionGetCollectionData {
    throw 0;
}

get fun get_nft_address_by_index(item_index: int257): address {
    throw 0;
}

get fun get_nft_content(index: int257, individual_content: cell): cell {
    throw 0;
}

get fun royalty_params(): NftCollectionRoyaltyParams {
    throw 0;
}

get fun get_pending_mints_count(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
