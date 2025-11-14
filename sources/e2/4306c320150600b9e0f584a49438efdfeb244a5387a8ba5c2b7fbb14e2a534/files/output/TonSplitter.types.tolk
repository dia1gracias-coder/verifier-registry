// Generated from the verified Tact contract ABI.
contract TonSplitter {
    storage: TonSplitterData
    incomingMessages: TonSplitterIncomingMessage
    thrownErrors: TonSplitterErrors
}

struct (0x946a98b6) TonSplitterDeploy {
    queryId: uint64
}

struct (0x7068ef94) TonSplitterUpdateParams {
    amount1: coins
    amount2: coins
    wallet1: address
    wallet2: address
    tactContinuation: Cell<TonSplitterUpdateParamsContinuation>
}

struct TonSplitterUpdateParamsContinuation {
    logAddress: address?
}

struct (0x20212c06) TonSplitterWithdrawFees {
}

struct (0x7a4508d9) TonSplitterPause {
}

struct (0x1494cd89) TonSplitterResume {
}

struct (0x78cd3681) TonSplitterUpdateLogging {
    logAddress: address?
    logGas: uint32
}

struct (0xd805921b) TonSplitterEmergencyWithdraw {
}

struct TonSplitterPendingMessage {
    value: uint64
    sender: address
}

struct TonSplitterFullState {
    amount1: int257
    amount2: int257
    wallet1: address
    tactContinuation: Cell<TonSplitterFullStateContinuation>
}

struct TonSplitterFullStateContinuation {
    wallet2: address
    owner: address
    balance: int257
    tactContinuation: Cell<TonSplitterFullStateContinuation2>
}

struct TonSplitterFullStateContinuation2 {
    total: int257
    requiredTotal: int257
    minAmount: int257
    tactContinuation: Cell<TonSplitterFullStateContinuation3>
}

struct TonSplitterFullStateContinuation3 {
    maxAmount: int257
    isReady: bool
    accumulatedFees: int257
    logGas: int257
}

struct TonSplitterData {
    tactDeploymentCompleted: bool
    amount1: coins
    amount2: coins
    wallet1: address
    wallet2: address
    tactContinuation: Cell<TonSplitterDataContinuation>
}

struct TonSplitterDataContinuation {
    owner: address
    logAddress: address?
    logGas: uint32
    nonce: uint32
    isPaused: bool
    lastUserOperation: uint32
    lastOwnerOperation: uint32
    accumulatedFees: coins
    inProgress: bool
    tactContinuation: Cell<TonSplitterDataContinuation2>
}

struct TonSplitterDataContinuation2 {
    pendingMsg: TonSplitterPendingMessage?
    lastSender: address?
    lastValue: uint64
    lastCallTime: uint32
}

type TonSplitterIncomingMessage =
    | TonSplitterUpdateParams
    | TonSplitterWithdrawFees
    | TonSplitterPause
    | TonSplitterResume
    | TonSplitterUpdateLogging
    | TonSplitterEmergencyWithdraw
    | TonSplitterDeploy

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
    /// Wallet2 cannot be owner
    Wallet2CannotBeOwner = 3006
    /// Amount1 must be positive
    Amount1MustBePositive = 5885
    /// Invalid log gas
    InvalidLogGas = 7797
    /// Amount1 too large
    Amount1TooLarge = 12451
    /// Total amount too large
    TotalAmountTooLarge = 14715
    /// Operation in progress
    OperationInProgress = 17773
    /// Contract is paused
    ContractIsPaused = 19792
    /// Wallet2 cannot be contract
    Wallet2CannotBeContract = 21539
    /// Amount2 must be positive
    Amount2MustBePositive = 22908
    /// No fees to withdraw
    NoFeesToWithdraw = 23041
    /// Amount2 too large
    Amount2TooLarge = 32164
    /// Invalid wallet2
    InvalidWallet2 = 35784
    /// Wallet1 is owner
    Wallet1IsOwner = 36944
    /// Wallets must be different
    WalletsMustBeDifferent = 38234
    /// Invalid refund amount
    InvalidRefundAmount = 45752
    /// Wallet2 is owner
    Wallet2IsOwner = 50771
    /// User time lock active
    UserTimeLockActive = 52322
    /// Wallet1 cannot be contract
    Wallet1CannotBeContract = 53344
    /// Insufficient balance
    InsufficientBalance = 54615
    /// Insufficient contract balance
    InsufficientContractBalance = 55591
    /// Wallet1 cannot be owner
    Wallet1CannotBeOwner = 57389
    /// Owner time lock active
    OwnerTimeLockActive = 58625
    /// Invalid wallet1
    InvalidWallet1 = 59536
}

get fun fullState(): TonSplitterFullState {
    throw 0;
}

get fun version(): int257 {
    throw 0;
}

get fun schemaVersion(): int257 {
    throw 0;
}

get fun isPaused(): bool {
    throw 0;
}

get fun nonce(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
