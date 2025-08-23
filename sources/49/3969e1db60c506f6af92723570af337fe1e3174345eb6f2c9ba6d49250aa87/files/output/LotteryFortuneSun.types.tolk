// Generated from the verified Tact contract ABI.
contract LotteryFortuneSun {
    storage: LotteryFortuneSunData
    incomingMessages: LotteryFortuneSunIncomingMessage
    thrownErrors: LotteryFortuneSunErrors
}

struct (0x946a98b6) LotteryFortuneSunDeploy {
    queryId: uint64
}

struct (0x00000001) LotteryFortuneSunEnter {
}

struct (0x00000002) LotteryFortuneSunDraw {
}

struct LotteryFortuneSunData {
    tactDeploymentCompleted: bool
    owner: address
    networkFee: int257
    minAmount: int257
    tactContinuation: Cell<LotteryFortuneSunDataContinuation>
}

struct LotteryFortuneSunDataContinuation {
    prizePool: int257
    participants: map<address, int128>
    participantsCount: int8
    maxParticipants: int8
    minParticipants: int8
    lastWinner: address?
    jackpot: address?
    jackpotPercent: int32
    ownerPercent: int32
    deadline: int32?
}

type LotteryFortuneSunIncomingMessage =
    | LotteryFortuneSunEnter
    | LotteryFortuneSunDraw
    | LotteryFortuneSunDeploy

enum LotteryFortuneSunErrors {
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
    /// Amount must more or equal than minAmount
    AmountMustMoreOrEqualThanMinAmount = 4960
    /// Winner not found. Retry!
    WinnerNotFoundRetry = 18978
    /// Exist participants
    ExistParticipants = 20671
    /// Not enough participants
    NotEnoughParticipants = 29056
    /// Early draw
    EarlyDraw = 59539
    /// Pool is full
    PoolIsFull = 59757
    /// Deadline is not set
    DeadlineIsNotSet = 62625
    /// Pool is closed
    PoolIsClosed = 63182
}

get fun isExistsParticipants(address: address): bool {
    throw 0;
}

get fun participantsCount(): int257 {
    throw 0;
}

get fun lastWinner(): address? {
    throw 0;
}

get fun minAmount(): int257 {
    throw 0;
}

get fun prizePool(): int257 {
    throw 0;
}

get fun participants(): map<address, int128> {
    throw 0;
}

get fun deadline(): int257? {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
