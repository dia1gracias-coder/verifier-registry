// Generated from the verified Tact contract ABI.
contract LayerswapV8 {
    storage: LayerswapV8Data
    incomingMessages: LayerswapV8IncomingMessage
    thrownErrors: LayerswapV8Errors
}

struct (0x946a98b6) LayerswapV8Deploy {
    queryId: uint64
}

struct LayerswapV8HTLC {
    dstAddress: string
    dstChain: string
    tactContinuation: Cell<LayerswapV8HTLCContinuation>
}

struct LayerswapV8HTLCContinuation {
    dstAsset: string
    srcAsset: string
    sender: address
    senderPubKey: int257
    srcReceiver: address
    tactContinuation: Cell<LayerswapV8HTLCContinuation2>
}

struct LayerswapV8HTLCContinuation2 {
    secret: int257
    hashlock: int257
    amount: int257
    tactContinuation: Cell<LayerswapV8HTLCContinuation3>
}

struct LayerswapV8HTLCContinuation3 {
    timelock: int257
    messenger: address
    redeemed: bool
    refunded: bool
}

struct (0x1b564d91) LayerswapV8Commit {
    dstChain: string
    dstAsset: string
    tactContinuation: Cell<LayerswapV8CommitContinuation>
}

struct LayerswapV8CommitContinuation {
    dstAddress: string
    srcAsset: string
    srcReceiver: address
    timelock: int257
    messenger: address
    tactContinuation: Cell<LayerswapV8CommitContinuation2>
}

struct LayerswapV8CommitContinuation2 {
    senderPubKey: int257
    hopChains: map<int257, Cell<LayerswapV8StringImpl>>
    hopAssets: map<int257, Cell<LayerswapV8StringImpl>>
    hopAddresses: map<int257, Cell<LayerswapV8StringImpl>>
}

struct (0x5cdd41d9) LayerswapV8AddLock {
    Id: int257
    hashlock: int257
    timelock: int257
}

struct (0x12e78cb1) LayerswapV8Lock {
    Id: int257
    hashlock: int257
    timelock: int257
    tactContinuation: Cell<LayerswapV8LockContinuation>
}

struct LayerswapV8LockContinuation {
    srcReceiver: address
    srcAsset: string
    dstChain: string
    dstAddress: string
    dstAsset: string
    messenger: address
}

struct (0x758db085) LayerswapV8Redeem {
    Id: int257
    secret: int257
}

struct (0xad821ef9) LayerswapV8Refund {
    Id: int257
}

struct LayerswapV8StringImpl {
    data: string
}

struct LayerswapV8Data {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    contracts: map<int257, Cell<LayerswapV8HTLC>>
    contractNonce: int257
    seed: int257
    zeroAddress: address
}

type LayerswapV8IncomingMessage =
    | LayerswapV8Commit
    | LayerswapV8AddLock
    | LayerswapV8Lock
    | LayerswapV8Redeem
    | LayerswapV8Refund
    | LayerswapV8Deploy

enum LayerswapV8Errors {
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
    /// Funds Not Sent
    FundsNotSent = 4670
    /// Hashlock Already Set
    HashlockAlreadySet = 8650
    /// Contract Already Exists
    ContractAlreadyExists = 11493
    /// Not Future Timelock
    NotFutureTimelock = 21683
    /// HTLC Already Exists
    HTLCAlreadyExists = 24064
    /// Commit Does Not Exist
    CommitDoesNotExist = 30789
    /// No Allowance
    NoAllowance = 31687
    /// Not Passed Timelock
    NotPassedTimelock = 38239
    /// HTLC Does Not Exist
    HTLCDoesNotExist = 42857
    /// Already Redeemed
    AlreadyRedeemed = 46887
    /// Invalid signature
    InvalidSignature = 48401
    /// Already Refunded
    AlreadyRefunded = 49162
    /// Hashlock Not Match
    HashlockNotMatch = 50918
    /// Contract Does Not Exist
    ContractDoesNotExist = 58417
}

get fun getDetails(Id: int257): LayerswapV8HTLC? {
    throw 0;
}

get fun getContractsLength(): int257 {
    throw 0;
}

get fun getContracts(senderAddr: address): map<int257, int257> {
    throw 0;
}
