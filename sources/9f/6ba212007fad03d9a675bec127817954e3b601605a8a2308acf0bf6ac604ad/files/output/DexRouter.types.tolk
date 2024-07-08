// Generated from the verified Tact contract ABI.
contract DexRouter {
    storage: DexRouterData
    incomingMessages: DexRouterIncomingMessage
    thrownErrors: DexRouterErrors
}

struct (0x819dbe99) DexRouterChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x946a98b6) DexRouterDeploy {
    queryId: uint64
}

struct (0x7362d09c) DexRouterTokenNotification {
    query_id: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct (0x670db556) DexRouterChangeFwdFee {
    stonfi_fwd: uint64
}

struct DexRouterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    stopped: bool
    stonfi_router: address
    stonfi_fwd_ton_amount: uint64
    stonfi_txorigin: address
}

type DexRouterIncomingMessage =
    | DexRouterTokenNotification
    | DexRouterChangeFwdFee
    | DexRouterDeploy
    | DexRouterChangeOwner

enum DexRouterErrors {
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
    /// at least 1 ton
    AtLeast1Ton = 29626
    /// Contract stopped
    ContractStopped2 = 40368
    /// Contract not stopped
    ContractNotStopped = 53296
}

get fun stopped(): bool {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
