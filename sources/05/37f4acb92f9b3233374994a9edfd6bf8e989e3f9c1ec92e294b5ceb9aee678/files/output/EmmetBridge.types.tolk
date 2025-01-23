// Generated from the verified Tact contract ABI.
contract EmmetBridge {
    storage: EmmetBridgeData
    incomingMessages: EmmetBridgeIncomingMessage
    thrownErrors: EmmetBridgeErrors
}

struct (0xeb126dcb) EmmetBridgeFreezeTon {
    target_chain: uint64
    to_token: cell
    to: cell
    from_token: cell
    amount: coins
}

struct (0x7bdd97de) EmmetBridgeJettonBurnNotification {
    query_id: uint64
    amount: coins
    sender: address
    response_destination: address
    forward_ton_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x7362d09c) EmmetBridgeTokenTransferNotification {
    query_id: uint64
    amount: coins
    sender: address
    forward_payload: RemainingBitsAndRefs
}

struct (0xd53276db) EmmetBridgeTokenExcesses {
    query_id: uint64
}

struct (0x946a98b6) EmmetBridgeDeploy {
    queryId: uint64
}

struct (0x12688ef6) EmmetBridgeDeleteChain {
    chain_id: int257
}

struct (0xddc3cb70) EmmetBridgeDeleteModule {
    step: int257
}

struct (0x66991fc4) EmmetBridgeDeleteStategies {
    chain_id: int257
    from_token: int257
    to_token: int257
}

struct (0x660975d0) EmmetBridgeDeleteToken {
    symbol: string
}

struct (0x747f7527) EmmetBridgeDeleteValidator {
    candidate: address
}

struct (0x7a4508d9) EmmetBridgePause {
}

struct (0xa1bc3662) EmmetBridgeSetAdmin {
    newAdmin: address
}

struct (0xcc77ce63) EmmetBridgeSetChain {
    name: string
    chain_id: int257
}

struct (0xd329ee83) EmmetBridgeSetCFO {
    newCFO: address
}

struct (0x7c86de62) EmmetBridgeSetModule {
    step: int257
    module: address
}

struct (0x6295d88f) EmmetBridgeSetValidator {
    candidate: address
}

struct (0xbd367607) EmmetBridgeSetStrategies {
    chain_id: int257
    from_token: int257
    to_token: int257
    tactContinuation: Cell<EmmetBridgeSetStrategiesContinuation>
}

struct EmmetBridgeSetStrategiesContinuation {
    foreign: EmmetBridgeSteps
    incomming: EmmetBridgeSteps
    local: EmmetBridgeSteps
}

struct (0x287dc1c8) EmmetBridgeSetToken {
    address: address
    decimals: uint8
    emmet_lp: address
    symbol: string
    swap_pool: address
    tactContinuation: Cell<EmmetBridgeSetTokenContinuation>
}

struct EmmetBridgeSetTokenContinuation {
    swap_router: address
    wallet: address
}

struct (0x8dcb2d19) EmmetBridgeUnpause {
}

struct (0x56a51c2a) EmmetBridgeUpdateChainFee {
    chain_id: int257
    strategy_step: uint8
    gas_amount: int257
}

struct (0xf2129f4e) EmmetBridgeUpdateConsensusFee {
    amount: int257
}

struct (0xb298851f) EmmetBridgeUpdateMinimumTxFee {
    amount: int257
}

struct (0x9b44b617) EmmetBridgeUpdateProtocolFee {
    amount: int257
}

struct (0x23e3b324) EmmetBridgeWithdrawGas {
    amount: int257
}

struct EmmetBridgeToken {
    address: address
    decimals: uint8
    emmet_lp: address
    symbol: string
    swap_pool: address
    tactContinuation: Cell<EmmetBridgeTokenContinuation>
}

struct EmmetBridgeTokenContinuation {
    swap_router: address
    wallet: address
}

struct EmmetBridgeChain {
    name: string
    chain_id: int257
}

struct EmmetBridgeForeignFees {
    i: map<int257, int257>
}

struct EmmetBridgeSteps {
    path: map<int257, int257>
    size: int257
}

struct EmmetBridgeStrategies {
    foreign: EmmetBridgeSteps
    incomming: EmmetBridgeSteps
    local: EmmetBridgeSteps
}

struct EmmetBridgeToTokenMap {
    i: map<int257, Cell<EmmetBridgeStrategies>>
}

struct EmmetBridgeFromTokenMap {
    i: map<int257, Cell<EmmetBridgeToTokenMap>>
}

struct (0x0a61db59) EmmetBridgeGrantRole {
    to: address
    role_id: int257
}

struct (0x1732be21) EmmetBridgeRenounceRole {
    role_id: int257
    address: address
}

struct (0x513ef35e) EmmetBridgeRevokeRole {
    to: address
    role_id: int257
}

struct EmmetBridgeRoleData {
    roles: map<address, bool>
    admin_role: int257
}

struct (0x24fa47c9) EmmetBridgeUpdateRoleAdmin {
    role_id: int257
    role_admin: int257
}

struct EmmetBridgeData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    admin: address
    cfo: address
    chains: map<int257, Cell<EmmetBridgeChain>>
    chainId: int257
    tactContinuation: Cell<EmmetBridgeDataContinuation>
}

struct EmmetBridgeDataContinuation {
    consensus_fee: int257
    foreign_fees: map<int257, Cell<EmmetBridgeForeignFees>>
    incomming_txs: map<int257, bool>
    locked: map<int257, int257>
    min_tx_fee: int257
    tactContinuation: Cell<EmmetBridgeDataContinuation2>
}

struct EmmetBridgeDataContinuation2 {
    modules: map<int257, address>
    nonce: int257
    paused: bool
    protocol_fee: int257
    roles: map<int257, Cell<EmmetBridgeRoleData>>
    token_strategies: map<int257, Cell<EmmetBridgeFromTokenMap>>
    threshold: int257
    tactContinuation: Cell<EmmetBridgeDataContinuation3>
}

struct EmmetBridgeDataContinuation3 {
    tokens: map<int257, Cell<EmmetBridgeToken>>
    TVL: int257
    validators: map<int257, address>
    validator_count: int257
}

type EmmetBridgeIncomingMessage =
    | EmmetBridgeTokenExcesses
    | EmmetBridgeFreezeTon
    | EmmetBridgeJettonBurnNotification
    | EmmetBridgeTokenTransferNotification
    | EmmetBridgeDeleteChain
    | EmmetBridgeDeleteModule
    | EmmetBridgeDeleteStategies
    | EmmetBridgeDeleteToken
    | EmmetBridgeDeleteValidator
    | EmmetBridgePause
    | EmmetBridgeSetAdmin
    | EmmetBridgeSetChain
    | EmmetBridgeSetCFO
    | EmmetBridgeSetModule
    | EmmetBridgeSetStrategies
    | EmmetBridgeSetToken
    | EmmetBridgeSetValidator
    | EmmetBridgeUnpause
    | EmmetBridgeUpdateChainFee
    | EmmetBridgeUpdateConsensusFee
    | EmmetBridgeUpdateMinimumTxFee
    | EmmetBridgeUpdateProtocolFee
    | EmmetBridgeWithdrawGas
    | EmmetBridgeDeploy
    | EmmetBridgeGrantRole
    | EmmetBridgeRevokeRole
    | EmmetBridgeRenounceRole
    | EmmetBridgeUpdateRoleAdmin

enum EmmetBridgeErrors {
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
    /// EmmetBridge: Wallet for Jetton not set
    EmmetBridgeWalletForJettonNotSet = 1348
    /// AccessControl: Role ID doesn't exist
    AccessControlRoleIDDoesnTExist = 2927
    /// AccessControl: Role ADMIN is undefined
    AccessControlRoleADMINIsUndefined = 5524
    /// AccessControl: Doesn't have the CFO role
    AccessControlDoesnTHaveTheCFORole = 6187
    /// AccessControl: Role VALIDATOR is undefined
    AccessControlRoleVALIDATORIsUndefined = 7912
    /// EmmetBridge: The contract is paused
    EmmetBridgeTheContractIsPaused = 7929
    /// AccessControl: BadConfirmation
    AccessControlBadConfirmation = 7947
    /// EmmetBridge: unsupported incoming strategy
    EmmetBridgeUnsupportedIncomingStrategy = 8083
    /// AccessControl: Doesn't have the BRIDGE role
    AccessControlDoesnTHaveTheBRIDGERole = 10858
    /// AccessControl: Role BRIDGE is undefined
    AccessControlRoleBRIDGEIsUndefined = 12450
    /// EmmetBridge: Previously processed TX
    EmmetBridgePreviouslyProcessedTX = 13687
    /// EmmetBridge: Burned with no bridge instructions
    EmmetBridgeBurnedWithNoBridgeInstructions = 15470
    /// AccessControl: Doesn't have the VALIDATOR role
    AccessControlDoesnTHaveTheVALIDATORRole = 15733
    /// AccessControl: Doesn't have the ADMIN role
    AccessControlDoesnTHaveTheADMINRole = 17039
    /// EmmetBridge: unsupported chain
    EmmetBridgeUnsupportedChain = 17393
    /// EmmetBridge: unsupported from_token
    EmmetBridgeUnsupportedFromToken = 17817
    /// AccessControl: Role doesn't exist
    AccessControlRoleDoesnTExist = 21733
    /// EmmetBridge: JettonWallet not set
    EmmetBridgeJettonWalletNotSet = 22394
    /// EmmetBridge: BFT threshold not reached.
    EmmetBridgeBFTThresholdNotReached = 23959
    /// EmmetBridge: Invalid Sender
    EmmetBridgeInvalidSender = 24015
    /// Validator already exists
    ValidatorAlreadyExists = 27930
    /// EmmetBridge: Unauthorised Burn notification
    EmmetBridgeUnauthorisedBurnNotification = 32311
    /// EmmetBridge: unsupported outgoing strategy
    EmmetBridgeUnsupportedOutgoingStrategy = 35021
    /// EmmetBridge: Insufficient fee
    EmmetBridgeInsufficientFee = 38572
    /// EmmetBridge: Unsupported step
    EmmetBridgeUnsupportedStep = 39260
    /// EmmetBridge: unsupported to_token
    EmmetBridgeUnsupportedToToken = 43937
    /// Negative protocol fee prohibited
    NegativeProtocolFeeProhibited = 48142
    /// EmmetBridge: Cannot MINT Toncoin
    EmmetBridgeCannotMINTToncoin = 48957
    /// AccessControl: Doesnt have the role
    AccessControlDoesntHaveTheRole = 50413
    /// EmmetBridge: Unsupported flow. Instead burn & notify the bridge!
    EmmetBridgeUnsupportedFlowInsteadBurnNotifyTheBridge = 53050
    /// AccessControl: Role CFO is undefined
    AccessControlRoleCFOIsUndefined = 53581
    /// EmmetBridge: in FreezeTon from_token must be TON
    EmmetBridgeInFreezeTonFromTokenMustBeTON = 54162
    /// EmmetBridge: Installment hash mismatch
    EmmetBridgeInstallmentHashMismatch = 57859
    /// Negative TX fee prohibited
    NegativeTXFeeProhibited = 61198
    /// EmmetBridge: Negative consensus fee prohibited
    EmmetBridgeNegativeConsensusFeeProhibited = 63023
}

get fun estimate_fee(chain_id: int257, from_token: int257, to_token: int257): int257 {
    throw 0;
}

get fun get_admin(): address {
    throw 0;
}

get fun get_cfo(): address {
    throw 0;
}

get fun get_chain(chain_id: int257): EmmetBridgeChain {
    throw 0;
}

get fun get_min_tx_fee(): int257 {
    throw 0;
}

get fun get_module(step: int257): address {
    throw 0;
}

get fun get_nonce(): int257 {
    throw 0;
}

get fun get_chain_id(): int257 {
    throw 0;
}

get fun get_consensus_fee(): int257 {
    throw 0;
}

get fun get_locked(token: int257): int257 {
    throw 0;
}

get fun get_paused(): bool {
    throw 0;
}

get fun get_protocol_fee(): int257 {
    throw 0;
}

get fun get_step_fee(chain_id: int257, step: int257): int257 {
    throw 0;
}

get fun get_threshold(): int257 {
    throw 0;
}

get fun get_token(key: int257): EmmetBridgeToken {
    throw 0;
}

get fun get_tvl(): int257 {
    throw 0;
}

get fun get_validator(index: int257): address {
    throw 0;
}

get fun get_validator_count(): int257 {
    throw 0;
}

get fun is_processed(hash: int257): bool {
    throw 0;
}

get fun is_validator(address: address): bool {
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

get fun validator_role_id(): int257 {
    throw 0;
}

get fun get_foreign_strategies(chain_id: int257, from_token: int257, to_token: int257): EmmetBridgeSteps {
    throw 0;
}

get fun get_incoming_strategies(chain_id: int257, from_token: int257, to_token: int257): EmmetBridgeSteps {
    throw 0;
}

get fun get_local_strategies(chain_id: int257, from_token: int257, to_token: int257): EmmetBridgeSteps {
    throw 0;
}

get fun get_strategies(chain_id: int257, from_token: int257, to_token: int257): EmmetBridgeStrategies {
    throw 0;
}
