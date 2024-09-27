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

struct (0xa258d3cd) NftCollectionMintParams {
    item_content: cell
    destination: address
}

struct (0x53f03e5a) NftCollectionPaidMintParams {
    item_content: cell
    destination: address
}

struct (0x693d3950) NftCollectionGetRoyaltyParams {
    query_id: uint64
}

struct NftCollectionCollectionData {
    next_item_index: int257
    collection_content: cell
    owner_address: address
}

struct NftCollectionMintingData {
    next_item_index: int257
    max_items_supply: uint32
    reserved_items_count: uint32
    minted_reserved_items: uint32
    mint_price: int257
}

struct NftCollectionRoyaltyParams {
    numerator: int257
    denominator: int257
    destination: address
}

struct NftCollectionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    ipfs_hashes: map<int257, bool>
    next_item_index: uint32
    max_items_supply: uint32
    reserved_items_count: uint32
    minted_reserved_items: uint32
    mint_price: int257
    owner_address: address
    tactContinuation: Cell<NftCollectionDataContinuation>
}

struct NftCollectionDataContinuation {
    royalty_params: NftCollectionRoyaltyParams?
    collection_content: cell
}

type NftCollectionIncomingMessage =
    | NftCollectionMintParams
    | NftCollectionPaidMintParams
    | NftCollectionGetRoyaltyParams

enum NftCollectionErrors {
    /// Stack undeflow
    StackUndeflow = 2
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
    /// Out of gas error
    OutOfGasError = 13
    /// Method ID not found
    MethodIDNotFound = 32
    /// Action is invalid or not supported
    ActionIsInvalidOrNotSupported = 34
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
    NotEnoughExtraCurrencies = 38
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
    /// exceed max supply (1024)
    ExceedMaxSupply1024 = 1510
    /// Reserved items supply (45) has been reached
    ReservedItemsSupply45HasBeenReached = 8700
    /// Only the owner can mint, use PaidMint to mint for others
    OnlyTheOwnerCanMintUsePaidMintToMintForOthers = 12233
    /// NFT with this IPFS hash already exists
    NFTWithThisIPFSHashAlreadyExists = 27273
    /// initialized tx need from collection
    InitializedTxNeedFromCollection = 27499
    /// Not enough funds for minting (1TON + GAS fee per NFT)
    NotEnoughFundsForMinting1TONGASFeePerNFT = 45169
    /// not owner
    NotOwner = 49280
    /// not from collection
    NotFromCollection = 49469
    /// Only the owner can withdraw
    OnlyTheOwnerCanWithdraw = 50353
    /// non-sequential NFTs
    NonSequentialNFTs = 62742
}

get fun get_collection_data(): NftCollectionCollectionData {
    throw 0;
}

get fun get_minting_data(): NftCollectionMintingData {
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

get fun royalty_params(): NftCollectionRoyaltyParams {
    throw 0;
}

get fun get_ipfs_hashes(): map<int257, bool> {
    throw 0;
}
