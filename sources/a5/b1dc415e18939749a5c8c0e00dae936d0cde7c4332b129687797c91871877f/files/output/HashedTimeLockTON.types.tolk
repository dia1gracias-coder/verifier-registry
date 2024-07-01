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

struct (0xbefc17a4) HashedTimeLockTONCreateP {
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
    dstChainId: int257
    dstAssetId: int257
    srcAssetId: int257
    tactContinuation: Cell<HashedTimeLockTONPHTLCDataContinuation>
}

struct HashedTimeLockTONPHTLCDataContinuation {
    timelock: int257
    srcAddress: address
    messenger: address
    dstAddress: string
    chainIDs: map<int257, int257>
    dstAddresses: map<int257, Cell<HashedTimeLockTONStringImpl>>
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
    __phtlcID: int257
    __sender: address
    tactContinuation: Cell<HashedTimeLockTONTonTransferInitiatedContinuation2>
}

struct HashedTimeLockTONTonTransferInitiatedContinuation2 {
    __srcAddress: address
    __messenger: address
    __targetCurrencyReceiverAddress: string
}

struct (0x2408e7eb) HashedTimeLockTONCreate {
    data: HashedTimeLockTONTonTransferInitiated
}

struct HashedTimeLockTONTonTransferClaimed {
    __hashlock: int257
    __secret: int257
}

struct (0xcb8c0e08) HashedTimeLockTONRedeem {
    data: HashedTimeLockTONTonTransferClaimed
}

struct HashedTimeLockTONTonTransferRefunded {
    __hashlock: int257
}

struct (0x27cc3317) HashedTimeLockTONRefund {
    data: HashedTimeLockTONTonTransferRefunded
}

struct HashedTimeLockTONData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    contracts: map<int257, Cell<HashedTimeLockTONHTLC>>
    pContracts: map<int257, Cell<HashedTimeLockTONPHTLC>>
    counter: int257
    contractLength: int257
    pContractLength: int257
}

type HashedTimeLockTONIncomingMessage =
    | HashedTimeLockTONCreateP
    | HashedTimeLockTONRefundP
    | HashedTimeLockTONConvertP
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

get fun getHTLCDetails(hashlock: int257): HashedTimeLockTONHTLC? {
    throw 0;
}

get fun getPHTLCDetails(phtlcID: int257): HashedTimeLockTONPHTLC? {
    throw 0;
}

get fun pContractLength(): int257 {
    throw 0;
}

get fun contractLength(): int257 {
    throw 0;
}
