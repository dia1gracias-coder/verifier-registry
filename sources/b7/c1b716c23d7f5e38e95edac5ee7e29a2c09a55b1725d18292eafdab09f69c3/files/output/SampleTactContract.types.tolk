// Generated from the verified Tact contract ABI.
contract SampleTactContract {
    storage: SampleTactContractData
    incomingMessages: SampleTactContractIncomingMessage
    thrownErrors: SampleTactContractErrors
}

struct (0x946a98b6) SampleTactContractDeploy {
    queryId: uint64
}

struct (0x87d43ac2) SampleTactContractAdd {
    amount: uint32
}

struct (0x5c8e8db9) SampleTactContractSubtract {
    amount: uint32
}

struct (0x8462dd01) SampleTactContractMultiMath {
    add: uint32
    subtract: uint32
    multiply: uint32
}

struct (0x82491bc4) SampleTactContractMultiply {
    amount: uint32
}

struct (0x7ca4745f) SampleTactContractDivide {
    amount: uint32
}

struct SampleTactContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    val_: int64
}

type SampleTactContractIncomingMessage =
    | SampleTactContractAdd
    | SampleTactContractSubtract
    | SampleTactContractMultiMath
    | SampleTactContractMultiply
    | SampleTactContractDivide
    | SampleTactContractDeploy

enum SampleTactContractErrors {
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
    /// Cannot divide by zero
    CannotDivideByZero = 61828
}

get fun value(): int257 {
    throw 0;
}
