// Generated from the verified Tact contract ABI.
contract AmmPool {
    storage: AmmPoolData
    incomingMessages: AmmPoolIncomingMessage
    thrownErrors: AmmPoolErrors
}

struct (0x7362d09c) AmmPoolDexTokenNotification {
    queryId: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct (0xad2c4ac6) AmmPoolTactTokenNotification {
    queryId: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct (0xd53276db) AmmPoolDexTokenExcesses {
    queryId: uint64
}

struct (0x35a240af) AmmPoolSetOcWallet {
    wallet: address
}

struct (0xc767e87a) AmmPoolSetUsdtWallet {
    wallet: address
}

struct (0x04314c7c) AmmPoolSetLpMaster {
    master: address
}

struct (0x5a8ca50d) AmmPoolSetLpWallet {
    wallet: address
}

struct (0x1fc695fa) AmmPoolSetProtocolWallet {
    wallet: address
}

struct (0xbedaeffc) AmmPoolSetOcMaster {
    master: address
}

struct (0x1748e58a) AmmPoolPoolPause {
}

struct (0xe24009ce) AmmPoolPoolUnpause {
}

struct (0x36586266) AmmPoolSetMaxSwapBps {
    bps: uint16
}

struct (0xdfb319dc) AmmPoolSetSendGas {
    gas: coins
}

struct (0xe3b9d846) AmmPoolSetMinReserveUsdt {
    amount: coins
}

struct (0x66e9f757) AmmPoolSetTimelockDelay {
    delay: uint64
}

struct (0x807a6be4) AmmPoolSetFeeRates {
    lpFeeBps: uint16
    protocolFeeBps: uint16
    burnFeeBps: uint16
}

struct (0xda02a109) AmmPoolSetBurnEnabled {
    enabled: bool
}

struct (0xfa85b8bb) AmmPoolSetPublicAddLiquidity {
    enabled: bool
}

struct (0xd0efdb76) AmmPoolSetLaunchEnd {
    endsAt: uint64
}

struct (0xa085ef87) AmmPoolSetPermitPublicKey {
    pubkey: uint256
}

struct (0xe3095f54) AmmPoolSetDailySellLimitBps {
    bps: uint16
}

struct (0x51de6b1d) AmmPoolCancelPendingDeposit {
}

struct (0x143cf991) AmmPoolExecuteRemoveLiquidity {
    queryId: uint64
}

struct (0xcec480a0) AmmPoolCancelRemoveLiquidity {
}

struct (0x38125fd9) AmmPoolAdminWithdrawToken {
    jettonWallet: address
    amount: coins
    to: address
}

struct (0x3bdbd1a1) AmmPoolAdminWithdrawTon {
    amount: coins
    to: address
}

struct AmmPoolPoolReserves {
    reserveOC: coins
    reserveUSDT: coins
    totalLpSupply: coins
}

struct AmmPoolPendingDepositInfo {
    user: address
    ocAmount: coins
    usdtAmount: coins
    timestamp: uint64
}

struct AmmPoolRemovalInfo {
    user: address
    lpAmount: coins
    scheduledAt: uint64
}

struct AmmPoolLaunchInfo {
    launchEndsAt: uint64
    launchSellFeeBps: uint16
    started: bool
    active: bool
}

struct AmmPoolGlobalDailySold {
    sold: coins
    cap: coins
    windowStart: uint64
}

struct AmmPoolPoolConfig {
    owner: address
    paused: bool
    maxSwapBps: uint16
    minReserveUSDT: coins
    timelockDelay: uint64
    protocolWallet: address
    deployedAt: uint64
    lpFeeBps: uint16
    protocolFeeBps: uint16
    burnFeeBps: uint16
    tactContinuation: Cell<AmmPoolPoolConfigContinuation>
}

struct AmmPoolPoolConfigContinuation {
    lpMaster: address?
    lpJettonWallet: address?
    burnEnabled: bool
    publicAddLiquidity: bool
}

struct AmmPoolData {
    tactDeploymentCompleted: bool
    owner: address
    sendGas: coins
    ocJettonWallet: address?
    usdtJettonWallet: address?
    tactContinuation: Cell<AmmPoolDataContinuation>
}

struct AmmPoolDataContinuation {
    lpMaster: address?
    lpJettonWallet: address?
    reserveOC: coins
    reserveUSDT: coins
    totalLpSupply: coins
    lpFeeBps: uint16
    protocolFeeBps: uint16
    burnFeeBps: uint16
    launchSellFeeBps: uint16
    tactContinuation: Cell<AmmPoolDataContinuation2>
}

struct AmmPoolDataContinuation2 {
    launchEndsAt: uint64
    launchStarted: bool
    permitPublicKey: uint256
    dailySellLimitBps: uint16
    globalDaySoldOC: coins
    globalDayStart: uint64
    globalDayCapOC: coins
    protocolWallet: address
    tactContinuation: Cell<AmmPoolDataContinuation3>
}

struct AmmPoolDataContinuation3 {
    ocMasterAddress: address?
    burnEnabled: bool
    publicAddLiquidity: bool
    paused: bool
    maxSwapBps: uint16
    minReserveUSDT: coins
    timelockDelay: uint64
    pendingOC: map<uint256, coins>
    pendingUSDT: map<uint256, coins>
    pendingUser: map<uint256, address>
    tactContinuation: Cell<AmmPoolDataContinuation4>
}

struct AmmPoolDataContinuation4 {
    pendingTimestamp: map<uint256, uint64>
    removeLpAmount: map<uint256, coins>
    removeScheduledAt: map<uint256, uint64>
    tactContinuation: Cell<AmmPoolDataContinuation5>
}

struct AmmPoolDataContinuation5 {
    removeUser: map<uint256, address>
    mintNonce: uint64
    mintUser: map<uint64, address>
    mintOC: map<uint64, coins>
    tactContinuation: Cell<AmmPoolDataContinuation6>
}

struct AmmPoolDataContinuation6 {
    mintUSDT: map<uint64, coins>
    mintTimestamp: map<uint64, uint64>
    userMintNonce: map<uint256, uint64>
    transferSeq: uint64
    deployedAt: uint64
}

type AmmPoolIncomingMessage =
    | AmmPoolSetOcWallet
    | AmmPoolSetUsdtWallet
    | AmmPoolSetLpMaster
    | AmmPoolSetLpWallet
    | AmmPoolSetProtocolWallet
    | AmmPoolSetOcMaster
    | AmmPoolPoolPause
    | AmmPoolPoolUnpause
    | AmmPoolSetMaxSwapBps
    | AmmPoolSetSendGas
    | AmmPoolSetMinReserveUsdt
    | AmmPoolSetTimelockDelay
    | AmmPoolSetBurnEnabled
    | AmmPoolSetPublicAddLiquidity
    | AmmPoolSetLaunchEnd
    | AmmPoolSetPermitPublicKey
    | AmmPoolSetDailySellLimitBps
    | AmmPoolSetFeeRates
    | AmmPoolDexTokenExcesses
    | AmmPoolAdminWithdrawToken
    | AmmPoolAdminWithdrawTon
    | AmmPoolTactTokenNotification
    | AmmPoolDexTokenNotification
    | AmmPoolCancelPendingDeposit
    | AmmPoolExecuteRemoveLiquidity
    | AmmPoolCancelRemoveLiquidity

enum AmmPoolErrors {
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
    /// Amount must be > 0
    AmountMustBe0 = 6243
    /// Zero amount
    ZeroAmount = 7189
    /// Insufficient gas for removal scheduling
    InsufficientGasForRemovalScheduling = 7879
    /// No pending deposit
    NoPendingDeposit = 8451
    /// No pending removal
    NoPendingRemoval = 12793
    /// Unknown jetton
    UnknownJetton = 17216
    /// Insufficient initial liquidity
    InsufficientInitialLiquidity = 19396
    /// Fee cannot be negative
    FeeCannotBeNegative = 20545
    /// Zero input
    ZeroInput = 21215
    /// Insufficient gas
    InsufficientGas = 23951
    /// Zero LP
    ZeroLP = 27923
    /// LP wallet not set
    LPWalletNotSet = 35874
    /// Invalid bps
    InvalidBps = 41390
    /// Insufficient gas for removal
    InsufficientGasForRemoval = 42790
    /// Send gas must be positive
    SendGasMustBePositive = 55121
    /// Below min reserve
    BelowMinReserve = 56080
    /// Total fee must be 0-10%
    TotalFeeMustBe010 = 59475
    /// Timelock not expired
    TimelockNotExpired = 62971
}

get fun get_ton_balance(): int257 {
    throw 0;
}

get fun get_recommended_ton_floor(): int257 {
    throw 0;
}

get fun get_permit_pubkey(): int257 {
    throw 0;
}

get fun get_global_daily_sold(): AmmPoolGlobalDailySold {
    throw 0;
}

get fun get_reserves(): AmmPoolPoolReserves {
    throw 0;
}

get fun get_config(): AmmPoolPoolConfig {
    throw 0;
}

get fun get_launch_info(): AmmPoolLaunchInfo {
    throw 0;
}

get fun get_pending_deposit(user: address): AmmPoolPendingDepositInfo {
    throw 0;
}

get fun get_removal_info(user: address): AmmPoolRemovalInfo {
    throw 0;
}

get fun estimate_swap_oc_to_usdt(inputOC: int257): int257 {
    throw 0;
}

get fun estimate_swap_usdt_to_oc(inputUSDT: int257): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
