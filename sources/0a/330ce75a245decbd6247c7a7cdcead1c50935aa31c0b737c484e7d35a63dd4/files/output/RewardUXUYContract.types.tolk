// Generated from the verified Tact contract ABI.
contract RewardUXUYContract {
    storage: RewardUXUYContractData
    incomingMessages: RewardUXUYContractIncomingMessage
    thrownErrors: RewardUXUYContractErrors
}

struct (0x946a98b6) RewardUXUYContractDeploy {
    queryId: uint64
}

struct RewardUXUYContractOperation {
    date: int257
    amount: coins
    transId: string
}

struct (0x569e2a01) RewardUXUYContractRewardUXUY {
    operation: RewardUXUYContractOperation
    signature: bits512
    query_id: uint64
}

struct (0xdef8c0ad) RewardUXUYContractUpdatePublicKey {
    publicKey: int257
}

struct (0x12f0a88d) RewardUXUYContractUpdateUXUYContractAddress {
    address: address
}

struct (0x6ba59489) RewardUXUYContractUpdateOwnerAddress {
    address: address
}

struct (0xc8cb0d72) RewardUXUYContractUpdateSalt {
    newSalt: string
}

struct RewardUXUYContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    transIds: map<int257, bool>
    jettonMasterAddress: address
    publicKey: uint256
    salt: string
}

type RewardUXUYContractIncomingMessage =
    | RewardUXUYContractUpdateOwnerAddress
    | RewardUXUYContractUpdateUXUYContractAddress
    | RewardUXUYContractUpdatePublicKey
    | RewardUXUYContractUpdateSalt
    | RewardUXUYContractRewardUXUY
    | RewardUXUYContractDeploy

enum RewardUXUYContractErrors {
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
    /// Only deployer is allowed to withdraw
    OnlyDeployerIsAllowedToWithdraw = 15509
    /// Exists transId
    ExistsTransId = 21655
    /// Only deployer can update public key
    OnlyDeployerCanUpdatePublicKey = 22490
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
