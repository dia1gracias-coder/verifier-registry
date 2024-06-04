// Generated from the verified Tact contract ABI.
contract HashedTimeLockTON {
    storage: HashedTimeLockTONData
    incomingMessages: HashedTimeLockTONIncomingMessage
    thrownErrors: HashedTimeLockTONErrors
}

struct (0x946a98b6) HashedTimeLockTONDeploy {
    queryId: uint64
}

struct HashedTimeLockTONPHTLC {
    dstAddress: string
    srcAssetId: int257
    sender: address
    srcAddress: address
    tactContinuation: Cell<HashedTimeLockTONPHTLCContinuation>
}

struct HashedTimeLockTONPHTLCContinuation {
    timelock: int257
    messenger: address
    amount: int257
    refunded: bool
    converted: bool
    tactContinuation: Cell<HashedTimeLockTONPHTLCContinuation2>
}

struct HashedTimeLockTONPHTLCContinuation2 {
    phtlcID: int257
}

struct (0x7f16a8a7) HashedTimeLockTONCreateP {
    data: HashedTimeLockTONPHTLCData
}

struct HashedTimeLockTONConvertPData {
    phtlcID: int257
    hashlock: int257
}

struct (0xb7ee06c4) HashedTimeLockTONConvertP {
    data: HashedTimeLockTONConvertPData
}

struct HashedTimeLockTONStringImpl {
    data: string
}

struct HashedTimeLockTONPHTLCData {
    chainIDs: map<int257, int257>
    dstAddresses: map<int257, Cell<HashedTimeLockTONStringImpl>>
    phtlcID: int257
    dstChainId: int257
    dstAssetId: int257
    dstAddress: string
    tactContinuation: Cell<HashedTimeLockTONPHTLCDataContinuation>
}

struct HashedTimeLockTONPHTLCDataContinuation {
    srcAssetId: int257
    srcAddress: address
    timelock: int257
    tactContinuation: Cell<HashedTimeLockTONPHTLCDataContinuation2>
}

struct HashedTimeLockTONPHTLCDataContinuation2 {
    messenger: address
    amount: int257
    refunded: bool
    converted: bool
}

struct (0x0fce1278) HashedTimeLockTONRefundP {
    phtlcID: int257
}

struct HashedTimeLockTONHTLC {
    hashlock: int257
    secret: int257
    amount: int257
    tactContinuation: Cell<HashedTimeLockTONHTLCContinuation>
}

struct HashedTimeLockTONHTLCContinuation {
    timelock: int257
    sender: address
    srcAddress: address
    redeemed: bool
    refunded: bool
}

struct HashedTimeLockTONTonTransferInitiated {
    __hashlock: int257
    __amount: int257
    __chainId: int257
    tactContinuation: Cell<HashedTimeLockTONTonTransferInitiatedContinuation>
}

struct HashedTimeLockTONTonTransferInitiatedContinuation {
    __timelock: int257
    __sender: address
    __srcAddress: address
    __targetCurrencyReceiverAddress: string
    tactContinuation: Cell<HashedTimeLockTONTonTransferInitiatedContinuation2>
}

struct HashedTimeLockTONTonTransferInitiatedContinuation2 {
    __phtlcID: int257
    __messenger: address
}

struct (0x98a79f27) HashedTimeLockTONCreate {
    data: HashedTimeLockTONTonTransferInitiated
}

struct HashedTimeLockTONTonTransferClaimed {
    __hashlock: int257
    __secret: int257
    __amount: int257
}

struct (0x22e6bcc1) HashedTimeLockTONRedeem {
    data: HashedTimeLockTONTonTransferClaimed
}

struct HashedTimeLockTONTonTransferRefunded {
    __hashlock: int257
    __receiver: address
    __amount: int257
}

struct (0x3d5a4d37) HashedTimeLockTONRefund {
    data: HashedTimeLockTONTonTransferRefunded
}

struct HashedTimeLockTONChainIDs {
    data: map<int257, int257>
}

struct HashedTimeLockTONDstAddresses {
    data: map<int257, Cell<HashedTimeLockTONStringImpl>>
}

struct HashedTimeLockTONCreatePBatchData {
    chainIds: map<int257, Cell<HashedTimeLockTONChainIDs>>
    dstAddresses: map<int257, Cell<HashedTimeLockTONDstAddresses>>
    dstChainId: map<int257, int257>
    tactContinuation: Cell<HashedTimeLockTONCreatePBatchDataContinuation>
}

struct HashedTimeLockTONCreatePBatchDataContinuation {
    dstAssetId: map<int257, address>
    dstAddress: map<int257, Cell<HashedTimeLockTONStringImpl>>
    srcAssetId: map<int257, int257>
    tactContinuation: Cell<HashedTimeLockTONCreatePBatchDataContinuation2>
}

struct HashedTimeLockTONCreatePBatchDataContinuation2 {
    srcAddress: map<int257, address>
    timelock: map<int257, int257>
    messenger: map<int257, address>
    tactContinuation: Cell<HashedTimeLockTONCreatePBatchDataContinuation3>
}

struct HashedTimeLockTONCreatePBatchDataContinuation3 {
    amount: map<int257, int257>
}

struct (0x6a855357) HashedTimeLockTONCreatePBatch {
    data: HashedTimeLockTONCreatePBatchData
}

struct HashedTimeLockTONConvertPBatchData {
    phtlcIDs: map<int257, int257>
    hashlocks: map<int257, int257>
}

struct (0x662e1bb1) HashedTimeLockTONConvertPBatch {
    data: HashedTimeLockTONConvertPBatchData
}

struct HashedTimeLockTONCreateBatchData {
    _srcAddresses: map<int257, address>
    _hashlocks: map<int257, int257>
    _timelocks: map<int257, int257>
    tactContinuation: Cell<HashedTimeLockTONCreateBatchDataContinuation>
}

struct HashedTimeLockTONCreateBatchDataContinuation {
    _chainIDs: map<int257, int257>
    _targetCurrencyReceiversAddresses: map<int257, Cell<HashedTimeLockTONStringImpl>>
    _amounts: map<int257, int257>
    tactContinuation: Cell<HashedTimeLockTONCreateBatchDataContinuation2>
}

struct HashedTimeLockTONCreateBatchDataContinuation2 {
    _phtlcIds: map<int257, int257>
    _messengers: map<int257, address>
}

struct (0xcc50d360) HashedTimeLockTONCreateBatch {
    data: HashedTimeLockTONCreateBatchData
}

struct HashedTimeLockTONBatchRedeemData {
    htlcIDs: map<int257, int257>
    secrets: map<int257, int257>
}

struct (0x6a0867af) HashedTimeLockTONBatchRedeem {
    data: HashedTimeLockTONBatchRedeemData
}

struct HashedTimeLockTONData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    contracts: map<int257, Cell<HashedTimeLockTONHTLC>>
    pContracts: map<int257, Cell<HashedTimeLockTONPHTLC>>
    counter: int257
}

type HashedTimeLockTONIncomingMessage =
    | HashedTimeLockTONCreateP
    | HashedTimeLockTONCreatePBatch
    | HashedTimeLockTONRefundP
    | HashedTimeLockTONConvertP
    | HashedTimeLockTONConvertPBatch
    | HashedTimeLockTONCreate
    | HashedTimeLockTONCreateBatch
    | HashedTimeLockTONRedeem
    | HashedTimeLockTONBatchRedeem
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
    /// Already Converted To HTLC
    AlreadyConvertedToHTLC = 19226
    /// Not Future Timelock
    NotFutureTimelock = 21683
    /// Incorrect Data
    IncorrectData = 26639
    /// No Allowance
    NoAllowance = 31687
    /// Not Passed Timelock
    NotPassedTimelock = 38239
    /// Already Redeemed
    AlreadyRedeemed = 46887
    /// Already Refunded
    AlreadyRefunded = 49162
    /// PreHTLC Does Not Exist
    PreHTLCDoesNotExist = 50782
    /// Hashlock Not Match
    HashlockNotMatch = 50918
    /// HTLC With That Hashlock Exists
    HTLCWithThatHashlockExists = 51083
    /// Contract Does Not Exist
    ContractDoesNotExist = 58417
    /// Already Converted
    AlreadyConverted = 59712
}

get fun getHTLCDetails(hashlock: int257): HashedTimeLockTONHTLC? {
    throw 0;
}

get fun getPHTLCDetails(phtlcID: int257): HashedTimeLockTONPHTLC? {
    throw 0;
}
