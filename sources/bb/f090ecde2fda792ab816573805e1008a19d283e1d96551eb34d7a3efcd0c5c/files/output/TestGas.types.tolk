// Generated from the verified Tact contract ABI.
contract TestGas {
    storage: TestGasData
    incomingMessages: TestGasIncomingMessage
    thrownErrors: TestGasErrors
}

struct (0x946a98b6) TestGasDeploy {
    queryId: uint64
}

struct TestGasGasDeductionResult {
    initialAmount: int257
    gasAmount: int257
    remainingAmount: int257
    isEnough: bool
}

struct TestGasStorageStats {
    lastUpdateTime: int257
    transactionCount: int257
    totalTimeInterval: int257
    tactContinuation: Cell<TestGasStorageStatsContinuation>
}

struct TestGasStorageStatsContinuation {
    totalStorageDueCollected: int257
    reservedStorage: int257
    storageLimit: int257
    tactContinuation: Cell<TestGasStorageStatsContinuation2>
}

struct TestGasStorageStatsContinuation2 {
    lastTonsReserve: int257
    storageTonsDeficit: int257
}

struct (0x1cfe8831) TestGasAdd {
    queryId: uint64
}

struct TestGasData {
    tactDeploymentCompleted: bool
    id: uint32
    old_increment: uint32
    increment: uint32
    gasStats: TestGasStorageStats
    tactContinuation: Cell<TestGasDataContinuation>
}

struct TestGasDataContinuation {
    gasResults: TestGasGasDeductionResult
}

type TestGasIncomingMessage =
    | TestGasAdd
    | TestGasDeploy

enum TestGasErrors {
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

get fun counter(): int257 {
    throw 0;
}

get fun id(): int257 {
    throw 0;
}

get fun gasStats(): TestGasStorageStats {
    throw 0;
}
