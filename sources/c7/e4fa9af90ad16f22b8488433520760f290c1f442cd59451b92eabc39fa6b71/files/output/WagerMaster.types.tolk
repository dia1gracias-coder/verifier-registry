// Generated from the verified Tact contract ABI.
contract WagerMaster {
    storage: WagerMasterData
    incomingMessages: WagerMasterIncomingMessage
    thrownErrors: WagerMasterErrors
}

struct (0x906b8ecf) WagerMasterCreateWager {
    deadline: uint32
    description: string
}

struct (0xc2e71f30) WagerMasterSetWagerResult {
    wagerId: uint256
    result: bool
}

struct (0x0dfbff59) WagerMasterAddJuror {
    jurorAddress: address
}

struct (0x8283c7bc) WagerMasterRequestNewJurors {
    wagerId: uint256
}

struct WagerMasterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    nextWagerId: uint256
    wagerCreatorFee: uint16
    platformFee: uint16
    wagers: map<int257, address>
    usdtMasterAddress: address
    tactContinuation: Cell<WagerMasterDataContinuation>
}

struct WagerMasterDataContinuation {
    jettonWalletCode: cell
    jury: map<int257, address>
    nextJurorId: uint32
}

type WagerMasterIncomingMessage =
    | WagerMasterCreateWager
    | WagerMasterSetWagerResult
    | WagerMasterAddJuror
    | WagerMasterRequestNewJurors

enum WagerMasterErrors {
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
    /// Only assigned juror can vote
    OnlyAssignedJurorCanVote = 1476
    /// Invalid USDT wallet
    InvalidUSDTWallet = 2174
    /// Only master can set new jurors
    OnlyMasterCanSetNewJurors = 2358
    /// Cannot set result before deadline
    CannotSetResultBeforeDeadline = 5227
    /// Result not set yet
    ResultNotSetYet = 16236
    /// Voting period has ended
    VotingPeriodHasEnded = 16262
    /// No winnings to claim
    NoWinningsToClaim = 23939
    /// Only owner can add jurors
    OnlyOwnerCanAddJurors = 28799
    /// Only owner can set wager result
    OnlyOwnerCanSetWagerResult = 34426
    /// Cannot set juror vote before deadline
    CannotSetJurorVoteBeforeDeadline = 35391
    /// Invalid wager ID
    InvalidWagerID = 35511
    /// Vote amount must be greater than 0
    VoteAmountMustBeGreaterThan0 = 36642
    /// Result already set
    ResultAlreadySet = 50762
    /// Cannot set result when jurors are present and within 24 hours of deadline
    CannotSetResultWhenJurorsArePresentAndWithin24HoursOfDeadline = 52726
    /// Only wager contract can request new jurors
    OnlyWagerContractCanRequestNewJurors = 53262
    /// Cannot claim before deadline
    CannotClaimBeforeDeadline = 53448
    /// Juror has already voted
    JurorHasAlreadyVoted = 58612
    /// Only master can set result
    OnlyMasterCanSetResult = 63988
}

get fun getWagerAddress(wagerId: int257): address {
    throw 0;
}

get fun getJurySize(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
