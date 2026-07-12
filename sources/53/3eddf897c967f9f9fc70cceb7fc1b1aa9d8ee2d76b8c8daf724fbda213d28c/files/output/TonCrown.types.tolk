// Generated from the verified Tact contract ABI.
contract TonCrown {
    storage: TonCrownData
    incomingMessages: TonCrownIncomingMessage
    thrownErrors: TonCrownErrors
}

struct (0x946a98b6) TonCrownDeploy {
    queryId: uint64
}

struct (0x819dbe99) TonCrownChangeOwner {
    queryId: uint64
    newOwner: address
}

struct TonCrownStakeInfo {
    stakeId: uint16
    amount: coins
    startTime: uint32
    duration: uint32
    vipClass: uint8
    autoRestake: bool
    lastClaim: uint32
    totalClaimed: coins
    isActive: bool
    stakedAsset: uint8
}

struct TonCrownStakeDetails {
    stakeId: uint16
    amount: coins
    startTime: uint32
    duration: uint32
    vipClass: uint8
    autoRestake: bool
    lastClaim: uint32
    totalClaimed: coins
    isActive: bool
    stakedAsset: uint8
    pendingReward: coins
}

struct TonCrownUserReferralInfo {
    referrer: address?
    directReferrals: uint16
    totalReferrals: uint32
    downlines: map<int257, address>
}

struct TonCrownUser {
    referrer: address?
    level: uint8
    vipClass: uint8
    directReferrals: uint16
    totalReferrals: uint32
    otherReferrals: uint32
    lastCheckIn: uint32
    levelExpiration: uint32
    totalEarned: coins
    isActive: bool
    registrationTime: uint32
    stakeCounter: uint16
    stakes: map<int257, Cell<TonCrownStakeInfo>>
    downlines: map<int257, address>
    spilloverIndex: uint16
    pendingCheckInRewards: coins
    totalCheckInEarned: coins
    totalCheckInClaimed: coins
    tactContinuation: Cell<TonCrownUserContinuation>
}

struct TonCrownUserContinuation {
    totalStakingClaimed: coins
    totalReferralEarned: coins
    totalSpilloverEarned: coins
    transactionCounter: uint32
    transactions: map<int257, Cell<TonCrownUserTransaction>>
}

struct TonCrownVipConfig {
    dailyRoi: uint16
    minLevel: uint8
    maxLevel: uint8
    stakingRoi: uint16
}

struct TonCrownPlatformStats {
    totalUsers: uint32
    totalStakedTon: coins
    totalStakedUsdt: coins
    totalDistributed: coins
    activeStakes: uint32
}

struct (0xb1e83451) TonCrownUpgradeLevel {
    targetLevel: uint8
    referrerAddress: address?
}

struct (0x37517518) TonCrownCheckIn {
}

struct (0xfcb606f5) TonCrownStakeTON {
    duration: uint32
    autoRestake: bool
    referrerAddress: address?
}

struct (0x653755ce) TonCrownClaimStakingRewards {
    stakeId: uint16
}

struct (0xc83f56c2) TonCrownUpdateAutoRestake {
    stakeId: uint16
    autoRestake: bool
}

struct (0x7362d09c) TonCrownJettonTransferNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0xf579295f) TonCrownDistributeDailyRewards {
    user: address
    stakeId: uint16
}

struct (0xe3b5e901) TonCrownUpdateLevelCost {
    level: uint8
    cost: coins
}

struct (0xa4e0c362) TonCrownSetUsdtJettonWallet {
    wallet: address
}

struct (0xbd834305) TonCrownSetDistributor {
    address: address
}

struct (0xe3226426) TonCrownOwnerDeposit {
}

struct (0xf16b8c67) TonCrownOwnerWithdraw {
    amount: coins
}

struct (0x5ca2ca0b) TonCrownClaimCheckInRewards {
}

struct TonCrownUserTransaction {
    txId: uint32
    timestamp: uint32
    txType: uint8
    amount: coins
    level: uint8
    stakeId: uint16
    assetType: uint8
    counterparty: address?
    description: string
}

struct TonCrownUserEarningsInfo {
    totalEarned: coins
    pendingCheckInRewards: coins
    totalCheckInEarned: coins
    totalCheckInClaimed: coins
    totalStakingClaimed: coins
    pendingStakingRewards: coins
    totalReferralEarned: coins
    totalSpilloverEarned: coins
    tactContinuation: Cell<TonCrownUserEarningsInfoContinuation>
}

struct TonCrownUserEarningsInfoContinuation {
    totalClaimable: coins
}

struct TonCrownPlatformEarningsInfo {
    totalUsers: uint32
    totalStakedTon: coins
    totalStakedUsdt: coins
    totalDistributed: coins
    totalCheckInRewardsAccrued: coins
    totalCheckInRewardsClaimed: coins
    totalReferralRewardsPaid: coins
    totalSpilloverRewardsPaid: coins
    tactContinuation: Cell<TonCrownPlatformEarningsInfoContinuation>
}

struct TonCrownPlatformEarningsInfoContinuation {
    totalCreatorRewardsPaid: coins
    totalUnclaimedCheckInRewards: coins
    activeStakes: uint32
    contractBalance: coins
}

struct TonCrownUserStakeSummary {
    totalStakes: uint16
    activeStakes: uint16
    inactiveStakes: uint16
    pendingStakingRewards: coins
}

struct TonCrownData {
    tactDeploymentCompleted: bool
    owner: address
    creatorWallet1: address
    creatorWallet2: address
    tactContinuation: Cell<TonCrownDataContinuation>
}

struct TonCrownDataContinuation {
    creatorWallet3: address
    creatorWallet4: address
    usdtJettonWalletAddress: address
    tactContinuation: Cell<TonCrownDataContinuation2>
}

struct TonCrownDataContinuation2 {
    distributorAddress: address
    users: map<address, Cell<TonCrownUser>>
    levelCosts: map<int257, int257>
    vipConfigs: map<int257, Cell<TonCrownVipConfig>>
    totalUsers: uint32
    totalStakedTon: coins
    totalStakedUsdt: coins
    totalDistributed: coins
    activeStakes: uint32
    isPaused: bool
    tactContinuation: Cell<TonCrownDataContinuation3>
}

struct TonCrownDataContinuation3 {
    userList: map<int257, address>
    spilloverNextIndexByBoughtLevel: map<int257, int257>
    totalCheckInRewardsAccrued: coins
    totalCheckInRewardsClaimed: coins
    totalReferralRewardsPaid: coins
    totalSpilloverRewardsPaid: coins
    totalCreatorRewardsPaid: coins
}

type TonCrownIncomingMessage =
    | TonCrownUpgradeLevel
    | TonCrownCheckIn
    | TonCrownClaimCheckInRewards
    | TonCrownStakeTON
    | TonCrownJettonTransferNotification
    | TonCrownClaimStakingRewards
    | TonCrownDistributeDailyRewards
    | TonCrownUpdateAutoRestake
    | TonCrownUpdateLevelCost
    | TonCrownSetUsdtJettonWallet
    | TonCrownSetDistributor
    | TonCrownOwnerDeposit
    | TonCrownOwnerWithdraw
    | TonCrownDeploy
    | TonCrownChangeOwner

enum TonCrownErrors {
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
    /// Stake not found
    StakeNotFound = 2512
    /// Insufficient check-in gas
    InsufficientCheckInGas = 3215
    /// Must upgrade sequentially
    MustUpgradeSequentially = 4639
    /// VIP status required for staking
    VIPStatusRequiredForStaking = 12510
    /// Invalid level
    InvalidLevel = 12835
    /// Already checked in today
    AlreadyCheckedInToday = 13250
    /// Contract is paused
    ContractIsPaused = 19792
    /// Stake amount below minimum
    StakeAmountBelowMinimum = 22945
    /// Reward below distribution fee
    RewardBelowDistributionFee = 23706
    /// Level 1 check-in period has ended
    Level1CheckInPeriodHasEnded = 29745
    /// Invalid staking duration
    InvalidStakingDuration = 35448
    /// Insufficient claim gas
    InsufficientClaimGas = 40569
    /// Stake inactive
    StakeInactive = 40919
    /// Not authorized
    NotAuthorized = 42435
    /// Unknown jetton wallet
    UnknownJettonWallet = 43382
    /// Invalid duration
    InvalidDuration = 45702
    /// Insufficient value for staking gas
    InsufficientValueForStakingGas = 51169
    /// Invalid cost
    InvalidCost = 53663
    /// No rewards yet
    NoRewardsYet = 54159
    /// Insufficient contract balance
    InsufficientContractBalance = 55591
    /// No check-in rewards to claim
    NoCheckInRewardsToClaim = 57153
    /// User not registered
    UserNotRegistered = 57406
    /// No active stake
    NoActiveStake = 59270
    /// Insufficient balance after reserve
    InsufficientBalanceAfterReserve = 59701
    /// Must have an active level to check in
    MustHaveAnActiveLevelToCheckIn = 60790
    /// Insufficient payment for level and gas
    InsufficientPaymentForLevelAndGas = 63423
}

get fun getUserInfo(userAddress: address): TonCrownUser? {
    throw 0;
}

get fun getPlatformStats(): TonCrownPlatformStats {
    throw 0;
}

get fun getUserAddressByIndex(index: int257): address? {
    throw 0;
}

get fun getUserStakeIds(userAddress: address): map<int257, bool> {
    throw 0;
}

get fun getStakeDetails(userAddress: address, stakeId: int257): TonCrownStakeDetails? {
    throw 0;
}

get fun getUserReferralInfo(userAddress: address): TonCrownUserReferralInfo? {
    throw 0;
}

get fun getUserEarningsInfo(userAddress: address): TonCrownUserEarningsInfo? {
    throw 0;
}

get fun getUserStakeSummary(userAddress: address): TonCrownUserStakeSummary {
    throw 0;
}

get fun getPlatformEarningsInfo(): TonCrownPlatformEarningsInfo {
    throw 0;
}

get fun getUserTransaction(userAddress: address, txId: int257): TonCrownUserTransaction? {
    throw 0;
}

get fun getUserTransactionCount(userAddress: address): int257 {
    throw 0;
}

get fun getUserTransactionsPaginated(userAddress: address, start: int257, limit: int257): map<int257, Cell<TonCrownUserTransaction>> {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
