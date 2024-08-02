// Generated from the verified Tact contract ABI.
contract Channel {
    storage: ChannelData
    incomingMessages: ChannelIncomingMessage
    thrownErrors: ChannelErrors
}

struct (0x946a98b6) ChannelDeploy {
    queryId: uint64
}

struct (0x819dbe99) ChannelChangeOwner {
    queryId: uint64
    newOwner: address
}

struct ChannelSoraEncodedCall {
    data: cell
}

struct (0x432df181) ChannelSendOutboundMessage {
    message: ChannelSoraEncodedCall
    sender: address
}

struct (0x44b1824c) ChannelSendInboundMessage {
    target: address
    message: cell
}

struct (0x267f9407) ChannelRegisterApp {
    app: address
}

struct (0x554f8589) ChannelReset {
}

struct ChannelData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    outboundNonce: uint64
    apps: map<address, bool>
}

type ChannelIncomingMessage =
    | ChannelSendOutboundMessage
    | ChannelRegisterApp
    | ChannelReset
    | ChannelSendInboundMessage
    | ChannelDeploy
    | ChannelChangeOwner

enum ChannelErrors {
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
    /// Only owner can initialize this contract
    OnlyOwnerCanInitializeThisContract = 11969
    /// Wrong call encoding
    WrongCallEncoding = 22178
    /// App is stopped
    AppIsStopped = 32543
    /// Only apps can send messages
    OnlyAppsCanSendMessages = 34095
    /// Amount should be greater than value
    AmountShouldBeGreaterThanValue = 53478
    /// Can only send messages to apps
    CanOnlySendMessagesToApps = 56305
}

get fun isApp(app: address): bool {
    throw 0;
}

get fun apps(): map<address, bool> {
    throw 0;
}

get fun outboundNonce(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
