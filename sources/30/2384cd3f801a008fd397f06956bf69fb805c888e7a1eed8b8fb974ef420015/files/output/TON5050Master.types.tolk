// Generated from the verified Tact contract ABI.
contract TON5050Master {
    storage: TON5050MasterData
    incomingMessages: TON5050MasterIncomingMessage
    thrownErrors: TON5050MasterErrors
}

struct (0x946a98b6) TON5050MasterDeploy {
    queryId: uint64
}

struct (0x5810d8e4) TON5050MasterCreateRaffle {
    duration: uint32
    salt: uint256
}

struct TON5050MasterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    platformWallet: address
    raffleCount: uint32
    creationFee: coins
}

type TON5050MasterIncomingMessage =
    | TON5050MasterCreateRaffle
    | TON5050MasterDeploy

enum TON5050MasterErrors {
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
    /// Raffle already drawn
    RaffleAlreadyDrawn = 13076
    /// Minimum raffle duration is 5 minutes (300s)
    MinimumRaffleDurationIs5Minutes300s = 16781
    /// Raffle has expired
    RaffleHasExpired = 23951
    /// Raffle has not expired yet
    RaffleHasNotExpiredYet = 33868
    /// Must send 10 TON creation fee
    MustSend10TONCreationFee = 49539
    /// Maximum raffle duration is 1 year (31536000s)
    MaximumRaffleDurationIs1Year31536000s = 55306
    /// Must send at least 2 TON
    MustSendAtLeast2TON = 56719
}

get fun platformWallet(): address {
    throw 0;
}

get fun raffleCount(): int257 {
    throw 0;
}

get fun creationFee(): int257 {
    throw 0;
}
