// Generated from the verified Tact contract ABI.
contract StakingPool {
    storage: StakingPoolData
    incomingMessages: StakingPoolIncomingMessage
    thrownErrors: StakingPoolErrors
}

struct (0x7362d09c) StakingPoolJettonNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0x6a3b2c22) StakingPoolJettonTransferCommitFailed {
    queryId: uint64
    amount: coins
}

struct (0x5a010010) StakingPoolIncrementTotalStake {
    queryId: uint64
    tier: uint8
    delta: coins
}

struct (0x5a010011) StakingPoolDecrementTotalStake {
    queryId: uint64
    tier: uint8
    delta: coins
}

struct (0x5a010012) StakingPoolPayRewards {
    queryId: uint64
    recipient: address
    amount: coins
}

struct (0x5a010017) StakingPoolPayUnstake {
    queryId: uint64
    recipient: address
    principal: coins
    reward: coins
}

struct (0x5a010013) StakingPoolCreditPoolBalance {
    queryId: uint64
    delta: coins
}

struct (0x5a010014) StakingPoolWireStakingMaster {
    queryId: uint64
    stakingMaster: address
}

struct (0x5a010015) StakingPoolRelayStakeFeeAccrual {
    queryId: uint64
    feeAmount: coins
}

struct StakingPoolData {
    tactSystemCell: cell
    bootstrapOwner: address
    stakingMaster: address
    jettonMinter: address
    totals: map<uint8, coins>
    pool_balance: coins
    master_wired: bool
}

type StakingPoolIncomingMessage =
    | StakingPoolJettonNotification
    | StakingPoolWireStakingMaster
    | StakingPoolRelayStakeFeeAccrual
    | StakingPoolIncrementTotalStake
    | StakingPoolDecrementTotalStake
    | StakingPoolCreditPoolBalance
    | StakingPoolPayRewards
    | StakingPoolPayUnstake
    | StakingPoolJettonTransferCommitFailed

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
    /// Incorrect balance after send
    IncorrectBalanceAfterSend = 2366
    /// Incorrect sender
    IncorrectSender = 9215
    /// Tier underflow
    TierUnderflow = 13102
    /// Only bootstrap
    OnlyBootstrap = 15314
    /// Bad reward
    BadReward = 17555
    /// Bad tier
    BadTier = 18306
    /// Fee destinations not configured
    FeeDestinationsNotConfigured = 21507
    /// Insufficient TON for payout
    InsufficientTONForPayout = 28701
    /// Insufficient amount of TON attached
    InsufficientAmountOfTONAttached = 32113
    /// Invalid fee bps
    InvalidFeeBps = 32270
    /// Only staking master
    OnlyStakingMaster = 37109
    /// Already wired
    AlreadyWired = 38186
    /// Only pool JW
    OnlyPoolJW = 38500
    /// Bad amount
    BadAmount = 40815
    /// Invalid gas params
    InvalidGasParams = 41940
    /// Fee split invariant
    FeeSplitInvariant = 42588
    /// Bad fee
    BadFee = 43422
    /// Pool master not wired
    PoolMasterNotWired = 43882
    /// Stake overflow
    StakeOverflow = 44206
    /// Bad delta
    BadDelta = 50136
    /// Bad principal
    BadPrincipal = 53797
    /// Insufficient TON for fee fanout
    InsufficientTONForFeeFanout = 54718
    /// Insufficient accounting balance
    InsufficientAccountingBalance = 60682
    /// Amount must be positive
    AmountMustBePositive = 61135
}

get fun get_staking_master(): address {
    throw 0;
}

get fun get_master_wired(): bool {
    throw 0;
}

get fun get_jetton_rewards_wallet(): address {
    throw 0;
}

get fun get_total_stake(tier: int257): int257 {
    throw 0;
}

get fun get_pool_balance(): int257 {
    throw 0;
}

get fun get_jetton_minter(): address {
    throw 0;
}
