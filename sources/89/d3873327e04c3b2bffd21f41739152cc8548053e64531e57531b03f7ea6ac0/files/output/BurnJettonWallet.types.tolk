// Generated from the verified Tact contract ABI.
contract BurnJettonWallet {
    storage: BurnJettonWalletData2
    incomingMessages: BurnJettonWalletIncomingMessage
    thrownErrors: BurnJettonWalletErrors
}

struct BurnJettonWalletData {
    balance: int257
    owner: address
    minter: address
    code: cell
}

struct (0x0f8a7ea5) BurnJettonWalletJettonTransfer {
    queryId: uint64
    amount: coins
    destination: address
    responseDestination: address?
    customPayload: cell?
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x178d4519) BurnJettonWalletJettonTransferInternal {
    queryId: uint64
    amount: coins
    sender: address
    responseDestination: address?
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x595f07bc) BurnJettonWalletJettonBurn {
    queryId: uint64
    amount: coins
    responseDestination: address?
    customPayload: cell?
}

struct (0x6a3b2c21) BurnJettonWalletCommitJettonTransfer {
    queryId: uint64
    amount: coins
    destination: address
    responseDestination: address?
    forwardTonAmount: coins
    forwardPayload: cell
    excludedTransfer: bool
}

struct (0x4d7e2bc4) BurnJettonWalletJettonUpdateFeeConfig {
    queryId: uint64
    burn_rate_bps: int257
    staking_rate_bps: int257
    treasury_rate_bps: int257
    tactContinuation: Cell<BurnJettonWalletJettonUpdateFeeConfigContinuation>
}

struct BurnJettonWalletJettonUpdateFeeConfigContinuation {
    staking_pool: address
    treasury: address
    dynamic_burn_enabled: bool
    large_tx_threshold: coins
    activity_threshold: int257
    tactContinuation: Cell<BurnJettonWalletJettonUpdateFeeConfigContinuation2>
}

struct BurnJettonWalletJettonUpdateFeeConfigContinuation2 {
    max_burn_rate_bps: int257
    tx_count_snapshot: int257
    activity_hour_bucket: int257
    low_supply_mode: bool
    tactContinuation: Cell<BurnJettonWalletJettonUpdateFeeConfigContinuation3>
}

struct BurnJettonWalletJettonUpdateFeeConfigContinuation3 {
    excluded_count: int257
    excluded_head: cell
    gas_min_ton_fee_path: coins
    gas_per_internal_deploy_ton: coins
    gas_pool_forward_min: coins
    gas_treasury_forward_min: coins
    gas_burn_notify_ton: coins
    gas_propagate_ton: coins
}

struct BurnJettonWalletGasParamsView {
    minTonFeePath: int257
    perInternalDeployTon: int257
    poolForwardMin: int257
    tactContinuation: Cell<BurnJettonWalletGasParamsViewContinuation>
}

struct BurnJettonWalletGasParamsViewContinuation {
    treasuryForwardMin: int257
    burnNotifyTon: int257
    propagateTon: int257
}

struct BurnJettonWalletData2 {
    owner: address
    master: address
    balance: coins
    feeConfig: cell
}

type BurnJettonWalletIncomingMessage =
    | BurnJettonWalletJettonUpdateFeeConfig
    | BurnJettonWalletJettonTransfer
    | BurnJettonWalletCommitJettonTransfer
    | BurnJettonWalletJettonTransferInternal
    | BurnJettonWalletJettonBurn

enum BurnJettonWalletErrors {
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
    /// Only timelock
    OnlyTimelock = 3095
    /// Mint cap exceeded
    MintCapExceeded = 6461
    /// Incorrect sender
    IncorrectSender = 9215
    /// Unauthorized burn
    UnauthorizedBurn = 10363
    /// Fee destinations not configured
    FeeDestinationsNotConfigured = 21507
    /// Invalid low fee bps
    InvalidLowFeeBps = 24220
    /// Insufficient amount of TON attached
    InsufficientAmountOfTONAttached = 32113
    /// Invalid fee bps
    InvalidFeeBps = 32270
    /// Insufficient TON for resolve
    InsufficientTONForResolve = 33399
    /// Insufficient gas for mint
    InsufficientGasForMint = 37629
    /// Invalid gas params
    InvalidGasParams = 41940
    /// Fee split invariant
    FeeSplitInvariant = 42588
    /// Insufficient TON for sync
    InsufficientTONForSync = 44320
    /// Insufficient gas for wallet discovery
    InsufficientGasForWalletDiscovery = 50281
    /// Unauthorized jetton wallet
    UnauthorizedJettonWallet = 50340
    /// Max excluded
    MaxExcluded = 51036
    /// Mint is closed
    MintIsClosed = 51950
    /// Insufficient TON for fee fanout
    InsufficientTONForFeeFanout = 54718
    /// Amount must be positive
    AmountMustBePositive = 61135
    /// Fee destinations not configured on master
    FeeDestinationsNotConfiguredOnMaster = 63727
}

get fun get_wallet_data(): BurnJettonWalletData {
    throw 0;
}

get fun get_fee_config_active(): bool {
    throw 0;
}

get fun get_gas_config(): BurnJettonWalletGasParamsView {
    throw 0;
}
