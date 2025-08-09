// Generated from the verified Tact contract ABI.
contract TinyVesting {
    storage: TinyVestingData
    incomingMessages: TinyVestingIncomingMessage
    thrownErrors: TinyVestingErrors
}

struct TinyVestingClaimInfo {
    user: address
    amount: uint256?
    time: uint64
}

struct TinyVestingPoolInfo {
    claimInfos: map<uint64, Cell<TinyVestingClaimInfo>>
    refundInfos: map<uint64, Cell<TinyVestingClaimInfo>>
    tactContinuation: Cell<TinyVestingPoolInfoContinuation>
}

struct TinyVestingPoolInfoContinuation {
    partialRefundInfos: map<uint64, Cell<TinyVestingClaimInfo>>
    bonusInfos: map<uint64, Cell<TinyVestingClaimInfo>>
    userClaimIds: map<address, uint64>
    tactContinuation: Cell<TinyVestingPoolInfoContinuation2>
}

struct TinyVestingPoolInfoContinuation2 {
    userClaimStatus: map<address, uint64>
    userClaimAmount: map<address, uint256>
    userBonusAmount: map<address, uint256>
    tactContinuation: Cell<TinyVestingPoolInfoContinuation3>
}

struct TinyVestingPoolInfoContinuation3 {
    userRefunded: map<address, bool>
    userPartialRefunded: map<address, bool>
    totalClaims: uint256
    totalBonuses: uint256
}

struct (0x00000005) TinyVestingSetSigner {
    signer: uint256
}

struct (0x00000006) TinyVestingSetStartTime {
    startTime: uint64
}

struct (0x00000007) TinyVestingWithdrawJetton {
    token: address
    to: address
    amount: uint256
}

struct TinyVestingData {
    tactDeploymentCompleted: bool
    poolInfos: map<uint64, Cell<TinyVestingPoolInfo>>
    owner: address
    signer: uint256
    startTime: uint64
}

type TinyVestingIncomingMessage =
    | TinyVestingSetSigner
    | TinyVestingSetStartTime
    | TinyVestingWithdrawJetton

enum TinyVestingErrors {
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
    /// Zero amount
    ZeroAmount = 7189
    /// Not Start
    NotStart = 10381
    /// Executed
    Executed = 13299
    /// Already partially refunded
    AlreadyPartiallyRefunded = 22335
    /// Already refunded
    AlreadyRefunded = 22411
    /// Zero Amount
    ZeroAmount2 = 24491
    /// Partial Refunded
    PartialRefunded = 33317
    /// Already claimed
    AlreadyClaimed = 42504
    /// Invalid time
    InvalidTime = 44092
    /// Refunded
    Refunded = 47004
    /// Invalid signature
    InvalidSignature = 48401
    /// Already executed
    AlreadyExecuted = 52683
    /// Claimed
    Claimed = 52721
    /// Vesting in progress
    VestingInProgress = 61486
    /// Invalid signer
    InvalidSigner = 62579
}

get fun getUserRefunded(poolId: int257, user: address): bool? {
    throw 0;
}

get fun getUserParitalRefunded(poolId: int257, user: address): bool? {
    throw 0;
}

get fun getUserClaimStatus(poolId: int257, user: address): int257? {
    throw 0;
}

get fun getSigner(): int257? {
    throw 0;
}

get fun getStartTime(): int257? {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
