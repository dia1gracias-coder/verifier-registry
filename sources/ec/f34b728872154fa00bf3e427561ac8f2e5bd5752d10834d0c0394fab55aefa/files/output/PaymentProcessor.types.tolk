// Generated from the verified Tact contract ABI.
contract PaymentProcessor {
    storage: PaymentProcessorData
    incomingMessages: PaymentProcessorIncomingMessage
    thrownErrors: PaymentProcessorErrors
}

struct (0x50525247) PaymentProcessorRegisterPartnerShare {
    wallet: address
    shareBps: int257?
}

struct (0x5052554e) PaymentProcessorUnregisterPartnerShare {
    wallet: address
}

struct (0x42c20f7a) PaymentProcessorTransfer {
    req: PaymentProcessorPaymentRequest
    tactContinuation: Cell<PaymentProcessorTransferContinuation>
}

struct PaymentProcessorTransferContinuation {
    deadline: int257
}

struct (0xeeab28d0) PaymentProcessorSetPlatformCommissionBps {
    newBps: int257
}

struct (0xe225cbda) PaymentProcessorWithdrawAll {
    to: address
}

struct (0xc2b41d43) PaymentProcessorSetOwner {
    newOwner: address
}

struct PaymentProcessorPaymentRequest {
    buyer: address
    seller: address
    amount: int257
    buyerPaysCommission: bool
    tactContinuation: Cell<PaymentProcessorPaymentRequestContinuation>
}

struct PaymentProcessorPaymentRequestContinuation {
    optionalCommissionWallet: address?
}

struct PaymentProcessorPreview {
    commission: int257
    totalPay: int257
}

struct PaymentProcessorConfigResponse {
    owner: address
    mainCommissionWallet: address
    nftCollection: address
    tactContinuation: Cell<PaymentProcessorConfigResponseContinuation>
}

struct PaymentProcessorConfigResponseContinuation {
    platformCommissionBps: int257
}

struct PaymentProcessorData {
    tactDeploymentCompleted: bool
    owner: address
    platformCommissionBps: int257
    mainCommissionWallet: address
    tactContinuation: Cell<PaymentProcessorDataContinuation>
}

struct PaymentProcessorDataContinuation {
    partnerCollection: address
    partnerShareBps: map<address, int257>
    nonces: map<address, int257>
}

type PaymentProcessorIncomingMessage =
    | PaymentProcessorSetOwner
    | PaymentProcessorSetPlatformCommissionBps
    | PaymentProcessorWithdrawAll
    | PaymentProcessorTransfer
    | PaymentProcessorRegisterPartnerShare
    | PaymentProcessorUnregisterPartnerShare

enum PaymentProcessorErrors {
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
}

get fun getConfig(): PaymentProcessorConfigResponse {
    throw 0;
}

get fun previewPayment(amount: int257, buyerPaysCommission: bool): PaymentProcessorPreview {
    throw 0;
}

get fun nonceOf(account: address): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
