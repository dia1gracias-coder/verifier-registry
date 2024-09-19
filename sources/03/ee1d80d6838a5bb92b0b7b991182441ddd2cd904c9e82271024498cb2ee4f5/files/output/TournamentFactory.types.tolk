// Generated from the verified Tact contract ABI.
contract TournamentFactory {
    storage: TournamentFactoryData
    incomingMessages: TournamentFactoryIncomingMessage
    thrownErrors: TournamentFactoryErrors
}

struct (0x946a98b6) TournamentFactoryDeploy {
    queryId: uint64
}

struct TournamentFactorySimpleIntArray {
    m: map<uint16, uint64>
    length: uint16
}

struct TournamentFactoryTournamentInitData {
    id: uint64
    leaderboardCapacity: uint8
    deadline: uint64
    matchAuthority: address
    entryFee: uint64
    elympicsTreasury: address
    elympicsCommission: uint32
    rewardDistributionPercents: TournamentFactorySimpleIntArray
}

struct (0x346f2434) TournamentFactoryJoinTournament {
    initData: TournamentFactoryTournamentInitData
    nonce: uint64
}

struct TournamentFactoryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    elympicsTreasury: address
    elympicsCommission: uint32
}

type TournamentFactoryIncomingMessage =
    | TournamentFactoryJoinTournament
    | TournamentFactoryDeploy

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
    /// Cannot call earlier than deadline
    CannotCallEarlierThanDeadline = 9666
    /// Cannot call past deadline
    CannotCallPastDeadline = 21170
    /// Invalid nonce
    InvalidNonce = 23767
    /// Array size too big
    ArraySizeTooBig = 42243
    /// Index out of bounds
    IndexOutOfBounds = 44718
    /// Map size too big
    MapSizeTooBig = 46189
    /// Unauthorized caller
    UnauthorizedCaller = 52222
    /// Commission too high
    CommissionTooHigh = 61168
    /// Invalid init data
    InvalidInitData = 62097
    /// Insufficient value sent
    InsufficientValueSent = 62441
}
