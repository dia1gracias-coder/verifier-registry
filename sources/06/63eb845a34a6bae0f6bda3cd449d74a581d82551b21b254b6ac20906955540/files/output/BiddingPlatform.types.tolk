// Generated from the verified Tact contract ABI.
contract BiddingPlatform {
    storage: BiddingPlatformData
    incomingMessages: BiddingPlatformIncomingMessage
    thrownErrors: BiddingPlatformErrors
}

struct (0x946a98b6) BiddingPlatformDeploy {
    queryId: uint64
}

struct (0x341deb08) BiddingPlatformNewService {
    description: string
}

struct (0x1758483f) BiddingPlatformFinalizeService {
    serviceId: uint256
}

struct BiddingPlatformData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    numServices: uint256
}

type BiddingPlatformIncomingMessage =
    | BiddingPlatformNewService
    | BiddingPlatformFinalizeService
    | BiddingPlatformDeploy

enum BiddingPlatformErrors {
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
    /// Service does not exist
    ServiceDoesNotExist = 17448
    /// Already finalized
    AlreadyFinalized = 21277
    /// Bid must be higher than current highest
    BidMustBeHigherThanCurrentHighest = 41606
    /// Parent only
    ParentOnly = 54404
    /// Bidding is finalized
    BiddingIsFinalized = 57085
    /// Insufficient funds sent
    InsufficientFundsSent = 58383
}

get fun numServices(): int257 {
    throw 0;
}

get fun serviceAddress(serviceId: int257): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
