// Generated from the verified Tact contract ABI.
contract JDexContract {
    storage: JDexContractData
    incomingMessages: JDexContractIncomingMessage
    thrownErrors: JDexContractErrors
}

struct (0x946a98b6) JDexContractDeploy {
    queryId: uint64
}

struct (0x5fefb6c4) JDexContractSwap {
    amount: uint64
    jetton: address
}

struct (0xcba7005e) JDexContractAddJettons {
    amountA: uint64
    amountB: uint64
}

struct JDexContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    amountOfJettonAOnContract: uint64
    amountOfJettonBOnContract: uint64
    jettonA: address
    jettonB: address
    tactContinuation: Cell<JDexContractDataContinuation>
}

struct JDexContractDataContinuation {
    decimal: int257
}

type JDexContractIncomingMessage =
    | JDexContractAddJettons
    | JDexContractSwap
    | JDexContractDeploy

enum JDexContractErrors {
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
    /// Admin cannot swap
    AdminCannotSwap = 4331
    /// Invalid sender
    InvalidSender = 4429
    /// Division by zero error
    DivisionByZeroError = 45549
    /// Swap amount must be greater than zero
    SwapAmountMustBeGreaterThanZero = 52754
    /// Insufficient Jetton B in contract
    InsufficientJettonBInContract = 56807
    /// Insufficient Jetton A in contract
    InsufficientJettonAInContract = 60537
}

get fun jettonABalances(): int257 {
    throw 0;
}

get fun jettonBBalances(): int257 {
    throw 0;
}

get fun jettonPrice(jetton: address): int257 {
    throw 0;
}
