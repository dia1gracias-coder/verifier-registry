// Generated from the verified Tact contract ABI.
contract Lottery {
    storage: LotteryData
    incomingMessages: LotteryIncomingMessage
    thrownErrors: LotteryErrors
}

struct (0x946a98b6) LotteryDeploy {
    queryId: uint64
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

struct LotteryTicketPayoutResponse {
    ticket: string
}

struct LotteryTicket {
    ticket: string
    ticketNumber: int257
    owner: address
}

struct (0x29285ea6) LotteryPoolCreated {
    ticketPrice: uint32
    initialRounds: uint8
    startTime: uint32
    endTime: uint32
    active: bool
}

struct (0x6900dd0c) LotteryRewardSetting {
    match_: int257
    percent: int257
}

struct (0xdf690a99) LotteryBuyTicket {
    poolId: int257
    roundId: int257
    quantity: int257
}

struct LotteryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    currentRoundId: int257
    currentPoolId: int257
    pools: map<int257, Cell<LotteryPool>>
    tactContinuation: Cell<LotteryDataContinuation>
}

struct LotteryDataContinuation {
    nextPoolId: int257
    usersTicket: map<address, Cell<LotteryTicketPayoutResponse>>
    ticketsUser: map<int257, Cell<LotteryTicket>>
    ticketsIndex: map<int257, int257>
    ticketArrayLength: int257
    tactContinuation: Cell<LotteryDataContinuation2>
}

struct LotteryDataContinuation2 {
    rewardSettings: map<int257, int257>
    result: int257
    rewardPools: map<int257, int257>
    publicKey: int257?
    jettonWalletAddress: address?
    isClaim: map<address, bool>
}

type LotteryIncomingMessage =
    | LotteryPoolCreated
    | LotteryRewardSetting
    | LotteryBuyTicket
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
    /// Winning numbers already drawn
    WinningNumbersAlreadyDrawn = 20265
    /// Invalid content
    InvalidContent = 23427
    /// Round is not open for ticket purchases
    RoundIsNotOpenForTicketPurchases = 24801
    /// Round does not exist
    RoundDoesNotExist = 36876
    /// Invalid reward percentage
    InvalidRewardPercentage = 39628
    /// Pool does not exist
    PoolDoesNotExist = 42120
    /// Round is not active
    RoundIsNotActive = 47697
    /// Round is still active
    RoundIsStillActive = 50778
    /// Insufficient funds sent
    InsufficientFundsSent = 58383
    /// Quantity must be positive
    QuantityMustBePositive = 59272
    /// Invalid match number
    InvalidMatchNumber = 63994
}

get fun currentPool(): int257 {
    throw 0;
}

get fun poolById(poolId: int257): LotteryPool? {
    throw 0;
}

get fun usersTicket(): map<address, Cell<LotteryTicketPayoutResponse>> {
    throw 0;
}

get fun userTicketByAddress(user: address): LotteryTicketPayoutResponse? {
    throw 0;
}

get fun currentRound(): LotteryRoundConfig? {
    throw 0;
}

get fun roundById(poolId: int257, roundId: int257): LotteryRoundConfig? {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
