// Generated from the verified Tact contract ABI.
contract Fireplace {
    storage: FireplaceData
    incomingMessages: FireplaceIncomingMessage
    thrownErrors: FireplaceErrors
}

struct (0x946a98b6) FireplaceDeploy {
    queryId: uint64
}

struct (0x8b341822) FireplaceAdd {
    queryId: uint64
    amount: uint32
}

struct (0xc5da2c73) FireplaceSubtract {
    queryId: uint64
    amount: uint32
}

struct FireplaceData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    counter: uint32
}

type FireplaceIncomingMessage =
    | FireplaceAdd
    | FireplaceSubtract
    | FireplaceDeploy

enum FireplaceErrors {
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
