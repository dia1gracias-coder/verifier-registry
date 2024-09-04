// Generated from the verified Tact contract ABI.
contract GenieLaunchpad {
    storage: GenieLaunchpadData
    incomingMessages: GenieLaunchpadIncomingMessage
    thrownErrors: GenieLaunchpadErrors
}

struct (0xe8414b30) GenieLaunchpadUpdateVestingSchedules {
    _vestingStartTime: uint256
    _vestingDuration: uint256
    _vestingInterval: uint256
    tactContinuation: Cell<GenieLaunchpadUpdateVestingSchedulesContinuation>
}

struct GenieLaunchpadUpdateVestingSchedulesContinuation {
    _cliffDuration: uint256
    _cliffPercentage: uint256
}

struct (0x7c5349a2) GenieLaunchpadDepositTokens {
    _amount: uint256
    _depositToken: address
}

struct (0x9cb36587) GenieLaunchpadWithdrawToken {
    _tokenAmount: uint256
    _token: address
}

struct (0xc57352da) GenieLaunchpadAddToken {
    tokenAmount: uint256
}

struct GenieLaunchpadUser {
    investedAmount: uint256
    claimedTokens: uint256
    investedTimestamp: uint256
    tactContinuation: Cell<GenieLaunchpadUserContinuation>
}

struct GenieLaunchpadUserContinuation {
    lastClaimedTimestamp: uint256
}

struct (0x946a98b6) GenieLaunchpadDeploy {
    queryId: uint64
}

struct (0x819dbe99) GenieLaunchpadChangeOwner {
    queryId: uint64
    newOwner: address
}

struct GenieLaunchpadData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    cliffDuration: uint256
    vestingStartTime: uint256
    vestingDuration: uint256
    tactContinuation: Cell<GenieLaunchpadDataContinuation>
}

struct GenieLaunchpadDataContinuation {
    vestingInterval: uint256
    cliffPercentage: uint32
    projectName: string
    projectStartTime: uint256
    projectEndTime: uint256
    tactContinuation: Cell<GenieLaunchpadDataContinuation2>
}

struct GenieLaunchpadDataContinuation2 {
    ICOToken: address
    owner: address
    totalRaised: uint256
    totalParticipants: uint32
    tactContinuation: Cell<GenieLaunchpadDataContinuation3>
}

struct GenieLaunchpadDataContinuation3 {
    maxCap: uint256
    minBuy: uint256
    maxBuy: uint256
    tactContinuation: Cell<GenieLaunchpadDataContinuation4>
}

struct GenieLaunchpadDataContinuation4 {
    tokenPrice: uint256
    userDetails: map<address, Cell<GenieLaunchpadUser>>
    investmentToken: address
    stopped: bool
}

type GenieLaunchpadIncomingMessage =
    | GenieLaunchpadUpdateVestingSchedules
    | GenieLaunchpadDepositTokens
    | GenieLaunchpadWithdrawToken
    | GenieLaunchpadAddToken
    | GenieLaunchpadDeploy
    | GenieLaunchpadChangeOwner

enum GenieLaunchpadErrors {
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
    /// Vesting Timestamp is greater than project end time
    VestingTimestampIsGreaterThanProjectEndTime = 1465
    /// No tokens to claim
    NoTokensToClaim = 2639
    /// Not mintable
    NotMintable = 3688
    /// Invalid value!!
    InvalidValue = 4159
    /// Invalid sender
    InvalidSender = 4429
    /// Max supply exceeded
    MaxSupplyExceeded = 12241
    /// Contribution amount must be at least minBuy amount
    ContributionAmountMustBeAtLeastMinBuyAmount = 12650
    /// Not owner
    NotOwner = 14534
    /// Amount must greater than zero
    AmountMustGreaterThanZero = 16022
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Vesting Already Started
    VestingAlreadyStarted = 22463
    /// Insufficient gas
    InsufficientGas = 23951
    /// Contract stopped
    ContractStopped2 = 40368
    /// Sale still active
    SaleStillActive = 41108
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Sale not started yet
    SaleNotStartedYet = 42973
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// Invalid max cap or token price
    InvalidMaxCapOrTokenPrice = 52983
    /// Contract not stopped
    ContractNotStopped = 53296
    /// Invalid start or end timestamp.
    InvalidStartOrEndTimestamp = 54256
    /// Sale Ended
    SaleEnded = 56378
    /// Amount must be positive
    AmountMustBePositive = 61135
    /// Contribution amount exceeds the maximum allowed amount.
    ContributionAmountExceedsTheMaximumAllowedAmount = 61288
    /// We can only use investmentToken or USDC for trade
    WeCanOnlyUseInvestmentTokenOrUSDCForTrade = 61602
    /// Invalid balance
    InvalidBalance = 62972
    /// Total contribution amount would exceed the campaign's maximum cap.
    TotalContributionAmountWouldExceedTheCampaignSMaximumCap = 63312
}

get fun calculateUnlockedToken(_wallet: address): int257 {
    throw 0;
}

get fun userDetails(_address: address): GenieLaunchpadUser? {
    throw 0;
}

get fun cliffDuration(): int257 {
    throw 0;
}

get fun vestingStartTime(): int257 {
    throw 0;
}

get fun vestingDuration(): int257 {
    throw 0;
}

get fun vestingInterval(): int257 {
    throw 0;
}

get fun cliffPercentage(): int257 {
    throw 0;
}

get fun projectName(): string {
    throw 0;
}

get fun projectStartTime(): int257 {
    throw 0;
}

get fun projectEndTime(): int257 {
    throw 0;
}

get fun ICOToken(): address {
    throw 0;
}

get fun totalRaised(): int257 {
    throw 0;
}

get fun totalParticipants(): int257 {
    throw 0;
}

get fun maxCap(): int257 {
    throw 0;
}

get fun minBuy(): int257 {
    throw 0;
}

get fun maxBuy(): int257 {
    throw 0;
}

get fun tokenPrice(): int257 {
    throw 0;
}

get fun investmentToken(): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}
