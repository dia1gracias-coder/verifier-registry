// Generated from the verified Tact contract ABI.
contract lottery {
    storage: lotteryData
    incomingMessages: lotteryIncomingMessage
    thrownErrors: lotteryErrors
}

struct (0x946a98b6) lotteryDeploy {
    queryId: uint64
}

struct (0x156da0a2) lotteryTokenPayout {
    value: coins
}

struct lotteryTokenPayoutResponse {
    token: string
}

struct lotteryWinner {
    value: coins
    token: int257
    address: address
}

struct lotteryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    winner: lotteryWinner
    owner: address
    tactContinuation: Cell<lotteryDataContinuation>
}

struct lotteryDataContinuation {
    balance: uint256
    tokenCost: uint256
    usersToken: map<address, Cell<lotteryTokenPayoutResponse>>
    tokensUser: map<int257, address>
    tokensIndex: map<int257, int257>
    tokenArrayLength: int257
    prizeClaimed: bool
}

type lotteryIncomingMessage =
    | lotteryTokenPayout
    | lotteryDeploy

enum lotteryErrors {
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
    /// Out of gas error
    OutOfGasError = 13
    /// Method ID not found
    MethodIDNotFound = 32
    /// Action is invalid or not supported
    ActionIsInvalidOrNotSupported = 34
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
    NotEnoughExtraCurrencies = 38
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
    /// Insufficient funds for token purchase
    InsufficientFundsForTokenPurchase = 12296
    /// Owner only access to run the game!
    OwnerOnlyAccessToRunTheGame = 21842
    /// Only the winner can claim the prize
    OnlyTheWinnerCanClaimThePrize = 24768
    /// No active prize to claim
    NoActivePrizeToClaim = 47682
    /// Prize has already been claimed
    PrizeHasAlreadyBeenClaimed = 53502
}

get fun totalBalance(): int257 {
    throw 0;
}

get fun getUserTokens(): map<address, Cell<lotteryTokenPayoutResponse>> {
    throw 0;
}

get fun getLastwinner(): lotteryWinner {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
