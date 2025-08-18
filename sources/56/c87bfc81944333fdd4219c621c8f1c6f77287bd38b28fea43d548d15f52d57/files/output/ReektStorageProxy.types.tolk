// Generated from the verified Tact contract ABI.
contract ReektStorageProxy {
    storage: ReektStorageProxyData
    incomingMessages: ReektStorageProxyDeploy
    thrownErrors: ReektStorageProxyErrors
}

struct (0x946a98b6) ReektStorageProxyDeploy {
    queryId: uint64
}

struct ReektStorageProxyKeysView {
    adminPublicKey: int257
    serverPublicKey: int257
}

struct ReektStorageProxyFinancialView {
    poolLiquidity: int257
}

struct ReektStorageProxyConfigView {
    maxBetPercent: int257
    maxPayoutPercent: int257
    withdrawalFeePercent: int257
    tactContinuation: Cell<ReektStorageProxyConfigViewContinuation>
}

struct ReektStorageProxyConfigViewContinuation {
    affiliateCommissionPercent: int257
    refundFeePercent: int257
}

struct ReektStorageProxySystemView {
    isPaused: bool
}

struct ReektStorageProxyStorageKeys {
    adminPublicKey: int257
    serverPublicKey: int257
    serverNonce: int257
    tactContinuation: Cell<ReektStorageProxyStorageKeysContinuation>
}

struct ReektStorageProxyStorageKeysContinuation {
    adminNonce: int257
}

struct ReektStorageProxyStorageFinancial {
    minReserve: int257
    houseBalance: int257
    poolLiquidity: int257
    tactContinuation: Cell<ReektStorageProxyStorageFinancialContinuation>
}

struct ReektStorageProxyStorageFinancialContinuation {
    reservedExposure: int257
    adminCommittedOutstanding: int257
    affiliatePot: int257
}

struct ReektStorageProxyStorageConfig {
    maxBetPercent: int257
    maxPayoutPercent: int257
    withdrawalFeePercent: int257
    tactContinuation: Cell<ReektStorageProxyStorageConfigContinuation>
}

struct ReektStorageProxyStorageConfigContinuation {
    affiliateCommissionPercent: int257
    refundFeePercent: int257
}

struct ReektStorageProxyStorageDicts {
    users: map<address, cell>
    games: map<int257, cell>
}

struct ReektStorageProxyHealthReport {
    healthLevel: int257
    daysCovered: int257
    annualStorageCost: int257
    message: cell
}

struct ReektStorageProxyGameStatistics {
    total: int257
    active: int257
    won: int257
    tactContinuation: Cell<ReektStorageProxyGameStatisticsContinuation>
}

struct ReektStorageProxyGameStatisticsContinuation {
    lost: int257
}

struct ReektStorageProxyPoolLiquidityStatus {
    poolLiquidity: int257
    committed: int257
    available: int257
    tactContinuation: Cell<ReektStorageProxyPoolLiquidityStatusContinuation>
}

struct ReektStorageProxyPoolLiquidityStatusContinuation {
    totalBalance: int257
    adminCommittedOutstanding: int257
}

struct ReektStorageProxyBetOptionsView {
    min: int257
    third: int257
    half: int257
    tactContinuation: Cell<ReektStorageProxyBetOptionsViewContinuation>
}

struct ReektStorageProxyBetOptionsViewContinuation {
    max: int257
    quant: int257
}

struct ReektStorageProxyProxyInfo {
    logicAddress: address
    adminPublicKey: int257
    serverPublicKey: int257
    isPaused: bool
}

struct ReektStorageProxyContractInfo {
    totalBalance: int257
    houseBalance: int257
    poolLiquidity: int257
    tactContinuation: Cell<ReektStorageProxyContractInfoContinuation>
}

struct ReektStorageProxyContractInfoContinuation {
    minReserve: int257
    isPaused: bool
    nextGameId: int257
}

struct ReektStorageProxyNonceStatus {
    serverNonce: int257
    adminNonce: int257
}

struct ReektStorageProxyEnhancedFinancialHealth {
    balance: int257
    houseBalance: int257
    poolLiquidity: int257
    tactContinuation: Cell<ReektStorageProxyEnhancedFinancialHealthContinuation>
}

struct ReektStorageProxyEnhancedFinancialHealthContinuation {
    availableForPayouts: int257
    storageCost: int257
    reserveMargin: int257
    tactContinuation: Cell<ReektStorageProxyEnhancedFinancialHealthContinuation2>
}

struct ReektStorageProxyEnhancedFinancialHealthContinuation2 {
    affiliateLiability: int257
}

struct ReektStorageProxyPruningRecommendations {
    prunableGames: int257
    estimatedStorageSavings: int257
    totalGames: int257
}

struct ReektStorageProxyGameAgeDistribution {
    age0to30: int257
    age31to90: int257
    age91to180: int257
    tactContinuation: Cell<ReektStorageProxyGameAgeDistributionContinuation>
}

struct ReektStorageProxyGameAgeDistributionContinuation {
    age180plus: int257
}

struct ReektStorageProxyGameSession {
    player: address
    betAmount: int257
    hashCommitment: cell
    createdAt: int257
    tactContinuation: Cell<ReektStorageProxyGameSessionContinuation>
}

struct ReektStorageProxyGameSessionContinuation {
    status: int257
    payoutAmount: int257
    multiplier: int257
    tactContinuation: Cell<ReektStorageProxyGameSessionContinuation2>
}

struct ReektStorageProxyGameSessionContinuation2 {
    maxPayoutForGame: int257
    moves: cell
    gameConfig: cell
    gameSeed: cell
    tactContinuation: Cell<ReektStorageProxyGameSessionContinuation3>
}

struct ReektStorageProxyGameSessionContinuation3 {
    gameSalt: cell
    finalGameState: cell
}

struct ReektStorageProxyWithdrawalRecord {
    gameId: int257
    date: int257
    amount: int257
}

struct ReektStorageProxyWithdrawalsPage {
    count: int257
    items: cell
}

struct ReektStorageProxyWithdrawalsTypedPage10 {
    count: int257
    tactContinuation: Cell<ReektStorageProxyWithdrawalsTypedPage10Continuation>
}

struct ReektStorageProxyWithdrawalsTypedPage10Continuation {
    r1: ReektStorageProxyWithdrawalRecord
    tactContinuation: Cell<ReektStorageProxyWithdrawalsTypedPage10Continuation2>
}

struct ReektStorageProxyWithdrawalsTypedPage10Continuation2 {
    r2: ReektStorageProxyWithdrawalRecord
    tactContinuation: Cell<ReektStorageProxyWithdrawalsTypedPage10Continuation3>
}

struct ReektStorageProxyWithdrawalsTypedPage10Continuation3 {
    r3: ReektStorageProxyWithdrawalRecord
    tactContinuation: Cell<ReektStorageProxyWithdrawalsTypedPage10Continuation4>
}

struct ReektStorageProxyWithdrawalsTypedPage10Continuation4 {
    r4: ReektStorageProxyWithdrawalRecord
    tactContinuation: Cell<ReektStorageProxyWithdrawalsTypedPage10Continuation5>
}

struct ReektStorageProxyWithdrawalsTypedPage10Continuation5 {
    r5: ReektStorageProxyWithdrawalRecord
    tactContinuation: Cell<ReektStorageProxyWithdrawalsTypedPage10Continuation6>
}

struct ReektStorageProxyWithdrawalsTypedPage10Continuation6 {
    r6: ReektStorageProxyWithdrawalRecord
    tactContinuation: Cell<ReektStorageProxyWithdrawalsTypedPage10Continuation7>
}

struct ReektStorageProxyWithdrawalsTypedPage10Continuation7 {
    r7: ReektStorageProxyWithdrawalRecord
    tactContinuation: Cell<ReektStorageProxyWithdrawalsTypedPage10Continuation8>
}

struct ReektStorageProxyWithdrawalsTypedPage10Continuation8 {
    r8: ReektStorageProxyWithdrawalRecord
    tactContinuation: Cell<ReektStorageProxyWithdrawalsTypedPage10Continuation9>
}

struct ReektStorageProxyWithdrawalsTypedPage10Continuation9 {
    r9: ReektStorageProxyWithdrawalRecord
    tactContinuation: Cell<ReektStorageProxyWithdrawalsTypedPage10Continuation10>
}

struct ReektStorageProxyWithdrawalsTypedPage10Continuation10 {
    r10: ReektStorageProxyWithdrawalRecord
}

struct ReektStorageProxyStorage {
    version: int257
    initialized: bool
    logicAddress: address
    upgradeProposed: bool
    proposedLogic: address
    tactContinuation: Cell<ReektStorageProxyStorageContinuation>
}

struct ReektStorageProxyStorageContinuation {
    proposedCodeHash: int257
    upgradeEta: int257
    isPaused: bool
    nextGameId: int257
    tactContinuation: Cell<ReektStorageProxyStorageContinuation2>
}

struct ReektStorageProxyStorageContinuation2 {
    keys: ReektStorageProxyStorageKeys
    tactContinuation: Cell<ReektStorageProxyStorageContinuation3>
}

struct ReektStorageProxyStorageContinuation3 {
    financial: ReektStorageProxyStorageFinancial
    tactContinuation: Cell<ReektStorageProxyStorageContinuation4>
}

struct ReektStorageProxyStorageContinuation4 {
    config: ReektStorageProxyStorageConfig
    dicts: ReektStorageProxyStorageDicts
    tactContinuation: Cell<ReektStorageProxyStorageContinuation5>
}

struct ReektStorageProxyStorageContinuation5 {
    affiliateRegistryRoot: int257
    currentAffEpoch: int257
    affEarningsRoots: map<int257, int257>
    usedClaims: map<int257, int257>
    activeGamesRoot: int257
    gameEpochRoots: map<int257, int257>
}

struct ReektStorageProxyData {
    tactDeploymentCompleted: bool
    storage: ReektStorageProxyStorage
}

enum ReektStorageProxyErrors {
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
}

get fun verifyAffiliateBundle(code: cell, addr: address, pubKey: int257, bannedBit: int257, index: int257, proof: cell): bool {
    throw 0;
}

get fun getIsPaused(): ReektStorageProxySystemView {
    throw 0;
}

get fun getKeysView(): ReektStorageProxyKeysView {
    throw 0;
}

get fun getPoolLiquidity(): ReektStorageProxyFinancialView {
    throw 0;
}

get fun getBetOptions(): ReektStorageProxyBetOptionsView {
    throw 0;
}

get fun getIsBetAllowed(bet: int257): bool {
    throw 0;
}

get fun getAffiliatePot(): int257 {
    throw 0;
}

get fun verifyGameProof(epoch: int257, gameId: int257, player: address, bet: int257, createdAt: int257, maxPayout: int257, hashCommitment: int257, proof: cell): bool {
    throw 0;
}

get fun getConfigView(): ReektStorageProxyConfigView {
    throw 0;
}

get fun getFullConfig(): ReektStorageProxyStorageConfig {
    throw 0;
}

get fun getFinancials(): ReektStorageProxyStorageFinancial {
    throw 0;
}

get fun getGame(gameId: int257): cell? {
    throw 0;
}

get fun getStorageHealthReport(): ReektStorageProxyHealthReport {
    throw 0;
}

get fun getGameStatistics(): ReektStorageProxyGameStatistics {
    throw 0;
}

get fun getPoolLiquidityStatus(): ReektStorageProxyPoolLiquidityStatus {
    throw 0;
}

get fun getTotalBalance(): int257 {
    throw 0;
}

get fun getChainNow(): int257 {
    throw 0;
}

get fun getNextGameId(): int257 {
    throw 0;
}

get fun getProxyInfo(): ReektStorageProxyProxyInfo {
    throw 0;
}

get fun getContractInfo(): ReektStorageProxyContractInfo {
    throw 0;
}

get fun getIsInitialized(): bool {
    throw 0;
}

get fun getNonces(): ReektStorageProxyNonceStatus {
    throw 0;
}

get fun getGameStatisticsRange(startId: int257, endId: int257): ReektStorageProxyGameStatistics {
    throw 0;
}

get fun getEnhancedFinancialHealth(): ReektStorageProxyEnhancedFinancialHealth {
    throw 0;
}

get fun getPruningRecommendations(): ReektStorageProxyPruningRecommendations {
    throw 0;
}

get fun getPrunableGamesInRange(startId: int257, endId: int257): int257 {
    throw 0;
}

get fun getGameAgeDistribution(): ReektStorageProxyGameAgeDistribution {
    throw 0;
}

get fun getGameAgeDistributionRange(startId: int257, endId: int257): ReektStorageProxyGameAgeDistribution {
    throw 0;
}

get fun getGameSession(gameId: int257): ReektStorageProxyGameSession? {
    throw 0;
}

get fun getUserWithdrawalsInRange(user: address, startId: int257, endId: int257, limit: int257): ReektStorageProxyWithdrawalsPage {
    throw 0;
}

get fun getUserWithdrawalsTypedInRange(user: address, startId: int257, endId: int257, limit: int257): ReektStorageProxyWithdrawalsTypedPage10 {
    throw 0;
}
