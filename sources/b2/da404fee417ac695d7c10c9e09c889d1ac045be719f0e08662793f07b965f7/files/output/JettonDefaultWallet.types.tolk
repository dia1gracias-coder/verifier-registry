// Generated from the verified Tact contract ABI.
contract JettonDefaultWallet {
    storage: JettonDefaultWalletData
    incomingMessages: JettonDefaultWalletIncomingMessage
    thrownErrors: JettonDefaultWalletErrors
}

struct (0x0f8a7ea5) JettonDefaultWalletTokenTransfer {
    queryId: uint64
    amount: coins
    destination: address
    responseDestination: address?
    customPayload: cell?
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x178d4519) JettonDefaultWalletTokenTransferInternal {
    queryId: uint64
    amount: coins
    from: address
    responseAddress: address?
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x595f07bc) JettonDefaultWalletTokenBurn {
    queryId: uint64
    amount: coins
    owner: address
    responseAddress: address?
}

struct JettonDefaultWalletJettonWalletData {
    balance: int257
    owner: address
    master: address
    walletCode: cell
}

struct JettonDefaultWalletData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    balance: int257
    owner: address
    master: address
}

type JettonDefaultWalletIncomingMessage =
    | JettonDefaultWalletTokenTransfer
    | JettonDefaultWalletTokenTransferInternal
    | JettonDefaultWalletTokenBurn

enum JettonDefaultWalletErrors {
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
    /// Invalid bounced message
    InvalidBouncedMessage = 13650
    /// Invalid value
    InvalidValue = 16059
    /// Invalid balance
    InvalidBalance = 62972
}

get fun get_wallet_data(): JettonDefaultWalletJettonWalletData {
    throw 0;
}
