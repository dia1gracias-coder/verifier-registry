// Generated from the verified Tact contract ABI.
contract BettingContract {
    storage: BettingContractData
    incomingMessages: BettingContractIncomingMessage
    thrownErrors: BettingContractErrors
}

struct (0x946a98b6) BettingContractDeploy {
    queryId: uint64
}

struct (0xea7969cd) BettingContractCreateRoom {
    roomId: uint256
    gameType: int8
    betVolume: coins
    capacity: uint256
}

struct (0xd31d011e) BettingContractBet {
    roomId: uint256
    betAmount: coins
    gameType: uint8
}

struct (0xbdbc9546) BettingContractEndGame {
    roomId: uint256
    winnerCount: uint8
    winner1: address
}

struct (0x6fb6be67) BettingContractWithdrawWinnings {
    user: address
}

struct (0x7362d09c) BettingContractJettonTransferNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct BettingContractRoom {
    gameType: uint8
    betVolume: coins
    capacity: uint8
    playersCount: uint8
    totalLocked: coins
}

struct BettingContractPendingBet {
    roomId: uint256
    betAmount: coins
}

struct BettingContractData {
    tactDeploymentCompleted: bool
    m_rooms: map<uint8, Cell<BettingContractRoom>>
    tactContinuation: Cell<BettingContractDataContinuation>
}

struct BettingContractDataContinuation {
    userWinnings: map<address, coins>
    owner: address
    feePercent: uint8
    withdrawalCap: coins
    userBets: map<uint256, bool>
    jettonWalletAddress: address
    totalReceivedJettons: coins
    pendingBets: map<address, Cell<BettingContractPendingBet>>
}

type BettingContractIncomingMessage =
    | BettingContractCreateRoom
    | BettingContractBet
    | BettingContractJettonTransferNotification
    | BettingContractEndGame
    | BettingContractWithdrawWinnings
    | BettingContractDeploy

enum BettingContractErrors {
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
    /// Room not found in getRoomInfo
    RoomNotFoundInGetRoomInfo = 2982
    /// Winnings below withdrawal cap
    WinningsBelowWithdrawalCap = 6823
    /// Invalid bet amount
    InvalidBetAmount = 11170
    /// Room not found for pending bet
    RoomNotFoundForPendingBet = 14062
    /// Room not found
    RoomNotFound = 14103
    /// Room already exists
    RoomAlreadyExists = 27407
    /// Notification not from jetton wallet
    NotificationNotFromJettonWallet = 33096
    /// No pending bet for sender
    NoPendingBetForSender = 36925
    /// Amount not found
    AmountNotFound = 51087
    /// User already bet in this room
    UserAlreadyBetInThisRoom = 51485
    /// Transferred amount does not match pending bet amount
    TransferredAmountDoesNotMatchPendingBetAmount = 52156
    /// Only owner can create rooms
    OnlyOwnerCanCreateRooms = 52447
    /// Room is full
    RoomIsFull = 62029
}

get fun getRoomInfo(roomId: int257): BettingContractRoom {
    throw 0;
}

get fun getUserWinnings(user: address): int257 {
    throw 0;
}

get fun get_jetton_balance(): int257 {
    throw 0;
}
