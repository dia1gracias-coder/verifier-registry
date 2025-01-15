// Generated from the verified Tact contract ABI.
contract GiftAuction {
    storage: GiftAuctionData
    incomingMessages: GiftAuctionIncomingMessage
    thrownErrors: GiftAuctionErrors
}

struct (0x946a98b6) GiftAuctionDeploy {
    queryId: uint64
}

struct (0x6b46b842) GiftAuctionSetAdmins {
    admins: map<address, bool>
}

struct (0x1d4fed6d) GiftAuctionPlaceBid {
    orderId: int257
}

struct (0x4f4df54c) GiftAuctionFinalizeAuction {
    orderId: int257
}

struct (0x1e5fa811) GiftAuctionOrderSuccessed {
    orderId: int257
    comment: string
}

struct (0x693cc676) GiftAuctionOrderUnsuccessed {
    orderId: int257
    comment: string
}

struct (0x1126db5c) GiftAuctionAuctionOrderPayload {
    id: int257
    description: string
    minBid: int257
    duration: int257
}

struct (0xbb4d76e3) GiftAuctionConfirmOrder {
    orderId: int257
    approve: bool
}

struct (0xb6c5357b) GiftAuctionNewMinBid {
    minBid: int257
}

struct (0x870df1d7) GiftAuctionNewMinOrderDuration {
    duration: int257
}

struct (0xb7f80775) GiftAuctionNewMinStep {
    step: int257
}

struct (0x60591510) GiftAuctionWithdraw {
    amount: int257
}

struct (0x974b3fb8) GiftAuctionSetFounder {
    founder: address
}

struct (0x3bbb5b70) GiftAuctionSetFeePercentageWinner {
    fee: int257
}

struct (0x017511c1) GiftAuctionSetFeePercentageBidder {
    fee: int257
}

struct (0x9357c9d5) GiftAuctionSetFeePercentageNoBid {
    fee: int257
}

struct (0x0feffb5e) GiftAuctionSetFeePercentageUnsuccess {
    fee: int257
}

struct (0x38e3484e) GiftAuctionSetPledgePerchentage {
    percentage: int257
}

struct GiftAuctionBid {
    bidder: address
    amount: int257
}

struct GiftAuctionAuctionOrder {
    id: int257
    owner: address
    description: string
    minBid: int257
    tactContinuation: Cell<GiftAuctionAuctionOrderContinuation>
}

struct GiftAuctionAuctionOrderContinuation {
    depositPaid: int257
    highestBid: GiftAuctionBid?
    tactContinuation: Cell<GiftAuctionAuctionOrderContinuation2>
}

struct GiftAuctionAuctionOrderContinuation2 {
    duration: int257
    endTime: int257
    finalized: bool
    active: bool
    successed: bool
}

struct GiftAuctionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    FeePercentageWinner: int257
    FeePercentageBidder: int257
    FeePercentageNoBid: int257
    tactContinuation: Cell<GiftAuctionDataContinuation>
}

struct GiftAuctionDataContinuation {
    FeePercentageUnsuccess: int257
    minBidRequire: int257
    minOrderDuration: int257
    tactContinuation: Cell<GiftAuctionDataContinuation2>
}

struct GiftAuctionDataContinuation2 {
    minStep: int257
    pledgePerchentage: int257
    deployer: address
    orders: map<int257, Cell<GiftAuctionAuctionOrder>>
    tactContinuation: Cell<GiftAuctionDataContinuation3>
}

struct GiftAuctionDataContinuation3 {
    orderCounter: int257
    admins: map<address, bool>
    version: uint32
    founder: address
}

type GiftAuctionIncomingMessage =
    | GiftAuctionSetAdmins
    | GiftAuctionAuctionOrderPayload
    | GiftAuctionConfirmOrder
    | GiftAuctionPlaceBid
    | GiftAuctionFinalizeAuction
    | GiftAuctionOrderSuccessed
    | GiftAuctionOrderUnsuccessed
    | GiftAuctionNewMinBid
    | GiftAuctionNewMinOrderDuration
    | GiftAuctionNewMinStep
    | GiftAuctionSetFounder
    | GiftAuctionSetFeePercentageWinner
    | GiftAuctionSetFeePercentageBidder
    | GiftAuctionSetFeePercentageNoBid
    | GiftAuctionSetFeePercentageUnsuccess
    | GiftAuctionSetPledgePerchentage
    | GiftAuctionWithdraw
    | GiftAuctionDeploy

enum GiftAuctionErrors {
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
    /// Bid is not higher than the current highest
    BidIsNotHigherThanTheCurrentHighest = 4987
    /// Order is not active
    OrderIsNotActive = 5735
    /// Minimum bid is too low
    MinimumBidIsTooLow = 10881
    /// Order already successed
    OrderAlreadySuccessed = 12497
    /// Only deployer is allowed to withdraw
    OnlyDeployerIsAllowedToWithdraw = 15509
    /// Only admins can confirm orders
    OnlyAdminsCanConfirmOrders = 16053
    /// Order not found
    OrderNotFound = 18518
    /// Only deployer can change min bid
    OnlyDeployerCanChangeMinBid = 19057
    /// Auction has ended
    AuctionHasEnded = 19240
    /// Only deployer can set the fee percentage for unsuccess
    OnlyDeployerCanSetTheFeePercentageForUnsuccess = 32752
    /// Only deployer can set the fee percentage for the winner
    OnlyDeployerCanSetTheFeePercentageForTheWinner = 33067
    /// Auction is not finalized
    AuctionIsNotFinalized = 33745
    /// Order is already active
    OrderIsAlreadyActive = 36510
    /// Only admins can unsuccess closing auction
    OnlyAdminsCanUnsuccessClosingAuction = 39751
    /// Invalid order ID
    InvalidOrderID = 39765
    /// Only admins can finalize auctions
    OnlyAdminsCanFinalizeAuctions = 42766
    /// Bid is too low
    BidIsTooLow = 43457
    /// Only deployer can set the fee percentage for no bid
    OnlyDeployerCanSetTheFeePercentageForNoBid = 43950
    /// Only deployer can set the founder
    OnlyDeployerCanSetTheFounder = 44488
    /// Auction is still ongoing
    AuctionIsStillOngoing = 48724
    /// Insufficient deposit for order creation
    InsufficientDepositForOrderCreation = 49245
    /// Only deployer can manage admins
    OnlyDeployerCanManageAdmins = 51964
    /// No bids were placed
    NoBidsWerePlaced = 54043
    /// Only deployer can set the fee percentage for the bidder
    OnlyDeployerCanSetTheFeePercentageForTheBidder = 54143
    /// Insufficient balance
    InsufficientBalance = 54615
    /// Only deployer can change min step
    OnlyDeployerCanChangeMinStep = 55138
    /// Only deployer can change min order duration
    OnlyDeployerCanChangeMinOrderDuration = 56025
    /// Auction duration must be at least 1 hour
    AuctionDurationMustBeAtLeast1Hour = 56711
    /// Auction already finalized
    AuctionAlreadyFinalized = 59324
    /// Order with this ID already exists
    OrderWithThisIDAlreadyExists = 60424
    /// Only admins can success closing auction
    OnlyAdminsCanSuccessClosingAuction = 61567
    /// Only deployer can set the pledge percentage
    OnlyDeployerCanSetThePledgePercentage = 63203
}

get fun getOrder(orderId: int257): GiftAuctionAuctionOrder {
    throw 0;
}

get fun allOrders(): map<int257, Cell<GiftAuctionAuctionOrder>> {
    throw 0;
}

get fun orderCount(): int257 {
    throw 0;
}

get fun getAdmins(): map<address, bool> {
    throw 0;
}

get fun getMinBid(): int257 {
    throw 0;
}

get fun getMinOrderDuration(): int257 {
    throw 0;
}

get fun getMinStep(): int257 {
    throw 0;
}

get fun getPledgePerchentage(): int257 {
    throw 0;
}

get fun getFounder(): address {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}

get fun lockedBalance(): int257 {
    throw 0;
}
