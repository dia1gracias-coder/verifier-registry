// Generated from the verified Tact contract ABI.
contract Dao {
    storage: DaoData
    incomingMessages: DaoIncomingMessage
    thrownErrors: DaoErrors
}

struct (0x946a98b6) DaoDeploy {
    queryId: uint64
}

struct (0x0d7b855f) DaoPropose {
    title: string
    description: string
    actionType: string
    startTimestamp: uint64
    endTimestamp: uint64
    target: address?
    value: coins
}

struct (0x073ceacf) DaoVote {
    proposalId: uint32
    choice: bool
}

struct (0xff633be1) DaoUnstake {
    amount: coins
}

struct (0x7362d09c) DaoJettonTransferNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct DaoData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    jettonAmount: coins
    jettonMasterContract: address?
    myJettonWalletAddress: address
    minVoteCount: uint32
    proposalsCount: uint32
    proposals: map<int257, address>
    tactContinuation: Cell<DaoDataContinuation>
}

struct DaoDataContinuation {
    stakeMembers: map<address, coins>
    minStakeAmount: coins
}

type DaoIncomingMessage =
    | DaoPropose
    | DaoVote
    | DaoJettonTransferNotification
    | DaoUnstake
    | DaoDeploy

enum DaoErrors {
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
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
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
    /// Invalid address
    InvalidAddress = 136
    /// Masterchain support is not enabled for this contract
    MasterchainSupportIsNotEnabledForThisContract = 137
    /// Only DAO's Jetton wallet can send notifications
    OnlyDAOSJettonWalletCanSendNotifications = 5563
    /// Only the parent DAO can register votes
    OnlyTheParentDAOCanRegisterVotes = 7215
    /// Only the parent DAO can launch proposals
    OnlyTheParentDAOCanLaunchProposals = 11009
    /// Include `STAKE` in the payload of the transfer for staking jettons
    IncludeSTAKEInThePayloadOfTheTransferForStakingJettons = 17976
    /// Invalid proposal ID
    InvalidProposalID = 18228
    /// Only members who previously staked jettons can unstake
    OnlyMembersWhoPreviouslyStakedJettonsCanUnstake = 23488
    /// Invalid unstake amount
    InvalidUnstakeAmount = 25165
    /// Only members who staked jettons can propose/vote
    OnlyMembersWhoStakedJettonsCanProposeVote = 28302
    /// Voter already voted
    VoterAlreadyVoted = 37944
    /// Invalid action type
    InvalidActionType = 38643
    /// Staked amount is less than the minimum required for membership
    StakedAmountIsLessThanTheMinimumRequiredForMembership = 48337
    /// Insufficient staked amount
    InsufficientStakedAmount = 50442
    /// Proposal does not exist
    ProposalDoesNotExist = 59037
}

get fun currentProposalCount(): int257 {
    throw 0;
}

get fun ownerAddress(): address {
    throw 0;
}

get fun minVoteCount(): int257 {
    throw 0;
}

get fun proposals(): map<int257, address> {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
