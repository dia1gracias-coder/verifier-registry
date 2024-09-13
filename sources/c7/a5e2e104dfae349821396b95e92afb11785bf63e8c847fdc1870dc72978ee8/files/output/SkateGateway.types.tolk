// Generated from the verified Tact contract ABI.
contract SkateGateway {
    storage: SkateGatewayData
    incomingMessages: SkateGatewayIncomingMessage
    thrownErrors: SkateGatewayErrors
}

struct (0x946a98b6) SkateGatewayDeploy {
    queryId: uint64
}

struct (0x819dbe99) SkateGatewayChangeOwner {
    queryId: uint64
    newOwner: address
}

struct SkateGatewayPayload {
    destination: cell
    data: cell
}

struct SkateGatewayExecutionInfo {
    value: coins
    expiration: uint32
    payload: SkateGatewayPayload
}

struct (0xf5eb6224) SkateGatewaySkateInitiateTaskNotification {
    query_id: uint64
    user: address
    execution_info: SkateGatewayExecutionInfo
    callback: bool
}

struct (0xc8c28f2d) SkateGatewaySetExecutor {
    executor: address
}

struct (0x471c2809) SkateGatewayRevokeExecutor {
    executor: address
}

struct (0x4c2925bc) SkateGatewayChangeTimeout {
    new_timeout: uint16
}

struct (0x75a6e8ec) SkateGatewayTopUpTON {
}

struct (0x44807e69) SkateGatewayWithdrawTON {
}

struct SkateGatewayData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    relayer: int257
    executors: map<address, bool>
    tactContinuation: Cell<SkateGatewayDataContinuation>
}

struct SkateGatewayDataContinuation {
    nonces: map<uint16, cell>
    old_nonces: map<uint16, cell>
    next_nonce: uint32
    timeout: uint16
    last_clean_timestamp: uint64
}

type SkateGatewayIncomingMessage =
    | SkateGatewayTopUpTON
    | SkateGatewayWithdrawTON
    | SkateGatewaySetExecutor
    | SkateGatewayRevokeExecutor
    | SkateGatewayChangeTimeout
    | SkateGatewaySkateInitiateTaskNotification
    | SkateGatewayDeploy
    | SkateGatewayChangeOwner

enum SkateGatewayErrors {
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
    /// SkateGateway::SkateExecuteTask::Nonce out of bound!
    SkateGatewaySkateExecuteTaskNonceOutOfBound = 5602
    /// SkateGateway::SkateInitiateTaskNotification::Not enough processing fee!
    SkateGatewaySkateInitiateTaskNotificationNotEnoughProcessingFee = 6808
    /// SkateGateway::validate_relayer_signature()::Invalid relayer signature!
    SkateGatewayValidateRelayerSignatureInvalidRelayerSignature = 10580
    /// SkateGateway::SkateExecuteTask::Invalid created_at!
    SkateGatewaySkateExecuteTaskInvalidCreatedAt = 15633
    /// SkateGateway::Bit index out of bound!
    SkateGatewayBitIndexOutOfBound = 23162
    /// SkateGateway::Nonce used, please request for new signature!
    SkateGatewayNonceUsedPleaseRequestForNewSignature = 33281
    /// SkateGateway::SkateExecuteTask::Task expired!
    SkateGatewaySkateExecuteTaskTaskExpired = 45396
    /// SkateGateway::set_relayer()::Not approved by new relayer!
    SkateGatewaySetRelayerNotApprovedByNewRelayer = 48599
    /// SkateGateway::Cell index out of bound!
    SkateGatewayCellIndexOutOfBound = 50932
    /// SkateGateway::SkateExecuteTask::Insufficient execution value
    SkateGatewaySkateExecuteTaskInsufficientExecutionValue = 54733
}

get fun next_nonce(): int257 {
    throw 0;
}

get fun timeout(): int257 {
    throw 0;
}

get fun creationMsg(): string {
    throw 0;
}

get fun relayer(): int257 {
    throw 0;
}

get fun isExecutor(addr: address): bool {
    throw 0;
}

get fun executors(): map<address, bool> {
    throw 0;
}

get fun changeRelayerMsg(): string {
    throw 0;
}

get fun payload_hash(query_id: int257, target: address, payload: SkateGatewayPayload, expiration: int257, nonce: int257, created_at: int257): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
