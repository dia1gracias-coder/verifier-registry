// Generated from the verified Tact contract ABI.
contract LayerswapV8Jetton {
    storage: LayerswapV8JettonData
    incomingMessages: LayerswapV8JettonIncomingMessage
    thrownErrors: LayerswapV8JettonErrors
}

struct (0x946a98b6) LayerswapV8JettonDeploy {
    queryId: uint64
}

struct (0x7362d09c) LayerswapV8JettonTokenNotification {
    queryId: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct (0xd53276db) LayerswapV8JettonTokenExcesses {
    queryId: uint64
}

struct LayerswapV8JettonHTLC {
    dstAddress: string
    dstChain: string
    tactContinuation: Cell<LayerswapV8JettonHTLCContinuation>
}

struct LayerswapV8JettonHTLCContinuation {
    dstAsset: string
    srcAsset: string
    sender: address
    senderPubKey: int257
    srcReceiver: address
    tactContinuation: Cell<LayerswapV8JettonHTLCContinuation2>
}

struct LayerswapV8JettonHTLCContinuation2 {
    secret: int257
    hashlock: int257
    amount: int257
    tactContinuation: Cell<LayerswapV8JettonHTLCContinuation3>
}

struct LayerswapV8JettonHTLCContinuation3 {
    timelock: int257
    redeemed: bool
    refunded: bool
    jettonMasterAddress: address
    htlcJettonWalletAddress: address
}

struct (0x5cdd41d9) LayerswapV8JettonAddLock {
    Id: int257
    hashlock: int257
    timelock: int257
}

struct (0x758db085) LayerswapV8JettonRedeem {
    Id: int257
    secret: int257
}

struct (0xad821ef9) LayerswapV8JettonRefund {
    Id: int257
}

struct LayerswapV8JettonData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    contracts: map<int257, Cell<LayerswapV8JettonHTLC>>
    contractNonce: int257
    seed: int257
    zeroAddress: address
}

type LayerswapV8JettonIncomingMessage =
    | LayerswapV8JettonTokenNotification
    | LayerswapV8JettonAddLock
    | LayerswapV8JettonRedeem
    | LayerswapV8JettonRefund
    | LayerswapV8JettonTokenExcesses
    | LayerswapV8JettonDeploy

enum LayerswapV8JettonErrors {
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
    /// No Allowance
    NoAllowance = 31687
    /// Not Passed Timelock
    NotPassedTimelock = 38239
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

get fun getDetails(Id: int257): LayerswapV8JettonHTLC? {
    throw 0;
}

get fun getContractsLength(): int257 {
    throw 0;
}

get fun getContracts(senderAddr: address): map<int257, int257> {
    throw 0;
}
