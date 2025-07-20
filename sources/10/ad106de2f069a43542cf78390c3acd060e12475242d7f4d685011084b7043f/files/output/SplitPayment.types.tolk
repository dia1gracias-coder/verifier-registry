// Generated from the verified Tact contract ABI.
contract SplitPayment {
    storage: SplitPaymentData
    incomingMessages: SplitPaymentIncomingMessage
    thrownErrors: SplitPaymentErrors
}

struct (0x00000004) SplitPaymentDirectPayment {
    to: address
    amount: int257
    groupId: string
}

struct (0x00000005) SplitPaymentBatchSettlement {
    recipients: map<address, int257>
    groupId: string
}

struct (0x00000001) SplitPaymentDeploy {
    queryId: int257
}

struct (0x00000006) SplitPaymentPauseContract {
}

struct (0x00000007) SplitPaymentResumeContract {
}

struct (0x00000008) SplitPaymentWithdrawFees {
    amount: int257
}

struct (0x00000009) SplitPaymentEmergencyWithdraw {
}

struct SplitPaymentContractInfo {
    owner: address
    totalVolume: int257
    totalFees: int257
    isActive: bool
}

struct SplitPaymentData {
    tactDeploymentCompleted: bool
    owner: address
    totalVolume: int257
    totalFees: int257
    isActive: bool
}

type SplitPaymentIncomingMessage =
    | SplitPaymentDeploy
    | SplitPaymentDirectPayment
    | SplitPaymentBatchSettlement
    | SplitPaymentPauseContract
    | SplitPaymentResumeContract
    | SplitPaymentWithdrawFees
    | SplitPaymentEmergencyWithdraw

enum SplitPaymentErrors {
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
    /// Insufficient fees available
    InsufficientFeesAvailable = 11459
    /// Contract is paused
    ContractIsPaused = 19792
    /// Contract must be paused first
    ContractMustBePausedFirst = 30231
    /// Only backend can trigger settlement
    OnlyBackendCanTriggerSettlement = 31982
    /// Only owner
    OnlyOwner = 35499
    /// Amount too large
    AmountTooLarge = 35507
    /// Insufficient funds sent
    InsufficientFundsSent = 58383
    /// Amount must be positive
    AmountMustBePositive = 61135
}

get fun getTotalVolume(): int257 {
    throw 0;
}

get fun isContractActive(): bool {
    throw 0;
}

get fun getOwner(): address {
    throw 0;
}

get fun getTotalFees(): int257 {
    throw 0;
}

get fun getContractBalance(): int257 {
    throw 0;
}

get fun getContractInfo(): SplitPaymentContractInfo {
    throw 0;
}

get fun validatePayment(amount: int257): bool {
    throw 0;
}
