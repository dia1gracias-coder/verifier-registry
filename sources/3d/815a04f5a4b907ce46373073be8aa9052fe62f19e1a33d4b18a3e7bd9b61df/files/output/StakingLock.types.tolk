// Generated from the verified Tact contract ABI.
contract StakingLock {
    storage: StakingLockData
    incomingMessages: StakingLockIncomingMessage
    thrownErrors: StakingLockErrors
}

struct StakingLockTierConfig {
    durationSeconds: uint64
    multiplier: int257
    rewardShare: int257
}

struct (0x5a030001) StakingLockSetLockDuration {
    queryId: uint64
    tier: uint8
    duration: uint64
}

struct (0x5a030002) StakingLockSetTierMultiplier {
    queryId: uint64
    tier: uint8
    multiplier: int257
}

struct (0x5a030003) StakingLockSetTierRewardShare {
    queryId: uint64
    tier: uint8
    share: int257
}

struct (0x5a030004) StakingLockSetStakingMasterForPush {
    queryId: uint64
    stakingMaster: address
}

struct (0x5a030005) StakingLockPushAllTierConfigs {
    queryId: uint64
}

struct (0x5a030006) StakingLockSetAllTierRewardShares {
    queryId: uint64
    share0: int257
    share1: int257
    share2: int257
    tactContinuation: Cell<StakingLockSetAllTierRewardSharesContinuation>
}

struct StakingLockSetAllTierRewardSharesContinuation {
    share3: int257
}

struct StakingLockData {
    timelock: address
    stakingMaster: address
    smPushWired: bool
    configs: map<int257, Cell<StakingLockTierConfig>>
}

type StakingLockIncomingMessage =
    | StakingLockSetStakingMasterForPush
    | StakingLockPushAllTierConfigs
    | StakingLockSetAllTierRewardShares
    | StakingLockSetLockDuration
    | StakingLockSetTierMultiplier
    | StakingLockSetTierRewardShare

enum StakingLockErrors {
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
    /// Low TON return
    LowTONReturn = 1631
    /// Incorrect balance after send
    IncorrectBalanceAfterSend = 2366
    /// Only timelock
    OnlyTimelock = 3095
    /// Bad share
    BadShare = 4730
    /// JW not configured
    JWNotConfigured = 6520
    /// Incorrect sender
    IncorrectSender = 9215
    /// Low TON claim
    LowTONClaim = 9981
    /// Zero effective vp
    ZeroEffectiveVp = 10204
    /// Tier underflow
    TierUnderflow = 13102
    /// Push already wired
    PushAlreadyWired = 14100
    /// Only bootstrap
    OnlyBootstrap = 15314
    /// Only staking lock
    OnlyStakingLock = 17827
    /// Bad tier
    BadTier = 18306
    /// Only master JW
    OnlyMasterJW = 20751
    /// Fee destinations not configured
    FeeDestinationsNotConfigured = 21507
    /// Push not wired
    PushNotWired = 25548
    /// Bad multiplier
    BadMultiplier = 27443
    /// No stake
    NoStake = 28115
    /// Bad payout
    BadPayout = 29572
    /// Shares must sum to 100
    SharesMustSumTo100 = 29616
    /// Governor already set
    GovernorAlreadySet = 30746
    /// Still locked
    StillLocked = 31443
    /// Insufficient amount of TON attached
    InsufficientAmountOfTONAttached = 32113
    /// Invalid fee bps
    InvalidFeeBps = 32270
    /// Only pool
    OnlyPool = 33142
    /// Only governor
    OnlyGovernor = 33186
    /// Bad amount
    BadAmount = 40815
    /// Too much
    TooMuch = 41093
    /// Missing tier cfg
    MissingTierCfg = 41383
    /// Invalid gas params
    InvalidGasParams = 41940
    /// Fee split invariant
    FeeSplitInvariant = 42588
    /// Bad fee
    BadFee = 43422
    /// Stake overflow
    StakeOverflow = 44206
    /// Nothing to claim
    NothingToClaim = 44799
    /// JW already set
    JWAlreadySet = 48567
    /// Bad delta
    BadDelta = 50136
    /// Zero claimed vp
    ZeroClaimedVp = 51621
    /// Bad principal
    BadPrincipal = 53797
    /// Insufficient TON for fee fanout
    InsufficientTONForFeeFanout = 54718
    /// Low TON unstake
    LowTONUnstake = 59611
    /// Empty stake
    EmptyStake = 60239
    /// Amount must be positive
    AmountMustBePositive = 61135
}

get fun get_lock_config(tier: int257): StakingLockTierConfig {
    throw 0;
}

get fun get_unlock_time(tier: int257, startTime: int257): int257 {
    throw 0;
}

get fun is_unlocked(tier: int257, startTime: int257, currentTime: int257): bool {
    throw 0;
}

get fun get_all_configs(): map<int257, Cell<StakingLockTierConfig>> {
    throw 0;
}

get fun get_tier_multiplier(tier: int257): int257 {
    throw 0;
}

get fun get_timelock(): address {
    throw 0;
}

get fun get_staking_master_push_target(): address {
    throw 0;
}

get fun get_sm_push_wired(): bool {
    throw 0;
}
