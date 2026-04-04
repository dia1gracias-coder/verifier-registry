// Generated from the verified Tact contract ABI.
contract TokenAccount {
    storage: TokenAccountData
    incomingMessages: TokenAccountIncomingMessage
    thrownErrors: TokenAccountErrors
}

struct (0x9a8ec272) TokenAccountAccountCredit {
    requestId: uint64
    quantity: coins
    sourceHolder: address
    cashbackTo: address
    tonForNotify: coins
}

struct (0x6d01af63) TokenAccountAccountTransfer {
    requestId: uint64
    quantity: coins
    recipient: address
    cashbackTo: address
    tonForNotify: coins
}

struct (0xe6d7b6d5) TokenAccountAccountBurn {
    requestId: uint64
    quantity: coins
    cashbackTo: address
}

struct TokenAccountData {
    tactDeploymentCompleted: bool
    tokenBalance: coins
    accountOwner: address
    masterAddress: address
}

type TokenAccountIncomingMessage =
    | TokenAccountAccountCredit
    | TokenAccountAccountTransfer
    | TokenAccountAccountBurn

enum TokenAccountErrors {
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
    /// Invalid burn sender
    InvalidBurnSender = 2306
    /// Administrator only
    AdministratorOnly = 20273
    /// Insufficient token balance
    InsufficientTokenBalance = 23911
    /// Unauthorized credit source
    UnauthorizedCreditSource = 28984
    /// Supply underflow
    SupplyUnderflow = 40326
    /// Owner only
    OwnerOnly = 57920
    /// Quantity must be positive
    QuantityMustBePositive = 59272
}

get fun getTokenBalance(): int257 {
    throw 0;
}

get fun getAccountOwner(): address {
    throw 0;
}

get fun getMasterAddress(): address {
    throw 0;
}
