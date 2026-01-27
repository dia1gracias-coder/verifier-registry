// Generated from the verified Tact contract ABI.
contract GamifyUnified {
    storage: GamifyUnifiedData
    incomingMessages: GamifyUnifiedIncomingMessage
    thrownErrors: GamifyUnifiedErrors
}

struct (0x946a98b6) GamifyUnifiedDeploy {
    queryId: uint64
}

struct (0xbdef266e) GamifyUnifiedAddAdmin {
    admin: address
}

struct (0xca0c3e01) GamifyUnifiedRemoveAdmin {
    admin: address
}

struct (0xf9ded7cb) GamifyUnifiedAddBackendSigner {
    signer: address
}

struct (0xd7c72418) GamifyUnifiedRemoveBackendSigner {
    signer: address
}

struct (0x0bcb187f) GamifyUnifiedDistributeLeaderboard {
    day: uint64
    recipients: map<address, coins>
}

struct (0x621ef0db) GamifyUnifiedPurchaseSubscription {
}

struct (0xf551d33a) GamifyUnifiedGrantSubscription {
    user: address
    days: uint32
}

struct (0x083c4acd) GamifyUnifiedRevokeSubscription {
    user: address
}

struct (0x70373fea) GamifyUnifiedTransferOwnership {
    newOwner: address
}

struct (0x27e60a88) GamifyUnifiedWithdraw {
    to: address
    amount: coins
}

struct (0xdd01ae2c) GamifyUnifiedWithdrawAll {
}

struct (0x1406afd3) GamifyUnifiedWithdrawSafe {
}

struct (0x82833e3f) GamifyUnifiedWithdrawFromVault {
    amount: coins
    recipient: address?
}

struct (0x6a0848d7) GamifyUnifiedSetTreasuryWallet {
    treasury: address
}

struct (0x7a4508d9) GamifyUnifiedPause {
}

struct (0x8dcb2d19) GamifyUnifiedUnpause {
}

struct GamifyUnifiedSubscriptionData {
    startDay: uint64
    startTimestamp: uint64
    totalDays: uint32
    remainingDays: uint32
}

struct GamifyUnifiedDistributionInfo {
    totalPool: coins
    leaderboardPool: coins
    backendPool: coins
    userCount: uint16
    timestamp: uint64
}

struct GamifyUnifiedSubscriptionSummary {
    active: bool
    startDay: uint64
    startTimestamp: uint64
    expiryTimestamp: uint64
    totalDays: uint32
    remainingDays: uint32
}

struct GamifyUnifiedPricingInfo {
    pricePerDay: coins
}

struct GamifyUnifiedDistributionInfoResult {
    totalPool: coins
    leaderboardPool: coins
    backendPool: coins
    userCount: uint16
    timestamp: uint64
}

struct GamifyUnifiedRewardsInfo {
    totalRewardsDistributed: coins
    totalBackendFees: coins
}

struct GamifyUnifiedStatistics {
    totalSubscriptionsGranted: uint64
    totalSubscriptionRevenue: coins
    totalRewardsDistributed: coins
    totalBackendFees: coins
    activeSubscriptionsCount: uint32
}

struct GamifyUnifiedAvailablePool {
    availablePool: coins
    safeGasReserve: coins
    totalGasReserve: coins
}

struct GamifyUnifiedDayInfo {
    day: uint64
    poolBalance: coins
    isDistributed: bool
    activeCount: uint32
    distributionInfo: GamifyUnifiedDistributionInfoResult
    treasuryAddress: address?
}

struct GamifyUnifiedActiveSubscribersListResult {
    totalCount: uint32
    addresses: map<uint32, address>
}

struct GamifyUnifiedData {
    tactDeploymentCompleted: bool
    owner: address
    isPaused: bool
    admins: map<address, bool>
    tactContinuation: Cell<GamifyUnifiedDataContinuation>
}

struct GamifyUnifiedDataContinuation {
    backendSigners: map<address, bool>
    subscriptions: map<address, Cell<GamifyUnifiedSubscriptionData>>
    activeSubscriptionsCount: uint32
    totalSubscriptionsGranted: uint64
    totalSubscriptionRevenue: coins
    activeSubscribersList: map<uint32, address>
    activeSubscribersListLength: uint32
    tactContinuation: Cell<GamifyUnifiedDataContinuation2>
}

struct GamifyUnifiedDataContinuation2 {
    activeSubscriberIndex: map<address, uint32>
    distributedDays: map<uint64, bool>
    dailyActiveCounts: map<uint64, uint32>
    tactContinuation: Cell<GamifyUnifiedDataContinuation3>
}

struct GamifyUnifiedDataContinuation3 {
    dailyPoolBalances: map<uint64, coins>
    distributionInfo: map<uint64, Cell<GamifyUnifiedDistributionInfo>>
    totalRewardsDistributed: coins
    totalBackendFees: coins
    vaultBalance: coins
    treasuryWallet: address?
}

type GamifyUnifiedIncomingMessage =
    | GamifyUnifiedPurchaseSubscription
    | GamifyUnifiedGrantSubscription
    | GamifyUnifiedRevokeSubscription
    | GamifyUnifiedDistributeLeaderboard
    | GamifyUnifiedAddAdmin
    | GamifyUnifiedRemoveAdmin
    | GamifyUnifiedAddBackendSigner
    | GamifyUnifiedRemoveBackendSigner
    | GamifyUnifiedTransferOwnership
    | GamifyUnifiedWithdraw
    | GamifyUnifiedWithdrawAll
    | GamifyUnifiedWithdrawSafe
    | GamifyUnifiedWithdrawFromVault
    | GamifyUnifiedSetTreasuryWallet
    | GamifyUnifiedPause
    | GamifyUnifiedUnpause
    | GamifyUnifiedDeploy

enum GamifyUnifiedErrors {
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
    /// No pool balance for this day
    NoPoolBalanceForThisDay = 2980
    /// New owner must be different from current owner
    NewOwnerMustBeDifferentFromCurrentOwner = 5365
    /// Day already distributed
    DayAlreadyDistributed = 7541
    /// Distribution amount must be greater than zero
    DistributionAmountMustBeGreaterThanZero = 8501
    /// Invalid amount
    InvalidAmount = 17062
    /// Unauthorized: admin required
    UnauthorizedAdminRequired = 18809
    /// Contract is paused
    ContractIsPaused = 19792
    /// Invalid days
    InvalidDays = 20405
    /// Insufficient vault balance
    InsufficientVaultBalance = 25623
    /// Unauthorized: backend signer required
    UnauthorizedBackendSignerRequired = 33142
    /// Days must be greater than zero
    DaysMustBeGreaterThanZero = 44680
    /// Insufficient payment - minimum is 0.2 TON per day
    InsufficientPaymentMinimumIs02TONPerDay = 44733
    /// Day too old - cannot distribute days older than 1 year
    DayTooOldCannotDistributeDaysOlderThan1Year = 45807
    /// No recipients
    NoRecipients = 46188
    /// Insufficient contract balance for distribution (including gas)
    InsufficientContractBalanceForDistributionIncludingGas = 48855
    /// Total distribution cannot exceed pool balance
    TotalDistributionCannotExceedPoolBalance = 48922
    /// Unauthorized: admin or backend required
    UnauthorizedAdminOrBackendRequired = 52300
    /// Insufficient balance
    InsufficientBalance = 54615
    /// Total amount must be positive
    TotalAmountMustBePositive = 54957
    /// Cannot distribute future days
    CannotDistributeFutureDays = 55886
    /// Days cannot exceed maximum (3650 days)
    DaysCannotExceedMaximum3650Days = 56721
    /// Too many recipients
    TooManyRecipients = 58172
    /// Cannot deallocate more pool than allocated
    CannotDeallocateMorePoolThanAllocated = 61279
    /// Insufficient payment for at least 1 day
    InsufficientPaymentForAtLeast1Day = 62652
}

get fun getCurrentDay(): int257 {
    throw 0;
}

get fun getCurrentTimestamp(): int257 {
    throw 0;
}

get fun getSubscriptionSummary(user: address): GamifyUnifiedSubscriptionSummary {
    throw 0;
}

get fun isSubscribed(user: address): bool {
    throw 0;
}

get fun getStartDay(user: address): int257 {
    throw 0;
}

get fun getStartTimestamp(user: address): int257 {
    throw 0;
}

get fun getExpiryTimestamp(user: address): int257 {
    throw 0;
}

get fun getTotalDays(user: address): int257 {
    throw 0;
}

get fun getRemainingDays(user: address): int257 {
    throw 0;
}

get fun getTotalSubscriptionsGrantedRaw(): int257 {
    throw 0;
}

get fun getDistributionTimestamp(day: int257): int257 {
    throw 0;
}

get fun isAdmin(address: address): bool {
    throw 0;
}

get fun isBackendSigner(address: address): bool {
    throw 0;
}

get fun getPricingInfo(): GamifyUnifiedPricingInfo {
    throw 0;
}

get fun getTotalRevenue(): int257 {
    throw 0;
}

get fun getTotalSubscriptionsGranted(): int257 {
    throw 0;
}

get fun getIsPaused(): bool {
    throw 0;
}

get fun getActiveSubscriptionsCount(): int257 {
    throw 0;
}

get fun getActiveSubscribersList(offset: int257, limit: int257): GamifyUnifiedActiveSubscribersListResult {
    throw 0;
}

get fun getActiveCountForDay(day: int257): int257 {
    throw 0;
}

get fun getDailyPoolBalanceForDay(day: int257): int257 {
    throw 0;
}

get fun isDayDistributed(day: int257): bool {
    throw 0;
}

get fun getDistributionInfo(day: int257): GamifyUnifiedDistributionInfoResult {
    throw 0;
}

get fun getTreasuryWallet(): address? {
    throw 0;
}

get fun getDayInfo(day: int257): GamifyUnifiedDayInfo {
    throw 0;
}

get fun getTotalRewardsInfo(): GamifyUnifiedRewardsInfo {
    throw 0;
}

get fun getVaultBalance(): int257 {
    throw 0;
}

get fun getOwner(): address {
    throw 0;
}

get fun getStatistics(): GamifyUnifiedStatistics {
    throw 0;
}

get fun getContractBalance(): int257 {
    throw 0;
}

get fun hasSufficientGas(): bool {
    throw 0;
}

get fun getAvailablePool(userCount: int257): GamifyUnifiedAvailablePool {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
