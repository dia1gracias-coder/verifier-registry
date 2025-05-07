// Generated from the verified Tact contract ABI.
contract Course {
    storage: CourseData2
    incomingMessages: CourseIncomingMessage
    thrownErrors: CourseErrors
}

struct CourseCollectionData {
    next_item_index: int257
    collection_content: cell
    owner_address: address
}

struct (0x1c3fe32a) CourseUpdateCourse {
    content: cell
    cost: coins
}

struct (0x107d1186) CourseCertificateIssue {
    student: address
    certificate_content: cell
}

struct (0xe5443d9f) CourseEnrollment {
    student_id: cell
    student_gmail: cell
}

struct (0xbbf36824) CourseQuiz {
    quizNumber: uint32
    answers: cell
}

struct CourseData {
    next_item_index: int257
    collection_content: cell
    owner_address: address
    cost: coins
}

struct CourseData2 {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    next_item_index: uint32
    owner: address
    collection_content: cell
    cost: coins
}

type CourseIncomingMessage =
    | CourseUpdateCourse
    | CourseEnrollment
    | CourseQuiz
    | CourseCertificateIssue

enum CourseErrors {
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
    /// certificate couldn't be transfered
    CertificateCouldnTBeTransfered = 10599
    /// content must be not empty
    ContentMustBeNotEmpty = 24103
    /// No enough funds to enroll
    NoEnoughFundsToEnroll = 42468
    /// id should be >= 0
    IdShouldBe0 = 43242
    /// not from collection
    NotFromCollection = 49469
    /// cost must be positive
    CostMustBePositive = 58974
    /// value should be >= 0.02
    ValueShouldBe002 = 60753
}

get fun get_collection_data(): CourseCollectionData {
    throw 0;
}

get fun get_course_data(): CourseData {
    throw 0;
}

get fun get_nft_address_by_index(item_index: int257): address? {
    throw 0;
}

get fun get_nft_content(index: int257, individual_content: cell): cell {
    throw 0;
}

get fun get_balance(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
