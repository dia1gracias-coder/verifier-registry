// Generated from the verified Tact contract ABI.
contract Counter {
    storage: CounterData
    incomingMessages: CounterIncomingMessage
    thrownErrors: CounterErrors
}

struct (0x946a98b6) CounterDeploy {
    queryId: uint64
}

struct (0x8b341822) CounterAdd {
    queryId: uint64
    amount: uint32
}

struct (0x4a2504c5) CounterExp {
    queryId: uint64
}

struct (0x260c4c4d) CounterSqrt {
    queryId: uint64
}

struct CounterInC {
    id: int257
    counter: int257
}

struct (0xc5da2c73) CounterSubtract {
    queryId: uint64
    amount: uint32
}

struct (0xe0c62a05) CounterUpgradeCode {
    newCode: cell
}

struct CounterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    id: uint32
    counter: uint32
}

type CounterIncomingMessage =
    | CounterAdd
    | CounterExp
    | CounterSqrt
    | CounterUpgradeCode
    | CounterSubtract
    | CounterDeploy

enum CounterErrors {
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
}

get fun counter(): int257 {
    throw 0;
}

get fun id(): int257 {
    throw 0;
}

get fun data(): CounterInC {
    throw 0;
}
