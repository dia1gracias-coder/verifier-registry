// Generated from the verified Tact contract ABI.
contract StakingMaster {
    storage: StakingMasterData
    incomingMessages: StakingMasterIncomingMessage
    thrownErrors: StakingMasterErrors
}

struct StakingMasterPeriodConfig {
    periodId: uint8
    durationSeconds: uint32
    multiplierX100: uint16
    isActive: bool
}

struct StakingMasterMasterConfig {
    owner: address
    isPaused: bool
    stakedJettonMaster: address
    stakedJettonWallet: address?
    tactContinuation: Cell<StakingMasterMasterConfigContinuation>
}

struct StakingMasterMasterConfigContinuation {
    totalActiveWeight: uint256
    totalStakedTokens: uint256
    nextPeriodId: uint8
    storageVersion: uint32
}

struct (0x7362d09c) StakingMasterJettonTransferNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0x00000002) StakingMasterPositionFinished {
    ownerAddress: address
    stakeIndex: uint64
    weight: uint256
    rewardDebt: map<address, int257>
}

struct (0x00000003) StakingMasterSendStakedJettonToOwner {
    ownerAddress: address
    stakeIndex: uint64
    amount: coins
    queryId: uint64
}

struct (0x00000010) StakingMasterAdminSetStakedJettonWallet {
    wallet: address
}

struct (0x00000011) StakingMasterAdminAddPeriod {
    durationSeconds: uint32
    multiplierX100: uint16
}

struct (0x00000012) StakingMasterAdminUpdatePeriodStatus {
    periodId: uint8
    isActive: bool
}

struct (0x00000013) StakingMasterAdminSetPause {
    isPaused: bool
}

struct (0x00000014) StakingMasterAdminForceFinishPosition {
    queryId: uint64
    ownerAddress: address
    stakeIndex: uint64
}

struct (0x00000015) StakingMasterAdminEmergencyWithdraw {
    amount: coins
    destination: address
}

struct (0x00000016) StakingMasterAdminTransferOwnership {
    newOwner: address
}

struct (0x00000017) StakingMasterAdminAcceptOwnership {
}

struct (0x00000018) StakingMasterAdminUpgradeMasterCode {
    newCode: cell
}

struct (0x00000019) StakingMasterAdminUpgradePositionCode {
    newCode: cell
}

struct (0x0000001a) StakingMasterAdminMigrateStorage {
    newVersion: uint32
}

struct (0x0000001b) StakingMasterAdminForceWithdrawPosition {
    queryId: uint64
    ownerAddress: address
    stakeIndex: uint64
}

struct (0x0000001c) StakingMasterAdminForceReleaseLock {
    ownerAddress: address
    stakeIndex: uint64
    token: address
}

struct StakingMasterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    storageVersion: uint32
    newOwnerAddress: address?
    isPaused: bool
    stakedJettonMaster: address
    tactContinuation: Cell<StakingMasterDataContinuation>
}

struct StakingMasterDataContinuation {
    stakedJettonWallet: address?
    periods: map<int257, Cell<StakingMasterPeriodConfig>>
    nextPeriodId: uint8
    nextStakeIndex: map<address, int257>
    totalActiveWeight: uint256
    totalStakedTokens: uint256
    stakePositionCode: cell
    tactContinuation: Cell<StakingMasterDataContinuation2>
}

struct StakingMasterDataContinuation2 {
    rewardPerWeightX128: map<address, int257>
    trustedSenders: map<address, bool>
    allowedRewardJettons: map<address, bool>
    tactContinuation: Cell<StakingMasterDataContinuation3>
}

struct StakingMasterDataContinuation3 {
    rewardJettonWallets: map<address, address>
    tonRewardEnabled: bool
    totalClaimed: map<address, uint256>
    totalRewardDeposited: map<address, uint256>
}

type StakingMasterIncomingMessage =
    | StakingMasterJettonTransferNotification
    | StakingMasterPositionFinished
    | StakingMasterSendStakedJettonToOwner
    | StakingMasterAdminSetStakedJettonWallet
    | StakingMasterAdminAddPeriod
    | StakingMasterAdminUpdatePeriodStatus
    | StakingMasterAdminSetPause
    | StakingMasterAdminForceFinishPosition
    | StakingMasterAdminForceWithdrawPosition
    | StakingMasterAdminEmergencyWithdraw
    | StakingMasterAdminTransferOwnership
    | StakingMasterAdminAcceptOwnership
    | StakingMasterAdminUpgradeMasterCode
    | StakingMasterAdminUpgradePositionCode
    | StakingMasterAdminForceReleaseLock
    | StakingMasterAdminMigrateStorage

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
    /// Already initialized
    AlreadyInitialized = 2977
    /// Period does not exist
    PeriodDoesNotExist = 3180
    /// Not the pending new owner
    NotThePendingNewOwner = 6221
    /// Weight underflow
    WeightUnderflow = 6930
    /// Not initialized
    NotInitialized = 7657
    /// Only master
    OnlyMaster = 16588
    /// Claim already in progress for this token
    ClaimAlreadyInProgressForThisToken = 17716
    /// No pending ownership transfer
    NoPendingOwnershipTransfer = 25741
    /// Not in vesting
    NotInVesting = 31035
    /// Jetton wallet not configured
    JettonWalletNotConfigured = 32101
    /// Only master can init
    OnlyMasterCanInit = 34917
    /// Period is not active
    PeriodIsNotActive = 35249
    /// Invalid StakePosition sender
    InvalidStakePositionSender = 37367
    /// Staking period not over
    StakingPeriodNotOver = 37804
    /// Nothing to withdraw
    NothingToWithdraw = 40636
    /// Staking is paused
    StakingIsPaused = 41141
    /// Nothing to claim
    NothingToClaim = 44799
    /// Unauthorized: not staked jetton wallet
    UnauthorizedNotStakedJettonWallet = 45796
    /// Unauthorized
    Unauthorized = 49729
    /// Missing period_id in payload
    MissingPeriodIdInPayload = 52416
    /// Period not found
    PeriodNotFound = 54425
    /// Not active
    NotActive = 61530
}

get fun get_config(): StakingMasterMasterConfig {
    throw 0;
}

get fun get_period_config(periodId: int257): StakingMasterPeriodConfig {
    throw 0;
}

get fun get_all_periods(): map<int257, Cell<StakingMasterPeriodConfig>> {
    throw 0;
}

get fun get_total_weight(): int257 {
    throw 0;
}

get fun get_total_staked_tokens(): int257 {
    throw 0;
}

get fun get_stake_position_address(ownerAddr: address, stakeIndex: int257): address {
    throw 0;
}

get fun get_next_stake_index(ownerAddr: address): int257 {
    throw 0;
}

get fun get_storage_version(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
