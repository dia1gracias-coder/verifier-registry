// Generated from the verified Tact contract ABI.
contract JettonWalletFeatureRich {
    storage: JettonWalletFeatureRichData
    incomingMessages: JettonWalletFeatureRichIncomingMessage
    thrownErrors: JettonWalletFeatureRichErrors
}

struct JettonWalletFeatureRichStateInit {
    code: cell
    data: cell
}

struct JettonWalletFeatureRichJettonWalletData {
    balance: int257
    owner: address
    minter: address
    code: cell
}

struct (0x0f8a7ea5) JettonWalletFeatureRichJettonTransfer {
    queryId: uint64
    amount: coins
    destination: address
    responseDestination: address?
    customPayload: cell?
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x1fdde72e) JettonWalletFeatureRichJettonTransferInternalV2 {
    queryId: uint64
    amount: coins
    sender: address
    responseDestination: address?
    forwardTonAmount: coins
    forwardStateInit: JettonWalletFeatureRichStateInit?
    forwardPayload: RemainingBitsAndRefs
}

struct (0x595f07bc) JettonWalletFeatureRichJettonBurn {
    queryId: uint64
    amount: coins
    responseDestination: address?
    customPayload: cell?
}

struct (0x7ac8d559) JettonWalletFeatureRichProvideWalletBalance {
    receiver: address
    includeVerifyInfo: bool
}

struct (0x0393b1ce) JettonWalletFeatureRichClaimTON {
    receiver: address
}

struct JettonWalletFeatureRichData {
    owner: address
    minter: address
    balance: coins
}

type JettonWalletFeatureRichIncomingMessage =
    | JettonWalletFeatureRichJettonTransfer
    | JettonWalletFeatureRichJettonTransferInternalV2
    | JettonWalletFeatureRichProvideWalletBalance
    | JettonWalletFeatureRichJettonBurn
    | JettonWalletFeatureRichClaimTON

enum JettonWalletFeatureRichErrors {
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
    /// Incorrect balance after send
    IncorrectBalanceAfterSend = 2366
    /// Incorrect sender
    IncorrectSender = 9215
    /// Forward state init is null with deploy send mode
    ForwardStateInitIsNullWithDeploySendMode = 18073
    /// Insufficient amount of TON attached
    InsufficientAmountOfTONAttached = 32113
    /// Deploy address doesn't match owner address
    DeployAddressDoesnTMatchOwnerAddress = 51864
    /// Incorrect send amount
    IncorrectSendAmount = 52281
}

get fun get_wallet_data(): JettonWalletFeatureRichJettonWalletData {
    throw 0;
}
