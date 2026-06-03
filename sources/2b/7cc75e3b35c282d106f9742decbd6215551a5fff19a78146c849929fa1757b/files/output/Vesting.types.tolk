// Generated from the verified Tact contract ABI.
contract Vesting {
    storage: VestingData
    incomingMessages: VestingIncomingMessage
    thrownErrors: VestingErrors
}

struct VestingSchedule {
    initialUnlock: int32
    cliffDuration: int64
    vestingDuration: int64
    startTime: int64
    claimInterval: int64
}

struct VestingClaimRecord {
    claims: map<int32, int64>
    lastClaims: map<int32, int64>
}

struct (0xeae244ce) VestingSetMerkleRootRequest {
    newRoot: bits256
}

struct (0x0fb02f39) VestingSetStakingContractAddressRequest {
    stakingContractAddress: address
}

struct (0xf98fd051) VestingSetScheduleRequest {
    vestingType: int8
    unlock: int32
    cliff: int64
    duration: int64
    interval: int64
}

struct (0x5e35d62b) VestingBanUserRequest {
    user: address
}

struct (0x7140728d) VestingUnbanUserRequest {
    user: address
}

struct (0xe483bd23) VestingSetJettonWalletRequest {
    wallet: address
}

struct (0x6c7308f9) VestingDrainRequest {
    queryId: uint64
    amount: coins
}

struct (0xdabad09f) VestingChangeAdminRequest {
    newAdmin: address
}

struct VestingData {
    tactDeploymentCompleted: bool
    admin: address
    jettonWallet: address?
    drainJettonWallet: address
    tactContinuation: Cell<VestingDataContinuation>
}

struct VestingDataContinuation {
    merkleRoot: bits256
    stakingContractAddress: address?
    startTime: int64
    schedules: map<int32, Cell<VestingSchedule>>
    claimed: map<address, Cell<VestingClaimRecord>>
    banned: map<address, bool>
}

type VestingIncomingMessage =
    | VestingSetScheduleRequest
    | VestingSetMerkleRootRequest
    | VestingSetStakingContractAddressRequest
    | VestingBanUserRequest
    | VestingUnbanUserRequest
    | VestingSetJettonWalletRequest
    | VestingChangeAdminRequest
    | VestingDrainRequest

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
    /// wallet not set
    WalletNotSet = 2975
    /// duration must be divisible by interval
    DurationMustBeDivisibleByInterval = 4879
    /// invalid unlock
    InvalidUnlock = 11629
    /// negative total
    NegativeTotal = 12409
    /// invalid vesting
    InvalidVesting = 14701
    /// banned
    Banned = 18919
    /// Insufficient gas
    InsufficientGas = 23951
    /// too big
    TooBig = 24961
    /// invalid interval
    InvalidInterval = 29350
    /// too long
    TooLong = 30115
    /// bad schedule
    BadSchedule = 31933
    /// bad proof
    BadProof = 32441
    /// not found
    NotFound = 35923
    /// too soon
    TooSoon = 36011
    /// invalid cliff
    InvalidCliff = 38303
    /// Can not stake
    CanNotStake = 44282
    /// Nothing to claim
    NothingToClaim = 44799
    /// invalid amount
    InvalidAmount = 54178
    /// already set
    AlreadySet = 55815
    /// not started
    NotStarted = 56772
}

get fun computeUnlocked(total: int257, s: VestingSchedule, now: int257): int257 {
    throw 0;
}

get fun get_claimed(user: address, vestingType: int257): int257 {
    throw 0;
}

get fun get_last_claim(user: address, vestingType: int257): int257 {
    throw 0;
}

get fun get_schedule(vestingType: int257): VestingSchedule {
    throw 0;
}

get fun get_merkle_root(): slice {
    throw 0;
}

get fun is_banned(user: address): bool {
    throw 0;
}

get fun get_jetton_wallet(): address? {
    throw 0;
}

get fun get_drain_jetton_wallet(): address {
    throw 0;
}
