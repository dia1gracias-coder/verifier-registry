// Generated from the verified Tact contract ABI.
contract SnatchTresasureContract {
    storage: SnatchTresasureContractData
    incomingMessages: SnatchTresasureContractIncomingMessage
    thrownErrors: SnatchTresasureContractErrors
}

struct (0x946a98b6) SnatchTresasureContractDeploy {
    queryId: uint64
}

struct (0x819dbe99) SnatchTresasureContractChangeOwner {
    queryId: uint64
    newOwner: address
}

struct SnatchTresasureContractRoundInfo {
    quotient: map<uint32, Cell<SnatchTresasureContractBuyInfo>>
    orders: map<uint32, uint16>
    sum: uint16
    arrLength: uint16
    sequence: uint16
    finish: bool
    winner: uint16
    awardAmount: coins
    startTime: uint32
    endTime: uint32
}

struct SnatchTresasureContractBuyInfo {
    startLuckyNum: uint16
    nifiNum: uint16
    address: address
}

struct SnatchTresasureContractWinnerInfo {
    luckyNum: uint16
    address: address
}

struct (0xe340781e) SnatchTresasureContractNewRoundMsg {
    round: uint32
    sum: uint16
    startTime: uint32
    endTime: uint32
    awardAmount: coins
}

struct (0x600fd230) SnatchTresasureContractCloseRoundMsg {
    round: uint32
}

struct (0x6e7208a0) SnatchTresasureContractBuyMsg {
    round: uint32
    nifiAmount: uint16
    orderNumber: uint32
    signature: cell
}

struct (0x021c4b88) SnatchTresasureContractDrawMsg {
    round: uint32
}

struct (0xd9d7cdc8) SnatchTresasureContractCleanMsg {
    round: uint32
}

struct (0xa64b9539) SnatchTresasureContractPrizeMsg {
    round: uint32
    txId: uint256
}

struct SnatchTresasureContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    rounds: map<uint32, Cell<SnatchTresasureContractRoundInfo>>
    owner: address
    publicKey: uint256
    records: map<uint32, uint256>
    tactContinuation: Cell<SnatchTresasureContractDataContinuation>
}

struct SnatchTresasureContractDataContinuation {
    winners: map<uint32, uint16>
}

type SnatchTresasureContractIncomingMessage =
    | SnatchTresasureContractNewRoundMsg
    | SnatchTresasureContractCloseRoundMsg
    | SnatchTresasureContractBuyMsg
    | SnatchTresasureContractDrawMsg
    | SnatchTresasureContractPrizeMsg
    | SnatchTresasureContractCleanMsg
    | SnatchTresasureContractDeploy
    | SnatchTresasureContractChangeOwner

enum SnatchTresasureContractErrors {
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
    /// current round time is over1
    CurrentRoundTimeIsOver1 = 9583
    /// current round has already been drawn
    CurrentRoundHasAlreadyBeenDrawn = 15307
    /// current round time is over
    CurrentRoundTimeIsOver = 21468
    /// order repetition
    OrderRepetition = 21474
    /// current round is not finish yet
    CurrentRoundIsNotFinishYet = 26794
    /// can not close
    CanNotClose = 48921
    /// signature verify failed
    SignatureVerifyFailed = 54750
    /// over bet amount
    OverBetAmount = 57177
    /// round already exist
    RoundAlreadyExist = 60050
    /// current round is finish
    CurrentRoundIsFinish = 61485
}

get fun getRoundWinner(round: int257): SnatchTresasureContractWinnerInfo? {
    throw 0;
}

get fun getWinnerRecord(): map<uint32, uint16> {
    throw 0;
}

get fun getRoundInfoState(key: int257): SnatchTresasureContractRoundInfo? {
    throw 0;
}

get fun getPrizeTxId(round: int257): int257? {
    throw 0;
}

get fun getPrizeRecord(): map<uint32, uint256> {
    throw 0;
}

get fun getOrderExist(round: int257, order: int257): int257? {
    throw 0;
}

get fun getBuyInfo(round: int257, seqNum: int257): SnatchTresasureContractBuyInfo? {
    throw 0;
}

get fun verifySignature(round: int257, nifiAmount: int257, orderNumber: int257, signature: cell, addr: address): bool {
    throw 0;
}

get fun getPubkey(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
