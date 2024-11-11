// Generated from the verified Tact contract ABI.
contract Registry {
    storage: RegistryData
    incomingMessages: RegistryIncomingMessage
    thrownErrors: RegistryErrors
}

struct (0x946a98b6) RegistryDeploy {
    queryId: uint64
}

struct (0xc95b9b64) RegistryDeployAndInitDao {
    owner: address
    proposalOwner: address
    metadata: address
}

struct (0xa8969119) RegistrySetDeployAndInitDaoFee {
    newDeployAndInitDaoFee: uint64
}

struct (0x03964bce) RegistrySetNewDaoFwdMsgFee {
    newDaosfwdMsgFee: uint64
}

struct (0x5815bd86) RegistrySendToDaoSetFwdMsgFee {
    daoId: uint32
    newFwdMsgFee: uint64
}

struct (0xc6d673ca) RegistrySetRegistryAdmin {
    newAdmin: address
}

struct RegistryContractState {
    registryId: uint32
    nextDaoId: uint32
    admin: address
    deployAndInitDaoFee: uint64
    newDaosfwdMsgFee: uint64
}

struct RegistryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    registryId: uint32
    nextDaoId: uint32
    admin: address
    deployAndInitDaoFee: uint64
    newDaosfwdMsgFee: uint64
}

type RegistryIncomingMessage =
    | RegistryDeployAndInitDao
    | RegistrySetDeployAndInitDaoFee
    | RegistrySetNewDaoFwdMsgFee
    | RegistrySendToDaoSetFwdMsgFee
    | RegistrySetRegistryAdmin
    | RegistryDeploy

enum RegistryErrors {
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

get fun state(): RegistryContractState {
    throw 0;
}

get fun nextDaoId(): int257 {
    throw 0;
}

get fun daoAddress(daoId: int257): address {
    throw 0;
}
