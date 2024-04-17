// Generated from the verified Tact contract ABI.
contract TrueAED {
    storage: TrueAEDData
    incomingMessages: TrueAEDIncomingMessage
    thrownErrors: TrueAEDErrors
}

struct (0x946a98b6) TrueAEDDeploy {
    queryId: uint64
}

struct TrueAEDJettonData {
    total_supply: int257
    mintable: bool
    admin_address: address
    jetton_content: cell
    jetton_wallet_code: cell
}

struct (0xfc708bd2) TrueAEDMint {
    amount: int257
    receiver: address
}

struct (0xaf1ca26a) TrueAEDTokenUpdateContent {
    content: cell
}

struct (0x819dbe99) TrueAEDChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x7bdd97de) TrueAEDTokenBurnNotification {
    query_id: uint64
    amount: coins
    owner: address
    response_destination: address?
}

struct TrueAEDData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    total_supply: coins
    content: cell
    mintable: bool
    owner: address
    stopped: bool
    id: uint8
}

type TrueAEDIncomingMessage =
    | TrueAEDMint
    | TrueAEDTokenUpdateContent
    | TrueAEDTokenBurnNotification
    | TrueAEDChangeOwner
    | TrueAEDDeploy

enum TrueAEDErrors {
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
    /// Not Owner
    NotOwner = 3734
    /// Invalid value!!
    InvalidValue = 4159
    /// Invalid sender
    InvalidSender = 4429
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Contract stopped
    ContractStopped2 = 40368
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// Contract not stopped
    ContractNotStopped = 53296
    /// Invalid balance
    InvalidBalance = 62972
}

get fun get_jetton_data(): TrueAEDJettonData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}
