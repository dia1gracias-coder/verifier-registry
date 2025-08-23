// Generated from the verified Tact contract ABI.
contract DzTonV3 {
    storage: DzTonV3Data
    incomingMessages: DzTonV3IncomingMessage
    thrownErrors: DzTonV3Errors
}

struct (0x946a98b6) DzTonV3Deploy {
    queryId: uint64
}

struct (0xd53276db) DzTonV3JettonExcesses {
    queryId: uint64
}

struct (0xb71ee889) DzTonV3SetMyJettonWallet {
    jettonWallet: address
}

struct (0x4bc5e8b4) DzTonV3AddHighloadWallet {
    wallet: address
}

struct (0x833985ad) DzTonV3RemoveHighloadWallet {
    wallet: address
}

struct (0x3ec0e17f) DzTonV3WithdrawToken {
    to: address
    amount: coins
    order: uint128
    queryId: uint64
    timeout: uint32
}

struct DzTonV3Data {
    tactDeploymentCompleted: bool
    owner: address
    myJettonWallet: address
    highloadWallets: map<address, bool>
    processedQueryTimeouts: map<uint64, uint32>
    processedQueryCount: int257
    withdrawLimit: coins
}

type DzTonV3IncomingMessage =
    | DzTonV3JettonExcesses
    | DzTonV3SetMyJettonWallet
    | DzTonV3AddHighloadWallet
    | DzTonV3RemoveHighloadWallet
    | DzTonV3WithdrawToken
    | DzTonV3Deploy

enum DzTonV3Errors {
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
    /// Invalid address
    InvalidAddress = 10905
    /// Timeout too long
    TimeoutTooLong = 12508
    /// Tx expired
    TxExpired = 13646
    /// Already processed
    AlreadyProcessed = 19257
    /// Invalid queryId!
    InvalidQueryId = 35042
    /// Not authorized
    NotAuthorized = 42435
    /// Invalid amount!
    InvalidAmount = 54529
    /// Jetton wallet empty
    JettonWalletEmpty = 55813
    /// Exceeds limit
    ExceedsLimit = 60379
}

get fun queryMyJettonWallet(): address {
    throw 0;
}

get fun queryOwner(): address {
    throw 0;
}

get fun queryHighloadWallet(wallet: address): bool {
    throw 0;
}

get fun checkIsQueryIdProcessed(queryId: int257): bool {
    throw 0;
}

get fun getWithdrawLimit(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
