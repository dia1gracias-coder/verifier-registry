// Generated from the verified Tact contract ABI.
contract TactWallet {
    storage: TactWalletData
    incomingMessages: TactWalletDeploy
    incomingExternal: TactWalletExtMessage
    thrownErrors: TactWalletErrors
}

struct TactWalletSendParameters {
    bounce: bool
    to: address
    value: int257
    mode: int257
    body: cell?
    code: cell?
    data: cell?
}

struct (0x946a98b6) TactWalletDeploy {
    queryId: uint64
}

struct (0xc1252abe) TactWalletExtMessage {
    signature: bits512
    seqno: uint32
    valid_until: uint32
    tactContinuation: Cell<TactWalletExtMessageContinuation>
}

struct TactWalletExtMessageContinuation {
    message_parameters: TactWalletSendParameters
}

struct TactWalletData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    seqno: uint32
    publicKey: uint256
}

enum TactWalletErrors {
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
    /// Invalid Signature
    InvalidSignature = 9577
    /// Invalid Time
    InvalidTime = 12033
    /// Invalid Seqno
    InvalidSeqno = 30508
}

get fun seqno(): int257 {
    throw 0;
}

get fun get_public_key(): int257 {
    throw 0;
}
