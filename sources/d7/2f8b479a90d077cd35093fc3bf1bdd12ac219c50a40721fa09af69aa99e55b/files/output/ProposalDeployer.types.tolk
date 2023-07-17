// Generated from the verified Tact contract ABI.
contract ProposalDeployer {
    storage: ProposalDeployerData
    incomingMessages: ProposalDeployerIncomingMessage
    thrownErrors: ProposalDeployerErrors
}

struct (0x946a98b6) ProposalDeployerDeploy {
    queryId: uint64
}

struct (0x5938a1cb) ProposalDeployerDeployAndInitProposal {
    body: ProposalDeployerParams
}

struct (0x991dac3f) ProposalDeployerSendUpdateProposal {
    proposalAddress: address
    updateParams: ProposalDeployerParams
}

struct ProposalDeployerParams {
    proposalStartTime: uint64
    proposalEndTime: uint64
    proposalSnapshotTime: uint64
    votingSystem: string
    votingPowerStrategies: string
    title: string
    tactContinuation: Cell<ProposalDeployerParamsContinuation>
}

struct ProposalDeployerParamsContinuation {
    description: string
    quorum: string
    hide: bool
}

struct ProposalDeployerData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    dao: address
    nextProposalId: uint32
}

type ProposalDeployerIncomingMessage =
    | ProposalDeployerDeployAndInitProposal
    | ProposalDeployerSendUpdateProposal
    | ProposalDeployerDeploy

enum ProposalDeployerErrors {
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
    /// Already initialized
    AlreadyInitialized = 2977
    /// Invalid sender
    InvalidSender = 4429
    /// Update proposals is possible only before start time
    UpdateProposalsIsPossibleOnlyBeforeStartTime = 8923
    /// only dao can send create proposal message
    OnlyDaoCanSendCreateProposalMessage = 13403
    /// only dao can send update proposal message
    OnlyDaoCanSendUpdateProposalMessage = 50214
    /// Incative proposal
    IncativeProposal = 52334
    /// Propsal was not initialized yet
    PropsalWasNotInitializedYet = 61278
}

get fun dao(): address {
    throw 0;
}

get fun nextProposalId(): int257 {
    throw 0;
}

get fun proposalAddr(index: int257): address {
    throw 0;
}
