// Generated from the verified Tact contract ABI.
contract JettonLP {
    storage: JettonLPData
    incomingMessages: JettonLPIncomingMessage
    thrownErrors: JettonLPErrors
}

struct JettonLPJettonData {
    total_supply: coins
    mintable: bool
    admin: address
    content: cell
    wallet_code: cell
}

struct (0x7362d09c) JettonLPTokenNotification {
    query_id: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct (0x7bdd97de) JettonLPTokenBurnNotification {
    query_id: uint64
    amount: coins
    sender: address
    response_destination: address?
}

struct (0xaf1ca26a) JettonLPTokenUpdateContent {
    content: cell
}

struct (0x2c76b973) JettonLPProvideWalletAddress {
    query_id: uint64
    owner_address: address
    include_address: bool
}

struct (0xba07912d) JettonLPUpdateDeposits {
    amount: int257
    sender: address
    receiver: address
}

struct JettonLPLPData {
    apy: int257
    available_underlying: int257
    decimals: int257
    tactContinuation: Cell<JettonLPLPDataContinuation>
}

struct JettonLPLPDataContinuation {
    fee_growth_global: int257
    fee_decimals: int257
    protocol_fee: int257
    tactContinuation: Cell<JettonLPLPDataContinuation2>
}

struct JettonLPLPDataContinuation2 {
    protocol_fee_amount: int257
    token_fee: int257
    total_supply: int257
}

struct (0x0a19fe9e) JettonLPReleaseTokens {
    to: address
    amount: int257
    body: cell?
}

struct JettonLPPosition {
    balance: int257
    last_fee_growth: int257
    rewards: int257
}

struct (0xa1bc3662) JettonLPSetAdmin {
    newAdmin: address
}

struct (0xfaf84a7d) JettonLPSetBridge {
    newBridge: address
}

struct (0xd329ee83) JettonLPSetCFO {
    newCFO: address
}

struct (0x36162067) JettonLPSetWalletAddress {
    token_wallet: address
}

struct (0x0852d51c) JettonLPUpdateFees {
    protocol_fee: int257
    token_fee: int257
}

struct (0x1b990487) JettonLPUpdateGasCost {
    newGasCost: int257
}

struct (0x60591510) JettonLPWithdraw {
    amount: int257
}

struct (0x23e3b324) JettonLPWithdrawGas {
    amount: int257
}

struct (0x32d20fa6) JettonLPWithdrawRewards {
}

struct (0x946a98b6) JettonLPDeploy {
    queryId: uint64
}

struct (0x0a61db59) JettonLPGrantRole {
    to: address
    role_id: int257
}

struct (0x1732be21) JettonLPRenounceRole {
    role_id: int257
    address: address
}

struct (0x513ef35e) JettonLPRevokeRole {
    to: address
    role_id: int257
}

struct JettonLPRoleData {
    roles: map<address, bool>
    admin_role: int257
}

struct (0x24fa47c9) JettonLPUpdateRoleAdmin {
    role_id: int257
    role_admin: int257
}

struct JettonLPData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    admin: address
    available_underlying: int257
    bridge: address
    tactContinuation: Cell<JettonLPDataContinuation>
}

struct JettonLPDataContinuation {
    cfo: address
    content: cell
    decimals: int257
    deployed: int257
    deposits: map<address, Cell<JettonLPPosition>>
    tactContinuation: Cell<JettonLPDataContinuation2>
}

struct JettonLPDataContinuation2 {
    fee_growth_global: int257
    gas_cost: int257
    query_id: int257
    mintable: bool
    tactContinuation: Cell<JettonLPDataContinuation3>
}

struct JettonLPDataContinuation3 {
    owner: address
    protocolFee: int257
    protocol_fee_amount: int257
    roles: map<int257, Cell<JettonLPRoleData>>
    tactContinuation: Cell<JettonLPDataContinuation4>
}

struct JettonLPDataContinuation4 {
    stake_token: address
    tokenFee: int257
    token_wallet: address
    tactContinuation: Cell<JettonLPDataContinuation5>
}

struct JettonLPDataContinuation5 {
    total_supply: int257
}

type JettonLPIncomingMessage =
    | JettonLPWithdrawGas
    | JettonLPTokenNotification
    | JettonLPReleaseTokens
    | JettonLPTokenBurnNotification
    | JettonLPWithdrawRewards
    | JettonLPUpdateDeposits
    | JettonLPWithdraw
    | JettonLPSetAdmin
    | JettonLPSetCFO
    | JettonLPSetBridge
    | JettonLPSetWalletAddress
    | JettonLPUpdateFees
    | JettonLPUpdateGasCost
    | JettonLPDeploy
    | JettonLPTokenUpdateContent
    | JettonLPProvideWalletAddress
    | JettonLPGrantRole
    | JettonLPRevokeRole
    | JettonLPRenounceRole
    | JettonLPUpdateRoleAdmin

enum JettonLPErrors {
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
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
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
    /// Invalid address
    InvalidAddress = 136
    /// Masterchain support is not enabled for this contract
    MasterchainSupportIsNotEnabledForThisContract = 137
    /// APY: rewards == 0
    APYRewards0 = 1237
    /// AccessControl: Role ID doesn't exist
    AccessControlRoleIDDoesnTExist = 2927
    /// Invalid sender
    InvalidSender = 4429
    /// AccessControl: Role ADMIN is undefined
    AccessControlRoleADMINIsUndefined = 5524
    /// AccessControl: Doesn't have the CFO role
    AccessControlDoesnTHaveTheCFORole = 6187
    /// AccessControl: BadConfirmation
    AccessControlBadConfirmation = 7947
    /// AccessControl: Doesn't have the BRIDGE role
    AccessControlDoesnTHaveTheBRIDGERole = 10858
    /// Insufficient LP balance to withdraw rewards
    InsufficientLPBalanceToWithdrawRewards = 11399
    /// AccessControl: Role BRIDGE is undefined
    AccessControlRoleBRIDGEIsUndefined = 12450
    /// TokenBurnNotification: Amount exceeds underlying balance
    TokenBurnNotificationAmountExceedsUnderlyingBalance = 12666
    /// APY: totalSupply == 0
    APYTotalSupply0 = 14033
    /// TokenBurn: Invalid balance
    TokenBurnInvalidBalance = 15100
    /// AccessControl: Doesn't have the ADMIN role
    AccessControlDoesnTHaveTheADMINRole = 17039
    /// Deposit amount must be greater than zero.
    DepositAmountMustBeGreaterThanZero = 17389
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// AccessControl: Role doesn't exist
    AccessControlRoleDoesnTExist = 21733
    /// Insufficient gas
    InsufficientGas = 23951
    /// ReleaseTokens: Unauthorized release tokens call.
    ReleaseTokensUnauthorizedReleaseTokensCall = 26704
    /// The caller has no staking position to withdraw
    TheCallerHasNoStakingPositionToWithdraw = 29285
    /// Protocol fee cannot exceed token fee.
    ProtocolFeeCannotExceedTokenFee = 29451
    /// Gas cost must be positive.
    GasCostMustBePositive = 33665
    /// Protocol fee cannot exceed the token fee.
    ProtocolFeeCannotExceedTheTokenFee = 33951
    /// TokenBurnNotification: Missing staker position
    TokenBurnNotificationMissingStakerPosition = 34727
    /// Insufficient staker's balance to withdraw the amount.
    InsufficientStakerSBalanceToWithdrawTheAmount = 36999
    /// WithdrawGas: Insufficient TON balance
    WithdrawGasInsufficientTONBalance = 40436
    /// UpdateDeposit must originate from the LP wallet.
    UpdateDepositMustOriginateFromTheLPWallet = 41817
    /// Invalid sender!
    InvalidSender2 = 42708
    /// APY: totalSupply and rewards are not on the same decimal scale
    APYTotalSupplyAndRewardsAreNotOnTheSameDecimalScale = 46518
    /// TokenBurnNotification: Amount exceeds total supply
    TokenBurnNotificationAmountExceedsTotalSupply = 48807
    /// AccessControl: Doesnt have the role
    AccessControlDoesntHaveTheRole = 50413
    /// Withdraw amount must be greater than zero.
    WithdrawAmountMustBeGreaterThanZero = 51942
    /// AccessControl: Role CFO is undefined
    AccessControlRoleCFOIsUndefined = 53581
    /// TokenTransferInternal: Invalid balance
    TokenTransferInternalInvalidBalance = 60960
    /// TokenTransfer: Invalid balance
    TokenTransferInvalidBalance = 61410
}

get fun underlying(): address {
    throw 0;
}

get fun currentAPY(): int257 {
    throw 0;
}

get fun decimals(): int257 {
    throw 0;
}

get fun feeGrowthGlobal(): int257 {
    throw 0;
}

get fun get_admin(): address {
    throw 0;
}

get fun get_available_underlying(): int257 {
    throw 0;
}

get fun get_cfo(): address {
    throw 0;
}

get fun get_data(): JettonLPLPData {
    throw 0;
}

get fun get_query_id(): int257 {
    throw 0;
}

get fun get_position(staker: address): JettonLPPosition {
    throw 0;
}

get fun get_total_supply(): int257 {
    throw 0;
}

get fun get_underlying_wallet(): address {
    throw 0;
}

get fun protocolFee(): int257 {
    throw 0;
}

get fun protocolFeeAmount(): int257 {
    throw 0;
}

get fun rewards(staker: address): int257 {
    throw 0;
}

get fun tokenFee(): int257 {
    throw 0;
}

get fun get_jetton_data(): JettonLPJettonData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun admin_role_id(): int257 {
    throw 0;
}

get fun bridge_role_id(): int257 {
    throw 0;
}

get fun cfo_role_id(): int257 {
    throw 0;
}

get fun has_role(address: address, role_id: int257): bool {
    throw 0;
}

get fun role_admin(role_id: int257): int257 {
    throw 0;
}
