// Generated from the verified Tact contract ABI.
contract MeetTon {
    storage: MeetTonData
    incomingMessages: MeetTonIncomingMessage
    thrownErrors: MeetTonErrors
}

struct (0x946a98b6) MeetTonDeploy {
    queryId: uint64
}

struct (0x819dbe99) MeetTonChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x0ba69751) MeetTonWithdraw {
    amount: coins
}

struct (0x2324ff54) MeetTonIncome {
    goal: string
    id: uint32
    for_: uint32?
}

struct MeetTonPayment {
    sender: address
    goal: string
    value: coins
    date: uint32
    id: uint32
    for_: uint32?
}

struct (0x6a472534) MeetTonClear {
    itemNumb: int257
}

struct MeetTonData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    stopped: bool
    payments: map<int257, Cell<MeetTonPayment>>
    arrLength: int257
}

type MeetTonIncomingMessage =
    | MeetTonIncome
    | MeetTonWithdraw
    | MeetTonClear
    | MeetTonDeploy
    | MeetTonChangeOwner

enum MeetTonErrors {
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
    /// You have more unresolved transactions
    YouHaveMoreUnresolvedTransactions = 27997
    /// Contract stopped
    ContractStopped2 = 40368
    /// Contract not stopped
    ContractNotStopped = 53296
    /// Insufficient balance
    InsufficientBalance = 54615
}

get fun balance(): int257 {
    throw 0;
}

get fun myAddress(): address {
    throw 0;
}

get fun payment(key: int257): MeetTonPayment? {
    throw 0;
}

get fun payments(): map<int257, Cell<MeetTonPayment>> {
    throw 0;
}

get fun length(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}
