// Generated from the verified Tact contract ABI.
contract CTonLock {
    storage: CTonLockData
    incomingMessages: CTonLockIncomingMessage
    thrownErrors: CTonLockErrors
}

struct (0x946a98b6) CTonLockDeploy {
    queryId: uint64
}

struct (0x10df73d6) CTonLockSetLocker {
    length: uint128
    keys: map<int257, int257>
    lockerInfo: map<int257, int257>
}

struct (0xe21f25d5) CTonLockTokenWithdraw {
    amount: uint256
    jettonWalletAddress: address
    receiver: address
}

struct CTonLockLockerInfo {
    owner: address
    totalAmountLocked: uint256
    totalAmountBalance: uint256
    tactContinuation: Cell<CTonLockLockerInfoContinuation>
}

struct CTonLockLockerInfoContinuation {
    lockerLength: uint256
    lockerMap: map<int257, int257>
}

struct CTonLockData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    totalAmountLocked: uint256
    totalAmountBalance: uint256
    tactContinuation: Cell<CTonLockDataContinuation>
}

struct CTonLockDataContinuation {
    lockerLength: uint256
    lockerTimeMap: map<int257, int257>
    lockerMap: map<int257, int257>
}

type CTonLockIncomingMessage =
    | CTonLockSetLocker
    | CTonLockTokenWithdraw
    | CTonLockDeploy

enum CTonLockErrors {
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
    /// Reject withdraw
    RejectWithdraw = 11137
    /// Not owner
    NotOwner = 14534
    /// Only owner can claim fee
    OnlyOwnerCanClaimFee = 59445
}

get fun lockerInfo(): CTonLockLockerInfo {
    throw 0;
}
