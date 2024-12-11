// Generated from the verified Tact contract ABI.
contract TonMaze {
    storage: TonMazeData
    incomingMessages: TonMazeIncomingMessage
    thrownErrors: TonMazeErrors
}

struct (0x80ddc17e) TonMazeTokenPurchase {
    queryId: int257
    amount: int257
}

struct (0xc6b0ab2f) TonMazeTokenSale {
    queryId: int257
    amount: int257
}

struct TonMazeData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    TonToMazeRate: int257
    MazeToTonRate: int257
    balance: int257
    tactContinuation: Cell<TonMazeDataContinuation>
}

struct TonMazeDataContinuation {
    owner: address
    master: address
}

type TonMazeIncomingMessage =
    | TonMazeTokenPurchase
    | TonMazeTokenSale

enum TonMazeErrors {
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
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
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
    /// Invalid address
    InvalidAddress = 136
    /// Masterchain support is not enabled for this contract
    MasterchainSupportIsNotEnabledForThisContract = 137
    /// Insufficient funds for token purchase
    InsufficientFundsForTokenPurchase = 12296
    /// Not enough TON for sale
    NotEnoughTONForSale = 21300
    /// Not enough tokens available
    NotEnoughTokensAvailable = 32030
    /// Only the owner can deposit tokens
    OnlyTheOwnerCanDepositTokens = 36065
    /// Amount must be greater than 0
    AmountMustBeGreaterThan0 = 40476
}
