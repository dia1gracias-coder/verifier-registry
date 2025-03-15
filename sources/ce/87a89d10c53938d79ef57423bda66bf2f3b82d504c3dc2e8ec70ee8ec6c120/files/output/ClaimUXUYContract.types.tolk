// Generated from the verified Tact contract ABI.
contract ClaimUXUYContract {
    storage: ClaimUXUYContractData
    incomingMessages: ClaimUXUYContractIncomingMessage
    thrownErrors: ClaimUXUYContractErrors
}

struct (0x946a98b6) ClaimUXUYContractDeploy {
    queryId: uint64
}

struct ClaimUXUYContractContractData {
    publicKey: uint256
    owner: address
    jettonMasterAddress: address
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
    transIds: map<int257, bool>
    jettonMasterAddress: address
    publicKey: uint256
}

type ClaimUXUYContractIncomingMessage =
    | ClaimUXUYContractUpdateOwnerAddress
    | ClaimUXUYContractUpdateUXUYContractAddress
    | ClaimUXUYContractUpdatePublicKey
    | ClaimUXUYContractClaim
    | ClaimUXUYContractDeploy

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
    /// Exists transId
    ExistsTransId = 21655
    /// Not the owner
    NotTheOwner = 54727
}

get fun existsTransId(transId: string): bool {
    throw 0;
}

get fun getContractData(): ClaimUXUYContractContractData {
    throw 0;
}
