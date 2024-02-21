// Generated from the verified Tact contract ABI.
contract Inshrimption {
    storage: InshrimptionData
    incomingMessages: InshrimptionIncomingMessage
    thrownErrors: InshrimptionErrors
}

struct (0x946a98b6) InshrimptionDeploy {
    queryId: uint64
}

struct (0x819dbe99) InshrimptionChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x5bc58ae8) InshrimptionBuy {
    seller: address
    amount: uint32
    price: uint256
    nonce: uint32
}

struct (0x768b4d10) InshrimptionCancel {
    amount: uint32
    price: uint256
    nonce: uint32
}

struct (0xd3bdb940) InshrimptionFee {
    sellPerc: int257
    msg: int257
    inscribe: int257
}

struct InshrimptionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    currSeqno: int257
    owner: address
    used: map<int257, int257>
    sellFeePerc: int257
    tactContinuation: Cell<InshrimptionDataContinuation>
}

struct InshrimptionDataContinuation {
    msgFee: int257
    inscribeFee: int257
}

type InshrimptionIncomingMessage =
    | InshrimptionBuy
    | InshrimptionCancel
    | InshrimptionFee
    | InshrimptionDeploy
    | InshrimptionChangeOwner

enum InshrimptionErrors {
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
    /// Order is expired or canceled
    OrderIsExpiredOrCanceled = 3737
    /// Inscription fee is not enough
    InscriptionFeeIsNotEnough = 7446
    /// Price after fee deduction is too low
    PriceAfterFeeDeductionIsTooLow = 10045
    /// no dust allowed
    NoDustAllowed = 48086
    /// Message fee is not enough
    MessageFeeIsNotEnough = 52161
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

get fun balance(): int257 {
    throw 0;
}

get fun contractSeqno(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
