// Generated from the verified Tact contract ABI.
contract StorageProxy {
    storage: StorageProxyData
    incomingMessages: StorageProxyDeploy
    thrownErrors: StorageProxyErrors
}

struct (0x946a98b6) StorageProxyDeploy {
    queryId: uint64
}

struct StorageProxyKeysView {
    adminPublicKey: int257
    serverPublicKey: int257
}

struct StorageProxyFinancialView {
    poolLiquidity: int257
}

struct StorageProxyConfigView {
    maxBetPercent: int257
    maxPayoutPercent: int257
    withdrawalFeePercent: int257
    tactContinuation: Cell<StorageProxyConfigViewContinuation>
}

struct StorageProxyConfigViewContinuation {
    affiliateCommissionPercent: int257
    lockupPeriod: int257
}

struct StorageProxySystemView {
    isPaused: bool
}

struct StorageProxyStorageKeys {
    adminPublicKey: int257
    serverPublicKey: int257
    serverNonce: int257
    tactContinuation: Cell<StorageProxyStorageKeysContinuation>
}

struct StorageProxyStorageKeysContinuation {
    adminNonce: int257
}

struct StorageProxyStorageFinancial {
    minReserve: int257
    houseBalance: int257
    poolLiquidity: int257
}

struct StorageProxyStorageConfig {
    maxBetPercent: int257
    maxPayoutPercent: int257
    withdrawalFeePercent: int257
    tactContinuation: Cell<StorageProxyStorageConfigContinuation>
}

struct StorageProxyStorageConfigContinuation {
    affiliateCommissionPercent: int257
    lockupPeriod: int257
}

struct StorageProxyStorageDicts {
    users: map<address, cell>
    games: map<int257, cell>
    tactContinuation: Cell<StorageProxyStorageDictsContinuation>
}

struct StorageProxyStorageDictsContinuation {
    affiliateBalances: map<address, int257>
    affiliateKeys: map<address, int257>
    affiliateNonces: map<address, int257>
}

struct StorageProxyHealthReport {
    healthLevel: int257
    daysCovered: int257
    annualStorageCost: int257
    message: cell
}

struct StorageProxyGameStatistics {
    total: int257
    active: int257
    won: int257
    tactContinuation: Cell<StorageProxyGameStatisticsContinuation>
}

struct StorageProxyGameStatisticsContinuation {
    lost: int257
}

struct StorageProxyPoolLiquidityStatus {
    poolLiquidity: int257
    committed: int257
    available: int257
    tactContinuation: Cell<StorageProxyPoolLiquidityStatusContinuation>
}

struct StorageProxyPoolLiquidityStatusContinuation {
    totalBalance: int257
}

struct StorageProxyProxyInfo {
    logicAddress: address
    adminPublicKey: int257
    serverPublicKey: int257
    isPaused: bool
}

struct StorageProxyStatusKeys {
    logicAddress: address
    isPaused: bool
    adminNonce: int257
    serverNonce: int257
}

struct StorageProxyContractInfo {
    totalBalance: int257
    houseBalance: int257
    poolLiquidity: int257
    tactContinuation: Cell<StorageProxyContractInfoContinuation>
}

struct StorageProxyContractInfoContinuation {
    minReserve: int257
    isPaused: bool
    nextGameId: int257
}

struct StorageProxySecurityStatus {
    serverNonce: int257
    adminNonce: int257
}

struct StorageProxyEnhancedFinancialHealth {
    balance: int257
    houseBalance: int257
    poolLiquidity: int257
    tactContinuation: Cell<StorageProxyEnhancedFinancialHealthContinuation>
}

struct StorageProxyEnhancedFinancialHealthContinuation {
    availableForPayouts: int257
    storageCost: int257
    reserveMargin: int257
    tactContinuation: Cell<StorageProxyEnhancedFinancialHealthContinuation2>
}

struct StorageProxyEnhancedFinancialHealthContinuation2 {
    affiliateLiability: int257
}

struct StorageProxyAffiliateLiabilityReport {
    totalLiability: int257
    affiliateCount: int257
    maxSingleBalance: int257
    tactContinuation: Cell<StorageProxyAffiliateLiabilityReportContinuation>
}

struct StorageProxyAffiliateLiabilityReportContinuation {
    highBalanceCount: int257
}

struct StorageProxyPrunningRecommendations {
    prunableGames: int257
    estimatedStorageSavings: int257
    totalGames: int257
}

struct StorageProxyGameAgeDistribution {
    age0to30: int257
    age31to90: int257
    age91to180: int257
    tactContinuation: Cell<StorageProxyGameAgeDistributionContinuation>
}

struct StorageProxyGameAgeDistributionContinuation {
    age180plus: int257
}

struct StorageProxyGameSession {
    player: address
    betAmount: int257
    hashCommitment: cell
    createdAt: int257
    tactContinuation: Cell<StorageProxyGameSessionContinuation>
}

struct StorageProxyGameSessionContinuation {
    status: int257
    payoutAmount: int257
    multiplier: int257
    tactContinuation: Cell<StorageProxyGameSessionContinuation2>
}

struct StorageProxyGameSessionContinuation2 {
    maxPayoutForGame: int257
    moves: cell
    gameConfig: cell
    gameSeed: cell
    tactContinuation: Cell<StorageProxyGameSessionContinuation3>
}

struct StorageProxyGameSessionContinuation3 {
    gameSalt: cell
    finalGameState: cell
}

struct StorageProxyStorage {
    version: int257
    initialized: bool
    logicAddress: address
    upgradeProposed: bool
    proposedLogic: address
    tactContinuation: Cell<StorageProxyStorageContinuation>
}

struct StorageProxyStorageContinuation {
    proposedCodeHash: int257
    upgradeEta: int257
    isPaused: bool
    nextGameId: int257
    tactContinuation: Cell<StorageProxyStorageContinuation2>
}

struct StorageProxyStorageContinuation2 {
    nextAffiliateId: int257
    tactContinuation: Cell<StorageProxyStorageContinuation3>
}

struct StorageProxyStorageContinuation3 {
    keys: StorageProxyStorageKeys
    tactContinuation: Cell<StorageProxyStorageContinuation4>
}

struct StorageProxyStorageContinuation4 {
    financial: StorageProxyStorageFinancial
    tactContinuation: Cell<StorageProxyStorageContinuation5>
}

struct StorageProxyStorageContinuation5 {
    config: StorageProxyStorageConfig
    tactContinuation: Cell<StorageProxyStorageContinuation6>
}

struct StorageProxyStorageContinuation6 {
    dicts: StorageProxyStorageDicts
    tactContinuation: Cell<StorageProxyStorageContinuation7>
}

struct StorageProxyStorageContinuation7 {
    affiliateIndexByAddress: map<address, int257>
    affiliateByIndex: map<int257, int257>
}

struct StorageProxyData {
    tactDeploymentCompleted: bool
    storage: StorageProxyStorage
}

enum StorageProxyErrors {
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
    /// Contract not initialized
    ContractNotInitialized = 12421
    /// ERROR_NO_UPGRADE_PROPOSED
    ERRORNOUPGRADEPROPOSED = 26624
    /// ERROR_INSUFFICIENT_FUNDS
    ERRORINSUFFICIENTFUNDS = 30540
    /// ERROR_RESERVE_VIOLATION
    ERRORRESERVEVIOLATION = 30801
    /// ERROR_MARK_LOST_FAILED
    ERRORMARKLOSTFAILED = 40649
    /// ERROR_SIGNATURE_EXPIRED
    ERRORSIGNATUREEXPIRED = 43061
    /// ERROR_CONTRACT_PAUSED
    ERRORCONTRACTPAUSED = 46199
    /// ERROR_CASHOUT_FAILED
    ERRORCASHOUTFAILED = 48798
    /// ERROR_NONCE_MISMATCH
    ERRORNONCEMISMATCH = 50352
    /// ERROR_UNAUTHORIZED
    ERRORUNAUTHORIZED = 61545
    /// ERROR_ETA_NOT_REACHED
    ERRORETANOTREACHED = 62891
    /// ERROR_GAME_NOT_CREATED
    ERRORGAMENOTCREATED = 63683
}

get fun getSystemView(): StorageProxySystemView {
    throw 0;
}

get fun getKeysView(): StorageProxyKeysView {
    throw 0;
}

get fun getFinancialView(): StorageProxyFinancialView {
    throw 0;
}

get fun getConfigView(): StorageProxyConfigView {
    throw 0;
}

get fun getFullConfig(): StorageProxyStorageConfig {
    throw 0;
}

get fun getFinancials(): StorageProxyStorageFinancial {
    throw 0;
}

get fun getGame(gameId: int257): cell? {
    throw 0;
}

get fun getAffiliateBalance(addr: address): int257 {
    throw 0;
}

get fun getStorageHealthReport(): StorageProxyHealthReport {
    throw 0;
}

get fun getGameStatistics(): StorageProxyGameStatistics {
    throw 0;
}

get fun getPoolLiquidityStatus(): StorageProxyPoolLiquidityStatus {
    throw 0;
}

get fun getTotalBalance(): int257 {
    throw 0;
}

get fun getProxyInfo(): StorageProxyProxyInfo {
    throw 0;
}

get fun getStatusKeys(): StorageProxyStatusKeys {
    throw 0;
}

get fun getContractInfo(): StorageProxyContractInfo {
    throw 0;
}

get fun getIsInitialized(): bool {
    throw 0;
}

get fun getSecurityStatus(): StorageProxySecurityStatus {
    throw 0;
}

get fun getEnhancedFinancialHealth(): StorageProxyEnhancedFinancialHealth {
    throw 0;
}

get fun getAffiliateLiabilityReport(): StorageProxyAffiliateLiabilityReport {
    throw 0;
}

get fun getPrunningRecommendations(): StorageProxyPrunningRecommendations {
    throw 0;
}

get fun getGameAgeDistribution(): StorageProxyGameAgeDistribution {
    throw 0;
}

get fun getGameSession(gameId: int257): StorageProxyGameSession? {
    throw 0;
}
