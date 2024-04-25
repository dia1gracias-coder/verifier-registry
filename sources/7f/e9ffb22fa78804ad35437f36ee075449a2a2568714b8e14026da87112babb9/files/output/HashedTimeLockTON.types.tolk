// Generated from the verified Tact contract ABI.
contract HashedTimeLockTON {
    storage: HashedTimeLockTONData
    incomingMessages: HashedTimeLockTONIncomingMessage
    thrownErrors: HashedTimeLockTONErrors
}

struct (0x946a98b6) HashedTimeLockTONDeploy {
    queryId: uint64
}

struct HashedTimeLockTONHTLC {
    hashlock: int256
    secret: int256
    amount: coins
    timelock: uint256
    tactContinuation: Cell<HashedTimeLockTONHTLCContinuation>
}

struct HashedTimeLockTONHTLCContinuation {
    sender: address
    _receiver: address
    redeemed: bool
    refunded: bool
}

struct HashedTimeLockTONTonTransferInitiated {
    __hashlock: int256
    __amount: coins
    __chainId: int256
    __timelock: int256
    tactContinuation: Cell<HashedTimeLockTONTonTransferInitiatedContinuation>
}

struct HashedTimeLockTONTonTransferInitiatedContinuation {
    __sender: address
    __receiver: address
    __targetCurrencyReceiverAddress: string
}

struct (0x1de616d0) HashedTimeLockTONCreate {
    data: HashedTimeLockTONTonTransferInitiated
}

struct HashedTimeLockTONTonTransferClaimed {
    __hashlock: int256
    __receiver: address
    __amount: coins
}

struct (0x73add0be) HashedTimeLockTONRedeem {
    data: HashedTimeLockTONTonTransferClaimed
}

struct HashedTimeLockTONTonTransferRefunded {
    __hashlock: int256
    __receiver: address
    __amount: coins
}

struct (0xa9dfd79e) HashedTimeLockTONRefund {
    data: HashedTimeLockTONTonTransferRefunded
}

struct HashedTimeLockTONData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    contracts: map<int256, Cell<HashedTimeLockTONHTLC>>
}

type HashedTimeLockTONIncomingMessage =
    | HashedTimeLockTONCreate
    | HashedTimeLockTONRedeem
    | HashedTimeLockTONRefund
    | HashedTimeLockTONDeploy

enum HashedTimeLockTONErrors {
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
    /// Funds Not Sent
    FundsNotSent = 4670
    /// Contract Already Exists
    ContractAlreadyExists = 11493
    /// Not Future Timelock
    NotFutureTimelock = 21683
    /// Not Passed Timelock
    NotPassedTimelock = 38239
    /// Already Redeemed
    AlreadyRedeemed = 46887
    /// Already Refunded
    AlreadyRefunded = 49162
    /// Hashlock Not Match
    HashlockNotMatch = 50918
}

get fun getHTLCDetails(hashlock: int257): HashedTimeLockTONHTLC? {
    throw 0;
}
