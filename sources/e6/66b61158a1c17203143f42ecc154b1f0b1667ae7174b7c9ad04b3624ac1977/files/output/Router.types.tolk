// Generated from the verified Tact contract ABI.
contract Router {
    storage: RouterData
    incomingMessages: RouterIncomingMessage
    thrownErrors: RouterErrors
}

struct (0x946a98b6) RouterDeploy {
    queryId: uint64
}

struct (0x2c10ad33) RouterRouteDeployAndInitDao {
    prodMsgValue: uint64
    devMsgValue: uint64
    prodRegistry: address
    devRegistry: address
    owner: address
    tactContinuation: Cell<RouterRouteDeployAndInitDaoContinuation>
}

struct RouterRouteDeployAndInitDaoContinuation {
    proposalOwner: address
    metadata: address
}

struct RouterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
}

type RouterIncomingMessage =
    | RouterRouteDeployAndInitDao
    | RouterDeploy

enum RouterErrors {
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
    /// Already initialized
    AlreadyInitialized = 2977
    /// Invalid sender
    InvalidSender = 4429
    /// Only admin can set the create dao fee
    OnlyAdminCanSetTheCreateDaoFee = 4600
    /// Only admin can set the dao fwd msg fee
    OnlyAdminCanSetTheDaoFwdMsgFee = 8645
    /// Only admin can set new registry admin
    OnlyAdminCanSetNewRegistryAdmin = 23452
    /// Below min fee for create dao
    BelowMinFeeForCreateDao = 46336
    /// Only registry can change fwd msg fee
    OnlyRegistryCanChangeFwdMsgFee = 51893
    /// Only admin can set the new dao fwd msg fee
    OnlyAdminCanSetTheNewDaoFwdMsgFee = 56012
    /// Below min fee for dao forward message
    BelowMinFeeForDaoForwardMessage = 60173
}
