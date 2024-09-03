// Generated from the verified Tact contract ABI.
contract TodoParent {
    storage: TodoParentData2
    incomingMessages: TodoParentIncomingMessage
    thrownErrors: TodoParentErrors
}

struct (0x946a98b6) TodoParentDeploy {
    queryId: uint64
}

struct TodoParentBetDetails {
    user: address
    amount: uint32
    betContract: address
    outcome: uint8
}

struct TodoParentBetArray {
    map: map<int257, Cell<TodoParentBetDetails>>
    length: uint32
}

struct (0xdc557c27) TodoParentBetDetailsMessage {
    user: address
    amount: int257
    betContract: address
    outcome: uint8
}

struct (0xb028071f) TodoParentBetInfoInit {
    title: string
    source: string
    bet_a_name: string
    tactContinuation: Cell<TodoParentBetInfoInitContinuation>
}

struct TodoParentBetInfoInitContinuation {
    bet_b_name: string
    image: string
}

struct TodoParentData2 {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    receiver: address
    numChildren: uint64
    BetList: map<int257, address>
    AllBets: map<address, address>
    tactContinuation: Cell<TodoParentDataContinuation>
}

struct TodoParentDataContinuation {
    UserBets: map<address, Cell<TodoParentBetArray>>
}

type TodoParentIncomingMessage =
    | TodoParentBetInfoInit
    | TodoParentBetDetailsMessage
    | TodoParentDeploy

enum TodoParentErrors {
    /// Stack undeflow
    StackUndeflow = 2
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
    /// Out of gas error
    OutOfGasError = 13
    /// Method ID not found
    MethodIDNotFound = 32
    /// Action is invalid or not supported
    ActionIsInvalidOrNotSupported = 34
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
    NotEnoughExtraCurrencies = 38
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
    /// Already initialized
    AlreadyInitialized = 2977
    /// Bet amount must be greater than the fixed fee
    BetAmountMustBeGreaterThanTheFixedFee = 5194
    /// No space left in the array for new items!
    NoSpaceLeftInTheArrayForNewItems = 12446
    /// Only owner can create bets
    OnlyOwnerCanCreateBets = 15338
    /// Contract stopped
    ContractStopped2 = 40368
    /// Only the admin can finalize
    OnlyTheAdminCanFinalize = 44933
    /// Contract not stopped
    ContractNotStopped = 53296
    /// Betting is over
    BettingIsOver = 63076
}

get fun numChildren(): int257 {
    throw 0;
}

get fun UserBetInfo(user: address): map<int257, Cell<TodoParentBetDetails>> {
    throw 0;
}

get fun getAllAddresses(): map<int257, address> {
    throw 0;
}
