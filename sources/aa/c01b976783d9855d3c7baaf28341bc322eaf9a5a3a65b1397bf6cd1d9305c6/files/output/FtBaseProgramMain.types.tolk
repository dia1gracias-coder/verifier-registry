// Generated from the verified Tact contract ABI.
contract FtBaseProgramMain {
    storage: FtBaseProgramMainData
    incomingMessages: FtBaseProgramMainIncomingMessage
    thrownErrors: FtBaseProgramMainErrors
}

struct (0x946a98b6) FtBaseProgramMainDeploy {
    queryId: uint64
}

struct (0xbc355a3a) FtBaseProgramMainSetupBaseProgramMain {
    owner: address
}

struct (0xd587100b) FtBaseProgramMainBuyLevel {
    owner: address
    userId: uint64
    invitedId: uint64
    levelNumber: uint8
    recipientExcesses: address
}

struct (0x740aa7de) FtBaseProgramMainUpdateLevelPrice {
    levelNumber: uint8
    levelPrice: coins
}

struct (0x289034e4) FtBaseProgramMainUpdateLevelFee {
    levelNumber: uint8
    levelFee: coins
}

struct (0x644f0517) FtBaseProgramMainUpdateGasMultiplier {
    newValue: coins
}

struct (0x4ce19704) FtBaseProgramMainUpdateRecipientAddress {
    newAddress: address
}

struct FtBaseProgramMainData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    gasMultiplier: coins
    isSetup: bool
    owner: address
    master: address
    recipient: address
    levelPrices: map<uint8, int257>
    tactContinuation: Cell<FtBaseProgramMainDataContinuation>
}

struct FtBaseProgramMainDataContinuation {
    levelFees: map<uint8, int257>
    totalProfit: coins
}

type FtBaseProgramMainIncomingMessage =
    | FtBaseProgramMainSetupBaseProgramMain
    | FtBaseProgramMainBuyLevel
    | FtBaseProgramMainUpdateLevelPrice
    | FtBaseProgramMainUpdateLevelFee
    | FtBaseProgramMainUpdateGasMultiplier
    | FtBaseProgramMainUpdateRecipientAddress
    | FtBaseProgramMainDeploy

enum FtBaseProgramMainErrors {
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

get fun programName(): string {
    throw 0;
}

get fun gasMultiplier(): int257 {
    throw 0;
}

get fun levelPrices(): map<uint8, int257> {
    throw 0;
}

get fun levelFees(): map<uint8, int257> {
    throw 0;
}

get fun totalProfit(): int257 {
    throw 0;
}

get fun masterAddress(): address {
    throw 0;
}

get fun recipientAddress(): address {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}

get fun userMainAddress(id: int257): address {
    throw 0;
}

get fun programUserAddress(id: int257): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
