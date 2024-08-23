// Generated from the verified Tact contract ABI.
contract Factory {
    storage: FactoryData
    incomingMessages: FactoryIncomingMessage
    thrownErrors: FactoryErrors
}

struct FactoryStateInit {
    code: cell
    data: cell
}

struct (0x946a98b6) FactoryDeploy {
    queryId: uint64
}

struct (0xacd2a5b1) FactoryBuyCall {
    tonAmount: int257
    minOut: int257
    referrer: address
    tactContinuation: Cell<FactoryBuyCallContinuation>
}

struct FactoryBuyCallContinuation {
    jetton: address
}

struct (0xe5363368) FactorySellCall {
    referrer: address
    jetton: address
    jettonAmount: int257
    tactContinuation: Cell<FactorySellCallContinuation>
}

struct FactorySellCallContinuation {
    minTonOut: int257
}

struct (0x00531283) FactoryDeployCurveParams {
    content: cell
}

struct FactoryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    deployer: address
    treasury: address
    referrals: map<address, address>
    referralsCount: int257
}

type FactoryIncomingMessage =
    | FactoryDeployCurveParams
    | FactoryBuyCall
    | FactorySellCall
    | FactoryDeploy

enum FactoryErrors {
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
    /// cannot self refer
    CannotSelfRefer = 1039
    /// not factory
    NotFactory = 2944
    /// Invalid sender
    InvalidSender = 4429
    /// invalid value for claim
    InvalidValueForClaim = 5306
    /// complete
    Complete = 8685
    /// Invalid value
    InvalidValue = 16059
    /// insufficient jetton balance
    InsufficientJettonBalance = 16266
    /// !complete
    Complete2 = 17598
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Insufficient gas
    InsufficientGas = 23951
    /// ValueMustBeGreaterThanZero
    ValueMustBeGreaterThanZero = 33172
    /// no token to claim
    NoTokenToClaim = 34036
    /// ExceedsSlipage
    ExceedsSlipage = 34744
    /// !liquidityAdded
    LiquidityAdded = 35772
    /// only factory can create
    OnlyFactoryCanCreate = 41223
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// value too low
    ValueTooLow = 58268
    /// Invalid balance
    InvalidBalance = 62972
}

get fun balance(): int257 {
    throw 0;
}

get fun getBondingCurveInit(creator: address, content: cell): FactoryStateInit {
    throw 0;
}

get fun getReferrer(user: address, referrer: address): address {
    throw 0;
}
