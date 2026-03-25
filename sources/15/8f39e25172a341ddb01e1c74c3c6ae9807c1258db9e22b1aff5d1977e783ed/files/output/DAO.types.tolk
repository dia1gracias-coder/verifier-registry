// Generated from the verified Tact contract ABI.
contract DAO {
    storage: DAOData
    incomingMessages: DAOIncomingMessage
    thrownErrors: DAOErrors
}

struct (0x946a98b6) DAODeploy {
    queryId: uint64
}

struct (0x7362d09c) DAOJettonTransferNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0x90c41b10) DAOCreateProposal {
    description: string
    deadline: uint64
    actionTarget: address
    actionAmount: coins
}

struct (0x4ff7136c) DAOExecute {
    proposalId: uint32
}

struct (0xb8e34b79) DAOSetJettonWallet {
    wallet: address
}

struct DAOProposal {
    description: string
    deadline: uint64
    yesVotes: coins
    noVotes: coins
    executed: bool
    actionTarget: address
    actionAmount: coins
    proposer: address
}

struct DAOData {
    tactDeploymentCompleted: bool
    owner: address
    jettonMaster: address
    jettonWalletOfDAO: address
    proposals: map<uint32, Cell<DAOProposal>>
    nextProposalId: uint32
}

type DAOIncomingMessage =
    | DAOSetJettonWallet
    | DAOCreateProposal
    | DAOJettonTransferNotification
    | DAOExecute
    | DAODeploy

enum DAOErrors {
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
    /// Deadline must be in the future
    DeadlineMustBeInTheFuture = 4391
    /// Voting still in progress
    VotingStillInProgress = 21003
    /// Proposal not found
    ProposalNotFound = 37039
    /// Proposal rejected
    ProposalRejected = 46880
    /// Not our jetton wallet
    NotOurJettonWallet = 51947
    /// Already executed
    AlreadyExecuted = 52683
    /// Voting has ended
    VotingHasEnded = 59195
}

get fun getProposal(id: int257): DAOProposal? {
    throw 0;
}

get fun getProposalById(id: int257): DAOProposal {
    throw 0;
}

get fun getNextProposalId(): int257 {
    throw 0;
}

get fun getJettonWallet(): address {
    throw 0;
}

get fun getJettonMaster(): address {
    throw 0;
}

get fun getOwner(): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
