// Generated from the verified Tact contract ABI.
contract HOLDVesting {
    storage: HOLDVestingData
    incomingMessages: HOLDVestingIncomingMessage
    thrownErrors: HOLDVestingErrors
}

struct (0x946a98b6) HOLDVestingDeploy {
    queryId: uint64
}

struct (0x819dbe99) HOLDVestingChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x9c781df9) HOLDVestingWithdrawJettons {
    queryId: uint64
    receiver: address
    amount: coins
}

struct (0x9a17330a) HOLDVestingWithdrawUnlockedJettons {
    queryId: uint64
    configId: uint8
    amount: coins
}

struct (0x958c1f43) HOLDVestingWithdrawDebtJettons {
    queryId: uint64
    receiver: address
    amount: coins
}

struct (0xa17c679d) HOLDVestingSetConfig {
    queryId: uint64
    configId: uint8
    amount: coins
    receiver: address
    description: cell
    cliffPeriodDuration: uint64
    cycleReleaseDuration: uint64
    cycleReleasePercent: uint64
}

struct (0x93ec1abf) HOLDVestingSetFreeze {
    newFrozenAt: uint64
}

struct HOLDVestingConfig {
    amount: coins
    receiver: address
    description: cell
    cliffPeriodDuration: uint64
    cycleReleaseDuration: uint64
    cycleReleasePercent: uint64
}

struct HOLDVestingAllocateData {
    isCliffPeriodEnded: bool
    cycleReleaseNumber: uint16
    totalJettons: coins
    totalAllocateJettons: coins
    totalUnlockedJettons: coins
    totalLockedJettons: coins
}

struct HOLDVestingData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    stopped: bool
    frozenAt: int257
    jettonMasterAddress: address
    jettonWalletCode: cell
    configs: map<uint8, Cell<HOLDVestingConfig>>
    tactContinuation: Cell<HOLDVestingDataContinuation>
}

struct HOLDVestingDataContinuation {
    totalAllocateJettons: map<uint8, int257>
    totalDebtJettons: coins
}

type HOLDVestingIncomingMessage =
    | HOLDVestingWithdrawJettons
    | HOLDVestingWithdrawUnlockedJettons
    | HOLDVestingWithdrawDebtJettons
    | HOLDVestingDeploy
    | HOLDVestingChangeOwner
    | HOLDVestingSetFreeze
    | HOLDVestingSetConfig

enum HOLDVestingErrors {
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
    /// The cliff period is not over yet
    TheCliffPeriodIsNotOverYet = 10523
    /// Invalid amount
    InvalidAmount = 17062
    /// Contract not frozen
    ContractNotFrozen = 28462
    /// Contract frozen
    ContractFrozen = 28705
    /// Config is not found
    ConfigIsNotFound = 38703
    /// Contract stopped
    ContractStopped2 = 40368
    /// Amount must be greater than 0
    AmountMustBeGreaterThan0 = 40476
    /// Freezing time cannot be in the past
    FreezingTimeCannotBeInThePast = 48649
    /// Contract not stopped
    ContractNotStopped = 53296
    /// Insufficient balance
    InsufficientBalance = 54615
}

get fun jettonMasterAddress(): address {
    throw 0;
}

get fun jettonWalletAddress(): address {
    throw 0;
}

get fun allocateData(configId: int257): HOLDVestingAllocateData? {
    throw 0;
}

get fun totalDebtJettons(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}

get fun isFrozen(): bool {
    throw 0;
}

get fun frozenAt(): int257 {
    throw 0;
}

get fun config(configId: int257): HOLDVestingConfig? {
    throw 0;
}
