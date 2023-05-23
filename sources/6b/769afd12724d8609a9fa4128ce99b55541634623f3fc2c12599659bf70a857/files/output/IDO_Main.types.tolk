// Generated from the verified Tact contract ABI.
contract IDO_Main {
    storage: IDO_MainData
    thrownErrors: IDO_MainErrors
}

struct IDO_MainData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    project_id: uint16
    owner: address
}

enum IDO_MainErrors {
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
    /// Timing incorrect
    TimingIncorrect = 1845
    /// not at right sender WallerV4 address
    NotAtRightSenderWallerV4Address = 4824
    /// not correct status
    NotCorrectStatus = 12873
    /// not the admin
    NotTheAdmin = 21884
    /// still in open status
    StillInOpenStatus = 22619
    /// ratio too high
    RatioTooHigh = 35067
    /// Time Frame too long
    TimeFrameTooLong = 35179
    /// not in open status for users to participate
    NotInOpenStatusForUsersToParticipate = 35535
    /// Time Frame too short
    TimeFrameTooShort = 37215
    /// not owner
    NotOwner = 49280
}

get fun get_round_address(project_id: int257): address {
    throw 0;
}
