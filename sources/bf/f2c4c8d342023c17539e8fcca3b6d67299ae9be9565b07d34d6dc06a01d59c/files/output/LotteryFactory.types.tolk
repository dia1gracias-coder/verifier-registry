// Generated from the verified Tact contract ABI.
contract LotteryFactory {
    storage: LotteryFactoryData
    incomingMessages: LotteryFactoryIncomingMessage
    thrownErrors: LotteryFactoryErrors
}

struct (0x946a98b6) LotteryFactoryDeploy {
    queryId: uint64
}

struct (0x2c7d9958) LotteryFactoryDraw {
    lotteryId: int257
}

struct (0x30251eb1) LotteryFactoryEmergencyWithdraw {
    lotteryId: int257
}

struct (0x5d7a8d75) LotteryFactorySetOperator {
    operator_: address
}

struct (0x1e2f1992) LotteryFactoryCreate {
    price: int257
    endTime: int257
    discountDivisor: int257
}

struct LotteryFactoryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    operator_: address
    lotteryCnt: uint256
    referrers: map<int257, address>
    tactContinuation: Cell<LotteryFactoryDataContinuation>
}

struct LotteryFactoryDataContinuation {
    referrer_cnt: int257
    withdraw_end: uint256
}

type LotteryFactoryIncomingMessage =
    | LotteryFactorySetOperator
    | LotteryFactoryCreate
    | LotteryFactoryDraw
    | LotteryFactoryEmergencyWithdraw
    | LotteryFactoryDeploy

enum LotteryFactoryErrors {
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

get fun lotteryCnt(): int257 {
    throw 0;
}

get fun lotteryAddress(seqno: int257): address {
    throw 0;
}

get fun referrerWalletAddress(user: address): address {
    throw 0;
}

get fun reffererNumber(user: address): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
