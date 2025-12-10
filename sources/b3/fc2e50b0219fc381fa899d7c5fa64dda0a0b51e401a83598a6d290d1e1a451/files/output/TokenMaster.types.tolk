// Generated from the verified Tact contract ABI.
contract TokenMaster {
    storage: TokenMasterData
    incomingMessages: TokenMasterIncomingMessage
    thrownErrors: TokenMasterErrors
}

struct (0x946a98b6) TokenMasterDeploy {
    queryId: uint64
}

struct TokenMasterTokenData {
    name: string
    symbol: string
    decimals: int257
}

struct TokenMasterVestingData {
    startTime: int257
    duration: int257
    cliff: int257
}

struct TokenMasterJettonData {
    totalSupply: int257
    mintable: bool
    owner: address
    content: cell
    walletCode: cell
}

struct (0xcf61fb0b) TokenMasterRedeemPoints {
    queryId: uint64
    points: uint64
    recipient: address
}

struct (0xa8aec8fe) TokenMasterMint {
    queryId: uint64
    amount: coins
    recipient: address
}

struct (0xbc92fce8) TokenMasterUpdateExchangeRate {
    queryId: uint64
    newRate: uint64
}

struct (0xb0d244fc) TokenMasterSetPaused {
    queryId: uint64
    paused: bool
}

struct (0x0caa6368) TokenMasterSetTransferEnabled {
    queryId: uint64
    enabled: bool
}

struct (0x3bdc4d6f) TokenMasterAddWhitelist {
    queryId: uint64
    address: address
}

struct (0xa3e75aaf) TokenMasterRemoveWhitelist {
    queryId: uint64
    address: address
}

struct (0xce2d096a) TokenMasterSetVestingParams {
    queryId: uint64
    startTime: uint32
    duration: uint32
    cliffDuration: uint32
}

struct TokenMasterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    totalSupply: coins
    mintable: bool
    name: string
    tactContinuation: Cell<TokenMasterDataContinuation>
}

struct TokenMasterDataContinuation {
    symbol: string
    decimals: uint8
    exchangeRate: uint64
    totalPointsRedeemed: uint64
    paused: bool
    transferEnabled: bool
    whitelist: map<address, bool>
    vestingStartTime: uint32
    vestingDuration: uint32
    vestingCliff: uint32
    walletCode: cell
    jettonContent: cell
}

type TokenMasterIncomingMessage =
    | TokenMasterRedeemPoints
    | TokenMasterMint
    | TokenMasterUpdateExchangeRate
    | TokenMasterSetPaused
    | TokenMasterSetTransferEnabled
    | TokenMasterAddWhitelist
    | TokenMasterRemoveWhitelist
    | TokenMasterSetVestingParams
    | TokenMasterDeploy

enum TokenMasterErrors {
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
    /// Invalid sender
    InvalidSender = 4429
    /// Invalid exchange rate
    InvalidExchangeRate = 5347
    /// Exchange rate not set
    ExchangeRateNotSet = 11990
    /// Contract is paused
    ContractIsPaused = 19792
    /// Only owner can burn
    OnlyOwnerCanBurn = 21543
    /// Minting is disabled
    MintingIsDisabled = 26288
    /// Only owner can transfer
    OnlyOwnerCanTransfer = 36952
    /// Insufficient balance
    InsufficientBalance = 54615
    /// Invalid points amount
    InvalidPointsAmount = 56239
}

get fun totalSupply(): int257 {
    throw 0;
}

get fun tokenInfo(): TokenMasterTokenData {
    throw 0;
}

get fun exchangeRate(): int257 {
    throw 0;
}

get fun totalPointsRedeemed(): int257 {
    throw 0;
}

get fun isPaused(): bool {
    throw 0;
}

get fun isTransferEnabled(): bool {
    throw 0;
}

get fun isWhitelisted(address: address): bool {
    throw 0;
}

get fun vestingParams(): TokenMasterVestingData {
    throw 0;
}

get fun walletAddress(owner: address): address {
    throw 0;
}

get fun calculateVestedPercentage(currentTime: int257): int257 {
    throw 0;
}

get fun get_jetton_data(): TokenMasterJettonData {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
