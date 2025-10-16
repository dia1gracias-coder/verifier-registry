// Generated from the verified Tact contract ABI.
contract FixedPriceSwap {
    storage: FixedPriceSwapData
    incomingMessages: FixedPriceSwapIncomingMessage
    thrownErrors: FixedPriceSwapErrors
}

struct (0x946a98b6) FixedPriceSwapDeploy {
    queryId: uint64
}

struct (0x7362d09c) FixedPriceSwapTokenTransferNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0x52ff8164) FixedPriceSwapUpdateTokenXPrice {
    newPrice: uint64
}

struct (0xbecf550e) FixedPriceSwapUpdateTonPrice {
    newPrice: uint64
}

struct (0xa47272ba) FixedPriceSwapSetTokenXWallet {
    wallet: address
}

struct (0x36102395) FixedPriceSwapSetUSDTWallet {
    wallet: address
}

struct (0xe94ce48e) FixedPriceSwapDepositTon {
    amount: coins
}

struct (0xfabed8e6) FixedPriceSwapWithdrawTon {
    amount: coins
}

struct (0xaa9bbfc8) FixedPriceSwapWithdrawTokenX {
    amount: coins
}

struct (0x494dcf46) FixedPriceSwapWithdrawUSDT {
    amount: coins
}

struct FixedPriceSwapData {
    tactDeploymentCompleted: bool
    owner: address
    tokenXPriceUSDT: uint64
    tonPriceUSDT: uint64
    tokenXWallet: address?
    usdtWallet: address?
    tactContinuation: Cell<FixedPriceSwapDataContinuation>
}

struct FixedPriceSwapDataContinuation {
    tonReserve: coins
}

type FixedPriceSwapIncomingMessage =
    | FixedPriceSwapDepositTon
    | FixedPriceSwapTokenTransferNotification
    | FixedPriceSwapUpdateTokenXPrice
    | FixedPriceSwapUpdateTonPrice
    | FixedPriceSwapSetTokenXWallet
    | FixedPriceSwapSetUSDTWallet
    | FixedPriceSwapWithdrawTon
    | FixedPriceSwapWithdrawTokenX
    | FixedPriceSwapWithdrawUSDT
    | FixedPriceSwapDeploy

enum FixedPriceSwapErrors {
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
    /// Insufficient reserve
    InsufficientReserve = 16323
    /// USDT wallet not set
    USDTWalletNotSet = 18843
    /// Minimum 0.1 TON required
    Minimum01TONRequired = 34367
    /// Insufficient TON reserve
    InsufficientTONReserve = 37192
    /// TokenX wallet not set
    TokenXWalletNotSet = 47808
    /// Price must be positive
    PriceMustBePositive = 59099
}

get fun tokenXPrice(): int257 {
    throw 0;
}

get fun tonPrice(): int257 {
    throw 0;
}

get fun tokenXWalletAddress(): address? {
    throw 0;
}

get fun usdtWalletAddress(): address? {
    throw 0;
}

get fun tonReserveAmount(): int257 {
    throw 0;
}

get fun calculateTonToTokenX(tonAmount: int257): int257 {
    throw 0;
}

get fun calculateTokenXToTon(tokenXAmount: int257): int257 {
    throw 0;
}

get fun calculateTokenXToUSDT(tokenXAmount: int257): int257 {
    throw 0;
}

get fun calculateUSDTToTokenX(usdtAmount: int257): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
