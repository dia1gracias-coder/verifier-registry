// Generated from the verified Tact contract ABI.
contract NftItem {
    storage: NftItemData
    incomingMessages: NftItemIncomingMessage
    thrownErrors: NftItemErrors
}

struct (0x946a98b6) NftItemDeploy {
    queryId: uint64
}

struct (0x5e19f431) NftItemTransfer {
    query_id: uint64
    new_owner: address
}

struct NftItemItemData {
    owner: address
    collection_address: address
    item_index: int257
    individual_content: cell
}

struct NftItemData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    collection_address: address
    item_index: int257
    individual_content: string
    tactContinuation: Cell<NftItemDataContinuation>
}

struct NftItemDataContinuation {
    ngocnt: int257
    ngocnt2: int257
}

type NftItemIncomingMessage =
    | NftItemTransfer
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
    /// Not enough ton
    NotEnoughTon = 1743
    /// Insufficient balance
    InsufficientBalance = 54615
    /// non-sequential NFTs
    NonSequentialNFTs = 62742
}

get fun get_item_data(): NftItemItemData {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
