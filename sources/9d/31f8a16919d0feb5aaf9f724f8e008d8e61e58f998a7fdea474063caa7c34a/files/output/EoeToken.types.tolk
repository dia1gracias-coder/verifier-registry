// Generated from the verified Tact contract ABI.
contract EoeToken {
    storage: EoeTokenData
    incomingMessages: EoeTokenIncomingMessage
    thrownErrors: EoeTokenErrors
}

struct (0x946a98b6) EoeTokenDeploy {
    queryId: uint64
}

struct (0x819dbe99) EoeTokenChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x7bdd97de) EoeTokenTokenBurnNotification {
    queryId: uint64
    amount: coins
    owner: address
    response_destination: address?
}

struct (0xaf1ca26a) EoeTokenTokenUpdateContent {
    content: cell
}

struct EoeTokenJettonData {
    totalSupply: int257
    mintable: bool
    owner: address
    content: cell
    walletCode: cell
}

struct (0xfc708bd2) EoeTokenMint {
    amount: int257
    receiver: address
}

struct EoeTokenData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    totalSupply: coins
    owner: address
    content: cell
    mintable: bool
    max_supply: coins
}

type EoeTokenIncomingMessage =
    | EoeTokenMint
    | EoeTokenTokenUpdateContent
    | EoeTokenTokenBurnNotification
    | EoeTokenChangeOwner
    | EoeTokenDeploy

enum EoeTokenErrors {
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
    /// Invalid value!!
    InvalidValue = 4159
    /// Invalid sender
    InvalidSender = 4429
    /// The total supply will be overlapping.
    TheTotalSupplyWillBeOverlapping = 6898
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// Invalid balance
    InvalidBalance = 62972
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun get_jetton_data(): EoeTokenJettonData {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
