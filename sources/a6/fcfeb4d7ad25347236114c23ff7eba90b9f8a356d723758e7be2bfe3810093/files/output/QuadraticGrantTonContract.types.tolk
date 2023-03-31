// Generated from the verified Tact contract ABI.
contract QuadraticGrantTonContract {
    storage: QuadraticGrantTonContractData
    incomingMessages: QuadraticGrantTonContractIncomingMessage
    thrownErrors: QuadraticGrantTonContractErrors
}

struct (0x946a98b6) QuadraticGrantTonContractDeploy {
    queryId: uint64
}

struct QuadraticGrantTonContractRound {
    id: int257
    tax_adjustment_multiplier: int257
    voting_unit: int257
    tactContinuation: Cell<QuadraticGrantTonContractRoundContinuation>
}

struct QuadraticGrantTonContractRoundContinuation {
    status: int257
    fund: int257
    project_number: int257
    tactContinuation: Cell<QuadraticGrantTonContractRoundContinuation2>
}

struct QuadraticGrantTonContractRoundContinuation2 {
    total_area: int257
    projects: map<int257, Cell<QuadraticGrantTonContractProject>>
}

struct QuadraticGrantTonContractProject {
    id: int257
    pid: int257
    area: int257
    tactContinuation: Cell<QuadraticGrantTonContractProjectContinuation>
}

struct QuadraticGrantTonContractProjectContinuation {
    votes: int257
    contribution: int257
    voters: map<address, int257>
}

struct QuadraticGrantTonContractVotes {
    project_id: int257
    votes: int257
}

struct (0x01a8de15) QuadraticGrantTonContractStartRound {
    tax_adjustment_multiplier: int257
    voting_unit: int257
    fund: int257
}

struct (0xf06775f6) QuadraticGrantTonContractSetFund {
    round_id: int257
    fund: int257
}

struct (0x6eed5804) QuadraticGrantTonContractBatchUploadProjects {
    round_id: int257
    count: int257
    projects: map<int257, int257>
}

struct (0xef120794) QuadraticGrantTonContractWeightedBatchVote {
    round_id: int257
    count: int257
    amounts: map<int257, Cell<QuadraticGrantTonContractVotes>>
}

struct (0x56257364) QuadraticGrantTonContractEndRound {
    round_id: int257
}

struct QuadraticGrantTonContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    currentRound: int257
    rounds: map<int257, Cell<QuadraticGrantTonContractRound>>
}

type QuadraticGrantTonContractIncomingMessage =
    | QuadraticGrantTonContractStartRound
    | QuadraticGrantTonContractSetFund
    | QuadraticGrantTonContractBatchUploadProjects
    | QuadraticGrantTonContractWeightedBatchVote
    | QuadraticGrantTonContractEndRound
    | QuadraticGrantTonContractDeploy

enum QuadraticGrantTonContractErrors {
    /// Stack undeflow
    StackUndeflow = 2
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
    /// Voting amount not integer
    VotingAmountNotInteger = 14329
    /// Amount is too small
    AmountIsTooSmall = 15518
    /// Round status is invalid
    RoundStatusIsInvalid = 26909
    /// Insufficient funds
    InsufficientFunds = 51754
}

get fun round(id: int257): QuadraticGrantTonContractRound? {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
