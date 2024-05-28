// Generated from the verified Tact contract ABI.
contract AirDrop {
    storage: AirDropData
    incomingMessages: AirDropIncomingMessage
    thrownErrors: AirDropErrors
}

struct (0x946a98b6) AirDropDeploy {
    queryId: uint64
}

struct (0x819dbe99) AirDropChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x353966c7) AirDropChangeJettonWallet {
    address: address
}

struct (0xd56be0b8) AirDropGetAnonToken {
    secret_bool: bool
}

struct (0xc242d9fc) AirDropChangeTotalValue {
    totalValue: coins
}

struct (0x441d86ed) AirDropChangeJettonAmount {
    jettonsToDrop: coins
}

struct (0xffdf9b46) AirDropChangeMinTonsToDrop {
    minTonsToDrop: coins
}

struct (0x86cc9cce) AirDropClearMap {
}

struct (0xd53276db) AirDropTokenExcesses {
    queryId: uint64
}

struct AirDropData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    id: uint32
    totalValue: coins
    currentValue: coins
    jettonsToDrop: coins
    minTonsToDrop: coins
    jettonWallet: address?
    usedWallets: map<address, bool>
    walletsCount: uint16
    stopped: bool
    tactContinuation: Cell<AirDropDataContinuation>
}

struct AirDropDataContinuation {
    owner: address
}

type AirDropIncomingMessage =
    | AirDropTokenExcesses
    | AirDropGetAnonToken
    | AirDropChangeJettonWallet
    | AirDropChangeTotalValue
    | AirDropChangeJettonAmount
    | AirDropChangeMinTonsToDrop
    | AirDropClearMap
    | AirDropDeploy
    | AirDropChangeOwner

enum AirDropErrors {
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
    /// Secret is not correct
    SecretIsNotCorrect = 13629
    /// Amount is too small
    AmountIsTooSmall = 15518
    /// This walled is used
    ThisWalledIsUsed = 16813
    /// No jettons
    NoJettons = 31055
    /// Contract stopped
    ContractStopped2 = 40368
    /// Not enough jettons
    NotEnoughJettons = 47147
    /// Contract not stopped
    ContractNotStopped = 53296
}

get fun id(): int257 {
    throw 0;
}

get fun GetTotalValue(): int257 {
    throw 0;
}

get fun GetCurrentValue(): int257 {
    throw 0;
}

get fun GetWalletsStat(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}
