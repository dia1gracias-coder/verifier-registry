// Generated from the verified Tact contract ABI.
contract TonBetPlayContract {
    storage: TonBetPlayContractData
    incomingMessages: TonBetPlayContractIncomingMessage
    thrownErrors: TonBetPlayContractErrors
}

struct (0x946a98b6) TonBetPlayContractDeploy {
    queryId: uint64
}

struct (0x78b333b4) TonBetPlayContractUserVote {
    timestamp: int257
    value: bool
}

struct (0x78b333b5) TonBetPlayContractUserClaim {
    amount: coins
}

struct (0x78b333b6) TonBetPlayContractSetResult {
    timestamp: int257
    value: bool
}

struct (0x78b333b7) TonBetPlayContractSetConfig {
    mode: int257
}

struct TonBetPlayContractVoteItem {
    value: bool
    amount: coins
    odd: int257
}

struct TonBetPlayContractVote {
    timestamp: int257
    result: bool?
    users: map<address, Cell<TonBetPlayContractVoteItem>>
}

struct TonBetPlayContractOdd {
    odd: int257
    trueAmount: int257
    falseAmount: int257
}

struct TonBetPlayContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    votes: map<int257, Cell<TonBetPlayContractVote>>
    tactContinuation: Cell<TonBetPlayContractDataContinuation>
}

struct TonBetPlayContractDataContinuation {
    odds: map<int257, Cell<TonBetPlayContractOdd>>
    users: map<address, int257>
    threshold: int257
}

type TonBetPlayContractIncomingMessage =
    | TonBetPlayContractUserVote
    | TonBetPlayContractSetConfig
    | TonBetPlayContractUserClaim
    | TonBetPlayContractSetResult
    | TonBetPlayContractDeploy

enum TonBetPlayContractErrors {
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
    /// Expired
    Expired = 17473
    /// Not enough balance
    NotEnoughBalance = 22565
    /// Only owner is allowed to withdraw
    OnlyOwnerIsAllowedToWithdraw = 27921
}

get fun my_vote(user: address): TonBetPlayContractVoteItem? {
    throw 0;
}

get fun my_balance(user: address): int257? {
    throw 0;
}
