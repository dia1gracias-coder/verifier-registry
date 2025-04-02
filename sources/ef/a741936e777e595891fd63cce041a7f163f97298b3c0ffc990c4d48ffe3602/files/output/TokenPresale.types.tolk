// Generated from the verified Tact contract ABI.
contract TokenPresale {
    storage: TokenPresaleData
    incomingMessages: TokenPresaleIncomingMessage
    thrownErrors: TokenPresaleErrors
}

struct (0x946a98b6) TokenPresaleDeploy {
    queryId: uint64
}

struct (0xd955a68e) TokenPresalePurchase {
    amount: coins
}

struct (0x23273e96) TokenPresaleClaim {
    amount: uint64
}

struct (0xb7225cdc) TokenPresaleAdminWithdraw {
    to: address
}

struct TokenPresalePresaleInfo {
    presaleStart: int257
    presaleEnd: int257
    rate: int257
    tactContinuation: Cell<TokenPresalePresaleInfoContinuation>
}

struct TokenPresalePresaleInfoContinuation {
    minPurchase: int257
    maxPurchase: int257
    hardcap: int257
    tactContinuation: Cell<TokenPresalePresaleInfoContinuation2>
}

struct TokenPresalePresaleInfoContinuation2 {
    totalRaised: int257
}

struct TokenPresaleData {
    tactDeploymentCompleted: bool
    owner: address
    token: address
    presaleStart: int257
    tactContinuation: Cell<TokenPresaleDataContinuation>
}

struct TokenPresaleDataContinuation {
    presaleEnd: int257
    rate: int257
    minPurchase: int257
    tactContinuation: Cell<TokenPresaleDataContinuation2>
}

struct TokenPresaleDataContinuation2 {
    maxPurchase: int257
    hardcap: int257
    totalRaised: int257
    claimed: bool
    contributions: map<address, int257>
}

type TokenPresaleIncomingMessage =
    | TokenPresalePurchase
    | TokenPresaleClaim
    | TokenPresaleAdminWithdraw
    | TokenPresaleDeploy

enum TokenPresaleErrors {
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
    /// Presale has ended
    PresaleHasEnded = 5448
    /// Hardcap reached
    HardcapReached = 20776
    /// No contribution found
    NoContributionFound = 22182
    /// Presale has not started yet
    PresaleHasNotStartedYet = 24249
    /// Purchase exceeds maximum allowed
    PurchaseExceedsMaximumAllowed = 25578
    /// Only owner can withdraw
    OnlyOwnerCanWithdraw = 26825
    /// Presale has not ended yet
    PresaleHasNotEndedYet = 40127
    /// Purchase amount below minimum
    PurchaseAmountBelowMinimum = 42210
}

get fun getContribution(address: address): int257 {
    throw 0;
}

get fun getPresaleInfo(): TokenPresalePresaleInfo {
    throw 0;
}

get fun isActive(): bool {
    throw 0;
}

get fun calculateTokens(tonAmount: int257): int257 {
    throw 0;
}
