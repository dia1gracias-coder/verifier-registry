// Generated from the verified Tact contract ABI.
contract TONNFTCollection {
    storage: TONNFTCollectionData
    incomingMessages: TONNFTCollectionIncomingMessage
    thrownErrors: TONNFTCollectionErrors
}

struct (0x946a98b6) TONNFTCollectionDeploy {
    queryId: uint64
}

struct TONNFTCollectionCollectionData {
    next_item_index: int257
    collection_content: cell
    owner_address: address
}

struct TONNFTCollectionRoyaltyParams {
    numerator: uint16
    denominator: uint16
    destination: address
}

struct (0x693d3950) TONNFTCollectionGetRoyaltyParams {
    query_id: uint64
}

struct (0x495fe55c) TONNFTCollectionMint {
    tgUserId: int257
}

struct (0x2365d020) TONNFTCollectionWithdraw {
}

struct TONNFTCollectionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    next_item_index: uint32
    collection_content: cell
    owner_address: address
    royalty_params: TONNFTCollectionRoyaltyParams
    minters: map<int257, int257>
}

type TONNFTCollectionIncomingMessage =
    | TONNFTCollectionMint
    | TONNFTCollectionWithdraw
    | TONNFTCollectionGetRoyaltyParams
    | TONNFTCollectionDeploy

enum TONNFTCollectionErrors {
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
    /// NFTItemStandard: Only the collection can initialize the NFT item
    NFTItemStandardOnlyTheCollectionCanInitializeTheNFTItem = 4020
    /// 0.1 TON Require for mint NFT
    _01TONRequireForMintNFT = 13121
    /// Only owner can withdraw
    OnlyOwnerCanWithdraw = 26825
    /// NFTItemStandard: Only the owner or collection can transfer the NFT item
    NFTItemStandardOnlyTheOwnerOrCollectionCanTransferTheNFTItem = 32575
}

get fun getLastMinterId(): int257? {
    throw 0;
}

get fun getAllMinters(): map<int257, int257> {
    throw 0;
}

get fun get_collection_data(): TONNFTCollectionCollectionData {
    throw 0;
}

get fun get_nft_address_by_index(index: int257): address {
    throw 0;
}

get fun get_nft_content(index: int257, individual_content: cell): cell {
    throw 0;
}

get fun royalty_params(): TONNFTCollectionRoyaltyParams {
    throw 0;
}
