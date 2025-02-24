// Generated from the verified Tact contract ABI.
contract TournamentFactory {
    storage: TournamentFactoryData
    incomingMessages: TournamentFactoryIncomingMessage
    thrownErrors: TournamentFactoryErrors
}

struct (0x3b542c8a) TournamentFactorySetMatchAuthority {
    newMatchAuthority: address
}

struct (0x6efe0a28) TournamentFactorySetElympicsTreasury {
    newElympicsTreasury: address
}

struct (0x69074bc9) TournamentFactorySetElympicsCommission {
    newElympicsCommission: int257
}

struct (0xa86dd47d) TournamentFactoryFund {
}

struct (0x5cf806c0) TournamentFactoryReturnRemainingBalance {
    target: address
}

struct TournamentFactorySimpleIntArray {
    m: map<uint16, uint64>
    length: uint16
}

struct TournamentFactoryTournamentConfig {
    id: string
    gameId: string
    deadline: uint64
    entryFee: uint64
    jettonMinterAddress: address?
    tactContinuation: Cell<TournamentFactoryTournamentConfigContinuation>
}

struct TournamentFactoryTournamentConfigContinuation {
    jettonWalletCode: cell?
    jettonImplementationVersion: int257?
    rewardDistributionPercents: TournamentFactorySimpleIntArray
}

struct TournamentFactoryTournamentInitData {
    tactContinuation: Cell<TournamentFactoryTournamentInitDataContinuation>
}

struct TournamentFactoryTournamentInitDataContinuation {
    config: TournamentFactoryTournamentConfig
    matchAuthority: address
    elympicsTreasury: address
    elympicsCommission: uint32
    tactContinuation: Cell<TournamentFactoryTournamentInitDataContinuation2>
}

struct TournamentFactoryTournamentInitDataContinuation2 {
    developerTreasury: address
    developerCommission: uint32
    author: address
    authorCommission: uint32
}

struct (0x4ffef387) TournamentFactoryCreateTournament {
    tournamentConfig: TournamentFactoryTournamentConfig
    developerTreasury: address
    developerCommission: uint32
    authorCommission: uint32
}

struct TournamentFactoryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    deployer: address
    matchAuthority: address
    elympicsTreasury: address
    elympicsCommission: uint32
}

type TournamentFactoryIncomingMessage =
    | TournamentFactoryCreateTournament
    | TournamentFactorySetMatchAuthority
    | TournamentFactorySetElympicsTreasury
    | TournamentFactorySetElympicsCommission
    | TournamentFactoryFund
    | TournamentFactoryReturnRemainingBalance

enum TournamentFactoryErrors {
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
    /// Out of gas error
    OutOfGasError = 13
    /// Method ID not found
    MethodIDNotFound = 32
    /// Action is invalid or not supported
    ActionIsInvalidOrNotSupported = 34
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
    NotEnoughExtraCurrencies = 38
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
    /// Invalid index
    InvalidIndex = 1173
    /// Already initialized
    AlreadyInitialized = 2977
    /// Cannot call earlier than deadline
    CannotCallEarlierThanDeadline = 9666
    /// Invalid reward distribution percents sum
    InvalidRewardDistributionPercentsSum = 9726
    /// Leaderboard capacity exceeds max size
    LeaderboardCapacityExceedsMaxSize = 14474
    /// Cannot exceed max number of entries
    CannotExceedMaxNumberOfEntries = 18644
    /// Cannot call past deadline
    CannotCallPastDeadline = 21170
    /// Insufficient number of unsettled entries
    InsufficientNumberOfUnsettledEntries = 30602
    /// Deadline set in the past
    DeadlineSetInThePast = 36099
    /// Total commission too high
    TotalCommissionTooHigh = 42107
    /// Array size too big
    ArraySizeTooBig = 42243
    /// Invalid Jetton implementation version
    InvalidJettonImplementationVersion = 42964
    /// Invalid number of entries
    InvalidNumberOfEntries = 43145
    /// Invalid tournament state
    InvalidTournamentState = 43412
    /// Index out of bounds
    IndexOutOfBounds = 44718
    /// Map entry does not exist
    MapEntryDoesNotExist = 45319
    /// Unauthorized caller
    UnauthorizedCaller = 52222
    /// Commission too high
    CommissionTooHigh = 61168
    /// Insufficient value sent
    InsufficientValueSent = 62441
}

get fun tournamentAddressOf(initData: TournamentFactoryTournamentInitData): address {
    throw 0;
}

get fun tournamentAddressOfUnflattenedJetton(id: string, gameId: string, deadline: int257, entryFee: int257, rewardDistribution: map<uint16, uint64>, leaderboardCapacity: int257, jettonMinterAddress: address, jettonWalletCode: cell, jettonImplementationVersion: int257, developerTreasury: address, developerCommission: int257, author: address, authorCommission: int257): address {
    throw 0;
}

get fun tournamentAddressOfUnflattened(id: string, gameId: string, deadline: int257, entryFee: int257, rewardDistribution: map<uint16, uint64>, leaderboardCapacity: int257, developerTreasury: address, developerCommission: int257, author: address, authorCommission: int257): address {
    throw 0;
}

get fun matchAuthority(): address {
    throw 0;
}

get fun elympicsTreasury(): address {
    throw 0;
}

get fun elympicsCommission(): int257 {
    throw 0;
}
