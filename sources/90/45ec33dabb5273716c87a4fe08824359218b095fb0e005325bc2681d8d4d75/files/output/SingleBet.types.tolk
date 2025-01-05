// Generated from the verified Tact contract ABI.
contract SingleBet {
    storage: SingleBetData
    incomingMessages: SingleBetIncomingMessage
    thrownErrors: SingleBetErrors
}

struct (0x946a98b6) SingleBetDeploy {
    queryId: uint64
}

struct SingleBetBetArray {
    m: map<uint16, Cell<SingleBetBet>>
    length: int257
}

struct (0x7d65bf2f) SingleBetBet {
    user: address
    amount: coins
    coef: uint32
    result: bool
}

struct (0x1d345a53) SingleBetEventBet {
    eventId: uint32
    bet: SingleBetBet
}

struct (0x9484abdf) SingleBetResolveBet {
    eventId: uint32
    result: bool
}

struct (0x224de97e) SingleBetRevokeBet {
    eventId: uint32
    user: address
}

struct (0x0ba69751) SingleBetWithdraw {
    amount: coins
}

struct SingleBetData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    nonce: int257
    owner: address
    activeBets: map<uint64, Cell<SingleBetBetArray>>
}

type SingleBetIncomingMessage =
    | SingleBetWithdraw
    | SingleBetEventBet
    | SingleBetResolveBet
    | SingleBetRevokeBet
    | SingleBetDeploy

enum SingleBetErrors {
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
    /// No items in the array!
    NoItemsInTheArray = 6947
    /// No items in the array to delete!
    NoItemsInTheArrayToDelete = 17848
    /// Index of the item cannot be negative!
    IndexOfTheItemCannotBeNegative = 19333
    /// Not enough balance
    NotEnoughBalance = 22565
    /// Index is out of array bounds!
    IndexIsOutOfArrayBounds = 24006
    /// Only owner can call this function
    OnlyOwnerCanCallThisFunction = 27831
    /// No space in the array left for new items!
    NoSpaceInTheArrayLeftForNewItems = 42469
    /// Not enough balance to pay the win amount
    NotEnoughBalanceToPayTheWinAmount = 53484
}

get fun balance(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun bets(): map<uint64, Cell<SingleBetBetArray>> {
    throw 0;
}
