// Generated from the verified Tact contract ABI.
contract Cashback {
    storage: CashbackData
    incomingMessages: CashbackIncomingMessage
    thrownErrors: CashbackErrors
}

struct (0x946a98b6) CashbackDeploy {
    queryId: uint64
}

struct (0xc47f29a3) CashbackWithdraw {
    queryId: uint64
}

struct (0xb36a9178) CashbackSetJettonWallet {
    jettonWallet: address
}

struct (0x5fe99a31) CashbackProcessPayment {
    tagId: string
    jettonAmount: uint32
    tonAmount: uint32
}

struct CashbackData {
    tactDeploymentCompleted: bool
    owner: address
    jettonWallet: address?
}

type CashbackIncomingMessage =
    | CashbackProcessPayment
    | CashbackSetJettonWallet
    | CashbackWithdraw
    | CashbackDeploy

enum CashbackErrors {
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
    /// Error: Jetton wallet address is not set by the owner.
    ErrorJettonWalletAddressIsNotSetByTheOwner = 8822
    /// Error: Jetton wallet can only be set once.
    ErrorJettonWalletCanOnlyBeSetOnce = 10342
    /// Error: Only the owner can set the jetton wallet.
    ErrorOnlyTheOwnerCanSetTheJettonWallet = 22513
    /// Error: Only the owner can withdraw funds.
    ErrorOnlyTheOwnerCanWithdrawFunds = 38231
    /// Error: Incorrect TON amount sent with the transaction.
    ErrorIncorrectTONAmountSentWithTheTransaction = 43924
}

get fun getOwner(): address {
    throw 0;
}

get fun getJettonWallet(): address? {
    throw 0;
}

get fun isJettonWalletSet(): bool {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}
