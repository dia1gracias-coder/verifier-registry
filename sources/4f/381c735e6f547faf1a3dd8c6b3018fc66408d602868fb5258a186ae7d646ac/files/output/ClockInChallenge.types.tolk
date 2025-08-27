// Generated from the verified Tact contract ABI.
contract ClockInChallenge {
    storage: ClockInChallengeData
    incomingMessages: ClockInChallengeIncomingMessage
    thrownErrors: ClockInChallengeErrors
}

struct (0x946a98b6) ClockInChallengeDeploy {
    queryId: uint64
}

struct (0xdcbd3cd5) ClockInChallengeUpgrade {
    code: cell?
    data: cell?
}

struct (0x00000001) ClockInChallengeStart {
}

struct (0x00000002) ClockInChallengeDeposit {
}

struct (0x00000003) ClockInChallengeCheckIn {
}

struct (0x00000004) ClockInChallengeFinalize {
}

struct (0x00000005) ClockInChallengeClaim {
}

struct (0x00000006) ClockInChallengeReset {
}

struct (0x00000007) ClockInChallengeWithdraw {
    value: coins
}

struct ClockInChallengeData {
    tactDeploymentCompleted: bool
    owner: address
    startTime: int257
    active: bool
    finalized: bool
    survivorsCount: int257
    share: coins
    participants: map<address, coins>
    tactContinuation: Cell<ClockInChallengeDataContinuation>
}

struct ClockInChallengeDataContinuation {
    participantsCount: int257
    checkins: map<address, int257>
    claimed: map<address, bool>
    totalPot: coins
    version: int257
}

type ClockInChallengeIncomingMessage =
    | ClockInChallengeStart
    | ClockInChallengeDeposit
    | ClockInChallengeCheckIn
    | ClockInChallengeFinalize
    | ClockInChallengeClaim
    | ClockInChallengeReset
    | ClockInChallengeWithdraw
    | ClockInChallengeDeploy
    | ClockInChallengeUpgrade

enum ClockInChallengeErrors {
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
    /// Below min deposit
    BelowMinDeposit = 1029
    /// Not in a check-in window
    NotInACheckInWindow = 4221
    /// Previous game not reset
    PreviousGameNotReset = 6834
    /// Not finalized
    NotFinalized = 13264
    /// Cannot withdraw during active game
    CannotWithdrawDuringActiveGame = 13902
    /// Game not active
    GameNotActive = 19483
    /// Outside window
    OutsideWindow = 20053
    /// Already finalized
    AlreadyFinalized = 21277
    /// Game active, no deposits
    GameActiveNoDeposits = 28146
    /// Game finalized
    GameFinalized = 28368
    /// Not a participant
    NotAParticipant = 30287
    /// Game over
    GameOver = 33235
    /// Game not over
    GameNotOver = 34528
    /// Not a survivor
    NotASurvivor = 40697
    /// Cannot reset active game
    CannotResetActiveGame = 42187
    /// Already claimed
    AlreadyClaimed = 42504
    /// No funds to withdraw
    NoFundsToWithdraw = 50815
    /// Already active
    AlreadyActive = 51818
    /// Already checked in this round
    AlreadyCheckedInThisRound = 52506
    /// Cannot withdraw with unclaimed winnings
    CannotWithdrawWithUnclaimedWinnings = 62837
    /// No survivors
    NoSurvivors = 63927
}

get fun startTime(): int257 {
    throw 0;
}

get fun isActive(): bool {
    throw 0;
}

get fun isFinalized(): bool {
    throw 0;
}

get fun totalPot(): int257 {
    throw 0;
}

get fun survivorsCount(): int257 {
    throw 0;
}

get fun share(): int257 {
    throw 0;
}

get fun userDeposit(addr: address): int257 {
    throw 0;
}

get fun userCheckins(addr: address): int257 {
    throw 0;
}

get fun hasClaimed(addr: address): bool {
    throw 0;
}

get fun contractBalance(): int257 {
    throw 0;
}

get fun participantsCount(): int257 {
    throw 0;
}

get fun balance(): string {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun isUpgradable(): bool {
    throw 0;
}

get fun version(): int257 {
    throw 0;
}
