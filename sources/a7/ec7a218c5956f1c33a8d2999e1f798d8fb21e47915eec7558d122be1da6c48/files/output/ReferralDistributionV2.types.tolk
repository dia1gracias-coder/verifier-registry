// Generated from the verified Tact contract ABI.
contract ReferralDistributionV2 {
    storage: ReferralDistributionV2Data
    incomingMessages: ReferralDistributionV2IncomingMessage
    thrownErrors: ReferralDistributionV2Errors
}

struct (0x946a98b6) ReferralDistributionV2Deploy {
    queryId: uint64
}

struct (0x819dbe99) ReferralDistributionV2ChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0xeeb1661e) ReferralDistributionV2ReferralPer {
    rank: int257
    percentage: int257
}

struct (0x6ac977d6) ReferralDistributionV2UpdateTreasuryAddress {
    treasuryAddress: address
}

struct (0x54ed62e4) ReferralDistributionV2UpdateGovnAddress {
    govnAddress: address
}

struct (0x9f347503) ReferralDistributionV2UpdateRewardPoolAddress {
    rewardPoolAddress: address
}

struct (0xdc827d1f) ReferralDistributionV2UpdateVaultAddress {
    vaultAddress: address
}

struct (0xefe5d5a0) ReferralDistributionV2BuyPet {
    userId: string
    amount: coins
    petConfigId: string
}

struct (0x808e6e06) ReferralDistributionV2Distribution {
    amount: coins
    transactionId: int257
    referralOneAddress: address?
    referralOneCommissionRate: int257?
    tactContinuation: Cell<ReferralDistributionV2DistributionContinuation>
}

struct ReferralDistributionV2DistributionContinuation {
    referralTwoAddress: address?
    referralTwoCommissionRate: int257?
    referralThreeAddress: address?
    tactContinuation: Cell<ReferralDistributionV2DistributionContinuation2>
}

struct ReferralDistributionV2DistributionContinuation2 {
    referralThreeCommissionRate: int257?
    referralFourAddress: address?
    referralFourCommissionRate: int257?
    tactContinuation: Cell<ReferralDistributionV2DistributionContinuation3>
}

struct ReferralDistributionV2DistributionContinuation3 {
    referralFiveAddress: address?
    referralFiveCommissionRate: int257?
}

struct (0xf16b8c67) ReferralDistributionV2OwnerWithdraw {
    amount: coins
}

struct (0xdda1447b) ReferralDistributionV2BuyUtils {
    opCode: int257
    userId: string
}

struct (0x3b6c2da0) ReferralDistributionV2Deposit {
    userId: string
    amount: coins
}

struct (0xa5edef7a) ReferralDistributionV2Withdraw {
    userId: string
    withdrawId: string
    transferTo: address
    amount: coins
}

struct (0x919923ed) ReferralDistributionV2UpdateMinDepositAmount {
    amount: coins
}

struct (0x63249161) ReferralDistributionV2UpdateUtils {
    opCode: int257
    utilsSetting: ReferralDistributionV2UtilsSetting
}

struct ReferralDistributionV2UtilsSetting {
    name: string
    amount: coins
    enabled: bool
    transferTo: address
}

struct ReferralDistributionV2Data {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    govnAddress: address
    treasuryAddress: address
    tactContinuation: Cell<ReferralDistributionV2DataContinuation>
}

struct ReferralDistributionV2DataContinuation {
    rewardPoolAddress: address
    vaultAddress: address
    minDepositAmount: int257
    stopped: bool
    referralPer: map<int257, int257>
    utilsMap: map<int257, Cell<ReferralDistributionV2UtilsSetting>>
}

type ReferralDistributionV2IncomingMessage =
    | ReferralDistributionV2ReferralPer
    | ReferralDistributionV2UpdateUtils
    | ReferralDistributionV2UpdateTreasuryAddress
    | ReferralDistributionV2UpdateGovnAddress
    | ReferralDistributionV2UpdateRewardPoolAddress
    | ReferralDistributionV2UpdateVaultAddress
    | ReferralDistributionV2UpdateMinDepositAmount
    | ReferralDistributionV2Deposit
    | ReferralDistributionV2Withdraw
    | ReferralDistributionV2BuyPet
    | ReferralDistributionV2BuyUtils
    | ReferralDistributionV2Distribution
    | ReferralDistributionV2OwnerWithdraw
    | ReferralDistributionV2Deploy
    | ReferralDistributionV2ChangeOwner

enum ReferralDistributionV2Errors {
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
    /// Total Percentage >= 100
    TotalPercentage100 = 2845
    /// Only govn address can call this function
    OnlyGovnAddressCanCallThisFunction = 5749
    /// Rank not available
    RankNotAvailable = 20131
    /// Contract stopped
    ContractStopped2 = 40368
    /// No utils found
    NoUtilsFound = 42468
    /// Insufficient Amount
    InsufficientAmount = 45436
    /// Contract not stopped
    ContractNotStopped = 53296
    /// Insufficient balance
    InsufficientBalance = 54615
    /// Amount Less Than Min Deposit Amount
    AmountLessThanMinDepositAmount = 60756
    /// Utils is not enabled
    UtilsIsNotEnabled = 62365
}

get fun referralPer(key: int257): int257 {
    throw 0;
}

get fun utilsMap(key: int257): ReferralDistributionV2UtilsSetting? {
    throw 0;
}

get fun treasuryAddress(): address {
    throw 0;
}

get fun govnAddress(): address {
    throw 0;
}

get fun rewardPoolAddress(): address {
    throw 0;
}

get fun vaultAddress(): address {
    throw 0;
}

get fun minDepositAmount(): int257 {
    throw 0;
}

get fun currentBalance(): int257 {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
