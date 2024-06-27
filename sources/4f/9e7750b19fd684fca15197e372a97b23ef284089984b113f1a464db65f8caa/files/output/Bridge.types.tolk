// Generated from the verified Tact contract ABI.
contract Bridge {
    storage: BridgeData
    incomingMessages: BridgeIncomingMessage
    thrownErrors: BridgeErrors
}

struct (0x946a98b6) BridgeDeploy {
    queryId: uint64
}

struct (0x7362d09c) BridgeJettonTransferNotification {
    query_id: uint64
    amount: coins
    sender: address
    forward_payload: RemainingBitsAndRefs
}

struct (0xd53276db) BridgeJettonExcesses {
    query_id: uint64
}

struct (0x7bdd97de) BridgeJettonBurnNotification {
    query_id: uint64
    amount: coins
    sender: address
    response_destination: address
    forward_ton_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x0a61db59) BridgeGrantRole {
    to: address
    role_id: int257
}

struct (0x513ef35e) BridgeRevokeRole {
    to: address
    role_id: int257
}

struct (0x1732be21) BridgeRenounceRole {
    role_id: int257
    address: address
}

struct (0x24fa47c9) BridgeUpdateRoleAdmin {
    role_id: int257
    role_admin: int257
}

struct BridgeRoleData {
    roles: map<address, bool>
    admin_role: int257
}

struct (0xeb126dcb) BridgeFreezeTon {
    target_chain: uint64
    to_token: cell
    to: cell
    from_token: cell
    amount: coins
}

struct (0x4b37c621) BridgeMapContract {
    token_id: int257
    token_symbol: string
    contract_: address
    decimals: uint8
    fee: int257
    tactContinuation: Cell<BridgeMapContractContinuation>
}

struct BridgeMapContractContinuation {
    fee_decimals: int257
    swap_address: address
    token_bridge_wallet_address: address
}

struct (0x49f3dd7e) BridgeSetChainFee {
    chain_id: uint64
    fee: uint256
}

struct BridgeOutgoingTransaction {
    id: uint256
    amount: coins
    from_token: cell
    to_token: cell
    to: cell
    target_chain_id: uint64
}

struct BridgeIncomingTransaction {
    id: uint256
    amount: coins
    from_token: cell
    to_token: cell
    target_chain_id: uint64
    to: address
}

struct BridgeToken {
    symbol: string
    address: address
    swap_address: address
    decimals: uint8
    fee: int257
    tactContinuation: Cell<BridgeTokenContinuation>
}

struct BridgeTokenContinuation {
    fee_decimals: int257
    token_bridge_wallet_address: address
}

struct (0xb4bb0ab5) BridgeUpdateBaseUri {
    new_base_uri: string
}

struct (0x6adf7881) BridgeUpdateTransferFee {
    new_fee: int257
}

struct (0x6ab8c041) BridgeRemoveMappedContract {
    token_id: uint256
}

struct BridgeFromTokenToTargetTokenToSteps {
    i: map<int257, Cell<BridgeTargetTokenToSteps>>
}

struct BridgeTargetTokenToSteps {
    i: map<int257, Cell<BridgeSteps>>
}

struct BridgeSteps {
    steps: map<int257, int257>
    size: int257
}

struct BridgeCrossChainStrategy {
    local_steps: BridgeSteps
    foreign_steps: BridgeSteps
}

struct BridgeTargetTokenToCrossChainStrategy {
    i: map<int257, Cell<BridgeCrossChainStrategy>>
}

struct BridgeFromTokenToTargetTokenToCrossChainStrategy {
    i: map<int257, Cell<BridgeTargetTokenToCrossChainStrategy>>
}

struct (0x3390d368) BridgeUpdateProtocolFee {
    new_fee: int257
}

struct (0x95d6fda2) BridgeAddValidator {
    key: int257
    address: address
}

struct (0xc3a5bde2) BridgeRemoveValidator {
    key: int257
}

struct (0x70ef6515) BridgeSetIncomingStrategy {
    from_chain: int257
    from_token: int257
    target_token: int257
    tactContinuation: Cell<BridgeSetIncomingStrategyContinuation>
}

struct BridgeSetIncomingStrategyContinuation {
    steps: BridgeSteps
}

struct (0x6cd57fd0) BridgeSetCrossChainStrategy {
    target_chain: int257
    from_token: int257
    target_token: int257
    tactContinuation: Cell<BridgeSetCrossChainStrategyContinuation>
}

struct BridgeSetCrossChainStrategyContinuation {
    local_steps: BridgeSteps
    foreign_steps: BridgeSteps
}

struct (0x70be6390) BridgeRemoveInternalStrategy {
    from_chain: int257
    from_token: int257
    target_token: int257
}

struct (0x0c589086) BridgeRemoveCrossChainStrategy {
    target_chain: int257
    from_token: int257
    target_token: int257
}

struct BridgeData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    nonce: int257
    native_coin: int257
    fees: int257
    tactContinuation: Cell<BridgeDataContinuation>
}

struct BridgeDataContinuation {
    TVL: int257
    chain_nonce: int257
    incoming: map<int257, Cell<BridgeIncomingTransaction>>
    outgoing: map<int257, Cell<BridgeOutgoingTransaction>>
    tokens: map<int257, Cell<BridgeToken>>
    tactContinuation: Cell<BridgeDataContinuation2>
}

struct BridgeDataContinuation2 {
    incoming_token_strategy: map<int257, Cell<BridgeFromTokenToTargetTokenToSteps>>
    cross_chain_token_storage: map<int257, Cell<BridgeFromTokenToTargetTokenToCrossChainStrategy>>
    default_admin_role: address
    roles: map<int257, Cell<BridgeRoleData>>
    tactContinuation: Cell<BridgeDataContinuation3>
}

struct BridgeDataContinuation3 {
    chain_fees: map<int257, int257>
    paused: bool
    burner: address
    base_uri: string
    transfer_fee: int257
    protocol_fee: int257
    validators: map<int257, address>
    tactContinuation: Cell<BridgeDataContinuation4>
}

struct BridgeDataContinuation4 {
    validators_count: int257
    threshold: int257
}

type BridgeIncomingMessage =
    | BridgeJettonTransferNotification
    | BridgeJettonBurnNotification
    | BridgeFreezeTon
    | BridgeMapContract
    | BridgeRemoveMappedContract
    | BridgeSetChainFee
    | BridgeJettonExcesses
    | BridgeUpdateProtocolFee
    | BridgeUpdateBaseUri
    | BridgeUpdateTransferFee
    | BridgeAddValidator
    | BridgeRemoveValidator
    | BridgeSetIncomingStrategy
    | BridgeSetCrossChainStrategy
    | BridgeRemoveCrossChainStrategy
    | BridgeRemoveInternalStrategy
    | BridgeDeploy
    | BridgeGrantRole
    | BridgeRevokeRole
    | BridgeRenounceRole
    | BridgeUpdateRoleAdmin

enum BridgeErrors {
    /// Stack undeflow
    StackUndeflow = 2
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
    /// Out of gas error
    OutOfGasError = 13
    /// Method ID not found
    MethodIDNotFound = 32
    /// Action is invalid or not supported
    ActionIsInvalidOrNotSupported = 34
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
    NotEnoughExtraCurrencies = 38
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
    /// JettonWallet: Only Jetton master or Jetton wallet can call this function
    JettonWalletOnlyJettonMasterOrJettonWalletCanCallThisFunction = 2296
    /// AccessControl: Role ID doesn't exist
    AccessControlRoleIDDoesnTExist = 2927
    /// Invalid native token id provided
    InvalidNativeTokenIdProvided = 4129
    /// Unsupported from_token for cross chain token strategy storage
    UnsupportedFromTokenForCrossChainTokenStrategyStorage = 6936
    /// AccessControl: BadConfirmation
    AccessControlBadConfirmation = 7947
    /// Sender is not a Jetton wallet
    SenderIsNotAJettonWallet = 9739
    /// Unsupported incoming token strategy for from_chain_id
    UnsupportedIncomingTokenStrategyForFromChainId = 11647
    /// JettonWallet: Not enough jettons to transfer
    JettonWalletNotEnoughJettonsToTransfer = 13105
    /// Invalid token sent
    InvalidTokenSent = 13199
    /// Unsupported incoming token strategy for from_token
    UnsupportedIncomingTokenStrategyForFromToken = 14558
    /// Insufficient funds Provided
    InsufficientFundsProvided = 17246
    /// JettonMaster: Mint can only be performed by owner
    JettonMasterMintCanOnlyBePerformedByOwner = 17773
    /// Contract is paused
    ContractIsPaused = 19792
    /// AccessControl: Role doesn't exist
    AccessControlRoleDoesnTExist = 21733
    /// No fees to withdraw
    NoFeesToWithdraw = 23041
    /// Transaction already submitted
    TransactionAlreadySubmitted = 26252
    /// Insufficient Funds
    InsufficientFunds = 27419
    /// Only owner can call this function
    OnlyOwnerCanCallThisFunction = 27831
    /// JettonMaster: Only Admin can set new owner.
    JettonMasterOnlyAdminCanSetNewOwner = 27954
    /// JettonWallet: Not allow negative balance after internal transfer
    JettonWalletNotAllowNegativeBalanceAfterInternalTransfer = 29133
    /// Pausable: Contract is already unpaused
    PausableContractIsAlreadyUnpaused = 29944
    /// JettonMaster: Jetton is not mintable
    JettonMasterJettonIsNotMintable = 30061
    /// Unsupported incoming token strategy for from token
    UnsupportedIncomingTokenStrategyForFromToken2 = 31212
    /// Unsupported to chain for cross chain token strategy storage
    UnsupportedToChainForCrossChainTokenStrategyStorage = 33124
    /// Unsupported incoming token strategy for from chain id
    UnsupportedIncomingTokenStrategyForFromChainId2 = 34665
    /// Only Burner Can Call this Method
    OnlyBurnerCanCallThisMethod = 35431
    /// JettonMaster: Only Admin can set new admin.
    JettonMasterOnlyAdminCanSetNewAdmin = 35462
    /// Not enough funds to transfer
    NotEnoughFundsToTransfer = 37185
    /// Unsupported target_token for cross chain token strategy storage
    UnsupportedTargetTokenForCrossChainTokenStrategyStorage = 42526
    /// JettonMaster: Sender is not a Jetton owner
    JettonMasterSenderIsNotAJettonOwner = 43365
    /// Threshold not reached.
    ThresholdNotReached = 46934
    /// JettonWallet: Only owner can burn tokens
    JettonWalletOnlyOwnerCanBurnTokens = 47048
    /// Invalid wrapped token id provided
    InvalidWrappedTokenIdProvided = 49100
    /// Previously Processed Transaction.
    PreviouslyProcessedTransaction = 50157
    /// Fees not configured for this chain
    FeesNotConfiguredForThisChain = 50245
    /// AccessControl: Doesnt have the role
    AccessControlDoesntHaveTheRole = 50413
    /// Wrong chainId
    WrongChainId = 50658
    /// AccessControl: Doesn't have role
    AccessControlDoesnTHaveRole = 54023
    /// Pausable: Contract is already paused
    PausableContractIsAlreadyPaused = 58304
    /// Target chainId cannot equal native or zero
    TargetChainIdCannotEqualNativeOrZero = 59332
    /// Unsupported incoming token strategy for from_token -> target_token
    UnsupportedIncomingTokenStrategyForFromTokenTargetToken = 59662
    /// JettonWallet: Not enough balance to burn tokens
    JettonWalletNotEnoughBalanceToBurnTokens = 60354
    /// Incorrect Token Specified in arguments
    IncorrectTokenSpecifiedInArguments = 60744
    /// Insufficient fee coverage.
    InsufficientFeeCoverage = 63413
}

get fun manager_role_id(): int257 {
    throw 0;
}

get fun signer_role_id(): int257 {
    throw 0;
}

get fun cfo_role_id(): int257 {
    throw 0;
}

get fun base_uri(): string {
    throw 0;
}

get fun protocol_fee(): int257 {
    throw 0;
}

get fun nonce(): int257 {
    throw 0;
}

get fun native_coin(): int257 {
    throw 0;
}

get fun fees(): int257 {
    throw 0;
}

get fun TVL(): int257 {
    throw 0;
}

get fun chain_nonce(): int257 {
    throw 0;
}

get fun incoming(): map<int257, Cell<BridgeIncomingTransaction>> {
    throw 0;
}

get fun outgoing(): map<int257, Cell<BridgeOutgoingTransaction>> {
    throw 0;
}

get fun tokens(): map<int257, Cell<BridgeToken>> {
    throw 0;
}

get fun chain_fees(): map<int257, int257> {
    throw 0;
}

get fun incoming_strategy(): map<int257, Cell<BridgeFromTokenToTargetTokenToSteps>> {
    throw 0;
}

get fun cross_chain_strategy(): map<int257, Cell<BridgeFromTokenToTargetTokenToCrossChainStrategy>> {
    throw 0;
}

get fun has_role(address: address, role_id: int257): bool {
    throw 0;
}

get fun role_admin(role_id: int257): int257 {
    throw 0;
}

get fun admin_role_id(): int257 {
    throw 0;
}
