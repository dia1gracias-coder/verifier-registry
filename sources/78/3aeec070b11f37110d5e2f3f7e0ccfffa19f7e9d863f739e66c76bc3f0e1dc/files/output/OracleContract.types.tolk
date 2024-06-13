// Generated from the verified Tact contract ABI.
contract OracleContract {
    storage: OracleContractData
    incomingMessages: OracleContractIncomingMessage
    thrownErrors: OracleContractErrors
}

struct (0x946a98b6) OracleContractDeploy {
    queryId: uint64
}

struct OracleContractPriceUpdate {
    lastUpdatedAt: uint64
    ticker: uint64
    usd: uint64
    usd24vol: uint64
    usd24change: int64
    btc: uint64
}

struct (0xc99be573) OracleContractOraclePriceRequest {
    queryID: uint64
    ticker: uint64
    minUpdatedAt: uint64
}

struct (0x1af44a9f) OracleContractMoveTo {
    newAddress: address
    moveCompleted: bool
}

struct OracleContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    demoAddress: address
    newAddress: address
    stopped: bool
    moved: bool
    prices: map<int257, Cell<OracleContractPriceUpdate>>
    tactContinuation: Cell<OracleContractDataContinuation>
}

struct OracleContractDataContinuation {
    enclavePublicKey: uint256
    enclaveMeasurment: uint256
    enclaveAttestation: string
}

type OracleContractIncomingMessage =
    | OracleContractOraclePriceRequest
    | OracleContractDeploy
    | OracleContractMoveTo

enum OracleContractErrors {
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
    /// Price update is outdated
    PriceUpdateIsOutdated = 2138
    /// Price update is from the future
    PriceUpdateIsFromTheFuture = 9925
    /// Moved to new address
    MovedToNewAddress = 39366
    /// Unknown ticker
    UnknownTicker = 39697
    /// Unknown caller
    UnknownCaller = 40104
    /// Contract stopped
    ContractStopped2 = 40368
    /// Unknown oracle
    UnknownOracle = 45226
    /// Invalid signature
    InvalidSignature = 48401
    /// Contract not stopped
    ContractNotStopped = 53296
    /// Unknown Demo
    UnknownDemo = 54462
}

get fun prices(): map<int257, Cell<OracleContractPriceUpdate>> {
    throw 0;
}

get fun price(ticker: int257): OracleContractPriceUpdate? {
    throw 0;
}

get fun demoAddress(): address {
    throw 0;
}

get fun enclavePublicKey(): int257 {
    throw 0;
}

get fun enclaveMeasurment(): int257 {
    throw 0;
}

get fun enclaveAttestation(): string {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun newAddress(): address {
    throw 0;
}
