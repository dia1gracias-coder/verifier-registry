// Generated from the verified Tact contract ABI.
contract DataSaver {
    storage: DataSaverData2
    incomingMessages: DataSaverIncomingMessage
    thrownErrors: DataSaverErrors
}

struct (0xdb9bbf11) DataSaverDataInput {
    key: string
    data: string
}

struct (0xd6061de2) DataSaverDataInputTest {
    key: string
    data: string
}

struct DataSaverHolder {
    total: int257
    holder: map<int257, int257>
}

struct DataSaverData {
    key: string
    data: string
}

struct DataSaverData2 {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    index: int257
    owner: map<int257, address>
    holder: map<address, Cell<DataSaverHolder>>
    tactContinuation: Cell<DataSaverDataContinuation>
}

struct DataSaverDataContinuation {
    data: map<int257, Cell<DataSaverData>>
}

type DataSaverIncomingMessage =
    | DataSaverDataInput
    | DataSaverDataInputTest

enum DataSaverErrors {
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

get fun get_data(index: int257): DataSaverData {
    throw 0;
}

get fun get_address(): DataSaverHolder {
    throw 0;
}
