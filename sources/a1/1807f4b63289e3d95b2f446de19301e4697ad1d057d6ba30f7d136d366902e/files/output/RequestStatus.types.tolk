// Generated from the verified Tact contract ABI.
contract RequestStatus {
    storage: RequestStatusData
    incomingMessages: RequestStatusIncomingMessage
    thrownErrors: RequestStatusErrors
}

struct (0x946a98b6) RequestStatusDeploy {
    queryId: uint64
}

struct (0x590deb3d) RequestStatusRelease {
    amount: coins
    user: address
    requestId: int257
}

struct (0x099c97b8) RequestStatusSwapAndRelease {
    amount: coins
    user: address
    requestId: int257
    vault: address
    tactContinuation: Cell<RequestStatusSwapAndReleaseContinuation>
}

struct RequestStatusSwapAndReleaseContinuation {
    pool: address
    tradeFee: coins
}

struct (0x3b6e5a53) RequestStatusPrevent {
    user: address
    requestId: int257
}

struct RequestStatusData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    bridge: address
    user: address
    requestId: int257
    released: bool
    prevented: bool
}

type RequestStatusIncomingMessage =
    | RequestStatusRelease
    | RequestStatusSwapAndRelease
    | RequestStatusPrevent
    | RequestStatusDeploy

enum RequestStatusErrors {
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
    /// Insufficient value
    InsufficientValue = 2805
    /// Request prevented
    RequestPrevented = 7468
    /// Payout payload empty
    PayoutPayloadEmpty = 7485
    /// Invalid trade fee
    InvalidTradeFee = 9587
    /// Only executors can release funds
    OnlyExecutorsCanReleaseFunds = 20600
    /// Invalid request id
    InvalidRequestId = 23152
    /// Request released
    RequestReleased = 27222
    /// Invalid fee bps
    InvalidFeeBps = 32270
    /// Only executors can prevent request from releasing
    OnlyExecutorsCanPreventRequestFromReleasing = 38897
    /// Invalid user address
    InvalidUserAddress = 46321
    /// Amount is less than min bridge amount
    AmountIsLessThanMinBridgeAmount = 53070
    /// Bridge only
    BridgeOnly = 53919
}
