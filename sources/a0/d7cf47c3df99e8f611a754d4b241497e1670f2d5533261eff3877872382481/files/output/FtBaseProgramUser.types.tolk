// Generated from the verified Tact contract ABI.
contract FtBaseProgramUser {
    storage: FtBaseProgramUserData
    incomingMessages: FtBaseProgramUserIncomingMessage
    thrownErrors: FtBaseProgramUserErrors
}

struct (0x946a98b6) FtBaseProgramUserDeploy {
    queryId: uint64
}

struct (0xb5b23017) FtBaseProgramUserActivateLevel {
    owner: address
    invitedId: uint64
    levelNumber: uint8
    levelPrice: coins
    recipientExcesses: address
}

struct (0x974dd3f0) FtBaseProgramUserUpdateMatrix {
    id: uint64
    fromId: uint64
    levelNumber: uint8
    levelPrice: coins
    recipientExcesses: address
}

struct (0x8a0257f4) FtBaseProgramUserOverflowDown {
    id: uint64
    fromId: uint64
    levelNumber: uint8
    levelPrice: coins
    recipientExcesses: address
}

struct (0x390258fe) FtBaseProgramUserOverflowUp {
    id: uint64
    fromId: uint64
    levelNumber: uint8
    levelPrice: coins
    recipientExcesses: address
}

struct (0x399aaa57) FtBaseProgramUserUpdateUpperAddress {
    fromId: uint64
    upperAddress: address
    levelNumber: int257
    recipientExcesses: address
}

struct FtBaseProgramUserMatrix {
    u1: uint64?
    u1t: uint8?
    u2: uint64?
    u2t: uint8?
    u3: uint64?
    u3t: uint8?
    u4: uint64?
    u4t: uint8?
    u5: uint64?
    u5t: uint8?
    u6: uint64?
    u6t: uint8?
}

struct FtBaseProgramUserInfo {
    totalProfit: coins
    lostProfit: coins
    reinvestCount: uint16
    personalReferralsCount: uint32
    wasUseUpperAddress: bool
    upperAddress: address?
    nextUpperAddress: address?
    tactContinuation: Cell<FtBaseProgramUserInfoContinuation>
}

struct FtBaseProgramUserInfoContinuation {
    matrix: FtBaseProgramUserMatrix
}

struct FtBaseProgramUserData {
    tactDeploymentCompleted: bool
    id: uint64
    owner: address?
    program: address
    invitedAddress: address?
    holdBalance: coins
    overtakeInfo: map<uint8, uint16>
    levelInfo: map<uint8, Cell<FtBaseProgramUserInfo>>
    lastLevel: uint8
}

type FtBaseProgramUserIncomingMessage =
    | FtBaseProgramUserActivateLevel
    | FtBaseProgramUserUpdateMatrix
    | FtBaseProgramUserOverflowUp
    | FtBaseProgramUserOverflowDown
    | FtBaseProgramUserUpdateUpperAddress
    | FtBaseProgramUserDeploy

enum FtBaseProgramUserErrors {
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

get fun id(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}

get fun withdrawBalance(): int257 {
    throw 0;
}

get fun holdBalance(): int257 {
    throw 0;
}

get fun invitedAddress(): address {
    throw 0;
}

get fun overtakeInfo(): map<uint8, uint16> {
    throw 0;
}

get fun levelInfo(): map<uint8, Cell<FtBaseProgramUserInfo>> {
    throw 0;
}

get fun lastLevel(): int257 {
    throw 0;
}

get fun programAddress(): address {
    throw 0;
}

get fun programUserAddress(id: int257): address {
    throw 0;
}
