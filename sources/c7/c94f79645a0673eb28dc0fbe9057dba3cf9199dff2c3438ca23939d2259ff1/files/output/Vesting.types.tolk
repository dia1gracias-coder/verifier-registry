// Generated from the verified Tact contract ABI.
contract Vesting {
    storage: VestingData
    incomingMessages: VestingIncomingMessage
    thrownErrors: VestingErrors
}

struct (0x5a060001) VestingVestRelease {
    queryId: uint64
}

struct (0x5a060002) VestingVestEmergencyRevoke {
    queryId: uint64
}

struct VestingInfo {
    beneficiary: address
    treasury: address
    timelock: address
    tactContinuation: Cell<VestingInfoContinuation>
}

struct VestingInfoContinuation {
    jetton_master: address
    total_amount: coins
    released_amount: coins
    start_time: uint64
    cliff_duration: uint64
    vesting_duration: uint64
}

struct VestingData {
    tactSystemCell: cell
    beneficiary: address
    total_amount: coins
    start_time: uint64
    cliff_duration: uint64
    vesting_duration: uint64
    released_amount: coins
    timelock: address
    tactContinuation: Cell<VestingDataContinuation>
}

struct VestingDataContinuation {
    jetton_master: address
    treasury: address
}

type VestingIncomingMessage =
    | VestingVestRelease
    | VestingVestEmergencyRevoke

enum VestingErrors {
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
    /// Not enough Toncoin
    NotEnoughToncoin = 37
    /// Not enough extra currencies
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
    /// Invalid standard address
    InvalidStandardAddress = 136
    /// Not a basechain address
    NotABasechainAddress = 138
    /// Incorrect balance after send
    IncorrectBalanceAfterSend = 2366
    /// Only timelock
    OnlyTimelock = 3095
    /// Incorrect sender
    IncorrectSender = 9215
    /// Insufficient gas for revoke
    InsufficientGasForRevoke = 10791
    /// Unexpected bounce
    UnexpectedBounce = 15056
    /// Nothing to revoke
    NothingToRevoke = 19111
    /// Bad vesting schedule
    BadVestingSchedule = 20247
    /// Fee destinations not configured
    FeeDestinationsNotConfigured = 21507
    /// Nothing to release
    NothingToRelease = 30773
    /// Insufficient amount of TON attached
    InsufficientAmountOfTONAttached = 32113
    /// Invalid fee bps
    InvalidFeeBps = 32270
    /// Invalid vesting schedule
    InvalidVestingSchedule = 32505
    /// Invalid gas params
    InvalidGasParams = 41940
    /// Fee split invariant
    FeeSplitInvariant = 42588
    /// Insufficient TON for fee fanout
    InsufficientTONForFeeFanout = 54718
    /// Only beneficiary
    OnlyBeneficiary = 57331
    /// Amount must be positive
    AmountMustBePositive = 61135
}

get fun get_beneficiary(): address {
    throw 0;
}

get fun get_treasury(): address {
    throw 0;
}

get fun get_timelock(): address {
    throw 0;
}

get fun get_jetton_master(): address {
    throw 0;
}

get fun get_total_amount(): int257 {
    throw 0;
}

get fun get_released_amount(): int257 {
    throw 0;
}

get fun get_schedule(): VestingInfo {
    throw 0;
}

get fun get_vested_at(currentTime: int257): int257 {
    throw 0;
}

get fun get_releasable_at(currentTime: int257): int257 {
    throw 0;
}
