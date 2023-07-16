// Generated from the verified Tact contract ABI.
contract Dao {
    storage: DaoData
    incomingMessages: DaoIncomingMessage
    thrownErrors: DaoErrors
}

struct DaoSendParameters {
    bounce: bool
    to: address
    value: int257
    mode: int257
    body: cell?
    code: cell?
    data: cell?
}

struct (0x946a98b6) DaoDeploy {
    queryId: uint64
}

struct (0xc2b41d43) DaoSetOwner {
    newOwner: address
}

struct (0xd0e3be76) DaoSetProposalOwner {
    newProposalOwner: address
}

struct (0xf4f3a602) DaoSetFwdMsgFee {
    newFwdMsgFee: uint64
}

struct (0xda2f907f) DaoSetMetadata {
    newMetadata: address
}

struct (0x64c3c3e4) DaoFwdMsg {
    fwdMsg: DaoSendParameters
}

struct (0xecb876eb) DaoInit {
    owner: address
    proposalOwner: address
    metadata: address
    fwdMsgFee: uint64
}

struct DaoContractState {
    registry: address
    owner: address
    proposalOwner: address
    tactContinuation: Cell<DaoContractStateContinuation>
}

struct DaoContractStateContinuation {
    metadata: address
    daoIndex: uint32
    fwdMsgFee: uint64
}

struct DaoData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    registry: address
    proposalOwner: address
    daoIndex: uint32
    tactContinuation: Cell<DaoDataContinuation>
}

struct DaoDataContinuation {
    metadata: address
    fwdMsgFee: uint64
}

type DaoIncomingMessage =
    | DaoInit
    | DaoSetOwner
    | DaoSetProposalOwner
    | DaoSetMetadata
    | DaoSetFwdMsgFee
    | DaoFwdMsg
    | DaoDeploy

enum DaoErrors {
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

get fun state(): DaoContractState {
    throw 0;
}
