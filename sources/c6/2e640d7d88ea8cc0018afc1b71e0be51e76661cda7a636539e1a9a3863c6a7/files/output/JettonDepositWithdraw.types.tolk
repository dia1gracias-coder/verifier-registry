// Generated from the verified Tact contract ABI.
contract JettonDepositWithdraw {
    storage: JettonDepositWithdrawData
    incomingMessages: JettonDepositWithdrawIncomingMessage
    thrownErrors: JettonDepositWithdrawErrors
}

struct (0x946a98b6) JettonDepositWithdrawDeploy {
    queryId: uint64
}

struct JettonDepositWithdrawUserBalances {
    balances: map<address, int257>
}

struct (0x7362d09c) JettonDepositWithdrawTokenNotification {
    queryId: uint64
    amount: coins
    from: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0xf925afce) JettonDepositWithdrawWithdrawRequest {
    jetton_master: address
    amount: coins
}

struct JettonDepositWithdrawData {
    tactDeploymentCompleted: bool
    owner: address
    jetton_wallets: map<address, address>
    tactContinuation: Cell<JettonDepositWithdrawDataContinuation>
}

struct JettonDepositWithdrawDataContinuation {
    deposits: map<address, Cell<JettonDepositWithdrawUserBalances>>
    total_deposited: map<address, int257>
}

type JettonDepositWithdrawIncomingMessage =
    | JettonDepositWithdrawTokenNotification
    | JettonDepositWithdrawWithdrawRequest
    | JettonDepositWithdrawDeploy

enum JettonDepositWithdrawErrors {
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
    /// Jetton wallet not set for this token
    JettonWalletNotSetForThisToken = 3553
    /// Invalid sender: not from Jetton wallet
    InvalidSenderNotFromJettonWallet = 9747
    /// Invalid query ID
    InvalidQueryID = 16264
    /// Only owner can withdraw
    OnlyOwnerCanWithdraw = 26825
    /// Withdraw amount must be positive
    WithdrawAmountMustBePositive = 33847
    /// Jetton wallet already set
    JettonWalletAlreadySet = 49291
    /// Only owner can set Jetton wallet
    OnlyOwnerCanSetJettonWallet = 49694
    /// Insufficient balance
    InsufficientBalance = 54615
    /// Amount must be positive
    AmountMustBePositive = 61135
}

get fun get_balance(jetton_master: address, user: address): int257 {
    throw 0;
}

get fun get_total_deposited(jetton_master: address): int257 {
    throw 0;
}

get fun get_jetton_wallet(jetton_master: address): address? {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
