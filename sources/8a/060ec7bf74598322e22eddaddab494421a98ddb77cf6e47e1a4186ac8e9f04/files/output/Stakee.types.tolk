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

struct StakeeStake {
    amount: coins
    timestamp: uint64
}

struct StakeeUser {
    stakes: map<int257, Cell<StakeeStake>>
    lastClaimTimestamp: uint64
    totalStaked: coins
    referrer: address?
    stakeCount: int257
    referralReward: int257
    tactContinuation: Cell<StakeeUserContinuation>
}

struct StakeeUserContinuation {
    withdrawn: int257
}

struct (0xd28aab06) StakeeReferralAddress {
    referral: address
    amount: int257
}

struct StakeeData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    users: map<address, Cell<StakeeUser>>
    dailyRoi: int257
    referralPercentage: int257
    tactContinuation: Cell<StakeeDataContinuation>
}

struct StakeeDataContinuation {
    globalTotalStaked: int257
    TIME_STEP: int257
}

type StakeeIncomingMessage =
    | StakeeReferralAddress
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
    /// Stake not found
    StakeNotFound = 2512
    /// User not found
    UserNotFound = 7177
    /// Insufficient funds sent
    InsufficientFundsSent = 58383
    /// No rewards to claim
    NoRewardsToClaim = 63475
}

get fun availableToWithdraw(userAddress: address): int257 {
    throw 0;
}

get fun getUserInfo(userAddress: address): StakeeUser? {
    throw 0;
}

get fun getTotalStaked(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
