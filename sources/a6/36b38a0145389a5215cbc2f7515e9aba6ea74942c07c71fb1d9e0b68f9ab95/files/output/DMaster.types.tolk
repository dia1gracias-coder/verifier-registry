// Generated from the verified Tact contract ABI.
contract DMaster {
    storage: DMasterData
    incomingMessages: DMasterIncomingMessage
    thrownErrors: DMasterErrors
}

struct (0x946a98b6) DMasterDeploy {
    queryId: uint64
}

struct (0x819dbe99) DMasterChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0xc74705cb) DMasterRegister {
    query_id: uint64
}

struct (0xc3b65efd) DMasterMintDBlog {
    query_id: uint64
    blog_data: DMasterNftCollectionMetadata
    d_user: address
}

struct (0xcf50183f) DMasterWithdraw {
    query_id: uint64
    amount: int257
}

struct (0xf3cdd238) DMasterWithdrawAll {
    query_id: uint64
    destroy: bool?
}

struct (0x07abf6a7) DMasterTopUp {
    query_id: uint64
}

struct DMasterNftCollectionMetadata {
    image: string
    name: string
    description: string
}

struct DMasterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    treasury_address: address
    next_blog_seq_no: uint32
}

type DMasterIncomingMessage =
    | DMasterRegister
    | DMasterMintDBlog
    | DMasterDeploy
    | DMasterChangeOwner
    | DMasterTopUp
    | DMasterWithdraw
    | DMasterWithdrawAll

enum DMasterErrors {
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
    /// DProfile is not waiting for blog
    DProfileIsNotWaitingForBlog = 5602
    /// DProfile already has a blog
    DProfileAlreadyHasABlog = 6841
    /// Only DPost can create a reply link
    OnlyDPostCanCreateAReplyLink = 7012
    /// You can only edit a post after 24 hours
    YouCanOnlyEditAPostAfter24Hours = 7455
    /// Only the profile owner can mint a blog
    OnlyTheProfileOwnerCanMintABlog = 13607
    /// not enough funds to create a blog
    NotEnoughFundsToCreateABlog = 16032
    /// Reached maximum number of replies
    ReachedMaximumNumberOfReplies = 16409
    /// index must be less than next_item_index
    IndexMustBeLessThanNextItemIndex = 25833
    /// This contract is not initialized yet
    ThisContractIsNotInitializedYet = 28330
    /// index must be positive
    IndexMustBePositive = 29995
    /// not enough funds to register a profile
    NotEnoughFundsToRegisterAProfile = 38130
    /// This contract is initialized already
    ThisContractIsInitializedAlready = 49931
    /// Only the blog can initialize the post
    OnlyTheBlogCanInitializeThePost = 50812
    /// DProfile already initialized
    DProfileAlreadyInitialized = 52598
    /// Only master can initialize the blog
    OnlyMasterCanInitializeTheBlog = 54093
    /// not enough funds to create a post
    NotEnoughFundsToCreateAPost = 56855
    /// Blog address mismatch
    BlogAddressMismatch = 60754
    /// Only DMaster can initialize DProfile
    OnlyDMasterCanInitializeDProfile = 62306
}

get fun version(): string {
    throw 0;
}

get fun blogs_count(): int257 {
    throw 0;
}

get fun blog_address_by_index(item_index: int257): address {
    throw 0;
}

get fun profile_address_by_user(user: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}
