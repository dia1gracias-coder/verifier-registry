// Generated from the verified Tact contract ABI.
contract ClaimContract {
    storage: ClaimContractData
    incomingMessages: ClaimContractIncomingMessage
    thrownErrors: ClaimContractErrors
}

struct (0x946a98b6) ClaimContractDeploy {
    queryId: uint64
}

struct (0x9703843b) ClaimContractAuthorizeOperator {
    address: address
}

struct (0x4c84e793) ClaimContractRevokeOperator {
    address: address
}

struct ClaimContractOperation {
    date: int257
    amount: coins
    transId: string
}

struct (0x4c26b684) ClaimContractClaim {
    operation: ClaimContractOperation
    signature: bits512
    query_id: uint64
}

struct (0xdef8c0ad) ClaimContractUpdatePublicKey {
    publicKey: int257
}

struct (0x12f0a88d) ClaimContractUpdateUXUYContractAddress {
    address: address
}

struct ClaimContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    reentrancyGuardStatus: int257
    status: bool
    userCheckInEntries: map<int257, bool>
    transIds: map<int257, bool>
    tactContinuation: Cell<ClaimContractDataContinuation>
}

struct ClaimContractDataContinuation {
    superOperators: map<address, bool>
    jettonMasterAddress: address
    publicKey: uint256
}

type ClaimContractIncomingMessage =
    | ClaimContractUpdateUXUYContractAddress
    | ClaimContractUpdatePublicKey
    | ClaimContractClaim
    | ClaimContractDeploy
    | ClaimContractAuthorizeOperator
    | ClaimContractRevokeOperator

enum ClaimContractErrors {
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
    /// Already Checked In!
    AlreadyCheckedIn = 1708
    /// Signature is invalid
    SignatureIsInvalid = 2069
    /// Not super operator
    NotSuperOperator = 11521
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

get fun haveCheckedIn(user: address, date: int257): bool {
    throw 0;
}

get fun existsTransId(transId: string): bool {
    throw 0;
}

get fun getPublicKey(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
