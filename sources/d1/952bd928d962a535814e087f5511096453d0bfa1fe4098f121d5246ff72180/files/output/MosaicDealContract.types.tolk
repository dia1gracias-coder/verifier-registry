// Generated from the verified Tact contract ABI.
contract MosaicDealContract {
    storage: MosaicDealContractData
    incomingMessages: MosaicDealContractIncomingMessage
    thrownErrors: MosaicDealContractErrors
}

struct (0x946a98b6) MosaicDealContractDeploy {
    queryId: uint64
}

struct (0x602a2c02) MosaicDealContractFinishDeal {
    id: string
}

struct (0xf3fe1904) MosaicDealContractAdminForceEnd {
    id: string
    receiver: address
}

struct (0x21eeb607) MosaicDealContractDeposit {
    amount: coins
}

struct MosaicDealContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    id: string
    amount: coins
    admin: address
    customer: address
    freelancer: address
    isActive: bool
    isFinished: bool
}

type MosaicDealContractIncomingMessage =
    | MosaicDealContractDeposit
    | MosaicDealContractFinishDeal
    | MosaicDealContractAdminForceEnd
    | MosaicDealContractDeploy

enum MosaicDealContractErrors {
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
    /// Incorrect sender
    IncorrectSender = 9215
    /// Non-admin address can't finish this deal
    NonAdminAddressCanTFinishThisDeal = 15439
    /// Incorrect admin address
    IncorrectAdminAddress = 18643
    /// Deal is already finished
    DealIsAlreadyFinished = 22325
    /// Incorrect amount
    IncorrectAmount = 22499
    /// Incorrect receiver address
    IncorrectReceiverAddress = 32056
    /// Incorrect deal Id
    IncorrectDealId = 40279
    /// Incorrect customer address
    IncorrectCustomerAddress = 45026
    /// Incorrect value of deal
    IncorrectValueOfDeal = 52350
    /// Deal isn't active
    DealIsnTActive = 54213
    /// Incorrect freelancer address
    IncorrectFreelancerAddress = 56296
    /// Deal is already active
    DealIsAlreadyActive = 61766
}

get fun id(): string {
    throw 0;
}

get fun amount(): int257 {
    throw 0;
}

get fun admin(): address {
    throw 0;
}

get fun customer(): address {
    throw 0;
}

get fun freelancer(): address {
    throw 0;
}

get fun isActive(): bool {
    throw 0;
}

get fun contractBalance(): int257 {
    throw 0;
}
