// Generated from the verified Tact contract ABI.
contract BidenDebate {
    storage: BidenDebateData
    incomingMessages: BidenDebateIncomingMessage
    thrownErrors: BidenDebateErrors
}

struct (0x946a98b6) BidenDebateDeploy {
    queryId: uint64
}

struct (0x934d91bd) BidenDebateSetSnapshot {
    holder: address
}

struct (0x0f2ef307) BidenDebateSetResult {
    result: bool
}

struct BidenDebateData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    result: bool
    isFinished: bool
    token: address
    holders: map<int257, address>
    holdersLength: int257
    owner: address
    tactContinuation: Cell<BidenDebateDataContinuation>
}

struct BidenDebateDataContinuation {
    lockAddress: address
    zeroAddress: address
}

type BidenDebateIncomingMessage =
    | BidenDebateSetResult
    | BidenDebateSetSnapshot
    | BidenDebateDeploy

enum BidenDebateErrors {
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
}

get fun token(): address {
    throw 0;
}

get fun lockAddress(): address {
    throw 0;
}

get fun result(): bool {
    throw 0;
}

get fun isFinished(): bool {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
