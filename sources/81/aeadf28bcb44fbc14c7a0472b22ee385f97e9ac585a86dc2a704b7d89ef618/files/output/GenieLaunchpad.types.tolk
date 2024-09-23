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

struct (0x5e4f8100) GenieLaunchpadWithdrawToken {
    _tokenAmount: coins
    _token: address
}

struct (0xa4ea90c6) GenieLaunchpadICOJetton {
    _token: address
}

struct (0x1ee9162a) GenieLaunchpadClaim {
    _token: address
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
    ICOTokenJetton: address
    owner: address
    tactContinuation: Cell<GenieLaunchpadDataContinuation3>
}

struct GenieLaunchpadDataContinuation3 {
    totalRaised: uint256
    totalParticipants: uint32
    maxCap: uint256
    minBuy: uint256
    tactContinuation: Cell<GenieLaunchpadDataContinuation4>
}

struct GenieLaunchpadDataContinuation4 {
    maxBuy: uint256
    tokenPrice: uint256
    userDetails: map<address, Cell<GenieLaunchpadUser>>
    stopped: bool
}

type GenieLaunchpadIncomingMessage =
    | GenieLaunchpadUpdateVestingSchedules
    | GenieLaunchpadICOJetton
    | GenieLaunchpadClaim
    | GenieLaunchpadWithdrawToken
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
    /// AMOUNT_INVALID
    AMOUNTINVALID = 9697
    /// Contribution amount must be at least minBuy amount
    ContributionAmountMustBeAtLeastMinBuyAmount = 12650
    /// Amount must greater than zero
    AmountMustGreaterThanZero = 16022
    /// Vesting Already Started
    VestingAlreadyStarted = 22463
    /// Only owner is allowed to withdraw
    OnlyOwnerIsAllowedToWithdraw = 27921
    /// Please Try Again
    PleaseTryAgain = 29958
    /// Contract stopped
    ContractStopped2 = 40368
    /// Sale still active
    SaleStillActive = 41108
    /// Sale not started yet
    SaleNotStartedYet = 42973
    /// Invalid max cap or token price
    InvalidMaxCapOrTokenPrice = 52983
    /// Contract not stopped
    ContractNotStopped = 53296
    /// Sale Ended
    SaleEnded = 56378
    /// Contribution amount exceeds the maximum allowed amount.
    ContributionAmountExceedsTheMaximumAllowedAmount = 61288
    /// Total contribution amount would exceed the campaign's maximum cap.
    TotalContributionAmountWouldExceedTheCampaignSMaximumCap = 63312
}

get fun calculateUnlockedToken(_wallet: address): int257 {
    throw 0;
}

get fun userDetails(_address: address): GenieLaunchpadUser {
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

get fun jettonAddress(): address {
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

get fun owner(): address {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}
