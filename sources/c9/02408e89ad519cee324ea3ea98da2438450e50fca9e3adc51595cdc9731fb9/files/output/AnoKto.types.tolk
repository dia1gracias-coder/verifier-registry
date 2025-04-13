// Generated from the verified Tact contract ABI.
contract AnoKto {
    storage: AnoKtoData
    incomingMessages: AnoKtoDeploy
    thrownErrors: AnoKtoErrors
}

struct (0x946a98b6) AnoKtoDeploy {
    queryId: uint64
}

struct AnoKtoProposal {
    votesFor: int257
    votesAgainst: int257
}

struct AnoKtoAgent {
    votingPower: int257
    isFounder: bool
}

struct AnoKtoData {
    tactDeploymentCompleted: bool
    count: int257
    last_message: string?
    last_sender: address?
    last_receiver: address?
    tactContinuation: Cell<AnoKtoDataContinuation>
}

struct AnoKtoDataContinuation {
    owner: address
    members: map<address, int257>
    aiAgents: map<address, Cell<AnoKtoAgent>>
    proposals: map<int257, Cell<AnoKtoProposal>>
    chairman: address
}

enum AnoKtoErrors {
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
    /// Only chairman, members or AI agents can create proposals
    OnlyChairmanMembersOrAIAgentsCanCreateProposals = 16055
    /// Only chairman can add AI agents
    OnlyChairmanCanAddAIAgents = 32504
    /// Only chairman can add members
    OnlyChairmanCanAddMembers = 58256
    /// Only members or AI agents can vote
    OnlyMembersOrAIAgentsCanVote = 58367
    /// Proposal does not exist
    ProposalDoesNotExist = 59037
}

get fun getProposalResult(proposalId: int257): AnoKtoProposal {
    throw 0;
}

get fun isAIAgentFounder(agentAddr: address): bool {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
