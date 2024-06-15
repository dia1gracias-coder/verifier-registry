// Generated from the verified Tact contract ABI.
contract Vesting {
    storage: VestingData
    incomingMessages: VestingIncomingMessage
    thrownErrors: VestingErrors
}

struct (0x250775b6) VestingWithdraw {
    amount: coins
    tokenWallet: address?
}

struct (0x819dbe99) VestingChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x7362d09c) VestingTokenNotification {
    queryId: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct VestingRecord {
    beneficiary: address
    totalAmount: uint256
    releasedAmount: uint256
    lastQueryId: uint64
}

struct VestingBeneficiaryRecord {
    beneficiary: address
    totalAmount: uint256
    lockedAmount: uint256
    tactContinuation: Cell<VestingBeneficiaryRecordContinuation>
}

struct VestingBeneficiaryRecordContinuation {
    releasedAmount: uint256
    releasableAmount: uint256
}

struct VestingConfig {
    startAt: uint64
    durationSeconds: uint64
    intervalSeconds: uint64
}

struct (0xb7323605) VestingClaim {
    queryId: uint64
    beneficiary: address
    responseTo: address?
}

struct (0xba95f11e) VestingUpdateVester {
    newVester: address?
}

struct (0x1e070c10) VestingDeploy {
    tokenWallet: address
    vester: address?
}

struct VestingData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    index: uint32?
    tokenWallet: address?
    vester: address?
    tactContinuation: Cell<VestingDataContinuation>
}

struct VestingDataContinuation {
    config: VestingConfig
    records: map<address, Cell<VestingRecord>>
    totalAmount: uint256
    totalReleasedAmount: uint256
}

type VestingIncomingMessage =
    | VestingDeploy
    | VestingClaim
    | VestingUpdateVester
    | VestingWithdraw
    | VestingChangeOwner
    | VestingTokenNotification

enum VestingErrors {
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
    /// Amount must be > 0
    AmountMustBe0 = 6243
    /// Unknown token type
    UnknownTokenType = 17808
    /// Already deployed
    AlreadyDeployed = 24123
    /// Not found
    NotFound = 25534
    /// Cannot withdraw vested tokens
    CannotWithdrawVestedTokens = 29236
    /// Should be overriden
    ShouldBeOverriden = 33636
    /// No access
    NoAccess = 36179
    /// Nothing to claim
    NothingToClaim = 44799
    /// Bad query
    BadQuery = 57218
}

get fun allRecords(): map<address, Cell<VestingRecord>> {
    throw 0;
}

get fun config(): VestingConfig {
    throw 0;
}

get fun index(): int257? {
    throw 0;
}

get fun vester(): address? {
    throw 0;
}

get fun tokenWallet(): address {
    throw 0;
}

get fun totalAmount(): int257 {
    throw 0;
}

get fun totalReleasedAmount(): int257 {
    throw 0;
}

get fun releasableAmount(beneficiary: address, dateInSeconds: int257?): int257 {
    throw 0;
}

get fun beneficiaryRecord(beneficiary: address, dateInSeconds: int257?): VestingBeneficiaryRecord {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
