// Generated from the verified Tact contract ABI.
contract ReverseSale {
    storage: ReverseSaleData
    incomingMessages: ReverseSaleIncomingMessage
    thrownErrors: ReverseSaleErrors
}

struct (0x946a98b6) ReverseSaleDeploy {
    queryId: uint64
}

struct (0x5253434e) ReverseSaleCancelSale {
    queryId: uint64
}

struct (0x5253524e) ReverseSaleRescueHeldNft {
    queryId: uint64
}

struct (0x52534642) ReverseSaleFillBuyOffer {
    queryId: uint64
    buyContract: address
    settlementPrice: coins
    acceptPayload: cell
}

struct (0x52534242) ReverseSaleBuyForReverseBuy {
    queryId: uint64
    acceptPayload: cell
}

struct (0x5242524a) ReverseSaleClaimRejectedNft {
    nft: address
}

struct (0x05138d91) ReverseSaleOwnershipAssigned {
    queryId: uint64
    prevOwner: address
    forwardPayload: RemainingBitsAndRefs
}

struct ReverseSaleSaleState {
    economicVersion: uint16
    status: uint8
    seller: address
    nft: address
    price: coins
    feeBps: uint16
    feeReceiver: address
    nftDeposited: bool
    pendingMode: uint8
    pendingUntil: uint32
}

struct ReverseSaleSaleRejectedItem {
    prevOwner: address
    reasonCode: uint8
    createdAt: uint32
}

struct ReverseSaleData {
    tactDeploymentCompleted: bool
    seller: address
    nft: address
    price: coins
    feeReceiver: address
    feeBps: uint16
    tactContinuation: Cell<ReverseSaleDataContinuation>
}

struct ReverseSaleDataContinuation {
    minContractReserve: coins
    minDepositValue: coins
    minBuyValue: coins
    nftTransferValue: coins
    minRejectStorageValue: coins
    status: uint8
    nftDeposited: bool
    pendingMode: uint8
    pendingBuy: address?
    tactContinuation: Cell<ReverseSaleDataContinuation2>
}

struct ReverseSaleDataContinuation2 {
    pendingPayment: coins
    pendingDealId: uint64
    rejectedItems: map<address, Cell<ReverseSaleSaleRejectedItem>>
}

type ReverseSaleIncomingMessage =
    | ReverseSaleDeploy
    | ReverseSaleOwnershipAssigned
    | ReverseSaleFillBuyOffer
    | ReverseSaleBuyForReverseBuy
    | ReverseSaleCancelSale
    | ReverseSaleRescueHeldNft
    | ReverseSaleClaimRejectedNft

enum ReverseSaleErrors {
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
    /// invalid price
    InvalidPrice = 12537
    /// insufficient deploy
    InsufficientDeploy = 25034
    /// insufficient return value
    InsufficientReturnValue = 39403
    /// not rejected
    NotRejected = 41792
    /// not previous owner
    NotPreviousOwner = 47652
    /// fee too high
    FeeTooHigh = 52892
    /// not seller
    NotSeller = 54672
    /// invalid config
    InvalidConfig = 59253
}

get fun get_sale_state(): ReverseSaleSaleState {
    throw 0;
}

get fun get_rejected_item(nft: address): ReverseSaleSaleRejectedItem? {
    throw 0;
}
