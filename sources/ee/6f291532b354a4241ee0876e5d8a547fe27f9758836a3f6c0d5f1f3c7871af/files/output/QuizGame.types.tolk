// Generated from the verified Tact contract ABI.
contract QuizGame {
    storage: QuizGameData
    incomingMessages: QuizGameIncomingMessage
    thrownErrors: QuizGameErrors
}

struct (0x946a98b6) QuizGameDeploy {
    queryId: uint64
}

struct QuizGameGameData {
    bet_amount: coins
    game_state: uint8
    player1: address
    player2: address
    winner: address
    tactContinuation: Cell<QuizGameGameDataContinuation>
}

struct QuizGameGameDataContinuation {
    total_pot: coins
}

struct (0x52323fc6) QuizGamePlaceBet {
    queryId: uint64
}

struct (0x7ff4786d) QuizGameEndGame {
    queryId: uint64
    winner_id: uint8
}

struct (0x74dbdec9) QuizGameClaim {
    queryId: uint64
}

struct QuizGameData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    game: QuizGameGameData
}

type QuizGameIncomingMessage =
    | QuizGamePlaceBet
    | QuizGameEndGame
    | QuizGameClaim
    | QuizGameDeploy

enum QuizGameErrors {
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
    /// Game is not in progress
    GameIsNotInProgress = 2321
    /// Game is not finished
    GameIsNotFinished = 5907
    /// Insufficient bet amount
    InsufficientBetAmount = 14721
    /// Game is not in waiting state
    GameIsNotInWaitingState = 28718
    /// Only players can end the game
    OnlyPlayersCanEndTheGame = 38640
    /// Only winner can claim
    OnlyWinnerCanClaim = 43564
    /// Game is full
    GameIsFull = 62887
}

get fun game_data(): QuizGameGameData {
    throw 0;
}

get fun claimable_balance(addr: address): int257 {
    throw 0;
}
