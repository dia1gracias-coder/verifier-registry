// Generated from the verified Tact contract ABI.
contract LotteryDraw {
    storage: LotteryDrawData
    incomingMessages: LotteryDrawIncomingMessage
    thrownErrors: LotteryDrawErrors
}

struct (0x946a98b6) LotteryDrawDeploy {
    queryId: uint64
}

struct LotteryDrawTicket_Owner {
    participent: address
    reward: int257
    hasClaimed: bool
}

struct (0x9832e795) LotteryDrawTicket {
    ticketId: int257
}

struct (0xccd5cd9f) LotteryDrawTickets {
    ticketIds: map<int257, int257>
    ticketcount: int257
}

struct (0x55fac4f8) LotteryDrawTicketId {
    ticket: int257
}

struct (0xbbd11a32) LotteryDrawDecreaseTime {
    seconds: int257
}

struct (0xed0b1534) LotteryDrawIncreaseTime {
    seconds: int257
}

struct (0xc346146e) LotteryDrawIncreaseTicket {
    ticket: int257
}

struct (0xe4e61ee9) LotteryDrawDecreaseTicket {
    ticket: int257
}

struct (0xa1ed4eaa) LotteryDrawPrepare_rewards {
}

struct (0xa1ed4eab) LotteryDrawDistribute_rewards {
}

struct (0xa1ed4eac) LotteryDrawOwnership {
    name: string
}

struct LotteryDrawData {
    tactDeploymentCompleted: bool
    owner: address
    bid: int257
    adminPercentage: int257
    tactContinuation: Cell<LotteryDrawDataContinuation>
}

struct LotteryDrawDataContinuation {
    floorPercentage: int257
    bonusPercentage: int257
    decayFactorNumerator: int257
    tactContinuation: Cell<LotteryDrawDataContinuation2>
}

struct LotteryDrawDataContinuation2 {
    decayFactorDenominator: int257
    fixedPointScale: int257
    admin: address?
    tickets: map<int257, int257>
    participents: map<int257, Cell<LotteryDrawTicket_Owner>>
    tactContinuation: Cell<LotteryDrawDataContinuation3>
}

struct LotteryDrawDataContinuation3 {
    totalPool: int257
    participantCount: int257
    rewardsPrepared: bool
    rewardsDistributed: bool
    minPrize: int257
    tactContinuation: Cell<LotteryDrawDataContinuation4>
}

struct LotteryDrawDataContinuation4 {
    remainingPool: int257
    bonusCount: int257
    guaranteedWinPool: int257
    tactContinuation: Cell<LotteryDrawDataContinuation5>
}

struct LotteryDrawDataContinuation5 {
    decayWinnerSum: int257
    remainingDecaySum: int257
    startTime: int257
    tactContinuation: Cell<LotteryDrawDataContinuation6>
}

struct LotteryDrawDataContinuation6 {
    endTime: int257
    maxTicket: int257
}

type LotteryDrawIncomingMessage =
    | LotteryDrawTicket
    | LotteryDrawTickets
    | LotteryDrawPrepare_rewards
    | LotteryDrawDistribute_rewards
    | LotteryDrawTicketId
    | LotteryDrawIncreaseTime
    | LotteryDrawDecreaseTime
    | LotteryDrawOwnership
    | LotteryDrawIncreaseTicket
    | LotteryDrawDecreaseTicket
    | LotteryDrawDeploy

enum LotteryDrawErrors {
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
    /// Only admin can increase ticket count
    OnlyAdminCanIncreaseTicketCount = 6531
    /// No items in the array!
    NoItemsInTheArray = 6947
    /// Sorry!This Ticket has not participated in draw!
    SorryThisTicketHasNotParticipatedInDraw = 9971
    /// Reward Not Distributed Yet. wait for draw!!
    RewardNotDistributedYetWaitForDraw = 10738
    /// first prepared reward then distribute reward
    FirstPreparedRewardThenDistributeReward = 10839
    /// Only admin can increase time
    OnlyAdminCanIncreaseTime = 15882
    /// Only admin
    OnlyAdmin = 16461
    /// No items in the array to delete!
    NoItemsInTheArrayToDelete = 17848
    /// Index of the item cannot be negative!
    IndexOfTheItemCannotBeNegative = 19333
    /// Cannot decrease ticket count below zero
    CannotDecreaseTicketCountBelowZero = 19684
    /// Duplicate ticket not allowed
    DuplicateTicketNotAllowed = 22830
    /// Index is out of array bounds!
    IndexIsOutOfArrayBounds = 24006
    /// You have already claimed your reward!
    YouHaveAlreadyClaimedYourReward = 24322
    /// Only current owner can transfer ownership
    OnlyCurrentOwnerCanTransferOwnership = 25826
    /// Only admin can decrease time
    OnlyAdminCanDecreaseTime = 26163
    /// Cannot decrease time beyond start time
    CannotDecreaseTimeBeyondStartTime = 26571
    /// Amount is not enough for buying....
    AmountIsNotEnoughForBuying = 36968
    /// Rewards already prepared
    RewardsAlreadyPrepared = 37181
    /// No participants
    NoParticipants = 39078
    /// No space in the array left for new items!
    NoSpaceInTheArrayLeftForNewItems = 42469
    /// Sorry! We have finished selling tickets...
    SorryWeHaveFinishedSellingTickets = 42805
    /// No tickets provided
    NoTicketsProvided = 48696
    /// Only admin can decrease ticket count
    OnlyAdminCanDecreaseTicketCount = 48981
    /// Invalid ticket ID
    InvalidTicketID = 49271
    /// Already prepared
    AlreadyPrepared = 49658
    /// Not enough TON for tickets
    NotEnoughTONForTickets = 56379
    /// Reward Already Distributed
    RewardAlreadyDistributed = 56656
    /// you have not participated in draw!!
    YouHaveNotParticipatedInDraw = 59515
    /// Sorry! we have ran out of tickets..
    SorryWeHaveRanOutOfTickets = 63603
}

get fun random_uint(max: int257, salt: int257): int257 {
    throw 0;
}

get fun get_decay_weight(index: int257): int257 {
    throw 0;
}

get fun get_participant_count(): int257 {
    throw 0;
}

get fun get_total_Pool(): int257 {
    throw 0;
}

get fun get_Ticket_Data(tk: int257): LotteryDrawTicket_Owner? {
    throw 0;
}

get fun get_Ticket_TotalData(): map<int257, Cell<LotteryDrawTicket_Owner>> {
    throw 0;
}

get fun get_Ticket_map(): map<int257, int257> {
    throw 0;
}

get fun get_BonusCount(): int257 {
    throw 0;
}

get fun get_prize(index: int257): int257 {
    throw 0;
}

get fun get_MinPrize(): int257 {
    throw 0;
}
