// Generated from the verified Tact contract ABI.
contract MadWorld {
    storage: MadWorldData
    incomingMessages: MadWorldIncomingMessage
    thrownErrors: MadWorldErrors
}

struct (0x91be1110) MadWorldBuyToken {
    country: int257
}

struct (0x1d50b5aa) MadWorldDeployCountryToken {
    id: int257
    country: string
    content: cell
}

struct MadWorldCountry {
    country: string
    address: address
    buyable: bool
    sellable: bool
}

struct MadWorldData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    buy_rate: int257
    sell_rate: int257
    tactContinuation: Cell<MadWorldDataContinuation>
}

struct MadWorldDataContinuation {
    min_fee: int257
    county_tokens: map<int257, Cell<MadWorldCountry>>
}

type MadWorldIncomingMessage =
    | MadWorldDeployCountryToken
    | MadWorldBuyToken

enum MadWorldErrors {
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
    /// Not mintable
    NotMintable = 3688
    /// Invalid sender
    InvalidSender = 4429
    /// Country token already exists
    CountryTokenAlreadyExists = 9843
    /// Not owner
    NotOwner = 14534
    /// Invalid value
    InvalidValue = 16059
    /// Country token not buyable
    CountryTokenNotBuyable = 18625
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Insufficient gas
    InsufficientGas = 23951
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// Insufficient funds
    InsufficientFunds = 51754
    /// Country token not found
    CountryTokenNotFound = 62849
    /// Invalid balance
    InvalidBalance = 62972
}

get fun get_country_address(id: int257): address {
    throw 0;
}
