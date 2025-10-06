// Generated from the verified Tact contract ABI.
contract OrderEscrowContract {
    storage: OrderEscrowContractData
    incomingMessages: OrderEscrowContractIncomingMessage
    thrownErrors: OrderEscrowContractErrors
}

struct (0x946a98b6) OrderEscrowContractDeploy {
    queryId: uint64
}

struct OrderEscrowContractOrderInfo {
    orderId: uint64
    objType: uint8
    orderAmount: coins
    price: coins
    buyerDeposit: coins
    sellerDeposit: coins
    buyerDepositPaid: coins
    sellerDepositPaid: coins
    settlementType: uint8
    status: int8
    tactContinuation: Cell<OrderEscrowContractOrderInfoContinuation>
}

struct OrderEscrowContractOrderInfoContinuation {
    buyerAddress: address
    sellerAddress: address
    createTime: uint32
    sellerPayTime: uint32
    buyerPayTime: uint32
    okTime: uint32
    deliveryTime: uint32
    acceptTime: uint32
    completeTime: uint32
    refunds: map<int257, Cell<OrderEscrowContractRefundRecord>>
    refundCount: uint32
    refundFlag: uint8
    cancelTime: uint32
    tactContinuation: Cell<OrderEscrowContractOrderInfoContinuation2>
}

struct OrderEscrowContractOrderInfoContinuation2 {
    cancelAddress: address?
    jettonMasterAddress: address?
}

struct OrderEscrowContractRefundRecord {
    applicant: address
    handler: address
    refundAmount: coins
    otherAmount: coins
    status: uint8
    requestTime: uint32
    handleTime: uint32
}

struct OrderEscrowContractPaymentRecord {
    sender: address
    amount: int257
    orderId: int257
    tactContinuation: Cell<OrderEscrowContractPaymentRecordContinuation>
}

struct OrderEscrowContractPaymentRecordContinuation {
    timestamp: int257
    reason: string
}

struct (0xc5a170e8) OrderEscrowContractCreateOrder {
    orderId: uint64
    objType: uint8
    price: coins
    buyerAddress: address?
    sellerAddress: address?
    tactContinuation: Cell<OrderEscrowContractCreateOrderContinuation>
}

struct OrderEscrowContractCreateOrderContinuation {
    jettonMasterAddress: address
}

struct (0x0219c07f) OrderEscrowContractInitiateContract {
    orderId: uint64
    orderAmount: coins
    buyerDeposit: coins
    sellerDeposit: coins
    settlementType: uint8
    jettonMasterAddress: address
}

struct (0xb780b45d) OrderEscrowContractProductOrderEdit {
    orderId: uint64
    orderAmount: coins
    jettonMasterAddress: address
}

struct (0x89a25ae6) OrderEscrowContractSellerSignContract {
    orderId: uint64
}

struct (0x3bf76ac9) OrderEscrowContractCompleteDelivery {
    orderId: uint64
}

struct (0xc765fd20) OrderEscrowContractConfirmAcceptance {
    orderId: uint64
}

struct (0xb50d6046) OrderEscrowContractCancelOrder {
    orderId: uint64
}

struct (0x0e31a3cc) OrderEscrowContractRequestRefund {
    orderId: uint64
    refundAmount: coins
}

struct (0xfe0d005f) OrderEscrowContractProcessRefund {
    orderId: uint64
    approve: bool
}

struct (0x6e5fedb1) OrderEscrowContractJettonTransferNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0x5788d7e4) OrderEscrowContractRescueErrorPayments {
    jettonMasterAddress: address
    to: address
    amount: coins
}

struct OrderEscrowContractData {
    tactDeploymentCompleted: bool
    platformFeeRate: uint16
    orders: map<uint64, Cell<OrderEscrowContractOrderInfo>>
    tactContinuation: Cell<OrderEscrowContractDataContinuation>
}

struct OrderEscrowContractDataContinuation {
    jettonWallets: map<address, address>
    jettonWalletCode: cell
    lastQueryId: uint64
    jettonTransferGas: coins
    usdtJettonMaster: address?
    paymentErrorRecords: map<uint64, Cell<OrderEscrowContractPaymentRecord>>
    paymentErrorRecordsLength: uint64
    paymentErrorAmountMaps: map<address, coins>
    owner: address
}

type OrderEscrowContractIncomingMessage =
    | OrderEscrowContractCreateOrder
    | OrderEscrowContractInitiateContract
    | OrderEscrowContractProductOrderEdit
    | OrderEscrowContractJettonTransferNotification
    | OrderEscrowContractSellerSignContract
    | OrderEscrowContractCompleteDelivery
    | OrderEscrowContractConfirmAcceptance
    | OrderEscrowContractCancelOrder
    | OrderEscrowContractRequestRefund
    | OrderEscrowContractProcessRefund
    | OrderEscrowContractRescueErrorPayments
    | OrderEscrowContractDeploy

enum OrderEscrowContractErrors {
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
    /// No refund request
    NoRefundRequest = 2000
    /// Jetton master address not correct
    JettonMasterAddressNotCorrect = 3076
    /// Seller deposit must be greater than 0
    SellerDepositMustBeGreaterThan0 = 3449
    /// Invalid settlement type
    InvalidSettlementType = 3629
    /// Not the handler
    NotTheHandler = 6098
    /// Sender address not correct
    SenderAddressNotCorrect = 6309
    /// Order not in correct state
    OrderNotInCorrectState = 7232
    /// Order no is required
    OrderNoIsRequired = 7923
    /// Refund already requested
    RefundAlreadyRequested = 14067
    /// Refund amount exceeds paid deposits
    RefundAmountExceedsPaidDeposits = 15376
    /// Buyer deposit must be greater than order amount
    BuyerDepositMustBeGreaterThanOrderAmount = 16351
    /// Refund amount must be greater than 1
    RefundAmountMustBeGreaterThan1 = 17929
    /// Order not found
    OrderNotFound = 18518
    /// Order already exists
    OrderAlreadyExists = 25019
    /// Order cannot be refunded
    OrderCannotBeRefunded = 33677
    /// Invalid object type
    InvalidObjectType = 33912
    /// Seller deposit is not 0
    SellerDepositIsNot0 = 36528
    /// Amount must be greater than 0
    AmountMustBeGreaterThan0 = 40476
    /// Jetton master error amount is not enough
    JettonMasterErrorAmountIsNotEnough = 41272
    /// Not a product order
    NotAProductOrder = 46881
    /// Buyer and seller cannot be the same
    BuyerAndSellerCannotBeTheSame = 48180
    /// Not the seller
    NotTheSeller = 48844
    /// Order amount must be greater than 1
    OrderAmountMustBeGreaterThan1 = 49706
    /// Price must be greater than 0
    PriceMustBeGreaterThan0 = 50036
    /// Not a task order
    NotATaskOrder = 55729
    /// Order cannot be cancelled
    OrderCannotBeCancelled = 55736
    /// Not the buyer
    NotTheBuyer = 56127
    /// Buyer deposit must be greater than 1
    BuyerDepositMustBeGreaterThan1 = 61686
    /// Seller address not correct
    SellerAddressNotCorrect = 62081
}

get fun paymentErrorRecord(index: int257): OrderEscrowContractPaymentRecord {
    throw 0;
}

get fun paymentErrorRecordsLength(): int257 {
    throw 0;
}

get fun order(orderId: int257): OrderEscrowContractOrderInfo? {
    throw 0;
}

get fun platformFeeRate(): int257 {
    throw 0;
}

get fun orderRefunds(orderId: int257): map<int257, Cell<OrderEscrowContractRefundRecord>> {
    throw 0;
}

get fun paymentErrorAmountMap(jettonMasterAddress: address): int257? {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
