// Generated from the verified Tact contract ABI.
contract NftItem {
    storage: NftItemData
    incomingMessages: NftItemIncomingMessage
    thrownErrors: NftItemErrors
}

struct (0x946a98b6) NftItemDeploy {
    queryId: uint64
}

struct (0xe42aa86e) NftItemMint {
    new_owner: address
    ton_site: string
}

struct (0xa1b42dbd) NftItemItemAddYear {
    from: address
    item_id: uint256
}

struct (0x5fcc3d14) NftItemTransfer {
    query_id: uint64
    new_owner: address
    response_destination: address?
    custom_payload: cell?
    forward_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x2fcb26a2) NftItemGetStaticData {
    query_id: uint64
}

struct NftItemGetNftData {
    is_initialized: bool
    index: int257
    collection_address: address
    owner_address: address
    individual_content: cell
}

struct NftItemGetFullNftData {
    is_initialized: bool
    index: int257
    collection_address: address
    owner_address: address
    individual_content: string
    tonsite: string
    tactContinuation: Cell<NftItemGetFullNftDataContinuation>
}

struct NftItemGetFullNftDataContinuation {
    expiration_date: int257
}

struct NftItemData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    id: uint256
    owner: address
    minTonsForStorage: coins
    gasConsumption: coins
    tactContinuation: Cell<NftItemDataContinuation>
}

struct NftItemDataContinuation {
    collection_address: address
    is_initialized: bool
    individual_content: string
    ton_site: string
    expiration_date: int257
}

type NftItemIncomingMessage =
    | NftItemItemAddYear
    | NftItemMint
    | NftItemTransfer
    | NftItemGetStaticData
    | NftItemDeploy

enum NftItemErrors {
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
    /// Item: Not the owner to add 1 year
    ItemNotTheOwnerToAdd1Year = 2931
    /// Access Denied!
    AccessDenied2 = 26930
    /// Not active yet
    NotActiveYet = 42679
    /// not from collection
    NotFromCollection = 49469
}

get fun get_nft_data(): NftItemGetNftData {
    throw 0;
}

get fun get_full_nft_data(): NftItemGetFullNftData {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
