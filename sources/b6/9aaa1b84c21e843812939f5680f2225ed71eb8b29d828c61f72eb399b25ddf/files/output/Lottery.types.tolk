// Generated from the verified Tact contract ABI.
contract Lottery {
    storage: LotteryData
    incomingMessages: LotteryIncomingMessage
    thrownErrors: LotteryErrors
}

struct (0x946a98b6) LotteryDeploy {
    queryId: uint64
}

struct LotteryPlayer {
    address: address
    bet: coins
    ticket_start: uint64
    ticket_end: uint64
}

struct (0x40386669) LotterySetPlayersMax {
    new_players_max: uint8
}

struct (0x7f8edeea) LotterySetBetMin {
    new_bet_min: coins
}

struct (0x11030c8e) LotterySetFeePercent {
    fee_percent: uint8
}

struct LotteryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    fee_percent: uint8
    bet_min: coins
    players_max: uint8
    players_current: uint8
    players_list: map<address, Cell<LotteryPlayer>>
    players_nav_list: map<int257, address>
    locked_balance: coins
    winner_ticket: uint64
}

type LotteryIncomingMessage =
    | LotterySetPlayersMax
    | LotterySetBetMin
    | LotterySetFeePercent
    | LotteryDeploy

enum LotteryErrors {
    /// Stack undeflow
    StackUndeflow = 2
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
    /// Too low min bet
    TooLowMinBet = 2325
    /// Too many players
    TooManyPlayers = 16129
    /// Take something from this
    TakeSomethingFromThis = 18428
    /// Error: Value < Minimum_bet!
    ErrorValueMinimumBet = 19324
    /// Too greedy
    TooGreedy = 22902
    /// Too big min bet
    TooBigMinBet = 27922
    /// Invalid value!
    InvalidValue = 30737
    /// Access denied.
    AccessDenied2 = 42133
    /// Too few players
    TooFewPlayers = 53502
}

get fun get_bet_min(): int257 {
    throw 0;
}

get fun get_players_max(): int257 {
    throw 0;
}

get fun get_players_current(): int257 {
    throw 0;
}

get fun get_locked_balance(): int257 {
    throw 0;
}

get fun get_winner_ticket(): int257 {
    throw 0;
}

get fun get_fee_percent(): int257 {
    throw 0;
}
