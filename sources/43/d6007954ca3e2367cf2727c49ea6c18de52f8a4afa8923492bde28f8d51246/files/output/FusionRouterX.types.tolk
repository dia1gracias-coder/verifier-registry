// Generated from the verified Tact contract ABI.
contract FusionRouterX {
    storage: FusionRouterXData
    incomingMessages: FusionRouterXIncomingMessage
    thrownErrors: FusionRouterXErrors
}

struct FusionRouterXNftData {
    deployed: bool
    index: int257
    collection: slice
    owner: slice
    content: cell
}

struct (0x7362d09c) FusionRouterXTransferNotification {
    query_id: uint64
    amount: coins
    sender: address
    forward_payload: RemainingBitsAndRefs
}

struct FusionRouterXHoneypot {
    address: address
    amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0xabcdef13) FusionRouterXClaim {
    query_id: uint64
    honeypots: map<int257, Cell<FusionRouterXHoneypot>>
    forward_payload: RemainingBitsAndRefs
}

struct (0xabcd3f13) FusionRouterXDeposit {
    query_id: uint64
}

struct (0xabcd2f13) FusionRouterXWithdraw {
    query_id: uint64
    amount: coins
}

struct (0xabcd1f13) FusionRouterXWithdrawAll {
    query_id: uint64
}

struct (0xabcd0f13) FusionRouterXWithdrawTokens {
    query_id: uint64
    amount: coins
    token_wallet: address
    forward_payload: RemainingBitsAndRefs
}

struct FusionRouterXData {
    tactDeploymentCompleted: bool
    owner: address
    authorizedPublicKey: int257
    obfPublicKey: int257
}

type FusionRouterXIncomingMessage =
    | FusionRouterXDeposit
    | FusionRouterXWithdraw
    | FusionRouterXWithdrawAll
    | FusionRouterXWithdrawTokens
    | FusionRouterXClaim
    | FusionRouterXTransferNotification

enum FusionRouterXErrors {
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
    /// Forbidden resource
    ForbiddenResource = 12186
    /// Insufficient funds after withdrawal
    InsufficientFundsAfterWithdrawal = 14705
    /// Not enough balance for owner transfer
    NotEnoughBalanceForOwnerTransfer = 44630
    /// Insufficient funds to maintain minimum balance
    InsufficientFundsToMaintainMinimumBalance = 48950
    /// Insufficient funds
    InsufficientFunds = 51754
}

get fun get_nft_data(): FusionRouterXNftData {
    throw 0;
}
