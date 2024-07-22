// Generated from the verified Tact contract ABI.
contract Lottery {
    storage: LotteryData
    incomingMessages: LotteryIncomingMessage
    thrownErrors: LotteryErrors
}

struct (0x946a98b6) LotteryDeploy {
    queryId: uint64
}

struct (0x195c9998) LotteryNewLotteryPool {
    creator: address
    pool_type: uint8
    expire_time: int257
}

struct (0x2625b4e1) LotteryBuyTicket {
    buyer: address
    lottery_pool_id: uint256
    select_number: uint32
    value: coins
}

struct LotteryData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    lottery_pool_nums: uint256
}

type LotteryIncomingMessage =
    | LotteryNewLotteryPool
    | LotteryBuyTicket
    | LotteryDeploy

enum LotteryErrors {
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
    /// Lottery pool does not exist
    LotteryPoolDoesNotExist = 17961
    /// value doesn't match pool type,needing 100 Ton!
    ValueDoesnTMatchPoolTypeNeeding100Ton = 21923
    /// Lottery Pool is invalid!
    LotteryPoolIsInvalid = 24477
    /// Pool type is wrong!
    PoolTypeIsWrong = 26944
    /// This number doesn't exist in the pool
    ThisNumberDoesnTExistInThePool = 35048
    /// The number of buyers exceeds 10
    TheNumberOfBuyersExceeds10 = 36143
    /// value doesn't match pool type,needing 10 Ton!
    ValueDoesnTMatchPoolTypeNeeding10Ton = 47751
    /// value doesn't match pool type,needing 1 Ton!
    ValueDoesnTMatchPoolTypeNeeding1Ton = 63339
}

get fun numPools(): int257 {
    throw 0;
}

get fun poolAddress(lottery_pool_id: int257): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
