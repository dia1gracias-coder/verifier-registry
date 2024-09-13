// Generated from the verified Tact contract ABI.
contract PayoutsMaster {
    storage: PayoutsMasterData
    incomingMessages: PayoutsMasterIncomingMessage
    thrownErrors: PayoutsMasterErrors
}

struct (0x946a98b6) PayoutsMasterDeploy {
    queryId: uint64
}

struct (0xd90aaa12) PayoutsMasterPayoutOk {
    address: address
    value: coins
}

struct (0x25bd488e) PayoutsMasterPayoutFailed {
    address: address
    value: coins
}

struct PayoutsMasterBurnParameters {
    startAt: uint32
    endAt: uint32
}

struct PayoutsMasterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    publicKey: uint256
    stopped: bool
    burn: PayoutsMasterBurnParameters?
}

type PayoutsMasterIncomingMessage =
    | PayoutsMasterPayoutOk
    | PayoutsMasterPayoutFailed
    | PayoutsMasterDeploy

enum PayoutsMasterErrors {
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
    /// Invalid sender
    InvalidSender = 4429
    /// Invalid burn parameters
    InvalidBurnParameters = 12724
    /// Invalid value
    InvalidValue = 16059
    /// Insufficient balance on master
    InsufficientBalanceOnMaster = 19204
    /// Contract stopped
    ContractStopped2 = 40368
    /// Invalid string
    InvalidString = 46762
    /// Invalid signature
    InvalidSignature = 48401
    /// Contract not stopped
    ContractNotStopped = 53296
    /// Check withdraw min value
    CheckWithdrawMinValue = 57826
}

get fun publicKey(): int257 {
    throw 0;
}

get fun burn(): PayoutsMasterBurnParameters? {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}
