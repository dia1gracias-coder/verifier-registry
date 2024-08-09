// Generated from the verified Tact contract ABI.
contract Balus {
    storage: BalusData
    incomingMessages: BalusIncomingMessage
    thrownErrors: BalusErrors
}

struct (0x946a98b6) BalusDeploy {
    queryId: uint64
}

struct BalusContent {
    id: int257
    owner: address
    text: string
    initialPrice: int257
    tactContinuation: Cell<BalusContentContinuation>
}

struct BalusContentContinuation {
    increasement: int257
    commision: int257
    pool: int257
    tactContinuation: Cell<BalusContentContinuation2>
}

struct BalusContentContinuation2 {
    supply: int257
    holders: map<address, int257>
}

struct (0xd66be657) BalusSetServiceFee {
    createServiceFee: int257
    tradeCommision: int257
}

struct (0xd5dae1a1) BalusCreate {
    text: string
    initialPrice: int257
    increasement: int257
    commision: int257
}

struct (0xefe2cdfb) BalusBuy {
    contentId: int257
    amount: int257
}

struct (0xa0ef28e3) BalusSell {
    contentId: int257
    amount: int257
}

struct (0xc95ee4b0) BalusWithdraw {
    reserve: int257
    to: address
}

struct BalusData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    deployer: address
    nextId: int257
    createServiceFee: int257
    tactContinuation: Cell<BalusDataContinuation>
}

struct BalusDataContinuation {
    tradeCommision: int257
    tvl: int257
    contentMap: map<int257, Cell<BalusContent>>
}

type BalusIncomingMessage =
    | BalusSetServiceFee
    | BalusWithdraw
    | BalusCreate
    | BalusBuy
    | BalusSell
    | BalusDeploy

enum BalusErrors {
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
    /// Sell amount must greater than 0
    SellAmountMustGreaterThan0 = 8011
    /// Insufficient payment amount
    InsufficientPaymentAmount = 10831
    /// Traded content does not exist
    TradedContentDoesNotExist = 22635
    /// No permission
    NoPermission = 29170
    /// Insufficient creation fee
    InsufficientCreationFee = 32904
    /// Amount should greater than 0
    AmountShouldGreaterThan0 = 40260
    /// Insufficient withdrawable balance in the pool
    InsufficientWithdrawableBalanceInThePool = 57216
    /// Insufficient shares held
    InsufficientSharesHeld = 59010
}

get fun allContent(): map<int257, Cell<BalusContent>> {
    throw 0;
}

get fun content(id: int257): BalusContent? {
    throw 0;
}

get fun createServiceFee(): int257 {
    throw 0;
}

get fun tradeCommision(): int257 {
    throw 0;
}

get fun tvl(): int257 {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}
