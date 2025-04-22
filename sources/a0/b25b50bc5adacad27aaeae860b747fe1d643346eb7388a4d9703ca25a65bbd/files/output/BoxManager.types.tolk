// Generated from the verified Tact contract ABI.
contract BoxManager {
    storage: BoxManagerData2
    incomingMessages: BoxManagerIncomingMessage
    thrownErrors: BoxManagerErrors
}

struct (0x946a98b6) BoxManagerDeploy {
    queryId: uint64
}

struct (0xa2ae46cb) BoxManagerSetUniqueIdManager {
    unique_id_manager: address
}

struct BoxManagerData {
    owner: address
    income_vault: address
    reward_vault: address
    gas_required: coins
    tactContinuation: Cell<BoxManagerDataContinuation>
}

struct BoxManagerDataContinuation {
    unique_id_manager: address?
}

struct BoxManagerData2 {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    income_vault: address
    reward_vault: address
    gas_required: coins
    tactContinuation: Cell<BoxManagerDataContinuation2>
}

struct BoxManagerDataContinuation2 {
    pub_key: int257
    unique_id_manager: address?
}

type BoxManagerIncomingMessage =
    | BoxManagerSetUniqueIdManager
    | BoxManagerDeploy

enum BoxManagerErrors {
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
    /// Not enough TON
    NotEnoughTON2 = 15304
    /// Message Expired
    MessageExpired = 17127
    /// OperationId check failed
    OperationIdCheckFailed = 17863
    /// Incorrect Signature
    IncorrectSignature = 25645
    /// Only Id Manager allowed
    OnlyIdManagerAllowed = 31245
    /// Only owner allowed
    OnlyOwnerAllowed = 51168
}

get fun getBoxManagerData(): BoxManagerData {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
