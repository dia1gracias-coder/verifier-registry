// Generated from the verified Tact contract ABI.
contract WormLottery {
    storage: WormLotteryData
    incomingMessages: WormLotteryIncomingMessage
    thrownErrors: WormLotteryErrors
}

struct (0x946a98b6) WormLotteryDeploy {
    queryId: uint64
}

struct WormLotteryTicket {
    owner: address
    winningAmount: int257
    claimed: bool
}

struct WormLotteryRound {
    status: int257
    startTime: int257
    endTime: int257
    tactContinuation: Cell<WormLotteryRoundContinuation>
}

struct WormLotteryRoundContinuation {
    maximumTicketId: int257
    tickets: map<int257, Cell<WormLotteryTicket>>
    winnerTickets: map<int257, int257>
    rewardsDistribution: map<int257, int257>
    numberOfWinnerTickets: int257
}

struct (0x7f72e0ce) WormLotteryStartRound {
    roundId: int257
    maximumTicketId: int257
}

struct (0x86fc4217) WormLotteryBuyTicket {
    roundId: int257
    ticketId: int257
}

struct (0x0d107fd6) WormLotteryFinishRound {
    roundId: int257
}

struct (0xe664742d) WormLotteryClaimRound {
    roundId: int257
    rewardsDistribution: map<int257, int257>
    numberOfWinnerTickets: int257
}

struct (0x96625b01) WormLotteryClaimTicket {
    roundId: int257
    ticketId: int257
}

struct WormLotteryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    rounds: map<int257, Cell<WormLotteryRound>>
}

type WormLotteryIncomingMessage =
    | WormLotteryStartRound
    | WormLotteryBuyTicket
    | WormLotteryFinishRound
    | WormLotteryClaimRound
    | WormLotteryClaimTicket
    | WormLotteryDeploy

enum WormLotteryErrors {
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
    /// Ticket is not valid.
    TicketIsNotValid = 5199
    /// You are not the owner.
    YouAreNotTheOwner = 10159
    /// Round status is not finished.
    RoundStatusIsNotFinished = 32538
    /// Round is not valid.
    RoundIsNotValid = 34436
    /// Round status is not claimable.
    RoundStatusIsNotClaimable = 38333
    /// Ticket is sold already.
    TicketIsSoldAlready = 38445
    /// Ticket has been claimed.
    TicketHasBeenClaimed = 47635
    /// Round status is not open.
    RoundStatusIsNotOpen = 58919
    /// You have not won anything.
    YouHaveNotWonAnything = 60242
    /// Ticket is not available.
    TicketIsNotAvailable = 61901
    /// Round is already started.
    RoundIsAlreadyStarted = 62611
}

get fun round(roundId: int257): WormLotteryRound {
    throw 0;
}
