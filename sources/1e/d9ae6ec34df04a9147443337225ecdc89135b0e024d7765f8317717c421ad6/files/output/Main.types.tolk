// Generated from the verified Tact contract ABI.
contract Main {
    storage: MainData
    incomingMessages: MainIncomingMessage
    thrownErrors: MainErrors
}

struct (0x946a98b6) MainDeploy {
    queryId: uint64
}

struct (0x29277552) MainSetStatus {
    statusId: int257
}

struct (0xd51c80ea) MainSetLockAddress {
    lockAddress: address
}

struct (0xa4ed8827) MainSetHoldersSnapshot {
    holder: address
}

struct MainData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    lockAddress: address
    token: address
    tactContinuation: Cell<MainDataContinuation>
}

struct MainDataContinuation {
    zeroAddress: address
    statusId: int257
    holders: map<int257, address>
    holdersLength: int257
}

type MainIncomingMessage =
    | MainSetStatus
    | MainSetLockAddress
    | MainSetHoldersSnapshot
    | MainDeploy

enum MainErrors {
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

get fun status(): int257 {
    throw 0;
}

get fun lockAddress(): address {
    throw 0;
}

get fun token(): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
