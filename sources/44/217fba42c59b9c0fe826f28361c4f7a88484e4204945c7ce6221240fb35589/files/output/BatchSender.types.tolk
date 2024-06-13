// Generated from the verified Tact contract ABI.
contract BatchSender {
    storage: BatchSenderData
    incomingMessages: BatchSenderIncomingMessage
    thrownErrors: BatchSenderErrors
}

struct (0x946a98b6) BatchSenderDeploy {
    queryId: uint64
}

struct (0xc00a7dad) BatchSenderSetFee {
    fee: int257
}

struct (0x0424f31b) BatchSenderSendTon {
    address: map<int257, address>
    amount: map<int257, int257>
    comment: map<int257, cell>
    length: int257
}

struct (0x4f394a32) BatchSenderSendJetton {
    contractAddress: address
    body: map<int257, cell>
    length: int257
    amount: int257
}

struct (0x109287bc) BatchSenderChangeContractOwner {
    newOwner: address
}

struct BatchSenderData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    deployer: address
    fee: int257
}

type BatchSenderIncomingMessage =
    | BatchSenderSendTon
    | BatchSenderSetFee
    | BatchSenderSendJetton
    | BatchSenderChangeContractOwner
    | BatchSenderDeploy

enum BatchSenderErrors {
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
    /// 400
    _400 = 14110
    /// Only deployer is allowed to withdraw
    OnlyDeployerIsAllowedToWithdraw = 15509
    /// 401
    _401 = 53657
}

get fun balance(): int257 {
    throw 0;
}

get fun fee(): int257 {
    throw 0;
}
