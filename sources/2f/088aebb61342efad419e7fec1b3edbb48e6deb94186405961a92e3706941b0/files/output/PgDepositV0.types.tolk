// Generated from the verified Tact contract ABI.
contract PgDepositV0 {
    storage: PgDepositV0Data
    incomingMessages: PgDepositV0IncomingMessage
    thrownErrors: PgDepositV0Errors
}

struct (0x633ac051) PgDepositV0RegisterInternal {
    queryId: uint64
    beneficiaries: map<uint8, address>
    referral: address
    fees: uint16
    shareRevenue: uint16
    newCode: cell?
}

struct (0x251e8f92) PgDepositV0UpgradeCode {
    code: cell
    version: uint32
    origin: address?
}

struct PgDepositV0Data {
    tactDeploymentCompleted: bool
    owner: address
    version: uint32
    merchant: address
    fees: uint16
    shareRevenue: uint16
    referral: address
    beneficiaries: map<uint8, address>
    extra: map<uint32, cell>
}

type PgDepositV0IncomingMessage =
    | PgDepositV0RegisterInternal
    | PgDepositV0UpgradeCode

enum PgDepositV0Errors {
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
    /// jetton not exists
    JettonNotExists = 1648
    /// id too low
    IdTooLow = 2765
    /// invalid notification
    InvalidNotification = 3242
    /// invalid wdExecutor
    InvalidWdExecutor = 10473
    /// insufficient amount
    InsufficientAmount = 12119
    /// Invalid signature!
    InvalidSignature = 12943
    /// id exists
    IdExists = 16320
    /// Index of the item cannot be negative!
    IndexOfTheItemCannotBeNegative = 19333
    /// No items in the circular buffer!
    NoItemsInTheCircularBuffer = 22661
    /// Minter not found
    MinterNotFound = 25937
    /// Insufficient ton for gas
    InsufficientTonForGas = 27660
    /// Beneficiary not found
    BeneficiaryNotFound = 36861
    /// Reach max beneficiaries
    ReachMaxBeneficiaries = 47024
    /// wdxecutor not exists
    WdxecutorNotExists = 53828
    /// jetton exists
    JettonExists = 60339
}

get fun owner(): address {
    throw 0;
}

get fun isUpgradable(): bool {
    throw 0;
}

get fun version(): int257 {
    throw 0;
}
