// Generated from the verified Tact contract ABI.
contract JettonWallet {
    storage: JettonWalletData2
    incomingMessages: JettonWalletIncomingMessage
    thrownErrors: JettonWalletErrors
}

struct JettonWalletData {
    balance: int257
    owner: address
    jetton: address
    jetton_wallet_code: cell
}

struct (0x595f07bc) JettonWalletTokenBurn {
    query_id: uint64
    amount: coins
    owner: address
    response_destination: address
}

struct (0x0f8a7ea5) JettonWalletTokenTransfer {
    query_id: uint64
    amount: coins
    destination: address
    response_destination: address
    custom_payload: cell?
    forward_ton_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x178d4519) JettonWalletTokenTransferInternal {
    query_id: uint64
    amount: coins
    from: address
    response_destination: address
    forward_ton_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct JettonWalletData2 {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    master: address
    owner: address
    balance: int257
}

type JettonWalletIncomingMessage =
    | JettonWalletTokenBurn
    | JettonWalletTokenTransfer
    | JettonWalletTokenTransferInternal

enum JettonWalletErrors {
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
    /// Not Owner
    NotOwner = 3734
    /// Invalid value!!
    InvalidValue = 4159
    /// Invalid sender
    InvalidSender = 4429
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Contract stopped
    ContractStopped2 = 40368
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// Contract not stopped
    ContractNotStopped = 53296
    /// Invalid balance
    InvalidBalance = 62972
}

get fun msgValue(value: int257): int257 {
    throw 0;
}

get fun get_wallet_data(): JettonWalletData {
    throw 0;
}
