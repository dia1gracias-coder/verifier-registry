// Generated from the verified Tact contract ABI.
contract JettonPreHTLC {
    storage: JettonPreHTLCData
    incomingMessages: JettonPreHTLCIncomingMessage
    thrownErrors: JettonPreHTLCErrors
}

struct (0x946a98b6) JettonPreHTLCDeploy {
    queryId: uint64
}

struct JettonPreHTLCPHTLC {
    dstAddress: string
    srcAssetId: int257
    sender: address
    srcAddress: address
    tactContinuation: Cell<JettonPreHTLCPHTLCContinuation>
}

struct JettonPreHTLCPHTLCContinuation {
    timelock: int257
    messenger: address
    amount: int257
    refunded: bool
    converted: bool
    tactContinuation: Cell<JettonPreHTLCPHTLCContinuation2>
}

struct JettonPreHTLCPHTLCContinuation2 {
    phtlcID: int257
}

struct (0xbefc17a4) JettonPreHTLCCreateP {
    data: JettonPreHTLCPHTLCData
}

struct JettonPreHTLCConvertPData {
    phtlcID: int257
    hashlock: int257
}

struct (0xb7ee06c4) JettonPreHTLCConvertP {
    data: JettonPreHTLCConvertPData
}

struct JettonPreHTLCStringImpl {
    data: string
}

struct JettonPreHTLCPHTLCData {
    dstChainId: int257
    dstAssetId: int257
    srcAssetId: int257
    tactContinuation: Cell<JettonPreHTLCPHTLCDataContinuation>
}

struct JettonPreHTLCPHTLCDataContinuation {
    timelock: int257
    srcAddress: address
    messenger: address
    dstAddress: string
    chainIDs: map<int257, int257>
    dstAddresses: map<int257, Cell<JettonPreHTLCStringImpl>>
}

struct (0x0fce1278) JettonPreHTLCRefundP {
    phtlcID: int257
}

struct JettonPreHTLCHTLC {
    hashlock: int257
    secret: int257
    amount: int257
    tactContinuation: Cell<JettonPreHTLCHTLCContinuation>
}

struct JettonPreHTLCHTLCContinuation {
    timelock: int257
    sender: address
    srcAddress: address
    redeemed: bool
    refunded: bool
}

struct JettonPreHTLCTonTransferInitiated {
    __hashlock: int257
    __amount: int257
    __chainId: int257
    tactContinuation: Cell<JettonPreHTLCTonTransferInitiatedContinuation>
}

struct JettonPreHTLCTonTransferInitiatedContinuation {
    __timelock: int257
    __phtlcID: int257
    __sender: address
    tactContinuation: Cell<JettonPreHTLCTonTransferInitiatedContinuation2>
}

struct JettonPreHTLCTonTransferInitiatedContinuation2 {
    __srcAddress: address
    __messenger: address?
    __targetCurrencyReceiverAddress: string
}

struct (0x80e1900e) JettonPreHTLCCreate {
    data: JettonPreHTLCTonTransferInitiated
}

struct JettonPreHTLCTonTransferClaimed {
    __hashlock: int257
    __secret: int257
}

struct (0xcb8c0e08) JettonPreHTLCRedeem {
    data: JettonPreHTLCTonTransferClaimed
}

struct JettonPreHTLCTonTransferRefunded {
    __hashlock: int257
}

struct (0x27cc3317) JettonPreHTLCRefund {
    data: JettonPreHTLCTonTransferRefunded
}

struct JettonPreHTLCData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    contracts: map<int257, Cell<JettonPreHTLCHTLC>>
    pContracts: map<int257, Cell<JettonPreHTLCPHTLC>>
    counter: int257
    contractLength: int257
    pContractLength: int257
}

type JettonPreHTLCIncomingMessage =
    | JettonPreHTLCCreateP
    | JettonPreHTLCRefundP
    | JettonPreHTLCConvertP
    | JettonPreHTLCCreate
    | JettonPreHTLCRedeem
    | JettonPreHTLCRefund
    | JettonPreHTLCDeploy

enum JettonPreHTLCErrors {
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
    /// Contract Already Exists
    ContractAlreadyExists = 11493
    /// Already Converted To HTLC
    AlreadyConvertedToHTLC = 19226
    /// Not Future Timelock
    NotFutureTimelock = 21683
    /// No Allowance
    NoAllowance = 31687
    /// Not Passed Timelock
    NotPassedTimelock = 38239
    /// Already Redeemed
    AlreadyRedeemed = 46887
    /// Already Refunded
    AlreadyRefunded = 49162
    /// Hashlock Not Match
    HashlockNotMatch = 50918
    /// HTLC With That Hashlock Exists
    HTLCWithThatHashlockExists = 51083
    /// Contract Does Not Exist
    ContractDoesNotExist = 58417
    /// Already Converted
    AlreadyConverted = 59712
}

get fun getHTLCDetails(hashlock: int257): JettonPreHTLCHTLC? {
    throw 0;
}

get fun getPHTLCDetails(phtlcID: int257): JettonPreHTLCPHTLC? {
    throw 0;
}

get fun pContractLength(): int257 {
    throw 0;
}

get fun contractLength(): int257 {
    throw 0;
}
