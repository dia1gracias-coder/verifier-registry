// Generated from the verified Tact contract ABI.
contract MessageVerifier {
    storage: MessageVerifierData
    incomingMessages: MessageVerifierIncomingMessage
    thrownErrors: MessageVerifierErrors
}

struct (0x946a98b6) MessageVerifierDeploy {
    queryId: uint64
}

struct (0x51f126a7) MessageVerifierSignedMessage {
    data: cell
    signature: cell
}

struct (0x569c6d63) MessageVerifierChangeJettonMaster {
    jettonMaster: address
}

struct (0x7362d09c) MessageVerifierTokenNotification {
    queryId: uint64
    amount: coins
    from: address
    forwardPayload: RemainingBitsAndRefs
}

struct MessageVerifierData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    publicKey: uint256
    jettonMaster: address
    jettonBalance: coins
    processedSignatures: map<int257, bool>
}

type MessageVerifierIncomingMessage =
    | MessageVerifierTokenNotification
    | MessageVerifierChangeJettonMaster
    | MessageVerifierSignedMessage
    | MessageVerifierDeploy

enum MessageVerifierErrors {
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
    /// Invalid amount
    InvalidAmount = 17062
    /// Invalid jetton address
    InvalidJettonAddress = 18502
    /// Signature already processed
    SignatureAlreadyProcessed = 37859
    /// Invalid signature
    InvalidSignature = 48401
    /// No jettons to sweep
    NoJettonsToSweep = 48569
    /// Insufficient jetton balance
    InsufficientJettonBalance = 51863
}

get fun getIsSignatureProcessed(signatureHash: int257): bool {
    throw 0;
}

get fun getPublicKey(): int257 {
    throw 0;
}

get fun getJettonBalance(): int257 {
    throw 0;
}

get fun getJettonMaster(): address {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
