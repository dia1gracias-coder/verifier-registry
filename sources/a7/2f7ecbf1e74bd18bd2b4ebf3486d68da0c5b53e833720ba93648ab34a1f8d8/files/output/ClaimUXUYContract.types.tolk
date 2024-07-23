// Generated from the verified Tact contract ABI.
contract ClaimUXUYContract {
    storage: ClaimUXUYContractData
    incomingMessages: ClaimUXUYContractIncomingMessage
    thrownErrors: ClaimUXUYContractErrors
}

struct (0x946a98b6) ClaimUXUYContractDeploy {
    queryId: uint64
}

struct (0x9703843b) ClaimUXUYContractAuthorizeOperator {
    address: address
}

struct (0x4c84e793) ClaimUXUYContractRevokeOperator {
    address: address
}

struct ClaimUXUYContractOperation {
    date: int257
    amount: coins
    transId: string
}

struct (0x4c26b684) ClaimUXUYContractClaim {
    operation: ClaimUXUYContractOperation
    signature: bits512
    query_id: uint64
}

struct (0xdef8c0ad) ClaimUXUYContractUpdatePublicKey {
    publicKey: int257
}

struct (0x12f0a88d) ClaimUXUYContractUpdateUXUYContractAddress {
    address: address
}

struct (0x6ba59489) ClaimUXUYContractUpdateOwnerAddress {
    address: address
}

struct ClaimUXUYContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    reentrancyGuardStatus: int257
    status: bool
    userCheckInEntries: map<int257, bool>
    transIds: map<int257, bool>
    tactContinuation: Cell<ClaimUXUYContractDataContinuation>
}

struct ClaimUXUYContractDataContinuation {
    superOperators: map<address, bool>
    jettonMasterAddress: address
    publicKey: uint256
}

type ClaimUXUYContractIncomingMessage =
    | ClaimUXUYContractUpdateOwnerAddress
    | ClaimUXUYContractUpdateUXUYContractAddress
    | ClaimUXUYContractUpdatePublicKey
    | ClaimUXUYContractClaim
    | ClaimUXUYContractDeploy
    | ClaimUXUYContractAuthorizeOperator
    | ClaimUXUYContractRevokeOperator

enum ClaimUXUYContractErrors {
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
    /// Not super operator
    NotSuperOperator = 11521
    /// Not owner
    NotOwner = 14534
    /// Only deployer is allowed to withdraw
    OnlyDeployerIsAllowedToWithdraw = 15509
    /// ReentrancyGuard: reentrant call
    ReentrancyGuardReentrantCall = 17510
    /// Exists transId
    ExistsTransId = 21655
    /// Only deployer can update public key
    OnlyDeployerCanUpdatePublicKey = 22490
    /// check-in status is false
    CheckInStatusIsFalse = 25821
}

get fun existsTransId(transId: string): bool {
    throw 0;
}

get fun getPublicKey(): int257 {
    throw 0;
}

get fun getUXUYContractAddress(): address {
    throw 0;
}

get fun getOwnerAddress(): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
