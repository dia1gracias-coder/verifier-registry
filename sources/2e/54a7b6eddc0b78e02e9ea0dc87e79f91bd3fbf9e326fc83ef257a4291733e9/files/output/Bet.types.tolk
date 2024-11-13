// Generated from the verified Tact contract ABI.
contract Bet {
    storage: BetData
    incomingMessages: BetIncomingMessage
    thrownErrors: BetErrors
}

struct (0x946a98b6) BetDeploy {
    queryId: uint64
}

struct BetGoal {
    id: uint256
    name: string
    description: string
    requiredStake: uint256
    creator: address
    completed: bool
    tactContinuation: Cell<BetGoalContinuation>
}

struct BetGoalContinuation {
    participants: map<uint256, address>
    participantsCount: uint256
    taskCount: uint256
    goalType: int257
    isParticipant: map<address, bool>
    isClaimed: map<address, bool>
    tactContinuation: Cell<BetGoalContinuation2>
}

struct BetGoalContinuation2 {
    completedTaskCount: map<address, uint256>
    rewards: map<address, uint256>
}

struct BetGoalInfo {
    id: uint256
    name: string
    description: string
    requiredStake: uint256
    creator: address
    completed: bool
    tactContinuation: Cell<BetGoalInfoContinuation>
}

struct BetGoalInfoContinuation {
    participants: map<uint256, address>
    goalType: int257
}

struct BetTask {
    id: string
    name: string
    completed: bool
    projectId: string
    taskCompleter: address
}

struct BetProject {
    id: string
    userPoints: map<address, uint256>
    participants: map<uint256, address>
    participantsCount: uint256
}

struct BetUserGoals {
    address: address
    goals: map<uint256, uint256>
    goalsLen: uint256
}

struct BetCompletedTasks {
    address: address
    tasks: map<uint256, uint256>
    tasksLen: uint256
}

struct BetGithubUser {
    githubUsername: string
}

struct (0x6f2239f5) BetLinkWallet {
    address: address
    github: string
}

struct (0x99f62b08) BetCreateGoal {
    goalType: int257
    name: string
    description: string
    requiredStake: int257
    taskCount: int257
}

struct (0x5e0b1ee7) BetStakeAndUnlockGoal {
    goalId: int257
}

struct (0x9811a72c) BetConfirmTaskCompletion {
    goalId: int257
    user: address
}

struct (0x71cb1ece) BetClaimStake {
    goalId: int257
}

struct (0x2ecbb389) BetSettleGoal {
    goalId: int257
}

struct (0xf7d126b3) BetCreateProject {
    projectId: string
    name: string
}

struct (0xa62b9ce2) BetCreateTask {
    id: string
    name: string
    projectId: string
}

struct (0x2dc00b3d) BetConfirmTask {
    taskId: string
    github: string
    taskPoints: int257
}

struct (0x7fada449) BetDonateToProject {
    projectId: string
    amount: int257
}

struct (0x47fa4d67) BetClaimReward {
    projectId: string
}

struct BetData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    goals: map<uint256, Cell<BetGoal>>
    goalsLen: uint256
    tactContinuation: Cell<BetDataContinuation>
}

struct BetDataContinuation {
    tasks: map<uint256, Cell<BetTask>>
    tasksLen: uint256
    taskIndices: map<uint256, uint256>
    userGoals: map<address, Cell<BetUserGoals>>
    tactContinuation: Cell<BetDataContinuation2>
}

struct BetDataContinuation2 {
    walletToGithub: map<address, Cell<BetGithubUser>>
    githubToWallet: map<uint256, address>
    userPoints: map<address, uint256>
    tactContinuation: Cell<BetDataContinuation3>
}

struct BetDataContinuation3 {
    userCompletedTasks: map<address, Cell<BetCompletedTasks>>
    projects: map<uint256, Cell<BetProject>>
    projectIds: map<uint256, uint256>
    projectCount: uint256
    tactContinuation: Cell<BetDataContinuation4>
}

struct BetDataContinuation4 {
    totalRewards: map<address, uint256>
    claimedRewards: map<address, uint256>
}

type BetIncomingMessage =
    | BetCreateGoal
    | BetLinkWallet
    | BetStakeAndUnlockGoal
    | BetConfirmTaskCompletion
    | BetClaimStake
    | BetSettleGoal
    | BetCreateProject
    | BetCreateTask
    | BetConfirmTask
    | BetDonateToProject
    | BetClaimReward
    | BetDeploy

enum BetErrors {
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
    /// Task already exists.
    TaskAlreadyExists = 16969
    /// Goal does not exist.
    GoalDoesNotExist = 32038
    /// Wallet already linked to a Github account
    WalletAlreadyLinkedToAGithubAccount = 44355
    /// Project already exists.
    ProjectAlreadyExists = 50111
}

get fun walletToGithub(): map<address, Cell<BetGithubUser>> {
    throw 0;
}

get fun allGoals(): map<uint256, Cell<BetGoalInfo>> {
    throw 0;
}

get fun userGoals(address: address): map<uint256, uint256> {
    throw 0;
}

get fun goalDetails(goalId: int257): BetGoalInfo {
    throw 0;
}

get fun allTasks(): map<uint256, Cell<BetTask>> {
    throw 0;
}

get fun unconfirmedTasks(): map<uint256, Cell<BetTask>> {
    throw 0;
}

get fun allProjectIds(): map<uint256, Cell<BetProject>> {
    throw 0;
}

get fun projectParticipants(projectId: string): map<uint256, address> {
    throw 0;
}

get fun projectUserPoints(projectId: string, user: address): int257 {
    throw 0;
}

get fun totalRewards(user: address): int257 {
    throw 0;
}

get fun claimedRewards(user: address): int257 {
    throw 0;
}

get fun userPoints(user: address): int257 {
    throw 0;
}

get fun userCompletedTasks(user: address): map<uint256, uint256> {
    throw 0;
}

get fun githubByWallet(wallet: address): string {
    throw 0;
}
