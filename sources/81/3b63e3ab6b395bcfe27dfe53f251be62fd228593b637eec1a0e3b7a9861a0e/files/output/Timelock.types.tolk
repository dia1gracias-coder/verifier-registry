// Generated from the verified Tact contract ABI.
contract Timelock {
    storage: TimelockData
    incomingMessages: TimelockIncomingMessage
    thrownErrors: TimelockErrors
}

struct (0x5a040201) TimelockQueue {
    queryId: uint64
    proposalId: uint64
    proposalContract: address
    target: address
    method: uint32
    args: cell
    delay: uint64
}

struct (0x5a040202) TimelockExecutePending {
    queryId: uint64
    proposalId: uint64
}

struct (0x5a040203) TimelockCancel {
    queryId: uint64
    proposalId: uint64
}

struct TimelockPendingAction {
    proposalId: uint64
    proposalContract: address
    target: address
    method: uint32
    args: cell
    scheduledTime: uint64
    executed: bool
}

struct TimelockData {
    governor: address
    highValueDelayFloorSec: uint32
    pendingActions: map<uint64, Cell<TimelockPendingAction>>
}

type TimelockIncomingMessage =
    | TimelockQueue
    | TimelockExecutePending
    | TimelockCancel

enum TimelockErrors {
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
    /// Not enough Toncoin
    NotEnoughToncoin = 37
    /// Not enough extra currencies
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
    /// Invalid standard address
    InvalidStandardAddress = 136
    /// Not a basechain address
    NotABasechainAddress = 138
    /// Delay too short
    DelayTooShort = 15168
    /// Execute budget too low
    ExecuteBudgetTooLow = 21329
    /// Not queued
    NotQueued = 30807
    /// Only governor
    OnlyGovernor = 33186
    /// Args method mismatch
    ArgsMethodMismatch = 49154
    /// Already executed
    AlreadyExecuted = 52683
    /// High-value delay below floor
    HighValueDelayBelowFloor = 52837
    /// Not yet executable
    NotYetExecutable = 54421
    /// Already queued
    AlreadyQueued = 60880
}

get fun get_pending(id: int257): TimelockPendingAction? {
    throw 0;
}

get fun get_all_pending(): map<uint64, Cell<TimelockPendingAction>> {
    throw 0;
}

get fun get_governor(): address {
    throw 0;
}

get fun get_high_value_delay_floor(): int257 {
    throw 0;
}
