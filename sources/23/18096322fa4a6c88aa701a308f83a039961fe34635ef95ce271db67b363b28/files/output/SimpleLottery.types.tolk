// Generated from the verified Tact contract ABI.
contract SimpleLottery {
    storage: SimpleLotteryData
    incomingMessages: SimpleLotteryIncomingMessage
    thrownErrors: SimpleLotteryErrors
}

struct (0x946a98b6) SimpleLotteryDeploy {
    queryId: uint64
}

struct SimpleLotteryTicket {
    owner: address
    lottery_type: uint8
    created_at: uint32
}

struct (0x85ad4c1c) SimpleLotteryStartDraw {
    lottery_type: uint8
}

struct (0xfee1dfd2) SimpleLotteryFinalizeDraw {
    lottery_type: uint8
    external_seed: uint256
}

struct SimpleLotteryData {
    tactDeploymentCompleted: bool
    owner: address
    paused: bool
    prize_pools: map<uint8, coins>
    tactContinuation: Cell<SimpleLotteryDataContinuation>
}

struct SimpleLotteryDataContinuation {
    tickets: map<uint64, Cell<SimpleLotteryTicket>>
    global_ticket_counter: uint64
    ticket_counters: map<uint8, uint64>
    active_draws: map<uint8, bool>
    draw_winners: map<uint8, address>
}

type SimpleLotteryIncomingMessage =
    | SimpleLotteryStartDraw
    | SimpleLotteryFinalizeDraw
    | SimpleLotteryDeploy

enum SimpleLotteryErrors {
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
    /// No tickets
    NoTickets = 1425
    /// Invalid quantity
    InvalidQuantity = 21178
    /// Insufficient gas
    InsufficientGas = 23951
    /// Draw already active
    DrawAlreadyActive = 29630
    /// Insufficient payment
    InsufficientPayment = 46647
    /// Invalid lottery type
    InvalidLotteryType = 47241
    /// Unauthorized
    Unauthorized = 49729
    /// No tickets sold
    NoTicketsSold = 50647
    /// Contract paused
    ContractPaused = 53793
    /// No active draw
    NoActiveDraw = 61627
}

get fun getPrizePool(ltype: int257): int257 {
    throw 0;
}

get fun getTotalTicketsForType(ltype: int257): int257 {
    throw 0;
}

get fun getIsDrawActive(ltype: int257): bool {
    throw 0;
}

get fun getAllPrizePools(): map<int257, int257> {
    throw 0;
}

get fun getAllTicketCounts(): map<int257, int257> {
    throw 0;
}

get fun getTicketPrice(ltype: int257): int257 {
    throw 0;
}

get fun isPaused(): bool {
    throw 0;
}

get fun getOwner(): address {
    throw 0;
}

get fun getWinner(ltype: int257): address? {
    throw 0;
}

get fun getTotalTickets(): int257 {
    throw 0;
}
