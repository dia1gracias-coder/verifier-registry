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
    sequence: uint32
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

struct LotteryUserTicket {
    users: map<address, Cell<LotteryTicketPayoutResponse>>
}

struct LotteryRoundTicket {
    rounds: map<int257, Cell<LotteryUserTicket>>
}

struct LotteryClaimInfo {
    info: map<int257, Cell<LotteryUserClaim>>
}

struct LotteryUserClaim {
    user: map<address, bool>
}

struct LotteryResult {
    rounds: map<int257, int257>
}

struct (0x7774c00b) LotteryCreatePool {
    jettonWallet: address
    ticketPrice: uint32
    initialRounds: uint8
    startTime: uint32
    endTime: uint32
    sequence: uint32
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

struct (0xd611ad04) LotteryDrawWinningNumbers {
    poolId: int257
    roundId: int257
    latestTxHash: string
}

struct (0xca86a987) LotterySetAdmin {
    admin: address
}

struct (0xc37bfdfe) LotterySetPublicKey {
    publicKey: int257
}

struct LotteryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    admin: map<address, bool>
    tactContinuation: Cell<LotteryDataContinuation>
}

struct LotteryDataContinuation {
    pools: map<int257, Cell<LotteryPool>>
    nextPoolId: int257
    usersTicket: map<int257, Cell<LotteryRoundTicket>>
    rewardSettings: map<int257, int257>
    tactContinuation: Cell<LotteryDataContinuation2>
}

struct LotteryDataContinuation2 {
    result: map<int257, Cell<LotteryResult>>
    rewardPools: map<int257, int257>
    publicKey: int257?
    claimData: map<int257, Cell<LotteryClaimInfo>>
}

type LotteryIncomingMessage =
    | LotteryCreatePool
    | LotteryRewardSetting
    | LotteryBuyTicket
    | LotteryDrawWinningNumbers
    | LotterySetAdmin
    | LotterySetPublicKey
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
    /// Invalid signature
    InvalidSignature = 48401
    /// Only the owner or admin can call this function
    OnlyTheOwnerOrAdminCanCallThisFunction = 58319
    /// Insufficient funds sent
    InsufficientFundsSent = 58383
    /// Quantity must be positive
    QuantityMustBePositive = 59272
    /// Invalid claim
    InvalidClaim = 61167
    /// Invalid match number
    InvalidMatchNumber = 63994
}

get fun admins(): map<address, bool> {
    throw 0;
}

get fun isAdmin(address: address): bool {
    throw 0;
}

get fun currentPool(): map<int257, Cell<LotteryPool>> {
    throw 0;
}

get fun poolById(poolId: int257): LotteryPool? {
    throw 0;
}

get fun usersTicket(poolId: int257, roundId: int257): LotteryUserTicket {
    throw 0;
}

get fun userTicketByAddress(poolId: int257, roundId: int257, user: address): LotteryTicketPayoutResponse? {
    throw 0;
}

get fun roundById(poolId: int257, roundId: int257): LotteryRoundConfig? {
    throw 0;
}

get fun resultByRound(poolId: int257, roundId: int257): int257? {
    throw 0;
}

get fun resultByPool(poolId: int257): LotteryResult? {
    throw 0;
}

get fun publicKey(): int257? {
    throw 0;
}

get fun claimData(poolId: int257, roundId: int257): LotteryUserClaim? {
    throw 0;
}

get fun isClaim(poolId: int257, roundId: int257, receiver: address): bool {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
