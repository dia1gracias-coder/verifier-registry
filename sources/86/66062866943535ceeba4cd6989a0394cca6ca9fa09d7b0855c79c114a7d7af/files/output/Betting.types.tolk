// Generated from the verified Tact contract ABI.
contract Betting {
    storage: BettingData
    incomingMessages: BettingIncomingMessage
    thrownErrors: BettingErrors
}

struct (0x946a98b6) BettingDeploy {
    queryId: uint64
}

struct (0x7362d09c) BettingTokenNotification {
    query_id: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct BettingRound {
    id: uint256
    token: address
    tokenWallet: address
    minBetAmount: coins
    tactContinuation: Cell<BettingRoundContinuation>
}

struct BettingRoundContinuation {
    rewardBaseCalAmount: coins
    rewardAmount: coins
    result: uint8
    startTimestamp: uint64
    lockTimestamp: uint64
    closeTimestamp: uint64
    owner: address
}

struct BettingRoundTotal {
    totalAmount: coins
    aAmount: coins
    bAmount: coins
}

struct BettingRoundFee {
    platformFeeAmount: coins
    bankerFeeAmount: coins
    isBonus: bool
}

struct BettingBetInfo {
    result: uint8
    amount: coins
    claimed: bool
}

struct (0x59d1da89) BettingSetTokenWallet {
    token: address
    tokenWallet: address?
}

struct (0x783858d1) BettingSetRound {
    id: uint256
    result: uint8
    forward_ton_amount: coins
}

struct (0x30979496) BettingSetFee {
    platformFee: int257
    platformBonusFee: int257
    bankerFee: int257
    tactContinuation: Cell<BettingSetFeeContinuation>
}

struct BettingSetFeeContinuation {
    bankerBonusFee: int257
    platformFeeAddress: address
    platformFeeBonusAddress: address
}

struct (0xab812cd2) BettingClaim {
    id: uint256
    reward: coins
}

struct (0x00d44bab) BettingRetriveToken {
    tokenWallet: address?
    amount: coins
    to: address
}

struct BettingData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    platformFee: int257
    bankerFee: int257
    tactContinuation: Cell<BettingDataContinuation>
}

struct BettingDataContinuation {
    platformBonusFee: int257
    bankerBonusFee: int257
    platformFeeAddress: address
    tactContinuation: Cell<BettingDataContinuation2>
}

struct BettingDataContinuation2 {
    platformFeeBonusAddress: address
    publicPrice: int257
    currentRound: uint256
    rounds: map<int257, Cell<BettingRound>>
    roundFees: map<int257, Cell<BettingRoundFee>>
    roundTotals: map<int257, Cell<BettingRoundTotal>>
    tactContinuation: Cell<BettingDataContinuation3>
}

struct BettingDataContinuation3 {
    betInfos: map<int257, Cell<BettingBetInfo>>
    tokenMapWallet: map<address, address>
    walletMapToken: map<address, address>
}

type BettingIncomingMessage =
    | BettingSetTokenWallet
    | BettingSetFee
    | BettingTokenNotification
    | BettingSetRound
    | BettingClaim
    | BettingRetriveToken
    | BettingDeploy

enum BettingErrors {
    /// Stack undeflow
    StackUndeflow = 2
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
    /// Round not bettable
    RoundNotBettable = 6022
    /// Bet amount error!
    BetAmountError = 9567
    /// NewRound amount error!
    NewRoundAmountError = 10589
    /// Not eligible for refund
    NotEligibleForRefund = 13496
    /// Invalid round!
    InvalidRound = 18741
    /// Round has not started
    RoundHasNotStarted = 20518
    /// Can only bet once per round
    CanOnlyBetOncePerRound = 22648
    /// Rewards calculated
    RewardsCalculated = 29819
    /// Invalid result!
    InvalidResult = 31724
    /// Round already set
    RoundAlreadySet = 32652
    /// Only owner!
    OnlyOwner = 36880
    /// Round has not ended
    RoundHasNotEnded = 37001
    /// Already claimed
    AlreadyClaimed = 42504
    /// Invalid sender!
    InvalidSender = 42708
    /// Invalid token!
    InvalidToken = 48390
    /// Not eligible for claim
    NotEligibleForClaim = 60596
}

get fun current_round(): int257 {
    throw 0;
}

get fun current_time(): int257 {
    throw 0;
}

get fun user_bet_info(id: int257, user: address): BettingBetInfo? {
    throw 0;
}

get fun get_round(id: int257): BettingRound? {
    throw 0;
}

get fun get_round_fee(id: int257): BettingRoundFee? {
    throw 0;
}

get fun get_round_total(id: int257): BettingRoundTotal? {
    throw 0;
}

get fun get_public_price(): int257 {
    throw 0;
}
