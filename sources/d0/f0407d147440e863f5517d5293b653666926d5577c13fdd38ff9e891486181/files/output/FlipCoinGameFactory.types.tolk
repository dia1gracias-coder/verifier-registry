// Generated from the verified Tact contract ABI.
contract FlipCoinGameFactory {
    storage: FlipCoinGameFactoryData
    incomingMessages: FlipCoinGameFactoryIncomingMessage
    thrownErrors: FlipCoinGameFactoryErrors
}

struct (0x946a98b6) FlipCoinGameFactoryDeploy {
    queryId: uint64
}

struct (0xcd28a913) FlipCoinGameFactorySetServiceFeeMsg {
    newValue: uint32
}

struct (0x75830ec7) FlipCoinGameFactorySetReferrerFeeMsg {
    newValue: uint32
}

struct (0xe7b208b5) FlipCoinGameFactorySetFeeReceiverMsg {
    newReceiver: address
}

struct (0xdd2e0196) FlipCoinGameFactorySetLowestBidMsg {
    newValue: uint256
}

struct (0x13ff5881) FlipCoinGameFactorySetHighestBidMsg {
    newValue: uint256
}

struct (0xab2af401) FlipCoinGameFactorySetWaitingForOpenBidSecondsMsg {
    newValue: uint256
}

struct (0x1994ad55) FlipCoinGameFactorySetMinReferrerPayoutValueMsg {
    newValue: uint256
}

struct (0xbff226ff) FlipCoinGameFactoryCreateGameAndOpenBidsMsg {
    bidValue: coins
    secret: uint256
    referrer: address?
    gameIdsToOpen: map<uint16, uint256>
    keysToOpen: map<uint16, uint256>
    count: uint16
}

struct (0xdeacd27b) FlipCoinGameFactoryJoinGameAndOpenBidsMsg {
    gameId: uint256
    bidValue: coins
    secret: uint256
    referrer: address?
    gameIdsToOpen: map<uint16, uint256>
    keysToOpen: map<uint16, uint256>
    count: uint16
}

struct (0xe07c2513) FlipCoinGameFactoryOpenMultipleGamesMsg {
    gameIdsToOpen: map<uint16, uint256>
    keysToOpen: map<uint16, uint256>
    count: uint16
}

struct (0x0f8125f3) FlipCoinGameFactoryCreateGameMsg {
    bidValue: coins
    secret: uint256
    referrer: address?
}

struct (0xd2dc8a75) FlipCoinGameFactoryForwardOpenBidMsg {
    gameId: uint256
    key: uint256
}

struct (0xe816ea78) FlipCoinGameFactoryForwardJoinGameMsg {
    gameId: uint256
    bidValue: coins
    secret: uint256
    referrer: address?
}

struct (0xeb292097) FlipCoinGameFactoryGameInitializedNotify {
    gameId: uint256
    playerOne: address
    bidValue: coins
}

struct (0x061e5e5b) FlipCoinGameFactoryGameStartedNotify {
    gameId: uint256
    playerOne: address
    playerTwo: address
    totalGainings: coins
}

struct (0x1fe7e643) FlipCoinGameFactoryGameFinishedNotify {
    gameId: uint256
    winner: address
    looser: address
    totalGainings: coins
}

struct (0x17287fd2) FlipCoinGameFactoryGameCancelledNotify {
    gameId: uint256
    playerOne: address
}

struct (0x47a818c8) FlipCoinGameFactorySecretOpenedNotify {
    gameId: uint256
    player: address
    coinSide: uint8
}

struct (0x12f40487) FlipCoinGameFactoryDrawNotify {
    gameId: uint256
}

struct (0xf740b5b3) FlipCoinGameFactoryInsufficientBalanceNotify {
    gameId: uint256
    required: coins
    actual: coins
}

struct FlipCoinGameFactoryDetailedStats {
    totalGamesCreated: uint64
    totalGamesInitialized: uint64
    totalGamesFinished: uint64
    totalGamesCancelled: uint64
    totalGamesDrawn: uint64
    totalSecretsOpened: uint64
    totalInsufficientBalance: uint64
}

struct FlipCoinGameFactoryFactoryConfig {
    serviceFeeNumerator: uint32
    referrerFeeNumerator: uint32
    waitingForOpenBidSeconds: uint32
    feeReceiver: address
    stopped: bool
}

struct FlipCoinGameFactoryGameAddressBatch {
    startId: uint32
    addresses: map<uint32, address>
}

struct FlipCoinGameFactoryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    stopped: bool
    owner: address
    serviceFeeNumerator: uint256
    referrerFeeNumerator: uint256
    tactContinuation: Cell<FlipCoinGameFactoryDataContinuation>
}

struct FlipCoinGameFactoryDataContinuation {
    lowestBid: uint256
    highestBid: uint256
    waitingForOpenBidSeconds: uint256
    tactContinuation: Cell<FlipCoinGameFactoryDataContinuation2>
}

struct FlipCoinGameFactoryDataContinuation2 {
    minReferrerPayoutValue: uint256
    feeReceiver: address
    salt: uint64
    totalGamesCreated: uint64
    totalGamesInitialized: uint64
    totalGamesFinished: uint64
    totalGamesCancelled: uint64
    totalGamesDrawn: uint64
    totalSecretsOpened: uint64
    tactContinuation: Cell<FlipCoinGameFactoryDataContinuation3>
}

struct FlipCoinGameFactoryDataContinuation3 {
    totalInsufficientBalance: uint64
    lastCreatedGameId: uint64
}

type FlipCoinGameFactoryIncomingMessage =
    | FlipCoinGameFactoryCreateGameAndOpenBidsMsg
    | FlipCoinGameFactoryCreateGameMsg
    | FlipCoinGameFactoryForwardOpenBidMsg
    | FlipCoinGameFactoryForwardJoinGameMsg
    | FlipCoinGameFactoryJoinGameAndOpenBidsMsg
    | FlipCoinGameFactoryOpenMultipleGamesMsg
    | FlipCoinGameFactoryGameInitializedNotify
    | FlipCoinGameFactoryGameStartedNotify
    | FlipCoinGameFactoryGameFinishedNotify
    | FlipCoinGameFactoryGameCancelledNotify
    | FlipCoinGameFactoryDrawNotify
    | FlipCoinGameFactorySecretOpenedNotify
    | FlipCoinGameFactoryInsufficientBalanceNotify
    | FlipCoinGameFactorySetFeeReceiverMsg
    | FlipCoinGameFactorySetServiceFeeMsg
    | FlipCoinGameFactorySetReferrerFeeMsg
    | FlipCoinGameFactorySetLowestBidMsg
    | FlipCoinGameFactorySetHighestBidMsg
    | FlipCoinGameFactorySetWaitingForOpenBidSecondsMsg
    | FlipCoinGameFactorySetMinReferrerPayoutValueMsg
    | FlipCoinGameFactoryDeploy

enum FlipCoinGameFactoryErrors {
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
    /// Too early for emergency
    TooEarlyForEmergency = 2126
    /// Insufficient value
    InsufficientValue = 2805
    /// Not stopped
    NotStopped = 3041
    /// Game is finishing
    GameIsFinishing = 5043
    /// Invalid key or coin side
    InvalidKeyOrCoinSide = 5211
    /// Wrong game status
    WrongGameStatus = 7636
    /// Invalid highest bid
    InvalidHighestBid = 8230
    /// Too early to cancel
    TooEarlyToCancel = 10070
    /// Wrong status
    WrongStatus = 11117
    /// Invalid lowest bid
    InvalidLowestBid = 11493
    /// Below minimum withdrawal
    BelowMinimumWithdrawal = 11567
    /// Only factory
    OnlyFactory = 11788
    /// You cannot input zero address for this operation
    YouCannotInputZeroAddressForThisOperation = 12043
    /// Cannot refer yourself
    CannotReferYourself = 12339
    /// Game not exists
    GameNotExists = 13330
    /// Only factory can initialize
    OnlyFactoryCanInitialize = 16083
    /// Cannot play with yourself
    CannotPlayWithYourself = 16881
    /// Invalid amount
    InvalidAmount = 17062
    /// Game already initialized
    GameAlreadyInitialized = 18666
    /// Bid too small
    BidTooSmall = 19141
    /// Batch too large
    BatchTooLarge = 20709
    /// Insufficient value received
    InsufficientValueReceived = 22366
    /// Wrong game ID
    WrongGameID = 26015
    /// Cannot cancel
    CannotCancel = 30773
    /// Only referrer can withdraw
    OnlyReferrerCanWithdraw = 34030
    /// Fee too high (max 20%)
    FeeTooHighMax20 = 34972
    /// Wrong value
    WrongValue = 34996
    /// Bid too high
    BidTooHigh = 35941
    /// Only creator can cancel
    OnlyCreatorCanCancel = 39159
    /// Already opened
    AlreadyOpened = 39497
    /// Nothing to withdraw
    NothingToWithdraw = 40636
    /// Invalid fees
    InvalidFees = 43094
    /// Invalid game sender
    InvalidGameSender = 44065
    /// Too early to finish
    TooEarlyToFinish = 45176
    /// Amount too small
    AmountTooSmall = 46710
    /// Already stopped
    AlreadyStopped = 49083
    /// Only factory can forward join
    OnlyFactoryCanForwardJoin = 51662
    /// Zero address
    ZeroAddress = 52336
    /// Contract not stopped
    ContractNotStopped = 53296
    /// Already finishing
    AlreadyFinishing = 56615
    /// Invalid timeout
    InvalidTimeout = 58890
    /// Game not ready
    GameNotReady = 59178
    /// Bid too low
    BidTooLow = 59839
    /// Insufficient gas reserve
    InsufficientGasReserve = 61927
}

get fun calculateGameAddress(gameId: int257): address {
    throw 0;
}

get fun isGameExists(gameId: int257): bool {
    throw 0;
}

get fun getGameAddressBatch(startId: int257, count: int257): FlipCoinGameFactoryGameAddressBatch {
    throw 0;
}

get fun statistics(): FlipCoinGameFactoryDetailedStats {
    throw 0;
}

get fun config(): FlipCoinGameFactoryFactoryConfig {
    throw 0;
}

get fun minReferrerPayoutValue(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}
