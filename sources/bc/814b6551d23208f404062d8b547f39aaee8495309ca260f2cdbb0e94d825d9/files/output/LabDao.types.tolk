// Generated from the verified Tact contract ABI.
contract LabDao {
    storage: LabDaoData
    incomingMessages: LabDaoIncomingMessage
    thrownErrors: LabDaoErrors
}

struct (0x946a98b6) LabDaoDeploy {
    queryId: uint64
}

struct (0x00000001) LabDaoCreateProposal {
    description: string
    duration: uint32
}

struct (0x00000002) LabDaoVote {
    proposalId: uint32
    support: bool
    power: uint32
}

struct (0x00000003) LabDaoExecuteProposal {
    proposalId: uint32
}

struct LabDaoProposal {
    id: uint32
    description: string
    votesFor: uint64
    votesAgainst: uint64
    deadline: uint32
    executed: bool
    passed: bool
    proposer: address
}

struct LabDaoData {
    tactDeploymentCompleted: bool
    tokenMaster: address
    admin: address
    proposalCount: uint32
    lastAcceptedProposalId: uint32
    proposals: map<int257, Cell<LabDaoProposal>>
    voted: map<int257, bool>
}

type LabDaoIncomingMessage =
    | LabDaoCreateProposal
    | LabDaoVote
    | LabDaoExecuteProposal
    | LabDaoDeploy

enum LabDaoErrors {
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
    /// Description cannot be empty
    DescriptionCannotBeEmpty = 19000
    /// Proposal not found
    ProposalNotFound = 37039
    /// Voting ended
    VotingEnded = 39447
    /// Voting is still active
    VotingIsStillActive = 47949
    /// Already executed
    AlreadyExecuted = 52683
    /// Already voted
    AlreadyVoted = 59369
    /// Power must be positive
    PowerMustBePositive = 63456
}

get fun getProposal(id: int257): LabDaoProposal? {
    throw 0;
}

get fun getProposalCount(): int257 {
    throw 0;
}

get fun getTokenMaster(): address {
    throw 0;
}

get fun getAdmin(): address {
    throw 0;
}

get fun getLastAcceptedProposalId(): int257 {
    throw 0;
}

get fun getHasVoted(proposalId: int257, voter: address): bool {
    throw 0;
}
