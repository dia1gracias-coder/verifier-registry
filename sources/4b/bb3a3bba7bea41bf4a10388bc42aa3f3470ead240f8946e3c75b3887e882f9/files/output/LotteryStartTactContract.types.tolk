// Generated from the verified Tact contract ABI.
contract LotteryStartTactContract {
    storage: LotteryStartTactContractData
    incomingMessages: LotteryStartTactContractIncomingMessage
    thrownErrors: LotteryStartTactContractErrors
}

struct (0x946a98b6) LotteryStartTactContractDeploy {
    queryId: uint64
}

struct (0xbf813085) LotteryStartTactContractJoinInfo {
    seqno: uint128
}

struct (0xcf49203f) LotteryStartTactContractDrawInfo {
    seqno: uint128
}

struct LotteryStartTactContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    transno: uint128
}

type LotteryStartTactContractIncomingMessage =
    | LotteryStartTactContractJoinInfo
    | LotteryStartTactContractDrawInfo
    | LotteryStartTactContractDeploy

enum LotteryStartTactContractErrors {
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
    /// seqno can not empty
    SeqnoCanNotEmpty = 15101
    /// address can not empty
    AddressCanNotEmpty = 29294
    /// Access denied
    AccessDenied2 = 49469
    /// the value must be greater than 0.1
    TheValueMustBeGreaterThan01 = 60523
}

get fun balance(): string {
    throw 0;
}
