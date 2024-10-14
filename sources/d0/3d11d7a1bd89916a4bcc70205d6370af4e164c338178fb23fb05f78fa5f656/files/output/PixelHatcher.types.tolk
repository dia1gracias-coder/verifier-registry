// Generated from the verified Tact contract ABI.
contract PixelHatcher {
    storage: PixelHatcherData
    incomingMessages: PixelHatcherIncomingMessage
    thrownErrors: PixelHatcherErrors
}

struct (0x946a98b6) PixelHatcherDeploy {
    queryId: uint64
}

struct (0x819dbe99) PixelHatcherChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x5bc58ae8) PixelHatcherBuy {
    seller: address
    amount: uint32
    price: uint256
    nonce: uint32
}

struct (0x768b4d10) PixelHatcherCancel {
    amount: uint32
    price: uint256
    nonce: uint32
}

struct (0xfe3552ad) PixelHatcherSettings {
    sellPerc: int257?
    msg: int257?
    inscribe: int257?
    tactContinuation: Cell<PixelHatcherSettingsContinuation>
}

struct PixelHatcherSettingsContinuation {
    maxOrderLength: int257?
}

struct PixelHatcherData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    seqno: int257
    owner: address
    stopped: bool
    orderClosed: map<int257, int257>
    tactContinuation: Cell<PixelHatcherDataContinuation>
}

struct PixelHatcherDataContinuation {
    orderHashList: map<int257, int257>
    orderHashListIndex: int257
    sellFeePerc: int257
    msgFee: int257
    tactContinuation: Cell<PixelHatcherDataContinuation2>
}

struct PixelHatcherDataContinuation2 {
    inscribeFee: int257
    maxOrderLength: int257
}

type PixelHatcherIncomingMessage =
    | PixelHatcherBuy
    | PixelHatcherCancel
    | PixelHatcherSettings
    | PixelHatcherDeploy
    | PixelHatcherChangeOwner

enum PixelHatcherErrors {
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
    /// Order is expired or canceled
    OrderIsExpiredOrCanceled = 3737
    /// Inscription fee is not enough
    InscriptionFeeIsNotEnough = 7446
    /// Contract stopped
    ContractStopped2 = 40368
    /// No dust allowed
    NoDustAllowed = 43410
    /// Message fee is not enough
    MessageFeeIsNotEnough = 52161
    /// Contract not stopped
    ContractNotStopped = 53296
}

get fun sellFeePerc(): int257 {
    throw 0;
}

get fun msgFee(): int257 {
    throw 0;
}

get fun inscribeFee(): int257 {
    throw 0;
}

get fun maxOrderLength(): int257 {
    throw 0;
}

get fun orderClosed(): map<int257, int257> {
    throw 0;
}

get fun orderHashList(): map<int257, int257> {
    throw 0;
}

get fun orderHashListIndex(): int257 {
    throw 0;
}

get fun contractSeqno(): int257 {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}
