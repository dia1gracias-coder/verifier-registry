// Generated from the verified Tact contract ABI.
contract AnzoEscrowJettonOffer {
    storage: AnzoEscrowJettonOfferData
    incomingMessages: AnzoEscrowJettonOfferIncomingMessage
    thrownErrors: AnzoEscrowJettonOfferErrors
}

struct (0x7362d09c) AnzoEscrowJettonOfferJettonTransferNotification {
    queryId: uint64
    amount: coins
    from: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0xa3000cd4) AnzoEscrowJettonOfferTakerCreateIntent {
    amount: int257
    isFeeShared: bool
}

struct (0x49d6dd62) AnzoEscrowJettonOfferAnzoCreateIntent {
    takerAddress: address
    amount: int257
    isFeeShared: bool
}

struct (0x6635f157) AnzoEscrowJettonOfferConfirmIntent {
    intentId: int257
}

struct (0xee6154b1) AnzoEscrowJettonOfferCancelIntent {
    intentId: int257
}

struct (0xbd5d9cce) AnzoEscrowJettonOfferMakerCancelOffer {
}

struct (0xa55d3bfb) AnzoEscrowJettonOfferWithdrawTakerDeposit {
}

struct (0xc33ad913) AnzoEscrowJettonOfferCollectFees {
}

struct (0x7b3e8d92) AnzoEscrowJettonOfferReclaimOffer {
}

struct AnzoEscrowJettonOfferContractConstructorData {
    makerAddress: address
    offChainOfferId: int257
    jettonTypeId: int257
    tactContinuation: Cell<AnzoEscrowJettonOfferContractConstructorDataContinuation>
}

struct AnzoEscrowJettonOfferContractConstructorDataContinuation {
    minimumIntentAmount: int257
    controllerWalletAddress: address
    feeCollectionWalletAddress: address
    tactContinuation: Cell<AnzoEscrowJettonOfferContractConstructorDataContinuation2>
}

struct AnzoEscrowJettonOfferContractConstructorDataContinuation2 {
    sharedFeeCollectionWalletAddress: address
    feeBasisPoints: int257
    availableAmount: int257
    tactContinuation: Cell<AnzoEscrowJettonOfferContractConstructorDataContinuation3>
}

struct AnzoEscrowJettonOfferContractConstructorDataContinuation3 {
    intentValidityDurationSeconds: int257
    myJettonWalletAddress: address
    offerExpiryTimestamp: int257
    tactContinuation: Cell<AnzoEscrowJettonOfferContractConstructorDataContinuation4>
}

struct AnzoEscrowJettonOfferContractConstructorDataContinuation4 {
    numActiveIntents: int257
    amountFeesCollected: int257
    amountSharedFeesCollected: int257
    isBuyOffer: bool
    tactContinuation: Cell<AnzoEscrowJettonOfferContractConstructorDataContinuation5>
}

struct AnzoEscrowJettonOfferContractConstructorDataContinuation5 {
    nextIntentId: int257
}

struct AnzoEscrowJettonOfferIntent {
    takerAddress: address
    amount: int257
    validUntilTimestamp: int257
    isMakerConfirmed: bool
    isTakerConfirmed: bool
    isControllerConfirmed: bool
    isFeeShared: bool
}

struct AnzoEscrowJettonOfferData {
    tactDeploymentCompleted: bool
    makerAddress: address
    offChainOfferId: int257
    jettonTypeId: int257
    intents: map<int257, Cell<AnzoEscrowJettonOfferIntent>>
    tactContinuation: Cell<AnzoEscrowJettonOfferDataContinuation>
}

struct AnzoEscrowJettonOfferDataContinuation {
    nextIntentId: int257
    minimumIntentAmount: int257
    myJettonWalletAddress: address
    tactContinuation: Cell<AnzoEscrowJettonOfferDataContinuation2>
}

struct AnzoEscrowJettonOfferDataContinuation2 {
    feeCollectionWalletAddress: address
    sharedFeeCollectionWalletAddress: address
    controllerWalletAddress: address
    tactContinuation: Cell<AnzoEscrowJettonOfferDataContinuation3>
}

struct AnzoEscrowJettonOfferDataContinuation3 {
    feeBasisPoints: int257
    amountFeesCollected: int257
    amountSharedFeesCollected: int257
    tactContinuation: Cell<AnzoEscrowJettonOfferDataContinuation4>
}

struct AnzoEscrowJettonOfferDataContinuation4 {
    availableAmount: int257
    availableTakerDeposits: map<address, int257>
    numActiveIntents: int257
    isBuyOffer: bool
    intentValidityDurationSeconds: int257
    tactContinuation: Cell<AnzoEscrowJettonOfferDataContinuation5>
}

struct AnzoEscrowJettonOfferDataContinuation5 {
    offerExpiryTimestamp: int257
}

type AnzoEscrowJettonOfferIncomingMessage =
    | AnzoEscrowJettonOfferJettonTransferNotification
    | AnzoEscrowJettonOfferTakerCreateIntent
    | AnzoEscrowJettonOfferAnzoCreateIntent
    | AnzoEscrowJettonOfferConfirmIntent
    | AnzoEscrowJettonOfferCancelIntent
    | AnzoEscrowJettonOfferMakerCancelOffer
    | AnzoEscrowJettonOfferReclaimOffer
    | AnzoEscrowJettonOfferCollectFees
    | AnzoEscrowJettonOfferWithdrawTakerDeposit

enum AnzoEscrowJettonOfferErrors {
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
    /// Notification not from your jetton wallet!
    NotificationNotFromYourJettonWallet = 12495
}

get fun makerAddress(): address {
    throw 0;
}

get fun offChainOfferId(): int257 {
    throw 0;
}

get fun jettonTypeId(): int257 {
    throw 0;
}

get fun intent(intentId: int257): AnzoEscrowJettonOfferIntent? {
    throw 0;
}

get fun nextIntentId(): int257 {
    throw 0;
}

get fun minimumIntentAmount(): int257 {
    throw 0;
}

get fun myJettonWalletAddress(): address {
    throw 0;
}

get fun feeCollectionWalletAddress(): address {
    throw 0;
}

get fun sharedFeeCollectionWalletAddress(): address {
    throw 0;
}

get fun controllerWalletAddress(): address {
    throw 0;
}

get fun feeBasisPoints(): int257 {
    throw 0;
}

get fun amountFeesCollected(): int257 {
    throw 0;
}

get fun amountSharedFeesCollected(): int257 {
    throw 0;
}

get fun availableAmount(): int257 {
    throw 0;
}

get fun availableTakerDeposit(takerAddress: address): int257 {
    throw 0;
}

get fun numActiveIntents(): int257 {
    throw 0;
}

get fun isBuyOffer(): bool {
    throw 0;
}

get fun intentValidityDurationSeconds(): int257 {
    throw 0;
}

get fun offerExpiryTimestamp(): int257 {
    throw 0;
}

get fun contractData(): AnzoEscrowJettonOfferContractConstructorData {
    throw 0;
}
