// Generated from the verified Tact contract ABI.
contract CAT {
    storage: CATData
    incomingMessages: CATIncomingMessage
    thrownErrors: CATErrors
}

struct (0x946a98b6) CATDeploy {
    queryId: uint64
}

struct (0x819dbe99) CATChangeOwner {
    queryId: uint64
    newOwner: address
}

struct CATStake {
    stake: int257
    notWithdrawn: int257
    timestamp: int257
    tactContinuation: Cell<CATStakeContinuation>
}

struct CATStakeContinuation {
    partner: address
    percentage: uint8
}

struct (0xc57dc42f) CATDepositF {
    partner: address
    amount: coins
}

struct (0x21eeb607) CATDeposit {
    amount: coins
}

struct (0x05ad9a76) CATReinvest {
    amount: coins
}

struct (0x0ba69751) CATWithdraw {
    amount: coins
}

struct (0x8e4702bf) CATMigrate {
    amount: coins
}

struct (0x69935ce3) CATLeaveCat {
    cat: address
    leave: bool
}

struct (0xdeff31cb) CATUpdatePartner {
    account: address
    newPartner: address
}

struct (0x5e5d0f72) CATUpdateDepositRate {
    a: int257
    b: int257
    c: int257
    tactContinuation: Cell<CATUpdateDepositRateContinuation>
}

struct CATUpdateDepositRateContinuation {
    d: int257
    e: int257
    f: int257
    tactContinuation: Cell<CATUpdateDepositRateContinuation2>
}

struct CATUpdateDepositRateContinuation2 {
    g: int257
    h: int257
    i: int257
}

struct (0xca5d3014) CATUpdateRefferalsRate {
    a: int257
    b: int257
    c: int257
    tactContinuation: Cell<CATUpdateRefferalsRateContinuation>
}

struct CATUpdateRefferalsRateContinuation {
    d: int257
    e: int257
    f: int257
    tactContinuation: Cell<CATUpdateRefferalsRateContinuation2>
}

struct CATUpdateRefferalsRateContinuation2 {
    g: int257
    h: int257
    i: int257
    tactContinuation: Cell<CATUpdateRefferalsRateContinuation3>
}

struct CATUpdateRefferalsRateContinuation3 {
    j: int257
}

struct (0xa3ea07d7) CATIncrementTime {
    hours: int257
}

struct CATData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    id: int257
    INIT_PERCENTAGES: map<int257, int257>
    INIT_AMOUNTS: map<int257, int257>
    tactContinuation: Cell<CATDataContinuation>
}

struct CATDataContinuation {
    PERCENTAGES: map<int257, int257>
    val_: uint32
    left: map<address, bool>
    stake: map<address, Cell<CATStake>>
    stopped: bool
    owner: address
    tactContinuation: Cell<CATDataContinuation2>
}

struct CATDataContinuation2 {
    unknown: map<int257, Cell<CATStake>>
    current_time: int257
}

type CATIncomingMessage =
    | CATIncrementTime
    | CATDepositF
    | CATDeposit
    | CATReinvest
    | CATWithdraw
    | CATMigrate
    | CATLeaveCat
    | CATUpdatePartner
    | CATUpdateDepositRate
    | CATUpdateRefferalsRate
    | CATDeploy
    | CATChangeOwner

enum CATErrors {
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
    /// Zero amount
    ZeroAmount = 7189
    /// Cannot set your own address as partner
    CannotSetYourOwnAddressAsPartner = 20765
    /// Invalid rates
    InvalidRates = 31448
    /// Cannot set user address as partner
    CannotSetUserAddressAsPartner = 37764
    /// Contract stopped
    ContractStopped2 = 40368
    /// Balance too low
    BalanceTooLow = 42655
    /// Cannot deposit more than sent
    CannotDepositMoreThanSent = 52422
    /// Contract not stopped
    ContractNotStopped = 53296
    /// Insufficient balance
    InsufficientBalance = 54615
    /// Left
    Left = 56882
}

get fun percent(account: address): int257 {
    throw 0;
}

get fun pending_reward(account: address): int257 {
    throw 0;
}

get fun my_stake(account: address): int257 {
    throw 0;
}

get fun my_not_withdrawn(account: address): int257 {
    throw 0;
}

get fun lefty(cat: address): bool {
    throw 0;
}

get fun my_partner(account: address): address {
    throw 0;
}

get fun cat_balance(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}
