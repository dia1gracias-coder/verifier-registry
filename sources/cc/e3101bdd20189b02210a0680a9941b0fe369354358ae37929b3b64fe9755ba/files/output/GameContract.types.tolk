// Generated from the verified Tact contract ABI.
contract GameContract {
    storage: GameContractData
    incomingMessages: GameContractIncomingMessage
    thrownErrors: GameContractErrors
}

struct GameContractGameState {
    owner: address
    tokenAddress: address?
    walletAddress: address?
    deployTime: uint64
    gameStarted: uint64
    airdropDuration: uint64
    tactContinuation: Cell<GameContractGameStateContinuation>
}

struct GameContractGameStateContinuation {
    streakState: uint64
    greenCount: uint64
    redCount: uint64
    cpaReward: uint64
    changeInterval: uint32
    lastChanged: uint32
    maxBet: uint64
    minBet: uint8
    streakRatio: uint8
    greenPrice: uint32
    redPrice: uint32
    gameHistory1: uint256
    gameHistory2: uint256
    tactContinuation: Cell<GameContractGameStateContinuation2>
}

struct GameContractGameStateContinuation2 {
    gameHistory3: uint256
    gameHistory4: uint256
    gameHistory5: uint256
    tactContinuation: Cell<GameContractGameStateContinuation3>
}

struct GameContractGameStateContinuation3 {
    gameHistory6: uint256
    gameHistory7: uint256
    gameHistory8: uint256
    currentHistoryLength: uint16
    createAt: uint64
}

struct (0x85dc9ff2) GameContractW2GStartGame {
    bet: uint256
    referrer: address?
}

struct (0x34776b1a) GameContractW2GStopGame {
}

struct (0xa3dfe41c) GameContractW2GRedGame {
    bet: uint256
    referrer: address?
}

struct (0x33057504) GameContractP2GTokenWithdraw {
    destination: address
    amount: uint256
}

struct (0xb99218e1) GameContractW2GTokenWithdraw {
    player: address
    amount: uint256
}

struct (0x7362d09c) GameContractJettonNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0xd53276db) GameContractJettonExcesses {
    queryId: uint64
}

struct GameContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    tokenMinted: bool
    tokenAddress: address?
    walletAddress: address?
    deployTime: uint64
    gameStarted: uint64
    airdropDuration: uint64
    tactContinuation: Cell<GameContractDataContinuation>
}

struct GameContractDataContinuation {
    streakState: uint64
    greenCount: uint64
    redCount: uint64
    cpaReward: uint256
    changeInterval: uint256
    lastChanged: uint256
    tactContinuation: Cell<GameContractDataContinuation2>
}

struct GameContractDataContinuation2 {
    maxBet: uint256
    minBet: uint256
    streakRatio: uint256
    tactContinuation: Cell<GameContractDataContinuation3>
}

struct GameContractDataContinuation3 {
    greenPrice: int257
    redPrice: int257
    gameHistory1: uint256
    tactContinuation: Cell<GameContractDataContinuation4>
}

struct GameContractDataContinuation4 {
    gameHistory2: uint256
    gameHistory3: uint256
    gameHistory4: uint256
    tactContinuation: Cell<GameContractDataContinuation5>
}

struct GameContractDataContinuation5 {
    gameHistory5: uint256
    gameHistory6: uint256
    gameHistory7: uint256
    tactContinuation: Cell<GameContractDataContinuation6>
}

struct GameContractDataContinuation6 {
    gameHistory8: uint256
    currentHistoryLength: uint16
}

type GameContractIncomingMessage =
    | GameContractW2GStartGame
    | GameContractW2GStopGame
    | GameContractW2GRedGame
    | GameContractJettonNotification
    | GameContractJettonExcesses
    | GameContractW2GTokenWithdraw
    | GameContractP2GTokenWithdraw

enum GameContractErrors {
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
    /// Access denied, Not Player
    AccessDeniedNotPlayer = 1908
    /// Incorrect balance after send
    IncorrectBalanceAfterSend = 2366
    /// Not Playing
    NotPlaying = 5843
    /// Incorrect sender
    IncorrectSender = 9215
    /// Unauthorized burn
    UnauthorizedBurn = 10363
    /// Max reached
    MaxReached = 14698
    /// Min reached
    MinReached = 18164
    /// Incorrect Sender
    IncorrectSender2 = 24687
    /// Insufficient amount of TON attached
    InsufficientAmountOfTONAttached = 32113
    /// Incorrect Jetton Sender
    IncorrectJettonSender = 35712
    /// Insufficient TON amount
    InsufficientTONAmount = 36890
    /// Not allowed yet, try later
    NotAllowedYetTryLater = 36962
    /// Insufficient gas for mint
    InsufficientGasForMint = 37629
    /// Playing, call StopPlayer to start again
    PlayingCallStopPlayerToStartAgain = 46681
    /// Access denied, Not Parent
    AccessDeniedNotParent = 50335
    /// Mint is closed
    MintIsClosed = 51950
    /// Insufficient balance
    InsufficientBalance = 54615
    /// Token minted
    TokenMinted = 54769
    /// Playing now, call StopPlayer to start again
    PlayingNowCallStopPlayerToStartAgain = 59061
    /// Incorrect sender2
    IncorrectSender22 = 60094
}

get fun playerAddress(address: address): address {
    throw 0;
}

get fun jettonAddress(address: address): address {
    throw 0;
}

get fun contractState(): GameContractGameState {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
