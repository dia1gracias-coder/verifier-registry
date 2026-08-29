// Generated from the verified Tact contract ABI.
contract StakingMaster {
    storage: StakingMasterData
    incomingMessages: StakingMasterIncomingMessage
    thrownErrors: StakingMasterErrors
}

struct (0x7362d09c) StakingMasterJettonNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0xd53276db) StakingMasterJettonExcesses {
    queryId: uint64
}

struct (0x5a040105) StakingMasterRequestTotalVpSnapshot {
    queryId: uint64
    proposalId: uint64
    proposer: address
    proposalType: uint32
    payload: cell
    period: uint64
    quorumPercent: uint16
    thresholdBps: uint16
    timelockDelay: uint64
}

struct (0x5a040019) StakingMasterGovernorVoteRelay {
    queryId: uint64
    proposal: address
    voter: address
    support: bool
    claimedVp: int257
    voteEndTime: uint64
}

struct (0x5a010018) StakingMasterEmissionReserveFunded {
    queryId: uint64
    amount: coins
}

struct (0x5a010016) StakingMasterStakeFeeRewardsAccrue {
    queryId: uint64
    feeAmount: coins
}

struct StakingMasterTierConfig {
    durationSeconds: uint64
    multiplier: int257
    rewardShare: int257
}

struct (0x5a030010) StakingMasterTierConfigSync {
    queryId: uint64
    tier: uint8
    durationSeconds: uint64
    multiplier: int257
    rewardShare: int257
}

struct (0x5a020002) StakingMasterUnstakeJetton {
    queryId: uint64
    tier: uint8
    amount: coins
}

struct (0x5a020003) StakingMasterClaimRewards {
    queryId: uint64
    tier: uint8
}

struct (0x5a020004) StakingMasterSetMasterJettonWallet {
    queryId: uint64
    wallet: address
}

struct (0x5a020005) StakingMasterSetGovernor {
    queryId: uint64
    governor: address
}

struct StakingMasterStakeInfoView {
    amount: coins
    tier: uint8
    startTime: int257
    lastClaimTime: int257
    unlockTime: int257
}

struct StakingMasterData {
    pool: address
    jettonMaster: address
    stakingLock: address
    tactContinuation: Cell<StakingMasterDataContinuation>
}

struct StakingMasterDataContinuation {
    bootstrapOwner: address
    governorAddr: address
    stakingJettonWallet: address
    jwConfigured: bool
    stakesT0: map<address, Cell<StakingMasterStakeInfoView>>
    stakesT1: map<address, Cell<StakingMasterStakeInfoView>>
    stakesT2: map<address, Cell<StakingMasterStakeInfoView>>
    tactContinuation: Cell<StakingMasterDataContinuation2>
}

struct StakingMasterDataContinuation2 {
    stakesT3: map<address, Cell<StakingMasterStakeInfoView>>
    rewardPerShare: map<uint8, int257>
    debtT0: map<address, int257>
    tactContinuation: Cell<StakingMasterDataContinuation3>
}

struct StakingMasterDataContinuation3 {
    debtT1: map<address, int257>
    debtT2: map<address, int257>
    debtT3: map<address, int257>
    tactContinuation: Cell<StakingMasterDataContinuation4>
}

struct StakingMasterDataContinuation4 {
    totalStakeByTier: map<uint8, coins>
    emissionStartTime: uint64
    lastEmitTime: uint64
    emittedSoFar: coins
    emissionFunded: coins
    tierConfigs: map<int257, Cell<StakingMasterTierConfig>>
}

type StakingMasterIncomingMessage =
    | StakingMasterJettonExcesses
    | StakingMasterSetMasterJettonWallet
    | StakingMasterSetGovernor
    | StakingMasterEmissionReserveFunded
    | StakingMasterJettonNotification
    | StakingMasterUnstakeJetton
    | StakingMasterClaimRewards
    | StakingMasterStakeFeeRewardsAccrue
    | StakingMasterGovernorVoteRelay
    | StakingMasterTierConfigSync
    | StakingMasterRequestTotalVpSnapshot

enum StakingMasterErrors {
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

get fun get_voting_power(ownerAddr: address): int257 {
    throw 0;
}

get fun get_voting_power_locked_beyond(ownerAddr: address, voteEndTime: int257): int257 {
    throw 0;
}

get fun get_total_voting_power(): int257 {
    throw 0;
}

get fun get_governor_addr(): address {
    throw 0;
}

get fun calculatePendingReward(ownerAddr: address, tier: int257): int257 {
    throw 0;
}

get fun get_pending_reward(ownerAddr: address, tier: int257): int257 {
    throw 0;
}

get fun get_reward_scale(): int257 {
    throw 0;
}

get fun get_reward_per_share(tier: int257): int257 {
    throw 0;
}

get fun get_user_reward_debt(ownerAddr: address, tier: int257): int257 {
    throw 0;
}

get fun get_master_total_stake(tier: int257): int257 {
    throw 0;
}

get fun get_pool(): address {
    throw 0;
}

get fun get_jetton_master(): address {
    throw 0;
}

get fun get_staking_lock(): address {
    throw 0;
}

get fun get_staking_jetton_wallet(): address {
    throw 0;
}

get fun get_stake(ownerAddr: address, tier: int257): StakingMasterStakeInfoView? {
    throw 0;
}

get fun get_emission_start_time(): int257 {
    throw 0;
}

get fun get_last_emit_time(): int257 {
    throw 0;
}

get fun get_emitted_so_far(): int257 {
    throw 0;
}

get fun get_total_emission_budget(): int257 {
    throw 0;
}

get fun get_emission_funded(): int257 {
    throw 0;
}

get fun get_tier_config(tier: int257): StakingMasterTierConfig {
    throw 0;
}
