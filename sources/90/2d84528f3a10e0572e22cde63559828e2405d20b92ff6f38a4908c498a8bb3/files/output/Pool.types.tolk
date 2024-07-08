// Generated from the verified Tact contract ABI.
contract Pool {
    storage: PoolData
    incomingMessages: PoolIncomingMessage
    thrownErrors: PoolErrors
}

struct (0x946a98b6) PoolDeploy {
    queryId: uint64
}

struct PoolReserveConfiguration {
    lTokenAddress: address
    dTokenAddress: address
    ltv: uint16
    liquidationThreshold: uint16
    liquidationBonus: uint16
    reserveFactor: uint16
    liquidationProtocolFee: uint16
    optimalUsageRatio: uint16
    slope1: uint16
    slope2: uint16
    borrowingEnabled: bool
    supplyCap: uint32
    borrowCap: uint32
}

struct PoolReserveData {
    liquidityIndex: uint128
    borrowIndex: uint128
    totalSupply: coins
    availableLiquidity: coins
    accruedToTreasury: coins
    totalBorrow: coins
    lastUpdateTimestamp: uint32
}

struct (0x66660001) PoolAddReserve {
    reserveAddress: address
    tactContinuation: Cell<PoolAddReserveContinuation>
}

struct PoolAddReserveContinuation {
    reserveConfiguration: PoolReserveConfiguration
}

struct (0x66660002) PoolDropReserve {
    reserveIndex: uint16
}

struct PoolData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    stopped: bool
    reserves: map<int257, address>
    reservesLength: int257
    reservesData: map<address, Cell<PoolReserveData>>
    tactContinuation: Cell<PoolDataContinuation>
}

struct PoolDataContinuation {
    reservesConfiguration: map<address, Cell<PoolReserveConfiguration>>
}

type PoolIncomingMessage =
    | PoolAddReserve
    | PoolDropReserve
    | PoolDeploy

enum PoolErrors {
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
    /// Reserve index out of bounds
    ReserveIndexOutOfBounds = 9583
    /// Liability not zero
    LiabilityNotZero = 11642
    /// Debt not zero
    DebtNotZero = 23298
    /// Contract stopped
    ContractStopped2 = 40368
    /// Reserve already exists
    ReserveAlreadyExists = 47600
    /// Contract not stopped
    ContractNotStopped = 53296
    /// Treasury share not zero
    TreasuryShareNotZero = 60151
}

get fun reservesLength(): int257 {
    throw 0;
}

get fun reserves(): map<int257, address> {
    throw 0;
}

get fun reserveAddress(reserveIndex: int257): address {
    throw 0;
}

get fun reserveData(reserveAddress: address): PoolReserveData {
    throw 0;
}

get fun reserveConfiguration(reserveAddress: address): PoolReserveConfiguration {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}
