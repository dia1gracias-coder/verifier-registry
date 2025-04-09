// Generated from the verified Tact contract ABI.
contract ICOMarketplace {
    storage: ICOMarketplaceData
    incomingMessages: ICOMarketplaceIncomingMessage
    thrownErrors: ICOMarketplaceErrors
}

struct (0x946a98b6) ICOMarketplaceDeploy {
    queryId: uint64
}

struct ICOMarketplaceTokenDetails {
    token: address
    supported: bool
    price: int257
    creator: address
    name: string
    symbol: string
}

struct (0x00000001) ICOMarketplaceCreateICOSale {
    token: address
    price: int257
}

struct (0x00000002) ICOMarketplaceBuyToken {
    token: address
    amount: int257
}

struct (0x00000003) ICOMarketplaceWithdrawToken {
    token: address
    amount: int257
}

struct (0x00000004) ICOMarketplaceTransferTON {
    to: address
    amount: coins
}

struct ICOMarketplaceData {
    tactDeploymentCompleted: bool
    owner: address
    tokenDetails: map<address, Cell<ICOMarketplaceTokenDetails>>
    allSupportedTokens: map<int257, address>
    tokensCount: uint32
}

type ICOMarketplaceIncomingMessage =
    | ICOMarketplaceCreateICOSale
    | ICOMarketplaceBuyToken
    | ICOMarketplaceWithdrawToken
    | ICOMarketplaceTransferTON
    | ICOMarketplaceDeploy

enum ICOMarketplaceErrors {
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
    /// Incorrect TON amount sent
    IncorrectTONAmountSent = 9845
    /// Multiplication overflow
    MultiplicationOverflow = 16330
    /// Token not supported
    TokenNotSupported = 19036
    /// Insufficient token balance
    InsufficientTokenBalance = 23911
    /// Amount must be greater than 0
    AmountMustBeGreaterThan0 = 40476
    /// Token does not exist
    TokenDoesNotExist = 44722
    /// Not token creator
    NotTokenCreator = 56609
    /// Contract does not accept TON directly
    ContractDoesNotAcceptTONDirectly = 58325
    /// Insufficient funds sent
    InsufficientFundsSent = 58383
}

get fun getBalance(token: address): int257 {
    throw 0;
}

get fun getSupportedTokens(): map<int257, address> {
    throw 0;
}

get fun getTokenDetails(token: address): ICOMarketplaceTokenDetails {
    throw 0;
}

get fun getTokensCreatedBy(creator: address): map<int257, Cell<ICOMarketplaceTokenDetails>> {
    throw 0;
}

get fun getAllTokens(): map<int257, Cell<ICOMarketplaceTokenDetails>> {
    throw 0;
}
