// Generated from the verified Tact contract ABI.
contract Lottery {
    storage: LotteryData
    incomingMessages: LotteryIncomingMessage
    thrownErrors: LotteryErrors
}

struct (0x946a98b6) LotteryDeploy {
    queryId: uint64
}

struct LotteryTicket {
    owner: address
    quantity: int257
    poolId: uint32
    roundId: uint32
}

struct LotteryPool {
    poolId: uint32
    creator: address
    rounds: map<int257, Cell<LotteryRoundConfig>>
    startTime: uint32
    endTime: uint32
    active: bool
}

struct LotteryRoundConfig {
    roundId: uint32
    poolId: uint32
    ticketPrice: coins
    startTime: uint32
    endTime: uint32
    active: bool
}

struct (0x7a877e4c) LotteryPoolCreated {
    poolId: int257
    ticketPrice: uint32
    initialRounds: uint8
    startTime: uint32
    endTime: uint32
    active: bool
}

struct LotteryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    tokenPool: int257
    currentRound: int257
    rounds: map<int257, Cell<LotteryRoundConfig>>
    tactContinuation: Cell<LotteryDataContinuation>
}

struct LotteryDataContinuation {
    tickets: map<int257, Cell<LotteryTicket>>
    winningNumbers: map<int257, int257>
    pools: map<int257, Cell<LotteryPool>>
    nextPoolId: int257
}

type LotteryIncomingMessage =
    | LotteryPoolCreated
    | LotteryDeploy

enum LotteryErrors {
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
    /// Pool is not active
    PoolIsNotActive = 13687
    /// Round is not open for ticket purchases
    RoundIsNotOpenForTicketPurchases = 24801
    /// Only owner can create pool
    OnlyOwnerCanCreatePool = 29498
    /// Only owner can add rounds
    OnlyOwnerCanAddRounds = 43934
    /// Round is not active
    RoundIsNotActive = 47697
    /// Insufficient funds sent
    InsufficientFundsSent = 58383
    /// Quantity must be positive
    QuantityMustBePositive = 59272
}

get fun currentRound(): int257 {
    throw 0;
}

get fun roundConfig(roundId: int257): LotteryRoundConfig? {
    throw 0;
}

get fun winningNumbers(roundId: int257): int257? {
    throw 0;
}
