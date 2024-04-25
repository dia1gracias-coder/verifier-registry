// Generated from the verified Tact contract ABI.
contract Payment {
    storage: PaymentData
    incomingMessages: PaymentIncomingMessage
    thrownErrors: PaymentErrors
}

struct (0x946a98b6) PaymentDeploy {
    queryId: uint64
}

struct (0x819dbe99) PaymentChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x0ba69751) PaymentWithdraw {
    amount: coins
}

struct (0xd7435ab8) PaymentOrder {
    id: uint256
}

struct PaymentData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    orders: map<int257, int257>
    owner: address
}

type PaymentIncomingMessage =
    | PaymentOrder
    | PaymentWithdraw
    | PaymentDeploy
    | PaymentChangeOwner

enum PaymentErrors {
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
    /// Only owner is allowed to withdraw
    OnlyOwnerIsAllowedToWithdraw = 27921
    /// order exists
    OrderExists = 34906
    /// Insufficient balance
    InsufficientBalance = 54615
}

get fun balance(): string {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
