// Generated from the verified Tact contract ABI.
contract FreelanceEscrow {
    storage: FreelanceEscrowData
    incomingMessages: FreelanceEscrowIncomingMessage
    thrownErrors: FreelanceEscrowErrors
}

struct (0xa86dd47d) FreelanceEscrowFund {
}

struct (0xfc264fcd) FreelanceEscrowClaim {
}

struct (0x2ea6b86d) FreelanceEscrowProposeCheckin {
    reportHash: uint256
}

struct (0x36d702ab) FreelanceEscrowConfirmCheckin {
}

struct (0x7a4508d9) FreelanceEscrowPause {
}

struct (0xb59875df) FreelanceEscrowWithdrawClient {
}

struct FreelanceEscrowContractState {
    status: uint8
    balance: coins
    lastPayment: uint32
    lastCheckin: uint32
    pausedAt: uint32
    pendingHash: uint256
    nextClaimAt: uint32
    checkinDeadline: uint32
    withdrawAvailable: uint32
}

struct FreelanceEscrowData {
    tactDeploymentCompleted: bool
    contractor: address
    client: address
    clientPubkey: uint256
    rate: coins
    period: uint32
    checkinInterval: uint32
    gracePeriod: uint32
    status: uint8
    tactContinuation: Cell<FreelanceEscrowDataContinuation>
}

struct FreelanceEscrowDataContinuation {
    balance: coins
    lastPayment: uint32
    lastCheckin: uint32
    pausedAt: uint32
    pendingHash: uint256
    pendingProposer: address
}

type FreelanceEscrowIncomingMessage =
    | FreelanceEscrowFund
    | FreelanceEscrowClaim
    | FreelanceEscrowProposeCheckin
    | FreelanceEscrowConfirmCheckin
    | FreelanceEscrowPause
    | FreelanceEscrowWithdrawClient

enum FreelanceEscrowErrors {
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
    /// not active
    NotActive = 2315
    /// pausedAt not set
    PausedAtNotSet = 18568
    /// insufficient balance
    InsufficientBalance = 19364
    /// send some TON
    SendSomeTON = 19597
    /// check-in already pending
    CheckInAlreadyPending = 21092
    /// grace period not elapsed
    GracePeriodNotElapsed = 21782
    /// participants only
    ParticipantsOnly = 26952
    /// contract is closed
    ContractIsClosed = 26993
    /// hash cannot be zero
    HashCannotBeZero = 31042
    /// cannot confirm own proposal
    CannotConfirmOwnProposal = 31064
    /// invalid client signature
    InvalidClientSignature = 31502
    /// contractor only
    ContractorOnly = 32550
    /// not paused
    NotPaused = 35507
    /// check-in overdue: client protection active
    CheckInOverdueClientProtectionActive = 40065
    /// period not elapsed
    PeriodNotElapsed = 45927
    /// no pending check-in
    NoPendingCheckIn = 47578
    /// client only
    ClientOnly = 49977
    /// already closed
    AlreadyClosed = 63882
}

get fun getStatus(): int257 {
    throw 0;
}

get fun getBalance(): int257 {
    throw 0;
}

get fun getNextClaimAt(): int257 {
    throw 0;
}

get fun getCheckinDeadline(): int257 {
    throw 0;
}

get fun getWithdrawAvailableAt(): int257 {
    throw 0;
}

get fun getPendingCheckin(): int257 {
    throw 0;
}

get fun getState(): FreelanceEscrowContractState {
    throw 0;
}
