// Generated from the verified Tact contract ABI.
contract NftItem {
    storage: NftItemData
    incomingMessages: NftItemIncomingMessage
    thrownErrors: NftItemErrors
}

struct NftItemGetNftData {
    is_initialized: bool
    index: int257
    collection_address: address
    owner_address: address
    individual_content: cell
}

struct (0xabcdef12) NftItemRefuel {
    query_id: uint64
}

struct (0x5fcc3d14) NftItemTransfer {
    query_id: uint64
    new_owner: address
    response_destination: address
    custom_payload: cell?
    forward_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x2fcb26a2) NftItemGetStaticData {
    query_id: uint64
}

struct NftItemData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    collection_address: address
    item_index: int257
    owner: address
    individual_content: cell
    is_initialized: bool
    tactContinuation: Cell<NftItemDataContinuation>
}

struct NftItemDataContinuation {
    points: int257
    last_refuel_time: int257
    daily_points_accumulated: int257
    tactContinuation: Cell<NftItemDataContinuation2>
}

struct NftItemDataContinuation2 {
    daily_reset_time: int257
}

type NftItemIncomingMessage =
    | NftItemTransfer
    | NftItemGetStaticData
    | NftItemRefuel

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
    /// must wait until earning period ends
    MustWaitUntilEarningPeriodEnds = 9444
    /// not owner
    NotOwner = 49280
    /// non-sequential NFTs
    NonSequentialNFTs = 62742
}

get fun get_nft_data(): NftItemGetNftData {
    throw 0;
}

get fun get_points(): int257 {
    throw 0;
}

get fun get_today_points(): int257 {
    throw 0;
}
