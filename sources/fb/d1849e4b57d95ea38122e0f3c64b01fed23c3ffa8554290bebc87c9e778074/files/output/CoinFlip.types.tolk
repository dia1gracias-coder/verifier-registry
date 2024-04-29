// Generated from the verified Tact contract ABI.
contract CoinFlip {
    storage: CoinFlipData
    incomingMessages: CoinFlipIncomingMessage
    thrownErrors: CoinFlipErrors
}

struct (0x819dbe99) CoinFlipChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x7a6e56c3) CoinFlipSetWinFeeParams {
    winFee: int257
}

struct (0x18326337) CoinFlipSetAllowParams {
    allowSize: int257
    allows: map<int257, int257>
}

struct CoinFlipData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    winFee: int257
    allowSize: int257
    allows: map<int257, int257>
}

type CoinFlipIncomingMessage =
    | CoinFlipSetWinFeeParams
    | CoinFlipSetAllowParams
    | CoinFlipChangeOwner

enum CoinFlipErrors {
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
}

get fun owner(): address {
    throw 0;
}
