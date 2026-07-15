// Generated from the verified Tact contract ABI.
contract ReverseBuy {
    storage: ReverseBuyData
    incomingMessages: ReverseBuyIncomingMessage
    thrownErrors: ReverseBuyErrors
}

struct (0x946a98b6) ReverseBuyDeploy {
    queryId: uint64
}

struct (0x5242434e) ReverseBuyCancelBuyOffer {
    queryId: uint64
}

struct (0x5242524e) ReverseBuyRescueStrandedNft {
    queryId: uint64
    nft: address
    recipient: address
}

struct (0x52425342) ReverseBuyBuySaleOffer {
    queryId: uint64
    saleContract: address
    nft: address
    salePrice: coins
    acceptPayload: cell
}

struct (0x05138d91) ReverseBuyOwnershipAssigned {
    queryId: uint64
    prevOwner: address
    forwardPayload: RemainingBitsAndRefs
}

struct ReverseBuyBuyState {
    economicVersion: uint16
    status: uint8
    buyer: address
    collection: address
    price: coins
    reservedBalance: coins
    feeBps: uint16
    tactContinuation: Cell<ReverseBuyBuyStateContinuation>
}

struct ReverseBuyBuyStateContinuation {
    feeReceiver: address
    conditionMode: uint8
    conditionCount: uint8
    conditionsHash: uint256
    eligibilityRoot: uint256
    funded: bool
    pendingMode: uint8
    pendingUntil: uint32
}

struct ReverseBuyData {
    tactDeploymentCompleted: bool
    buyer: address
    collection: address
    price: coins
    feeReceiver: address
    feeBps: uint16
    conditionMode: uint8
    conditionCount: uint8
    tactContinuation: Cell<ReverseBuyDataContinuation>
}

struct ReverseBuyDataContinuation {
    conditionsHash: uint256
    eligibilityRoot: uint256
    minContractReserve: coins
    minAcceptValue: coins
    nftTransferValue: coins
    minRejectStorageValue: coins
    status: uint8
    tactContinuation: Cell<ReverseBuyDataContinuation2>
}

struct ReverseBuyDataContinuation2 {
    reservedBalance: coins
    funded: bool
    pendingSale: address?
    pendingNft: address?
    pendingSalePrice: coins
    pendingDealId: uint64
}

type ReverseBuyIncomingMessage =
    | ReverseBuyDeploy
    | ReverseBuyCancelBuyOffer
    | ReverseBuyBuySaleOffer
    | ReverseBuyOwnershipAssigned
    | ReverseBuyRescueStrandedNft

enum ReverseBuyErrors {
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
    /// invalid condition mode
    InvalidConditionMode = 7197
    /// not buyer
    NotBuyer = 7643
    /// invalid price
    InvalidPrice = 12537
    /// too many conditions
    TooManyConditions = 19235
    /// missing root
    MissingRoot = 20989
    /// insufficient rescue value
    InsufficientRescueValue = 30731
    /// already funded
    AlreadyFunded = 33704
    /// order still active
    OrderStillActive = 44257
    /// fee too high
    FeeTooHigh = 52892
    /// invalid condition
    InvalidCondition = 55104
    /// invalid config
    InvalidConfig = 59253
    /// invalid condition data
    InvalidConditionData = 63623
    /// insufficient deposit
    InsufficientDeposit = 63847
}

get fun get_buy_state(): ReverseBuyBuyState {
    throw 0;
}
