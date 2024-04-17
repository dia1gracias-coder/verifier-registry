// Generated from the verified Tact contract ABI.
contract LuckyWallet {
    storage: LuckyWalletData
    incomingMessages: LuckyWalletIncomingMessage
    thrownErrors: LuckyWalletErrors
}

struct (0x5fcc3d14) LuckyWalletTransfer {
    query_id: uint64
    new_owner: address
    response_destination: address?
    custom_payload: cell?
    forward_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x2fcb26a2) LuckyWalletGetStaticData {
    query_id: uint64
}

struct LuckyWalletGetNftData {
    is_initialized: bool
    index: int257
    collection_address: address
    owner_address: address
    individual_content: cell
}

struct (0x00000777) LuckyWalletLuckySend {
    to: address
    value: coins
    mode: uint8
    body: cell?
    code: cell?
    data: cell?
}

struct LuckyWalletData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    collection_address: address
    item_index: int257
    is_initialized: bool
    owner: address?
    individual_content: cell
}

type LuckyWalletIncomingMessage =
    | LuckyWalletLuckySend
    | LuckyWalletTransfer
    | LuckyWalletGetStaticData

enum LuckyWalletErrors {
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
    /// Not owner
    NotOwner = 14534
    /// Not Lucky Bank
    NotLuckyBank = 33170
    /// Insufficient privelegies
    InsufficientPrivelegies = 36287
    /// Initialized need from Lucky Bank
    InitializedNeedFromLuckyBank = 37345
}

get fun get_nft_data(): LuckyWalletGetNftData {
    throw 0;
}

get fun lucky(): bool {
    throw 0;
}
