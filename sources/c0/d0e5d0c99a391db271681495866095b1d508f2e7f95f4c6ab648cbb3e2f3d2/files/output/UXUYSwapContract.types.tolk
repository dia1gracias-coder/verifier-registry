// Generated from the verified Tact contract ABI.
contract UXUYSwapContract {
    storage: UXUYSwapContractData
    incomingMessages: UXUYSwapContractIncomingMessage
    thrownErrors: UXUYSwapContractErrors
}

struct (0x946a98b6) UXUYSwapContractDeploy {
    queryId: uint64
}

struct UXUYSwapContractOperation {
    date: int257
    from_token_amont: coins
    swap_rate: int16
    rate_decimals: uint32
    transId: string
    trans_query_id: uint64
    query_id: uint64
    forward_ton_amount: coins
}

struct (0x9e19233e) UXUYSwapContractSwapSignature {
    operation: UXUYSwapContractOperation
    tactContinuation: Cell<UXUYSwapContractSwapSignatureContinuation>
}

struct UXUYSwapContractSwapSignatureContinuation {
    signature: bits512
    token_index: int8
    forward_payload: RemainingBitsAndRefs
}

struct (0xe5c499f4) UXUYSwapContractWithdrawToken {
    token_index: int8
    amount: coins
    query_id: uint64
    forward_ton_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct UXUYSwapContractSwapData {
    from_token_amont: coins
    amount: coins
    token_index: int8
    to: address
    transId: string
    query_id: uint64
    forward_ton_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0xdef8c0ad) UXUYSwapContractUpdatePublicKey {
    publicKey: int257
}

struct (0xc8cb0d72) UXUYSwapContractUpdateSalt {
    newSalt: string
}

struct (0x6ba59489) UXUYSwapContractUpdateOwnerAddress {
    address: address
}

struct (0xa0d165db) UXUYSwapContractUpdateServiceFeeRate {
    serviceFeeRate: int16
}

struct (0x3b27b063) UXUYSwapContractUpdateJettonWalletAddress {
    token_index: int8
    address: address
}

struct (0xd53276db) UXUYSwapContractTokenExcesses {
    query_id: uint64
}

struct UXUYSwapContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    transIds: map<int257, bool>
    tactContinuation: Cell<UXUYSwapContractDataContinuation>
}

struct UXUYSwapContractDataContinuation {
    queryIds: map<int257, Cell<UXUYSwapContractSwapData>>
    publicKey: uint256
    salt: string
    tokenIndexToJettonWalletAddress: map<int8, address>
    serviceFeeRate: int16
}

type UXUYSwapContractIncomingMessage =
    | UXUYSwapContractUpdateOwnerAddress
    | UXUYSwapContractUpdatePublicKey
    | UXUYSwapContractUpdateSalt
    | UXUYSwapContractUpdateServiceFeeRate
    | UXUYSwapContractUpdateJettonWalletAddress
    | UXUYSwapContractWithdrawToken
    | UXUYSwapContractSwapSignature
    | UXUYSwapContractTokenExcesses
    | UXUYSwapContractDeploy

enum UXUYSwapContractErrors {
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
    /// Signature is invalid
    SignatureIsInvalid = 2069
    /// Not owner
    NotOwner = 14534
    /// Exists transId
    ExistsTransId = 21655
    /// amount is zero
    AmountIsZero = 30696
    /// No such token
    NoSuchToken = 37378
}

get fun existsTransId(transId: string): bool {
    throw 0;
}

get fun getPublicKey(): int257 {
    throw 0;
}

get fun getOwnerAddress(): address {
    throw 0;
}

get fun get_swap_data(query_id: int257): UXUYSwapContractSwapData? {
    throw 0;
}
