// Generated from the verified Tact contract ABI.
contract TactV0 {
    storage: TactV0Data
    incomingMessages: TactV0IncomingMessage
    thrownErrors: TactV0Errors
}

struct (0x946a98b6) TactV0Deploy {
    queryId: uint64
}

struct (0x8b341822) TactV0Add {
    queryId: uint64
    amount: uint32
}

struct (0xc5da2c73) TactV0Subtract {
    queryId: uint64
    amount: uint32
}

struct (0x0e45764c) TactV0Upgrade {
    newCode: cell
    newData: cell
}

struct (0xe0c62a05) TactV0UpgradeCode {
    newCode: cell
}

struct (0x78d457a3) TactV0UpgradeData {
    newData: cell
}

struct TactV0InC {
    id: int257
    counter: int257
}

struct TactV0Data {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    id: uint32
    counter: uint32
}

type TactV0IncomingMessage =
    | TactV0Add
    | TactV0Upgrade
    | TactV0UpgradeCode
    | TactV0UpgradeData
    | TactV0Subtract
    | TactV0Deploy

enum TactV0Errors {
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

get fun counter(): int257 {
    throw 0;
}

get fun id(): int257 {
    throw 0;
}

get fun data(): TactV0InC {
    throw 0;
}
