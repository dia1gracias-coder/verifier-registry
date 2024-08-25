// Generated from the verified Tact contract ABI.
contract WinLotteryManager {
    storage: WinLotteryManagerData
    incomingMessages: WinLotteryManagerIncomingMessage
    thrownErrors: WinLotteryManagerErrors
}

struct (0x946a98b6) WinLotteryManagerDeploy {
    queryId: uint64
}

struct WinLotteryManagerLottery {
    winningTickets: map<int257, int257>
}

struct (0xf964e034) WinLotteryManagerPlayNewLottery {
    lotteryId: int257
    totalNumberOfTickets: int257
    numberOfWinningTickets: int257
}

struct WinLotteryManagerData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    id: uint32
    lotteries: map<int257, Cell<WinLotteryManagerLottery>>
    owner: address
}

type WinLotteryManagerIncomingMessage =
    | WinLotteryManagerPlayNewLottery
    | WinLotteryManagerDeploy

enum WinLotteryManagerErrors {
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
    /// Only the owner can increase the value!
    OnlyTheOwnerCanIncreaseTheValue = 20506
}

get fun lotteryResults(lotteryId: int257): map<int257, int257> {
    throw 0;
}

get fun id(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
