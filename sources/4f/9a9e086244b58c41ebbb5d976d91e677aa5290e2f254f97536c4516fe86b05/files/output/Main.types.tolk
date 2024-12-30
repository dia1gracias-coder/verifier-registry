// Generated from the verified Tact contract ABI.
contract Main {
    storage: MainData
    incomingMessages: MainIncomingMessage
    thrownErrors: MainErrors
}

struct (0x819dbe99) MainChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x946a98b6) MainDeploy {
    queryId: uint64
}

struct (0x756b6cbc) MainFinishRound {
    queryId: uint64
    winner: address
}

struct (0xe96937e9) MainUpdateParams {
    queryId: uint64
    entryFee: int257
    prizePercentage: int257
    commissionPercentage: int257
}

struct MainData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    id: uint64
    owner: address
    round: uint32
    stopped: bool
    entryFee: coins
    prizePercentage: uint32
    commissionPercentage: uint32
}

type MainIncomingMessage =
    | MainDeploy
    | MainFinishRound
    | MainUpdateParams
    | MainChangeOwner

enum MainErrors {
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
    /// 'Unknown' error
    UnknownError = 11
    /// Fatal error
    FatalError = 12
    /// Out of gas error
    OutOfGasError = 13
    /// Virtualization error
    VirtualizationError = 14
    /// Action list is invalid
    ActionListIsInvalid = 32
    /// Action list is too long
    ActionListIsTooLong = 33
    /// Action is invalid or not supported
    ActionIsInvalidOrNotSupported = 34
    /// Invalid source address in outbound message
    InvalidSourceAddressInOutboundMessage = 35
    /// Invalid destination address in outbound message
    InvalidDestinationAddressInOutboundMessage = 36
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
    NotEnoughExtraCurrencies = 38
    /// Outbound message does not fit into a cell after rewriting
    OutboundMessageDoesNotFitIntoACellAfterRewriting = 39
    /// Cannot process a message
    CannotProcessAMessage = 40
    /// Library reference is null
    LibraryReferenceIsNull = 41
    /// Library change action error
    LibraryChangeActionError = 42
    /// Exceeded maximum number of cells in the library or the maximum depth of the Merkle tree
    ExceededMaximumNumberOfCellsInTheLibraryOrTheMaximumDepthOfTheMerkleTree = 43
    /// Account state size exceeded limits
    AccountStateSizeExceededLimits = 50
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
    /// Invalid commission percentage.
    InvalidCommissionPercentage = 21711
    /// Not enough contact balance
    NotEnoughContactBalance = 22180
    /// Entry fee must be positive.
    EntryFeeMustBePositive = 38406
    /// Contract stopped
    ContractStopped2 = 40368
    /// Insufficient entry fee.
    InsufficientEntryFee = 44947
    /// Invalid prize percentage.
    InvalidPrizePercentage = 47031
    /// Contract not stopped
    ContractNotStopped = 53296
}

get fun round(): int257 {
    throw 0;
}

get fun id(): int257 {
    throw 0;
}

get fun entryFee(): int257 {
    throw 0;
}

get fun commissionPercentage(): int257 {
    throw 0;
}

get fun prizePercentage(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}
