// Generated from the verified Tact contract ABI.
contract Account {
    storage: AccountData
    incomingMessages: AccountIncomingMessage
    thrownErrors: AccountErrors
}

struct (0x00000210) AccountDeposit {
    queryId: uint8
}

struct (0x00000211) AccountWithdraw {
    amount: coins
}

struct (0x00000212) AccountIssue2 {
    size: coins
    interest: uint16
    duration: uint32
    borrower: address
    pawn: address
}

struct (0x00000213) AccountDispose2 {
    credit: address
}

struct (0x00000214) AccountProportion {
    proportion: uint8
}

struct (0x00000311) AccountBankIssueCredit {
    size: coins
    address: address
    premium: coins
}

struct (0x00000312) AccountGetNft {
    nft: address
    forward: coins
    payload: RemainingBitsAndRefs
}

struct (0x00000404) AccountDestroy {
}

struct AccountData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    bank: address
    creditProportion: uint8
}

type AccountIncomingMessage =
    | AccountDeposit
    | AccountWithdraw
    | AccountIssue2
    | AccountBankIssueCredit
    | AccountDispose2
    | AccountGetNft
    | AccountProportion
    | AccountDestroy

enum AccountErrors {
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
    /// Insufficient value
    InsufficientValue = 2805
    /// Invalid sender
    InvalidSender = 4429
    /// Invalid privelegies
    InvalidPrivelegies = 18449
    /// Invalid borrower
    InvalidBorrower = 30295
    /// Invalid lender
    InvalidLender = 35458
    /// Insufficient privelegies
    InsufficientPrivelegies = 36287
    /// Invalid time
    InvalidTime = 44092
    /// Invalid pawn
    InvalidPawn = 52413
    /// Insufficient balance
    InsufficientBalance = 54615
    /// Insufficient debt
    InsufficientDebt = 55895
    /// Not active
    NotActive = 61530
    /// Not init
    NotInit = 62407
}

get fun owner(): address {
    throw 0;
}

get fun bank(): address {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}
