// Generated from the verified Tact contract ABI.
contract GameTon {
    storage: GameTonData
    incomingMessages: GameTonClaim
    thrownErrors: GameTonErrors
}

struct (0x00000003) GameTonClaim {
}

struct GameTonTicket {
    price: coins
    timestamp: int64
    wallet: address
}

struct GameTonGameConfig {
    endTime: int32
    ticketDeadline: int64
    ticketAmount: int64
    authorPercent: int8
    owner: address
    beneficiary: address
    winner: address?
    winningPrice: int32
    isFinished: bool
    isClaimed: bool
    tactContinuation: Cell<GameTonGameConfigContinuation>
}

struct GameTonGameConfigContinuation {
    gameId: uint64
    gameName: string
}

struct GameTonGameDistribution {
    player: int64
    author: int64
    service: int64
}

struct GameTonGameAccounting {
    total: coins
    player: coins
    author: coins
    service: coins
}

struct GameTonData {
    tactDeploymentCompleted: bool
    endTime: int64
    ticketDeadline: int64
    ticketAmount: int64
    authorPercent: int8
    owner: address
    gameId: uint64
    gameName: string
    tickets: map<int257, Cell<GameTonTicket>>
    winner: address?
    winningPrice: int32
    isFinished: bool
    isClaimed: bool
    staked: coins
}

enum GameTonErrors {
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
    /// NO_TICKETS
    NOTICKETS = 6753
    /// PRICE_ALREADY_USED
    PRICEALREADYUSED = 8990
    /// DEADLINE_AFTER_END
    DEADLINEAFTEREND = 9041
    /// INVALID_TIMESTAMP
    INVALIDTIMESTAMP = 13949
    /// INVALID_TON_AMOUNT
    INVALIDTONAMOUNT = 14504
    /// ALREADY_CLAIMED
    ALREADYCLAIMED = 16036
    /// INVALID_PERCENT
    INVALIDPERCENT = 17488
    /// ALREADY_FINALIZED
    ALREADYFINALIZED = 20720
    /// TICKETS_CLOSED
    TICKETSCLOSED = 24126
    /// INSUFFICIENT_DEPLOY_VALUE
    INSUFFICIENTDEPLOYVALUE = 32537
    /// GAME_NOT_FINISHED
    GAMENOTFINISHED = 37565
    /// INVALID_AUTHOR_PERCENT
    INVALIDAUTHORPERCENT = 39112
    /// INVALID_SIGNATURE
    INVALIDSIGNATURE = 45972
    /// UNAUTHORIZED
    UNAUTHORIZED = 46955
    /// ENDTIME_MUST_BE_IN_FUTURE
    ENDTIMEMUSTBEINFUTURE = 48156
    /// NO_WINNER
    NOWINNER = 50453
    /// TICKET_AMOUNT_ZERO
    TICKETAMOUNTZERO = 53936
    /// MAX_TICKETS_EXCEEDED
    MAXTICKETSEXCEEDED = 54531
    /// NOT_FINISHED
    NOTFINISHED = 57109
}

get fun config(): GameTonGameConfig {
    throw 0;
}

get fun distribution(total: int257): GameTonGameDistribution {
    throw 0;
}

get fun distributable(): GameTonGameAccounting {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}

get fun ticketsFlat(): map<int257, Cell<GameTonTicket>> {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
