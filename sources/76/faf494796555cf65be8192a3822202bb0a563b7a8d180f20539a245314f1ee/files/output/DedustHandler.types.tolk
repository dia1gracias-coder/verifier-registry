// Generated from the verified Tact contract ABI.
contract DedustHandler {
    storage: DedustHandlerData
    incomingMessages: DedustHandlerIncomingMessage
    thrownErrors: DedustHandlerErrors
}

struct (0x7362d09c) DedustHandlerTokenNotification {
    query_id: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct (0xbcb93414) DedustHandlerSwapNativeInDedust {
    query_id: uint64
    amount: coins
    pool: address
    minReturn: coins
    recipient_addr: address?
    tactContinuation: Cell<DedustHandlerSwapNativeInDedustContinuation>
}

struct DedustHandlerSwapNativeInDedustContinuation {
    referral_addr: address?
    next: cell?
    invalidQuery: RemainingBitsAndRefs
}

struct (0xb75b96d7) DedustHandlerWithdrawInfo {
    token: address?
    amount: coins?
    to: address?
    value: coins?
    isNative: bool
}

struct (0x946a98b6) DedustHandlerDeploy {
    queryId: uint64
}

struct DedustHandlerData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    pool: address
}

type DedustHandlerIncomingMessage =
    | DedustHandlerSwapNativeInDedust
    | DedustHandlerTokenNotification
    | DedustHandlerWithdrawInfo
    | DedustHandlerDeploy

enum DedustHandlerErrors {
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
    /// amount = 0
    Amount0 = 44535
}
