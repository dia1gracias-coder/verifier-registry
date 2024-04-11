// Generated from the verified Tact contract ABI.
contract LuckyBank {
    storage: LuckyBankData
    incomingMessages: LuckyBankIncomingMessage
    thrownErrors: LuckyBankErrors
}

struct (0x693d3950) LuckyBankGetRoyaltyParams {
    query_id: uint64
}

struct LuckyBankCollectionData {
    next_item_index: int257
    collection_content: cell
    owner_address: address
}

struct LuckyBankRoyaltyParams {
    numerator: int257
    denominator: int257
    destination: address
}

struct (0x00000003) LuckyBankChangeOwner {
    query_id: uint64
    new_owner: address
}

struct (0x00000004) LuckyBankEditContent {
    query_id: uint64
    content: cell
    royalty: cell
}

struct (0x00000444) LuckyBankLuckyMint {
    index: uint256
}

struct LuckyBankData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner_address: address
    collection_content: cell
    collection_base: cell
    tactContinuation: Cell<LuckyBankDataContinuation>
}

struct LuckyBankDataContinuation {
    royalty_params: LuckyBankRoyaltyParams
}

type LuckyBankIncomingMessage =
    | LuckyBankLuckyMint
    | LuckyBankEditContent
    | LuckyBankChangeOwner
    | LuckyBankGetRoyaltyParams

enum LuckyBankErrors {
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

get fun get_collection_data(): LuckyBankCollectionData {
    throw 0;
}

get fun get_nft_address_by_index(item_index: int257): address? {
    throw 0;
}

get fun get_nft_content(index: int257, individual_content: cell): cell {
    throw 0;
}

get fun royalty_params(): LuckyBankRoyaltyParams {
    throw 0;
}
