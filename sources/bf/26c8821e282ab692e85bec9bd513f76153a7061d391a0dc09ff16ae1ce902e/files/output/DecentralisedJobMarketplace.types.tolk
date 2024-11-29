// Generated from the verified Tact contract ABI.
contract DecentralisedJobMarketplace {
    storage: DecentralisedJobMarketplaceData
    incomingMessages: DecentralisedJobMarketplaceIncomingMessage
    thrownErrors: DecentralisedJobMarketplaceErrors
}

struct (0x946a98b6) DecentralisedJobMarketplaceDeploy {
    queryId: uint64
}

struct DecentralisedJobMarketplaceJob {
    id: int257
    title: string
    description: string
    compensation: coins?
    tactContinuation: Cell<DecentralisedJobMarketplaceJobContinuation>
}

struct DecentralisedJobMarketplaceJobContinuation {
    skills: map<int257, cell>
    numberOfSkills: int257
    employer: address
    isAcceptingApplicants: bool
    worker: address?
    tactContinuation: Cell<DecentralisedJobMarketplaceJobContinuation2>
}

struct DecentralisedJobMarketplaceJobContinuation2 {
    worker_rating: int257?
    worker_review: string?
    isCompleted: bool?
    applicants: map<int257, address>
    numberOfApplicants: int257
    createdAt: int257
    tactContinuation: Cell<DecentralisedJobMarketplaceJobContinuation3>
}

struct DecentralisedJobMarketplaceJobContinuation3 {
    completedAt: int257?
}

struct DecentralisedJobMarketplacePost {
    id: int257
    title: string
    content: string
    author: address
    tactContinuation: Cell<DecentralisedJobMarketplacePostContinuation>
}

struct DecentralisedJobMarketplacePostContinuation {
    comments: map<int257, Cell<DecentralisedJobMarketplaceComment>>
    numberOfComments: int257
    upvotes: int257
    downvotes: int257
    tactContinuation: Cell<DecentralisedJobMarketplacePostContinuation2>
}

struct DecentralisedJobMarketplacePostContinuation2 {
    createdAt: int257
    archivedAt: int257?
}

struct DecentralisedJobMarketplaceComment {
    id: int257
    author: address
    content: string
    upvotes: int257
    tactContinuation: Cell<DecentralisedJobMarketplaceCommentContinuation>
}

struct DecentralisedJobMarketplaceCommentContinuation {
    downvotes: int257
}

struct DecentralisedJobMarketplaceUser {
    address: address
    name: string
    email: string
    tactContinuation: Cell<DecentralisedJobMarketplaceUserContinuation>
}

struct DecentralisedJobMarketplaceUserContinuation {
    skills: map<int257, cell>
    isEmployer: bool
    reputations: map<int257, Cell<DecentralisedJobMarketplaceReputation>>
    numberOfReputations: int257
}

struct DecentralisedJobMarketplaceReputation {
    rating: int257
    review: cell
}

struct (0x4d076d61) DecentralisedJobMarketplaceCreateUser {
    address: address
    name: string
    email: string
    skills: map<int257, cell>
    isEmployer: bool
}

struct (0x9fb828a4) DecentralisedJobMarketplaceUpdateUserName {
    address: address
    name: string
}

struct (0xb8770360) DecentralisedJobMarketplaceUpdateUserEmail {
    address: address
    email: string
}

struct (0x6b99c8ba) DecentralisedJobMarketplaceUpdateUserRole {
    address: address
    isEmployer: bool
}

struct (0x33a4c343) DecentralisedJobMarketplaceUpdateUserSkills {
    address: address
    skills: map<int257, cell>
}

struct (0x7fe14a75) DecentralisedJobMarketplaceCreateJob {
    title: string
    description: string
    compensation: coins
    skills: map<int257, cell>
    numberOfSkills: int257
}

struct (0xe92b55da) DecentralisedJobMarketplaceApplyForJob {
    job_id: int257
}

struct (0x44ca7f38) DecentralisedJobMarketplaceAcceptApplicant {
    job_id: int257
    applicant: address
}

struct (0x2c1fb245) DecentralisedJobMarketplaceCompleteJob {
    job_id: int257
    employer_rating: int257
    employer_review: string
}

struct (0xa6b3ada8) DecentralisedJobMarketplaceMarkJobCompleted {
    job_id: int257
    worker_rating: int257
    worker_review: string
    nft_metadata: cell
}

struct (0xf680ea1c) DecentralisedJobMarketplaceCreatePost {
    title: string
    content: string
}

struct (0x7c70be6a) DecentralisedJobMarketplaceCreateComment {
    post_id: int257
    content: string
}

struct (0xdedc047b) DecentralisedJobMarketplaceUpvotePost {
    post_id: int257
}

struct (0x3d8c5521) DecentralisedJobMarketplaceDownvotePost {
    post_id: int257
}

struct (0x29d2b51f) DecentralisedJobMarketplaceUpvoteComment {
    post_id: int257
    comment_id: int257
}

struct (0xba207345) DecentralisedJobMarketplaceDownvoteComment {
    post_id: int257
    comment_id: int257
}

struct (0x53f2f1a4) DecentralisedJobMarketplaceArchivePost {
    post_id: int257
}

struct DecentralisedJobMarketplaceData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    jobs: map<int257, Cell<DecentralisedJobMarketplaceJob>>
    jobCounter: int257
    tactContinuation: Cell<DecentralisedJobMarketplaceDataContinuation>
}

struct DecentralisedJobMarketplaceDataContinuation {
    posts: map<int257, Cell<DecentralisedJobMarketplacePost>>
    postCounter: int257
    nftCollection: address
    users: map<address, Cell<DecentralisedJobMarketplaceUser>>
}

type DecentralisedJobMarketplaceIncomingMessage =
    | DecentralisedJobMarketplaceCreateUser
    | DecentralisedJobMarketplaceUpdateUserName
    | DecentralisedJobMarketplaceUpdateUserEmail
    | DecentralisedJobMarketplaceUpdateUserRole
    | DecentralisedJobMarketplaceUpdateUserSkills
    | DecentralisedJobMarketplaceCreateJob
    | DecentralisedJobMarketplaceApplyForJob
    | DecentralisedJobMarketplaceAcceptApplicant
    | DecentralisedJobMarketplaceCompleteJob
    | DecentralisedJobMarketplaceMarkJobCompleted
    | DecentralisedJobMarketplaceCreatePost
    | DecentralisedJobMarketplaceCreateComment
    | DecentralisedJobMarketplaceUpvotePost
    | DecentralisedJobMarketplaceDownvotePost
    | DecentralisedJobMarketplaceArchivePost
    | DecentralisedJobMarketplaceUpvoteComment
    | DecentralisedJobMarketplaceDownvoteComment
    | DecentralisedJobMarketplaceDeploy

enum DecentralisedJobMarketplaceErrors {
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
    /// Only employer can accept applicant
    OnlyEmployerCanAcceptApplicant = 12294
    /// Description cannot be empty
    DescriptionCannotBeEmpty = 19000
    /// Job does not exist
    JobDoesNotExist = 20545
    /// Post does not exist
    PostDoesNotExist = 25737
    /// Sender is not an employer
    SenderIsNotAnEmployer = 28021
    /// Job is not accepting applicants
    JobIsNotAcceptingApplicants = 32768
    /// Only employer can complete job
    OnlyEmployerCanCompleteJob = 33446
    /// Job is not assigned
    JobIsNotAssigned = 35721
    /// Title cannot be empty
    TitleCannotBeEmpty = 39216
    /// Job is not completed by worker
    JobIsNotCompletedByWorker = 41135
    /// Comment does not exist
    CommentDoesNotExist = 42947
    /// Worker rating must be between 1 and 5
    WorkerRatingMustBeBetween1And5 = 46559
    /// User already exists
    UserAlreadyExists = 47804
    /// Job is already completed
    JobIsAlreadyCompleted = 50254
    /// Job is still accepting applicants
    JobIsStillAcceptingApplicants = 51672
    /// Incorrect value sent
    IncorrectValueSent = 54694
    /// Only author can archive post
    OnlyAuthorCanArchivePost = 58781
    /// User does not exist
    UserDoesNotExist = 59813
    /// Job already assigned
    JobAlreadyAssigned = 60462
    /// Only worker can complete job
    OnlyWorkerCanCompleteJob = 61570
    /// Employer does not exist
    EmployerDoesNotExist = 62101
}

get fun nftCollection(): address {
    throw 0;
}

get fun jobs(): map<int257, Cell<DecentralisedJobMarketplaceJob>> {
    throw 0;
}

get fun job_count(): int257 {
    throw 0;
}

get fun job(job_id: int257): DecentralisedJobMarketplaceJob? {
    throw 0;
}

get fun user(userAddress: address): DecentralisedJobMarketplaceUser {
    throw 0;
}

get fun posts(): map<int257, Cell<DecentralisedJobMarketplacePost>> {
    throw 0;
}

get fun post_count(): int257 {
    throw 0;
}

get fun post(post_id: int257): DecentralisedJobMarketplacePost? {
    throw 0;
}
