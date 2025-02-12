// Generated from the verified Tact contract ABI.
contract LotteryGame {
    storage: LotteryGameData
    incomingMessages: LotteryGameIncomingMessage
    thrownErrors: LotteryGameErrors
}

struct (0x946a98b6) LotteryGameDeploy {
    queryId: uint64
}

struct (0x819dbe99) LotteryGameChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0xb63bffe2) LotteryGameBuyNumber {
    num: uint16
}

struct (0x833f6db9) LotteryGameAwardPrizes {
    winners: cell
    maxPlayers: uint16?
    numPrice: coins?
    devFee: uint8?
    prizes: map<uint8, uint16>
}

struct (0xe7217b97) LotteryGameCancelNumber {
    num: uint16
}

struct LotteryGameLotteryData {
    startTime: uint32
    currentNumOfPlayers: uint16
    currentPlayers: map<uint16, address>
    maxPlayers: uint16
    numPrice: coins
    devFee: uint8
    prizes: map<uint8, uint16>
    prizePool: coins
}

struct LotteryGamePlayersData {
    currentPlayers: map<uint16, address>
    currentNumOfPlayers: uint16
}

struct LotteryGameData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    currentPlayers: map<uint16, address>
    currentNumOfPlayers: uint16
    maxPlayers: uint16
    numPrice: coins
    startTime: uint32
    devFee: uint8
    prizes: map<uint8, uint16>
}

type LotteryGameIncomingMessage =
    | LotteryGameBuyNumber
    | LotteryGameAwardPrizes
    | LotteryGameCancelNumber
    | LotteryGameDeploy
    | LotteryGameChangeOwner

enum LotteryGameErrors {
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
    /// Not enough funds to buy a ticket
    NotEnoughFundsToBuyATicket = 15352
    /// Only owner can cancel the number
    OnlyOwnerCanCancelTheNumber = 21592
    /// Lottery is full
    LotteryIsFull = 23638
    /// Lottery is not old enough to cancel
    LotteryIsNotOldEnoughToCancel = 26663
    /// Lottery is not full
    LotteryIsNotFull = 31280
    /// Invalid number
    InvalidNumber = 41644
    /// Number already taken
    NumberAlreadyTaken = 49589
}

get fun balance(): int257 {
    throw 0;
}

get fun currentNumOfPlayers(): int257 {
    throw 0;
}

get fun currentPlayers(): map<uint16, address> {
    throw 0;
}

get fun maxPlayers(): string {
    throw 0;
}

get fun numPrice(): int257 {
    throw 0;
}

get fun playerAddress(ticketNum: int257): address? {
    throw 0;
}

get fun playerNum(address: address): int257? {
    throw 0;
}

get fun devFee(): int257 {
    throw 0;
}

get fun data(): LotteryGameLotteryData {
    throw 0;
}

get fun playersInfo(): LotteryGamePlayersData {
    throw 0;
}

get fun prizes(): map<uint8, uint16> {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
