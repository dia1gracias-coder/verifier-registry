// Generated from the verified Tact contract ABI.
contract TonfarmRWA {
    storage: TonfarmRWAData
    incomingMessages: TonfarmRWAIncomingMessage
    thrownErrors: TonfarmRWAErrors
}

struct (0x946a98b6) TonfarmRWADeploy {
    queryId: uint64
}

struct (0x0f8a6ea5) TonfarmRWADeposit_msg {
    tarif: uint64
    amount: uint64
    upline: address
    sender: address
}

struct TonfarmRWATarif {
    life_days: int257
    percent: int257
}

struct TonfarmRWADeposit {
    tarif: int257
    amount: int257
    time: int257
}

struct TonfarmRWAPlayer {
    upline: address
    dividends: int257
    match_bonus: int257
    tactContinuation: Cell<TonfarmRWAPlayerContinuation>
}

struct TonfarmRWAPlayerContinuation {
    last_payout: int257
    total_invested: int257
    total_withdrawn: int257
    tactContinuation: Cell<TonfarmRWAPlayerContinuation2>
}

struct TonfarmRWAPlayerContinuation2 {
    total_match_bonus: int257
    deposits: map<int257, Cell<TonfarmRWADeposit>>
    structure: map<int257, int257>
    refCount: int257
    refDeposits: int257
    tactContinuation: Cell<TonfarmRWAPlayerContinuation3>
}

struct TonfarmRWAPlayerContinuation3 {
    index: int257
}

struct TonfarmRWAData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    mrktcap1: address
    mrktcap2: address
    tactContinuation: Cell<TonfarmRWADataContinuation>
}

struct TonfarmRWADataContinuation {
    mrktcap3: address
    invested: int257
    withdrawn: int257
    tactContinuation: Cell<TonfarmRWADataContinuation2>
}

struct TonfarmRWADataContinuation2 {
    match_bonus: int257
    locked: bool
    ref_bonuses: map<int257, int257>
    tarifs: map<int257, Cell<TonfarmRWATarif>>
    players: map<address, Cell<TonfarmRWAPlayer>>
}

type TonfarmRWAIncomingMessage =
    | TonfarmRWADeposit_msg
    | TonfarmRWADeploy

enum TonfarmRWAErrors {
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
    /// Minimum deposit amount is 0.1 TON
    MinimumDepositAmountIs01TON = 13806
    /// Not Input Tarif
    NotInputTarif = 17133
    /// Tarif not found
    TarifNotFound = 22257
    /// Player not found
    PlayerNotFound = 23691
    /// Not Input Sender Address
    NotInputSenderAddress = 50616
}
