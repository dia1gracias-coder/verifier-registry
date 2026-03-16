// Generated from the verified Tact contract ABI.
contract FpDao {
    storage: FpDaoData
    incomingMessages: FpDaoIncomingMessage
    thrownErrors: FpDaoErrors
}

struct (0x946a98b6) FpDaoDeploy {
    queryId: uint64
}

struct (0x00000001) FpDaoCreateProposal {
    description: string
    duration: int257
}

struct (0x00000002) FpDaoVote {
    proposalId: int257
    support: bool
}

struct (0x00000003) FpDaoExecuteProposal {
    proposalId: int257
}

struct FpDaoProposal {
    id: int257
    description: string
    votesFor: int257
    votesAgainst: int257
    tactContinuation: Cell<FpDaoProposalContinuation>
}

struct FpDaoProposalContinuation {
    deadline: int257
    executed: bool
    proposer: address
}

struct FpDaoData {
    tactDeploymentCompleted: bool
    jettonMaster: address
    proposals: map<int257, Cell<FpDaoProposal>>
    proposalCount: int257
    voted: map<int257, bool>
    version: int257
}

type FpDaoIncomingMessage =
    | FpDaoCreateProposal
    | FpDaoVote
    | FpDaoExecuteProposal
    | FpDaoDeploy

enum FpDaoErrors {
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
    /// Duration must be >= 60 seconds
    DurationMustBe60Seconds = 4505
    /// Voting period has ended
    VotingPeriodHasEnded = 16262
    /// Description cannot be empty
    DescriptionCannotBeEmpty = 19000
    /// Proposal not found
    ProposalNotFound = 37039
    /// Voting still active
    VotingStillActive = 41880
    /// Already executed
    AlreadyExecuted = 52683
    /// Already voted
    AlreadyVoted = 59369
}

get fun getProposal(id: int257): FpDaoProposal? {
    throw 0;
}

get fun getProposalCount(): int257 {
    throw 0;
}

get fun getJettonMaster(): address {
    throw 0;
}
