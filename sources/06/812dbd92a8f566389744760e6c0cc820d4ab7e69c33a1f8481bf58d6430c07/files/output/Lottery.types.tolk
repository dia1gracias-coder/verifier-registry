// Generated from the verified Tact contract ABI.
contract Lottery {
    storage: LotteryData
    incomingMessages: LotteryIncomingMessage
    thrownErrors: LotteryErrors
}

struct (0x946a98b6) LotteryDeploy {
    queryId: uint64
}

struct (0x7362d09c) LotteryTokenNotification {
    query_id: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct (0xd53276db) LotteryTokenExcesses {
    queryId: uint64
}

struct (0xb5362230) LotteryFeed {
    query_id: uint64
}

struct (0x71865ca1) LotteryChangeFee {
    feePercent: uint8
}

struct (0x0f474d03) LotteryChangeOwner {
    newOwner: address
}

struct LotteryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    id: uint32
    tonVaultAddr: address
    poolAddr: address
    jettonVaultAddr: address
    tactContinuation: Cell<LotteryDataContinuation>
}

struct LotteryDataContinuation {
    ownerAddr: address
    jettonWalletAddr: address?
    feePercent: uint8
    totalJettonValue: coins
}

type LotteryIncomingMessage =
    | LotteryTokenNotification
    | LotteryFeed
    | LotteryChangeFee
    | LotteryChangeOwner
    | LotteryTokenExcesses
    | LotteryDeploy

enum LotteryErrors {
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
    /// Only owner is allowed to change fee
    OnlyOwnerIsAllowedToChangeFee = 24312
    /// Only owner is allowed to change owner
    OnlyOwnerIsAllowedToChangeOwner = 36877
    /// Wrong jetton source
    WrongJettonSource = 38064
}

get fun id(): int257 {
    throw 0;
}

get fun getTotalAmount(): int257 {
    throw 0;
}

get fun getFee(): int257 {
    throw 0;
}
