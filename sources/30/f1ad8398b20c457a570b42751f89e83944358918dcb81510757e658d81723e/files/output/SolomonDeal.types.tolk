// Generated from the verified Tact contract ABI.
contract SolomonDeal {
    storage: SolomonDealData
    incomingMessages: SolomonDealIncomingMessage
    thrownErrors: SolomonDealErrors
}

struct (0x946a98b6) SolomonDealDeploy {
    queryId: uint64
}

struct (0xb69c688f) SolomonDealMakeDeal {
    id: uint128
    producer: address
    producerResponsibility: coins
    expirationTime: uint64
    amount: coins
    fee: coins
}

struct (0x7caa9f64) SolomonDealJudgeDeal {
    id: uint128
    isProducerFault: bool
}

struct (0xb3db4f18) SolomonDealPayResponsibility {
    id: uint128
}

struct (0x4381bccb) SolomonDealProducerGiveUpDeal {
    id: uint128
}

struct (0x41ddbcc6) SolomonDealConsumerReturnMoneyDueToNotLockedResponsibility {
    id: uint128
}

struct (0x95eda1c3) SolomonDealCompleteTheDeal {
    id: uint128
}

struct (0x6f59f3e5) SolomonDealSystemFailureWithdraw {
    id: uint128
}

struct (0x3df18fa8) SolomonDealChangeMinimalDealAmount {
    minimalDealAmount: coins
}

struct (0x6beab258) SolomonDealChangeFeePart {
    feePart: uint8
}

struct (0xe29d8b8b) SolomonDealChangeSystemFailureFreezeTime {
    systemFailureFreezeTime: uint64
}

struct (0x365f30c7) SolomonDealChangeMinimalContractBalance {
    minimalContractBalance: coins
}

struct SolomonDealDeal {
    id: uint128
    consumer: address
    producer: address
    amount: coins
    producerResponsibility: coins
    expirationTime: uint64
    producerPayed: bool
}

struct SolomonDealData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    judgeSystem: address
    minimalDealAmount: coins
    feePart: uint8
    feeFound: coins
    systemFailureFreezeTime: uint64
    minimalContractBalance: coins
    minimalAdditionAmountForFee: coins
    totalClientMoney: coins
    tactContinuation: Cell<SolomonDealDataContinuation>
}

struct SolomonDealDataContinuation {
    test_var: uint128
    currentDeals: map<int257, Cell<SolomonDealDeal>>
}

type SolomonDealIncomingMessage =
    | SolomonDealMakeDeal
    | SolomonDealCompleteTheDeal
    | SolomonDealPayResponsibility
    | SolomonDealProducerGiveUpDeal
    | SolomonDealConsumerReturnMoneyDueToNotLockedResponsibility
    | SolomonDealJudgeDeal
    | SolomonDealSystemFailureWithdraw
    | SolomonDealChangeMinimalDealAmount
    | SolomonDealChangeFeePart
    | SolomonDealChangeSystemFailureFreezeTime
    | SolomonDealChangeMinimalContractBalance
    | SolomonDealDeploy

enum SolomonDealErrors {
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
    /// Only judge system can change minimal found balance
    OnlyJudgeSystemCanChangeMinimalFoundBalance = 2879
    /// Only judge system can withdraw
    OnlyJudgeSystemCanWithdraw = 3017
    /// Deal is not expired yet
    DealIsNotExpiredYet = 7272
    /// Only judge system can change minimal deal amount
    OnlyJudgeSystemCanChangeMinimalDealAmount = 11470
    /// Only judge system can judge deal
    OnlyJudgeSystemCanJudgeDeal = 15696
    /// Deal is not expired yet or freeze time is not passed
    DealIsNotExpiredYetOrFreezeTimeIsNotPassed = 19598
    /// Only producer can give up deal
    OnlyProducerCanGiveUpDeal = 21702
    /// Only producer can pay responsibility
    OnlyProducerCanPayResponsibility = 25261
    /// Only consumer can withdraw in case of system failure
    OnlyConsumerCanWithdrawInCaseOfSystemFailure = 29762
    /// Only judge system can change fee part
    OnlyJudgeSystemCanChangeFeePart = 30535
    /// Only judge system can change system failure freeze time
    OnlyJudgeSystemCanChangeSystemFailureFreezeTime = 35536
    /// Not enough money to withdraw
    NotEnoughMoneyToWithdraw = 38435
    /// Minimal value required
    MinimalValueRequired = 44300
    /// Only consumer can return money due to not locked responsibility
    OnlyConsumerCanReturnMoneyDueToNotLockedResponsibility = 44791
    /// Producer responsibility should be equal to value
    ProducerResponsibilityShouldBeEqualToValue = 50882
    /// Only judge system or consumer can complete deal
    OnlyJudgeSystemOrConsumerCanCompleteDeal = 51184
    /// Producer responsibility should be positive
    ProducerResponsibilityShouldBePositive = 52143
    /// Amount should be positive
    AmountShouldBePositive = 54379
    /// Producer already payed
    ProducerAlreadyPayed = 56239
    /// Minimal contract balance required
    MinimalContractBalanceRequired = 57887
    /// Fee should be equal
    FeeShouldBeEqual = 58293
    /// Minimal deal amount required
    MinimalDealAmountRequired = 63984
}

get fun balance(): int257 {
    throw 0;
}

get fun allDeals(): map<int257, Cell<SolomonDealDeal>> {
    throw 0;
}

get fun feeFound(): int257 {
    throw 0;
}

get fun minimalDealAmount(): int257 {
    throw 0;
}

get fun feePart(): int257 {
    throw 0;
}

get fun systemFailureFreezeTime(): int257 {
    throw 0;
}

get fun minimalContractBalance(): int257 {
    throw 0;
}

get fun totalClientMoney(): int257 {
    throw 0;
}
