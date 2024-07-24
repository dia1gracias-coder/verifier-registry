// Generated from the verified Tact contract ABI.
contract Stakee {
    storage: StakeeData
    incomingMessages: StakeeIncomingMessage
    thrownErrors: StakeeErrors
}

struct (0x946a98b6) StakeeDeploy {
    queryId: uint64
}

struct (0x819dbe99) StakeeChangeOwner {
    queryId: uint64
    newOwner: address
}

struct StakeeUser {
    lastClaimTimestamp: uint64
    totalStaked: coins
    referrer: address
    referralReward: int257
    referralCount: int257
    tactContinuation: Cell<StakeeUserContinuation>
}

struct StakeeUserContinuation {
    withdrawn: int257
    availableToWithdraw: int257
}

struct (0xd28aab06) StakeeReferralAddress {
    referral: address
    amount: int257
}

struct (0xf8c9c6d2) StakeeUnstakeAmount {
    amount: int257
}

struct StakeeData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    ID: uint32
    owner: address
    users: map<address, Cell<StakeeUser>>
    APY: int257
    referralPercentage: int257
    tactContinuation: Cell<StakeeDataContinuation>
}

struct StakeeDataContinuation {
    adminPercentage: int257
    deductPercentage: int257
    globalTotalStaked: int257
    tactContinuation: Cell<StakeeDataContinuation2>
}

struct StakeeDataContinuation2 {
    TIME_STEP: int257
    MIN_STORAGE_FEE: int257
    TOTAL_STAKED: int257
}

type StakeeIncomingMessage =
    | StakeeReferralAddress
    | StakeeUnstakeAmount
    | StakeeDeploy
    | StakeeChangeOwner

enum StakeeErrors {
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
    /// User not found
    UserNotFound = 7177
    /// Invalid amount
    InvalidAmount = 17062
    /// Balance is low
    BalanceIsLow = 27389
    /// No referral reward to claim
    NoReferralRewardToClaim = 28359
    /// No stake reward to claim
    NoStakeRewardToClaim = 47479
    /// Insufficient balance for withdrawal
    InsufficientBalanceForWithdrawal = 48673
    /// Insufficient funds sent
    InsufficientFundsSent = 58383
}

get fun getUserInfo(userAddress: address): StakeeUser {
    throw 0;
}

get fun getTotalStaked(): int257 {
    throw 0;
}

get fun getAPY(): int257 {
    throw 0;
}

get fun getTimeStep(): int257 {
    throw 0;
}

get fun getMinFee(): int257 {
    throw 0;
}

get fun getBalance(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
