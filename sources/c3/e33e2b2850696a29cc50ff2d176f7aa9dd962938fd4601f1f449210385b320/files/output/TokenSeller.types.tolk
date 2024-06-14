// Generated from the verified Tact contract ABI.
contract TokenSeller {
    storage: TokenSellerData
    incomingMessages: TokenSellerIncomingMessage
    thrownErrors: TokenSellerErrors
}

struct (0x250775b6) TokenSellerWithdraw {
    amount: coins
    tokenWallet: address?
}

struct (0x819dbe99) TokenSellerChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x7362d09c) TokenSellerTokenNotification {
    queryId: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct (0x2d9b9823) TokenSellerDeploy {
    tokenWallet: address
    usdtWallet: address
    usdtToTokenFactor: TokenSellerFactor
    tonToTokenFactor: TokenSellerFactor
}

struct (0xde4c67b5) TokenSellerBuy {
    queryId: uint64
}

struct (0x8f8aa3bd) TokenSellerUpdateConfig {
    usdtToTokenFactor: TokenSellerFactor
    tonToTokenFactor: TokenSellerFactor
    usdtWallet: address?
}

struct TokenSellerFactor {
    numerator: uint32
    denominator: uint32
}

struct TokenSellerBuyRequest {
    buyer: address
    amount: coins
}

struct TokenSellerData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    vesting: address
    index: uint8
    tokenAmountOnSale: coins
    tokenWallet: address?
    tactContinuation: Cell<TokenSellerDataContinuation>
}

struct TokenSellerDataContinuation {
    usdtWallet: address?
    usdtToTokenFactor: TokenSellerFactor?
    tonToTokenFactor: TokenSellerFactor?
    buyRequests: map<int257, Cell<TokenSellerBuyRequest>>
}

type TokenSellerIncomingMessage =
    | TokenSellerDeploy
    | TokenSellerUpdateConfig
    | TokenSellerBuy
    | TokenSellerWithdraw
    | TokenSellerChangeOwner
    | TokenSellerTokenNotification

enum TokenSellerErrors {
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
    /// No tokens on sale!
    NoTokensOnSale = 18185
    /// Already deployed
    AlreadyDeployed = 24123
    /// Should be overriden
    ShouldBeOverriden = 33636
    /// Request is already registered
    RequestIsAlreadyRegistered = 37824
    /// Not enough tokens to withdraw
    NotEnoughTokensToWithdraw = 42479
    /// Not enough for processing
    NotEnoughForProcessing = 53433
}

get fun vesting(): address {
    throw 0;
}

get fun usdtWallet(): address? {
    throw 0;
}

get fun tokenWallet(): address? {
    throw 0;
}

get fun usdtToTokenFactor(): TokenSellerFactor? {
    throw 0;
}

get fun tonToTokenFactor(): TokenSellerFactor? {
    throw 0;
}

get fun tokenAmountOnSale(): int257 {
    throw 0;
}

get fun buyRequests(): map<int257, Cell<TokenSellerBuyRequest>> {
    throw 0;
}

get fun index(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
