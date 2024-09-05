// Generated from the verified Tact contract ABI.
contract JettonDex {
    storage: JettonDexData
    incomingMessages: JettonDexIncomingMessage
    thrownErrors: JettonDexErrors
}

struct (0x946a98b6) JettonDexDeploy {
    queryId: uint64
}

struct (0x228d8f29) JettonDexSwapRequest {
    amount: uint32
    fromJetton: address
}

struct (0xb4dd8c64) JettonDexAddJetton {
    amount: uint32
}

struct JettonDexData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    jettonABalance: uint32
    jettonBBalance: uint32
    jettonAAddress: address
    jettonBAddress: address
}

type JettonDexIncomingMessage =
    | JettonDexAddJetton
    | JettonDexSwapRequest
    | JettonDexDeploy

enum JettonDexErrors {
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
    /// Invalid sender
    InvalidSender = 4429
    /// Unsupported jetton address for swap
    UnsupportedJettonAddressForSwap = 9633
    /// Insufficient Jetton B balance
    InsufficientJettonBBalance = 23101
    /// Insufficient Jetton A balance
    InsufficientJettonABalance = 30901
    /// Unsupported jetton address
    UnsupportedJettonAddress = 30979
    /// Insufficient Jetton A for swap
    InsufficientJettonAForSwap = 53516
    /// Insufficient Jetton B for swap
    InsufficientJettonBForSwap = 54383
}

get fun getJettonABalance(): int257 {
    throw 0;
}

get fun getJettonBBalance(): int257 {
    throw 0;
}
