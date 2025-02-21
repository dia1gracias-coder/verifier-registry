// Generated from the verified Tact contract ABI.
contract Lottery {
    storage: LotteryData
    incomingMessages: LotteryIncomingMessage
    thrownErrors: LotteryErrors
}

struct LotteryTicket {
    number: uint32
    owner: address
}

struct (0x0dd2c966) LotteryCreateLottery {
    creator: address
    operator_: address?
    price: int257
    tactContinuation: Cell<LotteryCreateLotteryContinuation>
}

struct LotteryCreateLotteryContinuation {
    endTime: int257
    discountDivisor: int257
}

struct (0xc55356fd) LotteryBuyTicket {
    recipient: address
    amount: uint32
    ticketNumbers: map<uint32, uint32>
    refWallet: address?
}

struct (0x9b854c91) LotteryClaimTickets {
    ticketIds: map<uint32, uint32>
    ticketLength: uint32
}

struct LotteryInfo {
    seqno: int257
    creator: address
    ticketCnt: int257
    tactContinuation: Cell<LotteryInfoContinuation>
}

struct LotteryInfoContinuation {
    endTime: int257
    price: int257
    status: int257
    tactContinuation: Cell<LotteryInfoContinuation2>
}

struct LotteryInfoContinuation2 {
    amountCollected: int257
}

struct (0x36fa18c0) LotteryWithdraw {
    target: address
}

struct LotteryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    factory: address
    creator: address
    operator_: address
    tactContinuation: Cell<LotteryDataContinuation>
}

struct LotteryDataContinuation {
    seqno: int257
    ticketCnt: int257
    endTime: uint256
    tactContinuation: Cell<LotteryDataContinuation2>
}

struct LotteryDataContinuation2 {
    price: uint256
    discountDivisor: int257
    status: uint16
    claimed: map<address, uint8>
    feePercent: int257
    tactContinuation: Cell<LotteryDataContinuation3>
}

struct LotteryDataContinuation3 {
    refPercent: int257
    rewardPerBracket: map<int257, uint256>
    tickets: map<int257, Cell<LotteryTicket>>
    winnerCntPerBracket: map<int257, uint256>
    amountCollected: uint256
    feeAmount: uint256
    finalNumber: uint32
}

type LotteryIncomingMessage =
    | LotteryCreateLottery
    | LotteryBuyTicket
    | LotteryClaimTickets
    | LotteryWithdraw

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
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
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
    /// Invalid address
    InvalidAddress = 136
    /// Masterchain support is not enabled for this contract
    MasterchainSupportIsNotEnabledForThisContract = 137
    /// Lottery is not active
    LotteryIsNotActive = 5555
    /// Sufficient balance
    SufficientBalance = 6767
    /// Not enough Ton
    NotEnoughTon = 7825
    /// Lottery not close
    LotteryNotClose = 24518
    /// Lottery is over
    LotteryIsOver = 37690
    /// Access is denied
    AccessIsDenied = 39647
    /// Already claimed
    AlreadyClaimed = 42504
    /// Too many tickets
    TooManyTickets = 49030
    /// Lottery not claimable
    LotteryNotClaimable = 49671
    /// No ticket specified
    NoTicketSpecified = 50970
    /// You are not owner
    YouAreNotOwner = 54634
    /// You are not factory
    YouAreNotFactory = 55607
    /// Invalid balance
    InvalidBalance = 62972
}

get fun allTickets(): map<int257, Cell<LotteryTicket>> {
    throw 0;
}

get fun isClaimable(user: address): bool {
    throw 0;
}

get fun calculateTotalPriceForBulkTickets(amount: int257): int257 {
    throw 0;
}

get fun winningNumber(): int257 {
    throw 0;
}

get fun info(): LotteryInfo {
    throw 0;
}

get fun calculateRewardsForTicketId(ticketId: int257): int257 {
    throw 0;
}
