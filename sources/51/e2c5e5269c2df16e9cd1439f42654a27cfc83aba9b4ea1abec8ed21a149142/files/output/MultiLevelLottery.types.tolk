// Generated from the verified Tact contract ABI.
contract MultiLevelLottery {
    storage: MultiLevelLotteryData
    incomingMessages: MultiLevelLotteryIncomingMessage
    thrownErrors: MultiLevelLotteryErrors
}

struct (0x946a98b6) MultiLevelLotteryDeploy {
    queryId: uint64
}

struct (0x4b9a2e5d) MultiLevelLotteryOwnerSetBasePrice {
    newPrice: int257
}

struct (0x8f04f821) MultiLevelLotteryOwnerSetLevelMultiplier {
    level: int257
    k: int257
}

struct (0x7c1eb59d) MultiLevelLotteryOwnerWithdraw {
    amount: int257
    recipient: address
}

struct (0x7b90d55f) MultiLevelLotteryOwnerTransferOwnership {
    newOwner: address
}

struct (0x416e5c14) MultiLevelLotteryOwnerStartMega {
}

struct MultiLevelLotteryLevelConfig {
    k: int257
}

struct MultiLevelLotteryCycle {
    id: int257
    ticketsSold: int257
    isFinished: bool
    tickets: map<int257, address>
}

struct MultiLevelLotteryUserTickets {
    cycleId: int257
    count: int257
    ticketsOwned: map<int257, bool>
}

struct MultiLevelLotteryPlayerInfo {
    referrer: address
    userLevel: int257
    winningJackpotAmount: int257
    ticketsBought: map<int257, Cell<MultiLevelLotteryUserTickets>>
    tactContinuation: Cell<MultiLevelLotteryPlayerInfoContinuation>
}

struct MultiLevelLotteryPlayerInfoContinuation {
    referredCount: int257
    consecutiveWins: map<int257, int257>
    lastWinCycle: map<int257, int257>
    inRowBonus: int257
    buyBonus: map<int257, int257>
    soldBonus: int257
    tactContinuation: Cell<MultiLevelLotteryPlayerInfoContinuation2>
}

struct MultiLevelLotteryPlayerInfoContinuation2 {
    referralBonus: int257
    ticketsSoldByReferrals: int257
}

struct MultiLevelLotteryWinningTicketsList {
    winningTicketIds: map<int257, int257>
    winningTicketAmounts: map<int257, int257>
}

struct (0x837ddebb) MultiLevelLotteryRegister {
    user: address
    referrer: address
}

struct (0x0fbf40ca) MultiLevelLotteryBuyTicket {
    level: int257
    count: int257
}

struct MultiLevelLotteryData {
    tactDeploymentCompleted: bool
    owner: address
    basePrice: int257
    levelCfg: map<int257, Cell<MultiLevelLotteryLevelConfig>>
    tactContinuation: Cell<MultiLevelLotteryDataContinuation>
}

struct MultiLevelLotteryDataContinuation {
    cycles: map<int257, Cell<MultiLevelLotteryCycle>>
    winningTickets: map<int257, Cell<MultiLevelLotteryWinningTicketsList>>
    players: map<address, Cell<MultiLevelLotteryPlayerInfo>>
    megaJackpot: int257
    megaJackpotStart: int257
}

type MultiLevelLotteryIncomingMessage =
    | MultiLevelLotteryRegister
    | MultiLevelLotteryBuyTicket
    | MultiLevelLotteryOwnerSetBasePrice
    | MultiLevelLotteryOwnerSetLevelMultiplier
    | MultiLevelLotteryOwnerWithdraw
    | MultiLevelLotteryOwnerTransferOwnership
    | MultiLevelLotteryOwnerStartMega
    | MultiLevelLotteryDeploy

enum MultiLevelLotteryErrors {
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
    /// BAD_OWNER
    BADOWNER = 2404
    /// NOT_ENOUGH_TON
    NOTENOUGHTON = 3926
    /// NOT_REGISTERED
    NOTREGISTERED = 10602
    /// CYCLE_FINISHED
    CYCLEFINISHED = 20915
    /// BAD_MULT
    BADMULT = 24243
    /// BAD_AMOUNT
    BADAMOUNT = 29392
    /// BAD_COUNT
    BADCOUNT = 33070
    /// BAD_PRICE
    BADPRICE = 35867
    /// ONLY_OWNER
    ONLYOWNER = 37469
    /// ALREADY_REGISTERED
    ALREADYREGISTERED = 53267
    /// NO_CYCLE
    NOCYCLE = 61473
    /// BAD_LEVEL
    BADLEVEL = 62110
    /// TOO_MANY_TICKETS
    TOOMANYTICKETS = 62587
}

get fun getPlayerInfo(user: address): MultiLevelLotteryPlayerInfo? {
    throw 0;
}

get fun getCycle(level: int257): MultiLevelLotteryCycle? {
    throw 0;
}

get fun getCycleSoldTickets(level: int257): int257? {
    throw 0;
}

get fun getCycleId(level: int257): int257? {
    throw 0;
}

get fun getCycleTickets(level: int257): map<int257, address> {
    throw 0;
}

get fun getLevelConfig(level: int257): MultiLevelLotteryLevelConfig? {
    throw 0;
}

get fun getWinningTickets(level: int257): MultiLevelLotteryWinningTicketsList? {
    throw 0;
}

get fun getMegaJackpot(): int257 {
    throw 0;
}

get fun getBasePrice(): int257 {
    throw 0;
}

get fun getOwner(): address {
    throw 0;
}
