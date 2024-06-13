// Generated from the verified Tact contract ABI.
contract TestContract {
    storage: TestContractData2
    incomingMessages: TestContractDeploy
    thrownErrors: TestContractErrors
}

struct (0x946a98b6) TestContractDeploy {
    queryId: uint64
}

struct TestContractData {
    total_bet_a: uint32
    total_bet_b: uint32
    odds_a: uint32
    odds_b: uint32
    bets_a: map<address, int257>
    bets_b: map<address, int257>
    finalized: bool
    outcome_a_wins: bool
}

struct TestContractData2 {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    stopped: bool
    data: TestContractData
}

enum TestContractErrors {
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
    /// Betting is not finalized yet
    BettingIsNotFinalizedYet = 25096
    /// Contract stopped
    ContractStopped2 = 40368
    /// Only the owner can finalize
    OnlyTheOwnerCanFinalize = 49684
    /// No payout available for sender
    NoPayoutAvailableForSender = 51093
    /// Contract not stopped
    ContractNotStopped = 53296
    /// Betting is over
    BettingIsOver = 63076
}

get fun getTotalBetA(): int257 {
    throw 0;
}

get fun getTotalBetB(): int257 {
    throw 0;
}

get fun isFinalized(): bool {
    throw 0;
}

get fun getOwner(): address {
    throw 0;
}

get fun isStopped(): bool {
    throw 0;
}

get fun getoddA(): int257 {
    throw 0;
}

get fun getoddB(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}
