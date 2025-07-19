// Generated from the verified Tact contract ABI.
contract DrawContract {
    storage: DrawContractData
    incomingMessages: DrawContractIncomingMessage
    thrownErrors: DrawContractErrors
}

struct (0x946a98b6) DrawContractDeploy {
    queryId: uint64
}

struct DrawContractWinner {
    userId: int257
    tgId: int257
    firstName: string?
    lastName: string?
    tactContinuation: Cell<DrawContractWinnerContinuation>
}

struct DrawContractWinnerContinuation {
    username: string?
    ticketId: int257
    createdAt: int257
}

struct DrawContractDrawResult {
    drawId: int257
    ownerId: int257
    winnersCount: int257
    tactContinuation: Cell<DrawContractDrawResultContinuation>
}

struct DrawContractDrawResultContinuation {
    totalTickets: int257
    drawType: string
    completedAt: int257
    winners: map<int257, Cell<DrawContractWinner>>
}

struct (0x1b68043f) DrawContractRecordDrawResult {
    drawId: int257
    ownerId: int257
    winnersCount: int257
    tactContinuation: Cell<DrawContractRecordDrawResultContinuation>
}

struct DrawContractRecordDrawResultContinuation {
    totalTickets: int257
    drawType: string
    winners: map<int257, Cell<DrawContractWinner>>
}

struct DrawContractData {
    tactDeploymentCompleted: bool
    draws: map<int257, Cell<DrawContractDrawResult>>
    owner: address
    totalDraws: uint32
}

type DrawContractIncomingMessage =
    | DrawContractRecordDrawResult
    | DrawContractDeploy

enum DrawContractErrors {
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
    /// Draw already recorded
    DrawAlreadyRecorded = 24681
    /// Only owner can change ownership
    OnlyOwnerCanChangeOwnership = 38113
    /// Only owner can record draw results
    OnlyOwnerCanRecordDrawResults = 62342
}

get fun getDrawResult(drawId: int257): DrawContractDrawResult? {
    throw 0;
}

get fun getWinner(drawId: int257, winnerIndex: int257): DrawContractWinner? {
    throw 0;
}

get fun drawExists(drawId: int257): bool {
    throw 0;
}

get fun getTotalDraws(): int257 {
    throw 0;
}

get fun getOwner(): address {
    throw 0;
}
