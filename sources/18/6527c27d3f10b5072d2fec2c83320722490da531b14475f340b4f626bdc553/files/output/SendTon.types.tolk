// Generated from the verified Tact contract ABI.
contract SendTon {
    storage: SendTonData
    incomingMessages: SendTonIncomingMessage
    thrownErrors: SendTonErrors
}

struct (0x946a98b6) SendTonDeploy {
    queryId: uint64
}

struct (0x7ff037ce) SendTonWithdraw {
    user: address
    amount: coins
}

struct (0x575a726f) SendTonInvest {
    user: address
    referrer: address
}

struct (0x6d7ea550) SendTonLevelSetting {
    level: int257
    amount: coins
}

struct SendTonUser {
    id: int257
    referrer: address
    level: int257
}

struct SendTonData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    map_level: map<int257, coins>
    owner: address
    lastUserId: int257
    tactContinuation: Cell<SendTonDataContinuation>
}

struct SendTonDataContinuation {
    users: map<address, Cell<SendTonUser>>
    nodes: map<int257, address>
}

type SendTonIncomingMessage =
    | SendTonLevelSetting
    | SendTonInvest
    | SendTonWithdraw
    | SendTonDeploy

enum SendTonErrors {
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
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
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
    /// Invalid address
    InvalidAddress = 136
    /// Masterchain support is not enabled for this contract
    MasterchainSupportIsNotEnabledForThisContract = 137
    /// invalid owner
    InvalidOwner = 4109
    /// User exists
    UserExists = 32313
    /// invalid balance
    InvalidBalance = 43887
    /// invalid amount
    InvalidAmount = 54178
    /// invalid user
    InvalidUser = 58413
}

get fun balance(): int257 {
    throw 0;
}

get fun isUserExists(key: address): bool {
    throw 0;
}

get fun User(key: address): SendTonUser {
    throw 0;
}

get fun levelAmount(key: int257): int257 {
    throw 0;
}

get fun lastId(): int257 {
    throw 0;
}

get fun nodes(inx: int257): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
