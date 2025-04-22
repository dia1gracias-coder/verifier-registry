// Generated from the verified Tact contract ABI.
contract UniqueIdManager {
    storage: UniqueIdManagerData2
    incomingMessages: UniqueIdManagerIncomingMessage
    thrownErrors: UniqueIdManagerErrors
}

struct UniqueIdManagerStateInit {
    code: cell
    data: cell
}

struct (0x946a98b6) UniqueIdManagerDeploy {
    queryId: uint64
}

struct (0x80a57950) UniqueIdManagerSetBoxManager {
    box_manager: address
}

struct UniqueIdManagerData {
    owner: address
    box_manager: address?
}

struct UniqueIdManagerData2 {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    box_manager: address?
}

type UniqueIdManagerIncomingMessage =
    | UniqueIdManagerSetBoxManager
    | UniqueIdManagerDeploy

enum UniqueIdManagerErrors {
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
    /// Only for Box Manager
    OnlyForBoxManager = 7900
    /// Only for item contracts.
    OnlyForItemContracts = 9334
    /// Only master_contract allowed [INIT]
    OnlyMasterContractAllowedINIT = 28344
    /// Box Manager not set
    BoxManagerNotSet = 34655
    /// Check for nonsense
    CheckForNonsense = 36949
    /// Only owner allowed
    OnlyOwnerAllowed = 51168
    /// Only master_contract allowed
    OnlyMasterContractAllowed = 61051
}

get fun getUniqueIdManagerData(): UniqueIdManagerData {
    throw 0;
}

get fun getItemInit(operation_id: string): UniqueIdManagerStateInit {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
