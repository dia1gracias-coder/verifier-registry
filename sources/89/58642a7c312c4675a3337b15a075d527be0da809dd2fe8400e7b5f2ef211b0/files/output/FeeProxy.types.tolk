// Generated from the verified Tact contract ABI.
contract FeeProxy {
    storage: FeeProxyData
    incomingMessages: FeeProxyIncomingMessage
    thrownErrors: FeeProxyErrors
}

struct (0x946a98b6) FeeProxyDeploy {
    queryId: uint64
}

struct (0x50524f58) FeeProxyProxyForward {
    fragmentAddress: address
    forwardAmount: coins
    originalPayload: cell
}

struct (0x50524f59) FeeProxyProxyForwardRef {
    fragmentAddress: address
    forwardAmount: coins
    originalPayload: cell
    referrerAddress: address
    referralBps: uint16
}

struct (0x57445257) FeeProxyWithdrawFees {
    amount: coins
    to: address
}

struct FeeProxyData {
    tactDeploymentCompleted: bool
    owner: address
    totalForwarded: coins
    totalFees: coins
    totalReferralPaid: coins
}

type FeeProxyIncomingMessage =
    | FeeProxyProxyForward
    | FeeProxyProxyForwardRef
    | FeeProxyWithdrawFees
    | FeeProxyDeploy

enum FeeProxyErrors {
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
    /// Insufficient value
    InsufficientValue = 2805
    /// Not owner
    NotOwner = 14534
    /// Nothing to withdraw
    NothingToWithdraw = 40636
    /// Invalid referral bps
    InvalidReferralBps = 54755
}

get fun owner(): address {
    throw 0;
}

get fun totalForwarded(): int257 {
    throw 0;
}

get fun totalFees(): int257 {
    throw 0;
}

get fun totalReferralPaid(): int257 {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}
