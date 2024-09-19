// Generated from the verified Tact contract ABI.
contract MosaicDealFactory {
    storage: MosaicDealFactoryData
    incomingMessages: MosaicDealFactoryIncomingMessage
    thrownErrors: MosaicDealFactoryErrors
}

struct (0x946a98b6) MosaicDealFactoryDeploy {
    queryId: uint64
}

struct (0xb6642d80) MosaicDealFactoryDealDetails {
    admin: address
    customer: address
    freelancer: address
    amount: coins
}

struct (0xf3c78cd9) MosaicDealFactoryInfo {
    id: uint32
    admin: address
    customer: address
    freelancer: address
    amount: coins
}

struct MosaicDealFactoryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    id: uint32
}

type MosaicDealFactoryIncomingMessage =
    | MosaicDealFactoryDealDetails
    | MosaicDealFactoryDeploy

enum MosaicDealFactoryErrors {
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
    /// Insufficient value to create a deal
    InsufficientValueToCreateADeal = 31174
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

get fun numberOfChildren(): int257 {
    throw 0;
}

get fun addressOfChildren(msg: MosaicDealFactoryInfo): address {
    throw 0;
}
