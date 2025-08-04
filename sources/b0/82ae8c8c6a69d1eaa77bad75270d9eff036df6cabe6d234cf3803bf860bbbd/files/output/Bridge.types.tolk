// Generated from the verified Tact contract ABI.
contract Bridge {
    storage: BridgeData
    incomingMessages: BridgeIncomingMessage
    thrownErrors: BridgeErrors
}

struct (0x946a98b6) BridgeDeploy {
    queryId: uint64
}

struct (0x6637b249) BridgeDeposit {
    sender: address
    recipient: string
    amount: coins
    data: string
}

struct (0x7fcfec39) BridgeRevert {
    amount: coins
    to: address
}

struct (0x4d0831cc) BridgeWithdraw {
    amount: coins
    to: address
}

struct (0xff945571) BridgeWithdrawFee {
    to: address
}

struct (0x405a6446) BridgeSetFee {
    fee: coins
}

struct (0x4e07f565) BridgeSetFeeMultiplier {
    val_: int257
}

struct BridgeData {
    tactDeploymentCompleted: bool
    owner: address
    lockedAmount: int257
    collectedFees: int257
    tactContinuation: Cell<BridgeDataContinuation>
}

struct BridgeDataContinuation {
    feeAmount: int257
    feeMultiplier: int257
}

type BridgeIncomingMessage =
    | BridgeSetFee
    | BridgeDeposit
    | BridgeWithdraw
    | BridgeRevert
    | BridgeWithdrawFee
    | BridgeSetFeeMultiplier
    | BridgeDeploy

enum BridgeErrors {
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
    /// Withdrawal amount must be greater than zero
    WithdrawalAmountMustBeGreaterThanZero = 12482
    /// Insufficient locked funds
    InsufficientLockedFunds = 18859
    /// Fee cannot be negative
    FeeCannotBeNegative = 20545
    /// No fees to withdraw
    NoFeesToWithdraw = 23041
    /// Insufficient amount for fees
    InsufficientAmountForFees = 23317
    /// Amount must be greater than zero
    AmountMustBeGreaterThanZero = 53350
    /// Net amount must be positive
    NetAmountMustBePositive = 60834
}

get fun getLockedAmount(): int257 {
    throw 0;
}

get fun getCollectedFees(): int257 {
    throw 0;
}

get fun getFeeAmount(): int257 {
    throw 0;
}

get fun getFeeMultiplier(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
