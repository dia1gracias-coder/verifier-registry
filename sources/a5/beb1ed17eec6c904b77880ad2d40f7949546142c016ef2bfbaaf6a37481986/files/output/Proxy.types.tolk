// Generated from the verified Tact contract ABI.
contract Proxy {
    storage: ProxyData
    incomingMessages: ProxyIncomingMessage
    thrownErrors: ProxyErrors
}

struct (0x946a98b6) ProxyDeploy {
    queryId: uint64
}

struct (0x8da0f2c7) ProxyMessage {
    str: string
    to: address
}

struct (0xff5f0a11) ProxyChangeExampleOwner {
    address: address
}

struct ProxyLastMessage {
    last_message: string?
    last_sender: address?
    last_receiver: address?
}

struct ProxyData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    count: int257
    last_message: string?
    last_sender: address?
    tactContinuation: Cell<ProxyDataContinuation>
}

struct ProxyDataContinuation {
    last_receiver: address?
}

type ProxyIncomingMessage =
    | ProxyMessage
    | ProxyChangeExampleOwner
    | ProxyDeploy

enum ProxyErrors {
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
    /// Invalid sender
    InvalidSender = 4429
}

get fun owner(): address {
    throw 0;
}

get fun get_count(): int257 {
    throw 0;
}

get fun get_last(): ProxyLastMessage {
    throw 0;
}
