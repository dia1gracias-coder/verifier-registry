// Generated from the verified Tact contract ABI.
contract TonupLauncherFixedPriceUnrestricted {
    storage: TonupLauncherFixedPriceUnrestrictedData
    incomingMessages: TonupLauncherFixedPriceUnrestrictedIncomingMessage
    thrownErrors: TonupLauncherFixedPriceUnrestrictedErrors
}

struct (0x946a98b6) TonupLauncherFixedPriceUnrestrictedDeploy {
    queryId: uint64
}

struct (0x819dbe99) TonupLauncherFixedPriceUnrestrictedChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x7362d09c) TonupLauncherFixedPriceUnrestrictedTransferNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0xd53276db) TonupLauncherFixedPriceUnrestrictedExcesses {
    queryId: uint64
}

struct (0xe2e83b65) TonupLauncherFixedPriceUnrestrictedParticipate {
    amount: coins
}

struct (0xc9d50116) TonupLauncherFixedPriceUnrestrictedSetLauncherConfig {
    config: TonupLauncherFixedPriceUnrestrictedLauncherConfig
}

struct (0x5990fd56) TonupLauncherFixedPriceUnrestrictedSetClaimStartTime {
    time: uint32
}

struct (0x4b409006) TonupLauncherFixedPriceUnrestrictedAddDistributionPool {
    config: TonupLauncherFixedPriceUnrestrictedPoolConfig
}

struct (0xfd11e1df) TonupLauncherFixedPriceUnrestrictedDeleteDistributionPool {
    index: uint32
}

struct (0xf023536f) TonupLauncherFixedPriceUnrestrictedModifyDistributionPool {
    index: uint32
    config: TonupLauncherFixedPriceUnrestrictedPoolConfig
}

struct (0xcece9a6a) TonupLauncherFixedPriceUnrestrictedManualTransferNotification {
    amount: coins
}

struct TonupLauncherFixedPriceUnrestrictedLauncherConfig {
    min_total_ton: coins
    max_total_ton: coins
    min_ton_per_tx: coins
    max_ton_per_user: coins
    tokens_per_ton: coins
    token_wallet_address: address
    tactContinuation: Cell<TonupLauncherFixedPriceUnrestrictedLauncherConfigContinuation>
}

struct TonupLauncherFixedPriceUnrestrictedLauncherConfigContinuation {
    unsold_token_refund_address: address
    start_time: uint32
    end_time: uint32
}

struct TonupLauncherFixedPriceUnrestrictedPoolConfig {
    address: address
    share: uint32
}

struct TonupLauncherFixedPriceUnrestrictedData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    tactContinuation: Cell<TonupLauncherFixedPriceUnrestrictedDataContinuation>
}

struct TonupLauncherFixedPriceUnrestrictedDataContinuation {
    config: TonupLauncherFixedPriceUnrestrictedLauncherConfig
    total_ton_contributed: coins
    tactContinuation: Cell<TonupLauncherFixedPriceUnrestrictedDataContinuation2>
}

struct TonupLauncherFixedPriceUnrestrictedDataContinuation2 {
    total_ton_refunded: coins
    config_validated: bool
    tokens_awaiting_launch: coins
    claim_start_time: uint32
    participation: map<address, uint256>
    distribution_number_pools: uint32
    distribution_pools: map<int257, Cell<TonupLauncherFixedPriceUnrestrictedPoolConfig>>
    distribution_complete: bool
    launch_finalized: bool
    launch_successful: bool
}

type TonupLauncherFixedPriceUnrestrictedIncomingMessage =
    | TonupLauncherFixedPriceUnrestrictedTransferNotification
    | TonupLauncherFixedPriceUnrestrictedExcesses
    | TonupLauncherFixedPriceUnrestrictedSetLauncherConfig
    | TonupLauncherFixedPriceUnrestrictedSetClaimStartTime
    | TonupLauncherFixedPriceUnrestrictedAddDistributionPool
    | TonupLauncherFixedPriceUnrestrictedDeleteDistributionPool
    | TonupLauncherFixedPriceUnrestrictedModifyDistributionPool
    | TonupLauncherFixedPriceUnrestrictedManualTransferNotification
    | TonupLauncherFixedPriceUnrestrictedParticipate
    | TonupLauncherFixedPriceUnrestrictedDeploy
    | TonupLauncherFixedPriceUnrestrictedChangeOwner

enum TonupLauncherFixedPriceUnrestrictedErrors {
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
    /// Invalid index
    InvalidIndex = 1173
    /// Max TON limit exceeded
    MaxTONLimitExceeded = 10560
    /// Not enough TON
    NotEnoughTON2 = 15304
    /// Incorrect TON value
    IncorrectTONValue = 17325
    /// Config not validated
    ConfigNotValidated = 17926
    /// Distribution pools not set
    DistributionPoolsNotSet = 20619
    /// Too late
    TooLate = 26949
    /// Min TON limit not met
    MinTONLimitNotMet = 31191
    /// Distribution not complete
    DistributionNotComplete = 32513
    /// Too many pools
    TooManyPools = 35898
    /// Not enough tokens
    NotEnoughTokens = 41029
    /// Too early
    TooEarly = 42340
    /// Nothing to claim
    NothingToClaim = 44799
    /// Min TON per tx not met
    MinTONPerTxNotMet = 47824
    /// Already started
    AlreadyStarted = 48002
    /// Launch not finalized
    LaunchNotFinalized = 49317
    /// Min TON limit already met
    MinTONLimitAlreadyMet = 54891
    /// Max TON per user exceeded
    MaxTONPerUserExceeded = 62424
}

get fun config(): TonupLauncherFixedPriceUnrestrictedLauncherConfig {
    throw 0;
}

get fun totalTon(): int257 {
    throw 0;
}

get fun validated(): bool {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}

get fun participation(addr: address): int257 {
    throw 0;
}

get fun numberPools(): int257 {
    throw 0;
}

get fun poolConfig(index: int257): TonupLauncherFixedPriceUnrestrictedPoolConfig {
    throw 0;
}

get fun claimStartTime(): int257 {
    throw 0;
}

get fun launchFinalized(): bool {
    throw 0;
}

get fun launchSuccessful(): bool {
    throw 0;
}

get fun tokensAwaitingLaunch(): int257 {
    throw 0;
}

get fun metadataName(): string {
    throw 0;
}

get fun metadataType(): string {
    throw 0;
}

get fun metadataVersion(): string {
    throw 0;
}

get fun metadataTicker(): string {
    throw 0;
}

get fun gasClaim(): int257 {
    throw 0;
}

get fun gasRefund(): int257 {
    throw 0;
}

get fun gasParticipate(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
