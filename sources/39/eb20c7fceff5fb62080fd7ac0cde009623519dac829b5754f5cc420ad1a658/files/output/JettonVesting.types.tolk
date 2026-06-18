// Generated from the verified Tact contract ABI.
contract JettonVesting {
    storage: JettonVestingData
    incomingMessages: JettonVestingIncomingMessage
    thrownErrors: JettonVestingErrors
}

struct (0x51a6f0c1) JettonVestingSetJettonWallet {
    wallet: address
}

struct (0xd53276db) JettonVestingJettonExcess {
    queryId: uint64
}

struct JettonVestingReleaseNode {
    releaseTime: uint32
    amount: coins
    claimedAmount: coins
    claimedBy: uint2
    pendingQueryId: uint64
    pendingAmount: coins
}

struct JettonVestingPendingClaim {
    amount: coins
    recipient: address
    claimedBy: uint2
    firstNode: uint16
    endNode: uint16
    active: bool
}

struct JettonVestingVestingConfig {
    setupWallet: address
    claimWallet: address
    fallbackWallet: address
    tactContinuation: Cell<JettonVestingVestingConfigContinuation>
}

struct JettonVestingVestingConfigContinuation {
    jettonWallet: address
    jettonWalletReady: bool
    claimJettonWallet: address
    fallbackJettonWallet: address
    totalAmount: coins
    nodesCount: uint16
    tactContinuation: Cell<JettonVestingVestingConfigContinuation2>
}

struct JettonVestingVestingConfigContinuation2 {
    totalClaimed: coins
    nextQueryId: uint64
}

struct JettonVestingReleaseNodeStatus {
    releaseTime: uint32
    amount: coins
    primaryUnlocked: bool
    fallbackUnlocked: bool
    claimed: bool
    claimedBy: uint2
    claimedAmount: coins
    pendingQueryId: uint64
    pendingAmount: coins
}

struct JettonVestingData {
    tactDeploymentCompleted: bool
    setupWallet: address
    claimWallet: address
    fallbackWallet: address
    tactContinuation: Cell<JettonVestingDataContinuation>
}

struct JettonVestingDataContinuation {
    jettonWallet: address
    jettonWalletReady: bool
    claimJettonWallet: address
    fallbackJettonWallet: address
    totalAmount: coins
    nodes: map<uint16, Cell<JettonVestingReleaseNode>>
    pendingClaims: map<uint64, Cell<JettonVestingPendingClaim>>
    nodesCount: uint16
    tactContinuation: Cell<JettonVestingDataContinuation2>
}

struct JettonVestingDataContinuation2 {
    totalClaimed: coins
    nextQueryId: uint64
}

type JettonVestingIncomingMessage =
    | JettonVestingSetJettonWallet
    | JettonVestingJettonExcess

enum JettonVestingErrors {
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
    /// jetton wallet not set
    JettonWalletNotSet = 1092
    /// unauthorized
    Unauthorized = 2233
    /// jetton wallet already set
    JettonWalletAlreadySet = 4655
    /// invalid schedule
    InvalidSchedule = 4725
    /// invalid claim
    InvalidClaim = 19489
    /// not enough TON
    NotEnoughTON = 30226
    /// invalid claimed
    InvalidClaimed = 33109
    /// invalid total
    InvalidTotal = 35645
    /// node already pending
    NodeAlreadyPending = 40292
    /// too many nodes
    TooManyNodes = 41586
    /// invalid nodes
    InvalidNodes = 44110
    /// invalid bounce
    InvalidBounce = 46184
    /// wallets match
    WalletsMatch = 46863
    /// missing node
    MissingNode = 51526
    /// invalid pending range
    InvalidPendingRange = 51684
    /// invalid jetton wallet
    InvalidJettonWallet = 51780
    /// invalid amount
    InvalidAmount = 54178
    /// amount mismatch
    AmountMismatch = 59680
    /// invalid final comment
    InvalidFinalComment = 59777
    /// nothing to claim
    NothingToClaim = 62845
    /// invalid pending
    InvalidPending = 63539
}

get fun getConfig(): JettonVestingVestingConfig {
    throw 0;
}

get fun getNode(index: int257): JettonVestingReleaseNode {
    throw 0;
}

get fun getNodeStatus(index: int257): JettonVestingReleaseNodeStatus {
    throw 0;
}

get fun getClaimable(address: address): int257 {
    throw 0;
}
