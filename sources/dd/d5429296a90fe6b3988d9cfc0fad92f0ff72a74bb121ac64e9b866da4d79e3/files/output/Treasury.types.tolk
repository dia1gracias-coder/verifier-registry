// Generated from the verified Tact contract ABI.
contract Treasury {
    storage: TreasuryData
    incomingMessages: TreasuryIncomingMessage
    thrownErrors: TreasuryErrors
}

struct (0x7362d09c) TreasuryJettonNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0x6a3b2c22) TreasuryJettonTransferCommitFailed {
    queryId: uint64
    amount: coins
}

struct TreasurySpendRecord {
    recipient: address
    amount: coins
    reason: string
    timestamp: uint64
    proposalId: uint64
    queryId: uint64
}

struct (0x5a1c9010) TreasurySpend {
    queryId: uint64
    recipient: address
    amount: coins
    reason: string
    proposalId: uint64
}

struct TreasuryData {
    tactSystemCell: cell
    timelock: address
    jetton_master: address
    total_received: coins
    total_spent: coins
    spending_log: map<int257, Cell<TreasurySpendRecord>>
    tactContinuation: Cell<TreasuryDataContinuation>
}

struct TreasuryDataContinuation {
    spending_count: int257
}

type TreasuryIncomingMessage =
    | TreasuryJettonNotification
    | TreasurySpend
    | TreasuryJettonTransferCommitFailed

enum TreasuryErrors {
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
    /// Insufficient gas for spend
    InsufficientGasForSpend = 1060
    /// Incorrect balance after send
    IncorrectBalanceAfterSend = 2366
    /// Only timelock
    OnlyTimelock = 3095
    /// Zero amount
    ZeroAmount = 7189
    /// Incorrect sender
    IncorrectSender = 9215
    /// Unexpected bounce
    UnexpectedBounce = 15056
    /// Bounce queryId unknown
    BounceQueryIdUnknown = 16170
    /// Fee destinations not configured
    FeeDestinationsNotConfigured = 21507
    /// Insufficient tracked balance
    InsufficientTrackedBalance = 26486
    /// Insufficient amount of TON attached
    InsufficientAmountOfTONAttached = 32113
    /// Invalid fee bps
    InvalidFeeBps = 32270
    /// Duplicate spend queryId
    DuplicateSpendQueryId = 41076
    /// Invalid gas params
    InvalidGasParams = 41940
    /// Fee split invariant
    FeeSplitInvariant = 42588
    /// Insufficient TON for fee fanout
    InsufficientTONForFeeFanout = 54718
    /// Unexpected bounce log
    UnexpectedBounceLog = 57441
    /// Bounce amount mismatch
    BounceAmountMismatch = 59438
    /// Amount must be positive
    AmountMustBePositive = 61135
    /// Only treasury jetton wallet
    OnlyTreasuryJettonWallet = 61898
}

get fun get_timelock(): address {
    throw 0;
}

get fun get_jetton_master(): address {
    throw 0;
}

get fun get_total_received(): int257 {
    throw 0;
}

get fun get_total_spent(): int257 {
    throw 0;
}

get fun get_spending_count(): int257 {
    throw 0;
}

get fun get_spending_history(): map<int257, Cell<TreasurySpendRecord>> {
    throw 0;
}

get fun get_accounted_balance(): int257 {
    throw 0;
}
