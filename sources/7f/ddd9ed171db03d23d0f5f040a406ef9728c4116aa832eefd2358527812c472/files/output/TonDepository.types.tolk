// Generated from the verified Tact contract ABI.
contract TonDepository {
    storage: TonDepositoryData
    incomingMessages: TonDepositoryIncomingMessage
    thrownErrors: TonDepositoryErrors
}

struct (0x946a98b6) TonDepositoryDeploy {
    queryId: uint64
}

struct (0x6bfe94fe) TonDepositoryActivateOracle {
    oracle: address
    isActivated: bool
}

struct (0x819dbe99) TonDepositoryChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x7362d09c) TonDepositoryTokenNotification {
    query_id: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct (0x0ba69751) TonDepositoryWithdraw {
    amount: coins
}

struct (0xc6d0ecd9) TonDepositoryWithdrawFor {
    amount: coins
    to: address
}

struct TonDepositoryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    oracles: map<address, bool>
    jetton_wallet: address
}

type TonDepositoryIncomingMessage =
    | TonDepositoryTokenNotification
    | TonDepositoryWithdraw
    | TonDepositoryWithdrawFor
    | TonDepositoryDeploy
    | TonDepositoryActivateOracle
    | TonDepositoryChangeOwner

enum TonDepositoryErrors {
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
    /// Invalid sender
    InvalidSender = 4429
    /// Invalid value
    InvalidValue = 16059
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Funds can be deposited only from the Jetton wallet
    FundsCanBeDepositedOnlyFromTheJettonWallet = 19117
    /// Insufficient gas
    InsufficientGas = 23951
    /// Only oracle allowed
    OnlyOracleAllowed = 30379
    /// Amount must be greater than 0
    AmountMustBeGreaterThan0 = 40476
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// Invalid balance
    InvalidBalance = 62972
}

get fun jetton_wallet(): address {
    throw 0;
}

get fun oracles(): map<address, bool> {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
