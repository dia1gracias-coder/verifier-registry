// Generated from the verified Tact contract ABI.
contract Lottery {
    storage: LotteryData
    incomingMessages: LotteryIncomingMessage
    thrownErrors: LotteryErrors
}

struct (0x946a98b6) LotteryDeploy {
    queryId: uint64
}

struct (0x156da0a2) LotteryTokenPayout {
    value: coins
}

struct LotteryTokenPayoutResponse {
    token: string
}

struct LotteryWinner {
    value: coins
    token: int257
    address: address
}

struct LotteryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    winner: LotteryWinner
    owner: address
    tactContinuation: Cell<LotteryDataContinuation>
}

struct LotteryDataContinuation {
    balance: uint256
    tokenCost: uint256
    usersToken: map<address, Cell<LotteryTokenPayoutResponse>>
    tokensUser: map<int257, address>
    tokensIndex: map<int257, int257>
    tokenArrayLength: int257
}

type LotteryIncomingMessage =
    | LotteryTokenPayout
    | LotteryDeploy

enum LotteryErrors {
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
    /// winner not found
    WinnerNotFound = 5352
    /// Owner only access to run the game!
    OwnerOnlyAccessToRunTheGame = 21842
    /// Each token price is 1 ton
    EachTokenPriceIs1Ton = 57066
}

get fun totalBalance(): int257 {
    throw 0;
}

get fun getUserTokens(): map<address, Cell<LotteryTokenPayoutResponse>> {
    throw 0;
}

get fun getLastwinner(): LotteryWinner {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
