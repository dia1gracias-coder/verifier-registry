// Generated from the verified Tact contract ABI.
contract TonSplitter {
    storage: TonSplitterData
    incomingMessages: TonSplitterIncomingMessage
    thrownErrors: TonSplitterErrors
}

struct (0x7a4508d9) TonSplitterPause {
}

struct (0x8dcb2d19) TonSplitterUnpause {
}

struct (0x60591510) TonSplitterWithdraw {
    amount: int257
}

struct (0x24d518e9) TonSplitterUpdateParams {
    total: int257
    amount1: int257
    amount2: int257
    tactContinuation: Cell<TonSplitterUpdateParamsContinuation>
}

struct TonSplitterUpdateParamsContinuation {
    wallet1: address
    wallet2: address
}

struct TonSplitterState {
    owner: address
    wallet1: address
    wallet2: address
    tactContinuation: Cell<TonSplitterStateContinuation>
}

struct TonSplitterStateContinuation {
    total: int257
    amount1: int257
    amount2: int257
    paused: bool
}

struct TonSplitterData {
    tactDeploymentCompleted: bool
    owner: address
    total: int257
    amount1: int257
    tactContinuation: Cell<TonSplitterDataContinuation>
}

struct TonSplitterDataContinuation {
    amount2: int257
    wallet1: address
    wallet2: address
    paused: bool
    tactContinuation: Cell<TonSplitterDataContinuation2>
}

struct TonSplitterDataContinuation2 {
    lastUser: address?
    lastUserCallTime: int257
    lastOwnerCallTime: int257
}

type TonSplitterIncomingMessage =
    | TonSplitterPause
    | TonSplitterUnpause
    | TonSplitterWithdraw
    | TonSplitterUpdateParams

enum TonSplitterErrors {
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
    /// Total positive
    TotalPositive = 4031
    /// Too large amounts
    TooLargeAmounts = 10321
    /// Low value
    LowValue = 10700
    /// Wallet1 invalid
    Wallet1Invalid = 16570
    /// Amount positive
    AmountPositive = 17095
    /// Amount1 positive
    Amount1Positive = 20423
    /// Not Paused
    NotPaused = 21564
    /// Wallet2 invalid
    Wallet2Invalid = 25793
    /// Amount2 positive
    Amount2Positive = 26293
    /// Owner timelock
    OwnerTimelock = 28230
    /// User timelock
    UserTimelock = 32791
    /// Only owner
    OnlyOwner = 35499
    /// Wallet1 is owner
    Wallet1IsOwner = 36944
    /// Owner invalid
    OwnerInvalid = 38831
    /// Same Wallets
    SameWallets = 47859
    /// Low Balance
    LowBalance = 50617
    /// Wallet2 is owner
    Wallet2IsOwner = 50771
    /// Paused
    Paused = 59457
}

get fun state(): TonSplitterState {
    throw 0;
}
