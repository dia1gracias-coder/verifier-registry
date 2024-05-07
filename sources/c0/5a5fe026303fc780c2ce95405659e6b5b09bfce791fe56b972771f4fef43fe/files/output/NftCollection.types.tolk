// Generated from the verified Tact contract ABI.
contract NftCollection {
    storage: NftCollectionData
    incomingMessages: NftCollectionIncomingMessage
    thrownErrors: NftCollectionErrors
}

struct (0x946a98b6) NftCollectionDeploy {
    queryId: uint64
}

struct NftCollectionNftRoyaltyParams {
    numerator: int257
    denominator: int257
    royalty_destination: address
}

struct (0x693d3950) NftCollectionNftGetRoyaltyParams {
    query_id: uint64
}

struct (0x244bb6fd) NftCollectionRequestNftDeploy {
    amount: coins
    owner: address
    content: cell
}

struct (0x588bd148) NftCollectionSetDropStorage {
    supply: int257
    tier: int257
    price: int257
}

struct NftCollectionCollectionData {
    next_index: int257
    content: cell
    owner: address
}

struct NftCollectionDropStorage {
    supply: uint256
    current_minted: uint256
    tier: int257
    mint_list: map<address, bool>
    tactContinuation: Cell<NftCollectionDropStorageContinuation>
}

struct NftCollectionDropStorageContinuation {
    price: int257
}

struct NftCollectionNftInfo {
    tier: int257
    nft_address: address
}

struct NftCollectionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    next_index: uint256
    content: cell
    royalty_destination: address
    numerator: uint16
    denominator: uint16
    tactContinuation: Cell<NftCollectionDataContinuation>
}

struct NftCollectionDataContinuation {
    drop: NftCollectionDropStorage
    nft_info: map<int257, Cell<NftCollectionNftInfo>>
    tactContinuation: Cell<NftCollectionDataContinuation2>
}

struct NftCollectionDataContinuation2 {
    mint_accoint: address
}

type NftCollectionIncomingMessage =
    | NftCollectionRequestNftDeploy
    | NftCollectionSetDropStorage
    | NftCollectionDeploy
    | NftCollectionNftGetRoyaltyParams

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
    /// Not Deployed
    NotDeployed = 11850
    /// Invalid Sender
    InvalidSender = 23263
    /// Price is higher
    PriceIsHigher = 27195
    /// Invalid Amount
    InvalidAmount = 30404
    /// Drop ended
    DropEnded = 30428
    /// Invalid Owner
    InvalidOwner = 42491
    /// Invalid Index
    InvalidIndex = 44083
    /// error mint
    ErrorMint = 46593
    /// Already Deployed
    AlreadyDeployed = 50324
    /// only owner
    OnlyOwner = 58772
}

get fun get_nft_info(index: int257): NftCollectionNftInfo {
    throw 0;
}

get fun get_collection_data(): NftCollectionCollectionData {
    throw 0;
}

get fun get_nft_address_by_index(index: int257): address {
    throw 0;
}

get fun get_nft_content(index: int257, individual_content: cell): cell {
    throw 0;
}

get fun get_drop_storage(): NftCollectionDropStorage {
    throw 0;
}

get fun get_next_index(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun royalty_params(): NftCollectionNftRoyaltyParams {
    throw 0;
}
