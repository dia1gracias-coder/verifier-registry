// Generated from the verified Tact contract ABI.
contract Governor {
    storage: GovernorData
    incomingMessages: GovernorIncomingMessage
    thrownErrors: GovernorErrors
}

struct GovernorProposalConfig {
    quorumPercent: int257
    thresholdPercent: int257
    period: uint64
    timelockDelay: uint64
}

struct (0x5a040104) GovernorTimelockSetProposalConfig {
    queryId: uint64
    proposalType: uint32
    config: GovernorProposalConfig
}

struct (0x5a040101) GovernorCreateProposal {
    queryId: uint64
    proposalType: uint32
    payload: cell
    claimedVp: int257
}

struct (0x5a040106) GovernorTotalVpSnapshotReply {
    queryId: uint64
    proposalId: uint64
    proposer: address
    proposalType: uint32
    payload: cell
    period: uint64
    quorumPercent: uint16
    thresholdBps: uint16
    timelockDelay: uint64
    totalVp: int257
    tactContinuation: Cell<GovernorTotalVpSnapshotReplyContinuation>
}

struct GovernorTotalVpSnapshotReplyContinuation {
    proposerVp: int257
}

struct (0x5a040102) GovernorCastVote {
    queryId: uint64
    proposalId: uint64
    support: bool
    claimedVp: int257
}

struct (0x5a040103) GovernorExecuteProposal {
    queryId: uint64
    proposalId: uint64
}

struct (0x5a040122) GovernorProposalStateReportToGovernor {
    proposalId: uint64
    newState: uint8
    queueDelay: uint64
    queueTarget: address
    queueMethod: uint32
    queueArgs: cell
    queueActive: bool
}

struct GovernorData {
    tactSystemCell: cell
    proposalCount: uint64
    proposals: map<uint64, address>
    tactContinuation: Cell<GovernorDataContinuation>
}

struct GovernorDataContinuation {
    proposalStateById: map<uint64, uint8>
    proposalEndTimeById: map<uint64, uint64>
    knownProposals: map<address, bool>
    tactContinuation: Cell<GovernorDataContinuation2>
}

struct GovernorDataContinuation2 {
    proposalConfigs: map<uint32, Cell<GovernorProposalConfig>>
    minProposalVp: int257
    stakingMaster: address
    stakingLock: address
    tactContinuation: Cell<GovernorDataContinuation3>
}

struct GovernorDataContinuation3 {
    timelock: address
    timelockDelaySec: uint64
    cancelLagSec: uint64
    treasury: address
}

type GovernorIncomingMessage =
    | GovernorCreateProposal
    | GovernorTotalVpSnapshotReply
    | GovernorCastVote
    | GovernorExecuteProposal
    | GovernorProposalStateReportToGovernor
    | GovernorTimelockSetProposalConfig

enum GovernorErrors {
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
    /// Emergency reason required
    EmergencyReasonRequired = 1944
    /// Only timelock
    OnlyTimelock = 3095
    /// Only proposer
    OnlyProposer = 3282
    /// Still voting
    StillVoting = 4002
    /// Need TON for deploy
    NeedTONForDeploy = 4874
    /// Cfg thresh
    CfgThresh = 4918
    /// Need TON for vote
    NeedTONForVote = 5554
    /// Bad snapshot source
    BadSnapshotSource = 8521
    /// Unknown proposal
    UnknownProposal = 11671
    /// Vp snapshot too low for quorum
    VpSnapshotTooLowForQuorum = 11939
    /// Bad queue delay
    BadQueueDelay = 13106
    /// Insufficient proposal vp
    InsufficientProposalVp = 18139
    /// Bad proposal type
    BadProposalType = 18698
    /// Missing config
    MissingConfig = 21286
    /// Too late
    TooLate = 26949
    /// Not succeeded
    NotSucceeded = 29432
    /// Unknown proposal cfg
    UnknownProposalCfg = 29899
    /// Feature description required
    FeatureDescriptionRequired = 31268
    /// Bad threshold
    BadThreshold = 31699
    /// Bad totalVp snapshot
    BadTotalVpSnapshot = 32121
    /// Bad caller
    BadCaller = 32178
    /// Only governor
    OnlyGovernor = 33186
    /// Unknown proposal end
    UnknownProposalEnd = 36296
    /// Use timelock path
    UseTimelockPath = 38384
    /// Cfg period
    CfgPeriod = 39256
    /// Voting ended
    VotingEnded = 39447
    /// Cfg quorum
    CfgQuorum = 47417
    /// Bad threshold pct
    BadThresholdPct = 51006
    /// Not started
    NotStarted = 54220
    /// Zero vp
    ZeroVp = 54863
    /// Spend reason required
    SpendReasonRequired = 56118
    /// Bad threshold bps
    BadThresholdBps = 57514
    /// Already voted
    AlreadyVoted = 59369
    /// Payload trailing data
    PayloadTrailingData = 59830
    /// Treasury address mismatch
    TreasuryAddressMismatch = 61091
    /// Only vote relay
    OnlyVoteRelay = 61283
    /// Not active
    NotActive = 61530
}

get fun get_proposal(id: int257): address? {
    throw 0;
}

get fun get_is_known_proposal(addr: address): bool {
    throw 0;
}

get fun get_proposal_count(): int257 {
    throw 0;
}

get fun get_proposal_state(id: int257): int257 {
    throw 0;
}

get fun get_proposal_config(proposalType: int257): GovernorProposalConfig {
    throw 0;
}

get fun get_min_proposal_vp(): int257 {
    throw 0;
}

get fun get_staking_master(): address {
    throw 0;
}

get fun get_staking_lock(): address {
    throw 0;
}

get fun get_timelock_addr(): address {
    throw 0;
}

get fun get_timelock_delay(): int257 {
    throw 0;
}

get fun get_cancel_lag(): int257 {
    throw 0;
}

get fun get_treasury(): address {
    throw 0;
}
