// Generated from the verified Tact contract ABI.
contract RaffleManager {
    storage: RaffleManagerData
    incomingMessages: RaffleManagerIncomingMessage
    thrownErrors: RaffleManagerErrors
}

struct (0x946a98b6) RaffleManagerDeploy {
    queryId: uint64
}

struct (0x819dbe99) RaffleManagerChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x4df9f5d0) RaffleManagerCreatePot {
    potId: int257
    entryFee: uint128
}

struct (0x0912de49) RaffleManagerJoinPot {
    potId: int257
}

struct (0x9bcd5051) RaffleManagerClosePot {
    potId: int257
}

struct RaffleManagerPotInfo {
    potId: int257
    totalAmount: uint128
    entryFee: uint128
    participants: map<int257, address>
    participantsLength: uint8
    participantsStart: uint8
    winner: address
    closed: bool
}

struct RaffleManagerData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    pots: map<int257, Cell<RaffleManagerPotInfo>>
}

type RaffleManagerIncomingMessage =
    | RaffleManagerCreatePot
    | RaffleManagerJoinPot
    | RaffleManagerClosePot
    | RaffleManagerDeploy
    | RaffleManagerChangeOwner

enum RaffleManagerErrors {
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
    /// Pot is already closed
    PotIsAlreadyClosed = 11148
    /// Insufficient entry fee
    InsufficientEntryFee = 20096
    /// Index out of bounds
    IndexOutOfBounds = 44718
    /// Pot ID already exists
    PotIDAlreadyExists = 50275
    /// Pot does not exist
    PotDoesNotExist = 52908
}

get fun potInfo(potId: int257): RaffleManagerPotInfo {
    throw 0;
}

get fun participant(potId: int257, index: int257): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
