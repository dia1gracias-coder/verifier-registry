// Generated from the verified Tact contract ABI.
contract BatchDistribute {
    storage: BatchDistributeData
    incomingMessages: BatchDistributeIncomingMessage
    thrownErrors: BatchDistributeErrors
}

struct (0x7362d09c) BatchDistributeJettonNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct BatchDistributeTransferParams {
    destination: address
    forwardTonAmount: coins
    tonValue: coins
    amount: coins
    margin: coins
    customPayload: cell?
}

struct (0x2a9fd3ca) BatchDistributeBatchJettonTransfer {
    recipients: map<int257, Cell<BatchDistributeTransferParams>>
}

struct (0x5a598603) BatchDistributeEmergencyJettonWithdraw {
    queryId: int257
    to: address
    amount: coins
    forwardTonAmount: coins
    tonValue: coins
    customPayload: cell?
}

struct (0x35ea144d) BatchDistributeAddDistributor {
    distributor: address
}

struct (0x684921b8) BatchDistributeRemoveDistributor {
    distributor: address
}

struct (0x0e316c5d) BatchDistributeAddEmergencyOperator {
    operator_: address
}

struct (0x20eb01b2) BatchDistributeRemoveEmergencyOperator {
    operator_: address
}

struct (0x8649c126) BatchDistributeUpdateMaxBatchSize {
    newMaxBatchSize: int257
}

struct (0x3080c9dd) BatchDistributeSyncJettonBalance {
    newBalance: coins
}

struct BatchDistributeData {
    tactDeploymentCompleted: bool
    myJettonAmount: coins
    jettonMasterAddress: address
    jettonWalletCode: cell
    owner: address
    myJettonWalletAddress: address
    tactContinuation: Cell<BatchDistributeDataContinuation>
}

struct BatchDistributeDataContinuation {
    maxBatchSize: int257
    distributors: map<address, bool>
    emergencyOperators: map<address, bool>
}

type BatchDistributeIncomingMessage =
    | BatchDistributeJettonNotification
    | BatchDistributeBatchJettonTransfer
    | BatchDistributeEmergencyJettonWithdraw
    | BatchDistributeAddDistributor
    | BatchDistributeRemoveDistributor
    | BatchDistributeAddEmergencyOperator
    | BatchDistributeRemoveEmergencyOperator
    | BatchDistributeUpdateMaxBatchSize
    | BatchDistributeSyncJettonBalance

enum BatchDistributeErrors {
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
    /// Not authorized as emergency operator
    NotAuthorizedAsEmergencyOperator = 4520
    /// Custom payload size exceeds limit
    CustomPayloadSizeExceedsLimit = 7068
    /// Balance overflow protection
    BalanceOverflowProtection = 7781
    /// Not authorized as distributor
    NotAuthorizedAsDistributor = 8729
    /// Incorrect sender
    IncorrectSender = 9215
    /// Total amount overflow protection
    TotalAmountOverflowProtection = 9491
    /// Transfer amount must be positive
    TransferAmountMustBePositive = 10272
    /// Insufficient TON for gas fees
    InsufficientTONForGasFees = 15613
    /// Custom payload size exceeds maximum limit
    CustomPayloadSizeExceedsMaximumLimit = 15783
    /// Subtraction amount must be positive
    SubtractionAmountMustBePositive = 17343
    /// Not enough funds to withdraw
    NotEnoughFundsToWithdraw = 20020
    /// Payload data size exceeds limit
    PayloadDataSizeExceedsLimit = 32070
    /// Payload cell count exceeds limit
    PayloadCellCountExceedsLimit = 34327
    /// Batch size exceeds maximum limit
    BatchSizeExceedsMaximumLimit = 37588
    /// Invalid bounced amount
    InvalidBouncedAmount = 46616
    /// Invalid bounce source
    InvalidBounceSource = 47047
    /// Forward TON amount must be at least 0.001 TON
    ForwardTONAmountMustBeAtLeast0001TON = 49509
    /// Balance cannot be negative
    BalanceCannotBeNegative = 50433
    /// Invalid batch size
    InvalidBatchSize = 52380
    /// Insufficient balance
    InsufficientBalance = 54615
    /// TON value must be positive
    TONValueMustBePositive = 59303
}

get fun balance(): int257 {
    throw 0;
}

get fun isDistributor(address: address): bool {
    throw 0;
}

get fun isEmergencyOperator(address: address): bool {
    throw 0;
}

get fun getMaxBatchSize(): int257 {
    throw 0;
}

get fun getMyJettonWalletAddress(): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
