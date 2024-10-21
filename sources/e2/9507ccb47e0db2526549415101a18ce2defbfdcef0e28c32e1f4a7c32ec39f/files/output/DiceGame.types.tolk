// Generated from the verified Tact contract ABI.
contract DiceGame {
    storage: DiceGameData
    incomingMessages: DiceGameIncomingMessage
    thrownErrors: DiceGameErrors
}

struct (0x946a98b6) DiceGameDeploy {
    queryId: uint64
}

struct (0xd36ad20c) DiceGameDepositToPool {
}

struct (0x4dbc1282) DiceGameWithdrawFromPool {
    amount: int257
}

struct (0xac16476e) DiceGamePlaceBet {
    choice: bool
}

struct (0x07ff9739) DiceGameSetAdmin {
    admin: address
    active: bool
}

struct (0x8906fd61) DiceGameSetFeePercent {
    percent: int257
}

struct (0x9f68372f) DiceGameSetMaxBet {
    amount: int257
}

struct DiceGameData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    admin: map<address, bool>
    publicKey: int257?
    feePercent: int257
    tactContinuation: Cell<DiceGameDataContinuation>
}

struct DiceGameDataContinuation {
    maxBet: int257
}

type DiceGameIncomingMessage =
    | DiceGameDepositToPool
    | DiceGameWithdrawFromPool
    | DiceGamePlaceBet
    | DiceGameSetAdmin
    | DiceGameSetFeePercent
    | DiceGameSetMaxBet
    | DiceGameDeploy

enum DiceGameErrors {
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
    /// Bet amount must be between 1 and 10 TON
    BetAmountMustBeBetween1And10TON = 13449
    /// Max bet amount must be greater than 0
    MaxBetAmountMustBeGreaterThan0 = 23144
    /// Deposit amount must be greater than 0
    DepositAmountMustBeGreaterThan0 = 40128
    /// Invalid withdraw amount
    InvalidWithdrawAmount = 46439
    /// Fee percent must be between 0 and 1000
    FeePercentMustBeBetween0And1000 = 57490
    /// Only the owner or admin can call this function
    OnlyTheOwnerOrAdminCanCallThisFunction = 58319
}

get fun isAdmin(address: address): bool {
    throw 0;
}

get fun poolBalance(): int257 {
    throw 0;
}

get fun feePercent(): int257 {
    throw 0;
}

get fun maxBet(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
