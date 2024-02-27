// Generated from the verified Tact contract ABI.
contract LotteryStartTactContract {
    storage: LotteryStartTactContractData
    incomingMessages: LotteryStartTactContractIncomingMessage
    thrownErrors: LotteryStartTactContractErrors
}

struct (0x946a98b6) LotteryStartTactContractDeploy {
    queryId: uint64
}

struct (0xb3d41e96) LotteryStartTactContractJoinInfo {
    address: address
    seqno: uint128
}

struct (0xcf49203f) LotteryStartTactContractDrawInfo {
    seqno: uint128
}

struct (0xb4e57534) LotteryStartTactContractWinnerInfo {
    address: address
    seqno: uint128
}

struct (0x18561478) LotteryStartTactContractClearInfo {
    seqno: uint128
}

struct (0x0ba69751) LotteryStartTactContractWithdraw {
    amount: coins
}

struct LotteryStartTactContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    transno: uint128
    winnerList: map<int257, Cell<LotteryStartTactContractWinnerInfo>>
    winnerQuantity: uint8
}

type LotteryStartTactContractIncomingMessage =
    | LotteryStartTactContractJoinInfo
    | LotteryStartTactContractDrawInfo
    | LotteryStartTactContractWinnerInfo
    | LotteryStartTactContractClearInfo
    | LotteryStartTactContractWithdraw
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
    /// Only owner is allowed to withdraw
    OnlyOwnerIsAllowedToWithdraw = 27921
    /// not father
    NotFather = 28440
    /// address can not empty
    AddressCanNotEmpty = 29294
    /// not child
    NotChild = 36611
    /// value is not enough
    ValueIsNotEnough = 48085
    /// Insufficient balance
    InsufficientBalance = 54615
    /// Only owner is allowed to drawLottery
    OnlyOwnerIsAllowedToDrawLottery = 60255
}

get fun balance(): int257 {
    throw 0;
}

// Tact getter name: address
// Tact method ID: 69216
get fun address_(): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun transno(): int257 {
    throw 0;
}

get fun winnerQuantity(): int257 {
    throw 0;
}

get fun winnerList(): map<int257, Cell<LotteryStartTactContractWinnerInfo>> {
    throw 0;
}
