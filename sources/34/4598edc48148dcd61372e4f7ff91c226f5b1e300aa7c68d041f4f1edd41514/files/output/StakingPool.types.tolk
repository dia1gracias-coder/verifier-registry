// Generated from the verified Tact contract ABI.
contract StakingPool {
    storage: StakingPoolData
    incomingMessages: StakingPoolIncomingMessage
    thrownErrors: StakingPoolErrors
}

struct (0x946a98b6) StakingPoolDeploy {
    queryId: uint64
}

struct (0x52c96770) StakingPoolDeposit {
    referrer: address
}

struct (0xe23f5938) StakingPoolClaimDepositRewards {
}

struct (0xbe1052b1) StakingPoolClaimReferralRewards {
}

struct (0x47b96725) StakingPoolWithdrawDeposit {
    depositId: uint32
}

struct (0x7a4508d9) StakingPoolPause {
}

struct (0x8dcb2d19) StakingPoolUnpause {
}

struct (0xf9de2729) StakingPoolSetWalletA {
    walletA: address
}

struct (0xc694cae1) StakingPoolSetWalletB {
    walletB: address
}

struct (0xeef920a3) StakingPoolSetClaimMode {
    partialPayoutMode: bool
}

struct (0x9d641ba9) StakingPoolEmergencyWithdraw {
    destination: address
}

struct StakingPoolUser {
    referrer: address
    totalDeposited: coins
    totalWithdrawn: coins
    referralRewards: coins
    totalReferralEarned: coins
    depositDebt: coins
    activeDepositCount: uint32
    level0Count: uint32
    level1Count: uint32
    level2Count: uint32
    tactContinuation: Cell<StakingPoolUserContinuation>
}

struct StakingPoolUserContinuation {
    level3Count: uint32
    level4Count: uint32
}

struct StakingPoolDepositInfo {
    owner: address
    amount: coins
    start: uint32
    lastClaim: uint32
    expiry: uint32
}

struct StakingPoolContractStats {
    totalUsers: uint32
    totalDeposited: coins
    totalPaidOut: coins
    totalReferralPaid: coins
    availableLiquidity: coins
    contractBalance: coins
    partialPayoutMode: bool
}

struct StakingPoolUserInfoResponse {
    referrer: address
    totalDeposited: coins
    totalWithdrawn: coins
    referralRewards: coins
    totalReferralEarned: coins
    depositDebt: coins
    pendingDepositRewards: coins
    tactContinuation: Cell<StakingPoolUserInfoResponseContinuation>
}

struct StakingPoolUserInfoResponseContinuation {
    activeDepositCount: uint32
}

struct StakingPoolData {
    tactDeploymentCompleted: bool
    owner: address
    walletA: address
    walletB: address
    paused: bool
    partialPayoutMode: bool
    minDeposit: coins
    tactContinuation: Cell<StakingPoolDataContinuation>
}

struct StakingPoolDataContinuation {
    maxDeposit: coins
    minClaim: coins
    dailyRoiBps: uint16
    rewardDurationSeconds: uint32
    referralPercent0: uint16
    referralPercent1: uint16
    referralPercent2: uint16
    referralPercent3: uint16
    referralPercent4: uint16
    totalUsers: uint32
    totalDeposited: coins
    totalPaidOut: coins
    totalReferralPaid: coins
    totalClaimed: coins
    nextDepositId: uint32
    users: map<address, Cell<StakingPoolUser>>
    deposits: map<int257, Cell<StakingPoolDepositInfo>>
}

type StakingPoolIncomingMessage =
    | StakingPoolDeposit
    | StakingPoolClaimDepositRewards
    | StakingPoolClaimReferralRewards
    | StakingPoolWithdrawDeposit
    | StakingPoolPause
    | StakingPoolUnpause
    | StakingPoolSetWalletA
    | StakingPoolSetWalletB
    | StakingPoolSetClaimMode
    | StakingPoolEmergencyWithdraw
    | StakingPoolDeploy

enum StakingPoolErrors {
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
    /// 'Unknown' error
    UnknownError = 11
    /// Fatal error
    FatalError = 12
    /// Out of gas error
    OutOfGasError = 13
    /// Virtualization error
    VirtualizationError = 14
    /// Action list is invalid
    ActionListIsInvalid = 32
    /// Action list is too long
    ActionListIsTooLong = 33
    /// Action is invalid or not supported
    ActionIsInvalidOrNotSupported = 34
    /// Invalid source address in outbound message
    InvalidSourceAddressInOutboundMessage = 35
    /// Invalid destination address in outbound message
    InvalidDestinationAddressInOutboundMessage = 36
    /// Not enough Toncoin
    NotEnoughToncoin = 37
    /// Not enough extra currencies
    NotEnoughExtraCurrencies = 38
    /// Outbound message does not fit into a cell after rewriting
    OutboundMessageDoesNotFitIntoACellAfterRewriting = 39
    /// Cannot process a message
    CannotProcessAMessage = 40
    /// Library reference is null
    LibraryReferenceIsNull = 41
    /// Library change action error
    LibraryChangeActionError = 42
    /// Exceeded maximum number of cells in the library or the maximum depth of the Merkle tree
    ExceededMaximumNumberOfCellsInTheLibraryOrTheMaximumDepthOfTheMerkleTree = 43
    /// Account state size exceeded limits
    AccountStateSizeExceededLimits = 50
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
    /// Invalid standard address
    InvalidStandardAddress = 136
    /// Not a basechain address
    NotABasechainAddress = 138
    /// Deposit above maximum
    DepositAboveMaximum = 7024
    /// Daily ROI too high
    DailyROITooHigh = 13173
    /// Not deposit owner
    NotDepositOwner = 14657
    /// Deposit not matured
    DepositNotMatured = 19325
    /// Deposit not found
    DepositNotFound = 19599
    /// Max deposit must be >= min deposit
    MaxDepositMustBeMinDeposit = 30330
    /// Insufficient liquidity for withdrawal
    InsufficientLiquidityForWithdrawal = 33237
    /// Deposit reward below minimum claim
    DepositRewardBelowMinimumClaim = 34735
    /// Min deposit must be >= 1 TON
    MinDepositMustBe1TON = 40547
    /// Min claim must be >= 1 TON
    MinClaimMustBe1TON = 52289
    /// Referral reward below minimum claim
    ReferralRewardBelowMinimumClaim = 53218
    /// Contract paused
    ContractPaused = 53793
    /// Deposit below minimum
    DepositBelowMinimum = 54981
    /// Insufficient liquidity
    InsufficientLiquidity = 60783
}

get fun contractStats(): StakingPoolContractStats {
    throw 0;
}

get fun getUserInfo(account: address): StakingPoolUserInfoResponse {
    throw 0;
}

get fun pendingRewards(account: address): int257 {
    throw 0;
}

get fun pendingReferralRewards(account: address): int257 {
    throw 0;
}

get fun getDepositInfo(depositId: int257): StakingPoolDepositInfo {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
