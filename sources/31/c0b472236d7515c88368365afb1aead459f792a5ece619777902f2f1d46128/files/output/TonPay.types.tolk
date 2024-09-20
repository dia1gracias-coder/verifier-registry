// Generated from the verified Tact contract ABI.
contract TonPay {
    storage: TonPayData2
    incomingMessages: TonPayIncomingMessage
    thrownErrors: TonPayErrors
}

struct (0x946a98b6) TonPayDeploy {
    queryId: uint64
}

struct (0x819dbe99) TonPayChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x3335b2f2) TonPayPayoutRequest {
    requestId: string
    sender: address
    payee: address
    amount: coins
    currency: uint8
    jettonMasterAddress: address?
}

struct (0x3bbe25e8) TonPayPayoutResponse {
    requestInfo: TonPayPayoutRequest
}

struct TonPayData {
    owner: address
    recipient: address
    publicKey: uint256
    tactContinuation: Cell<TonPayDataContinuation>
}

struct TonPayDataContinuation {
    usdtMasterAddress: address
    jettonWalletGovernedCode: cell
    tonPayUsdtWallet: address
}

struct (0xcf1221ea) TonPayUpdatePublicKey {
    publicKey: uint256
}

struct (0xca622aec) TonPayUpdateJettonWalletGoverned {
    usdtMasterAddress: address?
    jettonWalletGovernedCode: cell?
}

struct (0x7809b7fa) TonPayUpdateRecipient {
    recipient: address
}

struct (0x7362d09c) TonPayTokenNotification {
    query_id: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct TonPayData2 {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    recipient: address
    publicKey: uint256
    tactContinuation: Cell<TonPayDataContinuation2>
}

struct TonPayDataContinuation2 {
    usdtMasterAddress: address
    jettonWalletGovernedCode: cell
    tonPayUsdtWallet: address
}

type TonPayIncomingMessage =
    | TonPayTokenNotification
    | TonPayUpdatePublicKey
    | TonPayUpdateJettonWalletGoverned
    | TonPayUpdateRecipient
    | TonPayPayoutResponse
    | TonPayDeploy
    | TonPayChangeOwner

enum TonPayErrors {
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
    /// Invalid sender
    InvalidSender = 4429
    /// Invalid currency
    InvalidCurrency = 7533
    /// not enough TONs to deposit
    NotEnoughTONsToDeposit = 14470
    /// Message expired
    MessageExpired = 25135
    /// not enough TONs to withdraw
    NotEnoughTONsToWithdraw = 27238
    /// Invalid signature
    InvalidSignature = 48401
}

get fun tonPayData(): TonPayData {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun publicKey(): int257 {
    throw 0;
}
