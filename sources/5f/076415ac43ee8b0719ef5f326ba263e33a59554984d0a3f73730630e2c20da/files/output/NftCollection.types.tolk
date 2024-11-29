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

struct NftCollectionCollectionData {
    next_item_index: int257
    collection_content: cell
    owner_address: address
}

struct (0x879994a7) NftCollectionMintNFT {
    amount: uint32
}

struct (0xf794fbe8) NftCollectionUpdateSalePrice {
    new_price: int257
}

struct (0xe43b3ad1) NftCollectionUpdateCollectionSize {
    new_size: int257
}

struct (0xbb6a3223) NftCollectionUpdateSaleStatus {
    new_status: int257
}

struct (0xcb43d5af) NftCollectionUpdateTreasuryAddress {
    new_treasury_address: address
}

struct (0x946a98b6) NftCollectionDeploy {
    queryId: uint64
}

struct NftCollectionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    next_item_index: uint32
    owner_address: address
    treasury_address: address
    collection_content: cell
    nft_price: int257
    tactContinuation: Cell<NftCollectionDataContinuation>
}

struct NftCollectionDataContinuation {
    authority_address: address
    max_collection_amount: int257
    total_minted_amount: int257
    tactContinuation: Cell<NftCollectionDataContinuation2>
}

struct NftCollectionDataContinuation2 {
    sale_status: int257
    minted_amounts: map<address, int257>
}

type NftCollectionIncomingMessage =
    | NftCollectionMintNFT
    | NftCollectionUpdateSaleStatus
    | NftCollectionUpdateTreasuryAddress
    | NftCollectionUpdateSalePrice
    | NftCollectionUpdateCollectionSize
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
    /// Sale is not active
    SaleIsNotActive = 1269
    /// Only owner can update treasury address
    OnlyOwnerCanUpdateTreasuryAddress = 3717
    /// Only owner can update sale price
    OnlyOwnerCanUpdateSalePrice = 6746
    /// SBT cannot be transferred
    SBTCannotBeTransferred = 9397
    /// Exceeds max collection amount
    ExceedsMaxCollectionAmount = 9431
    /// Already revoked
    AlreadyRevoked = 10990
    /// Not owner
    NotOwner = 14534
    /// Initialized tx need from collection
    InitializedTxNeedFromCollection = 17481
    /// Not from collection
    NotFromCollection = 23386
    /// Invalid NFT index
    InvalidNFTIndex = 24887
    /// Only owner can withdraw
    OnlyOwnerCanWithdraw = 26825
    /// Invalid status
    InvalidStatus = 27002
    /// Invalid mint amount
    InvalidMintAmount = 27544
    /// Only owner can update sale status
    OnlyOwnerCanUpdateSaleStatus = 30649
    /// No TON to withdraw
    NoTONToWithdraw = 31066
    /// Insufficient funds for minting
    InsufficientFundsForMinting = 41925
    /// Not authorized
    NotAuthorized = 42435
    /// Only owner can update collection size
    OnlyOwnerCanUpdateCollectionSize = 61799
}

get fun get_collection_data(): NftCollectionCollectionData {
    throw 0;
}

get fun get_sale_status(): string {
    throw 0;
}

get fun get_sale_price(): int257 {
    throw 0;
}

get fun get_collection_size(): int257 {
    throw 0;
}

get fun get_total_minted_amount(): int257 {
    throw 0;
}

get fun get_minted_amount_by_user(user_address: address): int257 {
    throw 0;
}

get fun get_nft_mint_total_cost(): int257 {
    throw 0;
}

get fun get_nft_address_by_index(item_index: int257): address? {
    throw 0;
}

get fun getNftItemInit(item_index: int257): NftCollectionStateInit {
    throw 0;
}

get fun get_nft_content(index: int257, individual_content: cell): cell {
    throw 0;
}
