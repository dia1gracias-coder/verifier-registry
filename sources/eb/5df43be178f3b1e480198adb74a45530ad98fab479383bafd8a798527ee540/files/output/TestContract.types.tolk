// Generated from the verified Tact contract ABI.
contract TestContract {
    storage: TestContractData
    incomingMessages: TestContractIncomingMessage
    thrownErrors: TestContractErrors
}

struct (0x946a98b6) TestContractDeploy {
    queryId: uint64
}

struct (0x8b341822) TestContractAdd {
    queryId: uint64
    amount: uint32
}

struct TestContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    id: uint32
    counter: uint32
    counter_one: uint32
    counter_two: uint32
    t_id: uint32
    te_id2: uint32
    te_id3: uint32
    te_id4: uint32
    te_id115: uint32
    counter_test: uint32
}

type TestContractIncomingMessage =
    | TestContractAdd
    | TestContractDeploy

enum TestContractErrors {
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

get fun counter2(): int257 {
    throw 0;
}

get fun counter3(): int257 {
    throw 0;
}

get fun countertest(): int257 {
    throw 0;
}

get fun id(): int257 {
    throw 0;
}

get fun tid(): int257 {
    throw 0;
}

get fun teid2(): int257 {
    throw 0;
}

get fun teidtest2(): int257 {
    throw 0;
}
