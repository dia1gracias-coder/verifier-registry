// Generated from the verified Tact contract ABI.
contract MosaicDealContract {
    storage: MosaicDealContractData
    incomingMessages: MosaicDealContractIncomingMessage
    thrownErrors: MosaicDealContractErrors
}

struct (0x946a98b6) MosaicDealContractDeploy {
    queryId: uint64
}

struct (0xc2a367cd) MosaicDealContractFinishDeal {
    dealId: uint32
}

struct (0xf7e3ed72) MosaicDealContractAdminForceEnd {
    dealId: uint32
    receiver: address
}

struct MosaicDealContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    dealId: int257
    amount: coins
    admin: address
    customer: address
    tactContinuation: Cell<MosaicDealContractDataContinuation>
}

struct MosaicDealContractDataContinuation {
    freelancer: address
    isActive: bool
    isFinished: bool
}

type MosaicDealContractIncomingMessage =
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
    /// Incorrect amount
    IncorrectAmount = 22499
    /// Incorrect receiver address
    IncorrectReceiverAddress = 32056
    /// Incorrect deal Id
    IncorrectDealId = 40279
    /// Incorrect customer address
    IncorrectCustomerAddress = 45026
    /// Deal isn't active
    DealIsnTActive = 54213
    /// Incorrect freelancer address
    IncorrectFreelancerAddress = 56296
}

get fun dealId(): int257 {
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
