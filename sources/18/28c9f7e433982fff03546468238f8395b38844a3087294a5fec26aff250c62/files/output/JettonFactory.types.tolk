// Generated from the verified Tact contract ABI.
contract JettonFactory {
    storage: JettonFactoryData
    incomingMessages: JettonFactoryIncomingMessage
    thrownErrors: JettonFactoryErrors
}

struct (0x946a98b6) JettonFactoryDeploy {
    queryId: uint64
}

struct (0xf135c98b) JettonFactoryTokenDeploy {
    name: string
    description: string
    symbol: string
    tactContinuation: Cell<JettonFactoryTokenDeployContinuation>
}

struct JettonFactoryTokenDeployContinuation {
    image: string
}

struct (0x7362d09c) JettonFactoryTransferNotification {
    jetton_amount: coins
    from_user: address
    ref_msg_data: cell
}

struct JettonFactoryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    counter: uint16
    jettonList: map<int257, address>
}

type JettonFactoryIncomingMessage =
    | JettonFactoryTransferNotification
    | JettonFactoryTokenDeploy
    | JettonFactoryDeploy

enum JettonFactoryErrors {
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
    /// Not mintable
    NotMintable = 3688
    /// Invalid sender
    InvalidSender = 4429
    /// Max supply exceeded
    MaxSupplyExceeded = 12241
    /// Not owner
    NotOwner = 14534
    /// Invalid value
    InvalidValue = 16059
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Insufficient gas
    InsufficientGas = 23951
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// must idx < counter
    MustIdxCounter = 43650
    /// must idx > 0
    MustIdx0 = 58095
    /// Invalid balance
    InvalidBalance = 62972
}

get fun getLastCounter(): int257 {
    throw 0;
}

get fun getJettonAddress(idx: int257): address {
    throw 0;
}
