// Generated from the verified Tact contract ABI.
contract OMNI {
    storage: OMNIData
    incomingMessages: OMNIIncomingMessage
    thrownErrors: OMNIErrors
}

struct (0x819dbe99) OMNIChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x946a98b6) OMNIDeploy {
    queryId: uint64
}

struct (0xc238ffb5) OMNIFrozenToken {
    query_id: uint64
    userAddress: address
    amount: coins
    response_destination: address?
}

struct (0x115d3a8f) OMNISetAddressFrozen {
    query_id: uint64
    userAddress: address
    frozen: bool
    response_destination: address?
}

struct (0x3e4ae0a0) OMNIForcedBurnToken {
    query_id: uint64
    userAddress: address
    amount: coins
    response_destination: address?
    custom_payload: cell?
}

struct (0x4b8dbe07) OMNIForcedTransferToken {
    query_id: uint64
    amount: coins
    from: address
    destination: address
    response_destination: address?
    custom_payload: cell?
    tactContinuation: Cell<OMNIForcedTransferTokenContinuation>
}

struct OMNIForcedTransferTokenContinuation {
    forward_ton_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct OMNIJettonData {
    total_supply: int257
    mintable: bool
    owner: address
    content: cell
    wallet_code: cell
}

struct (0x7bdd97de) OMNITokenBurnNotification {
    query_id: uint64
    amount: coins
    sender: address
    response_destination: address?
}

struct (0xaf1ca26a) OMNITokenUpdateContent {
    content: cell
}

struct (0x2c76b973) OMNIProvideWalletAddress {
    query_id: uint64
    owner_address: address
    include_address: bool
}

struct OMNIDocumentData {
    lastModified: uint64
    uri: string
    hash: int257
    name: string
}

struct (0xae0a9587) OMNISetDocument {
    uri: string
    hash: int257
    name: string
}

struct (0x0e5c4d8b) OMNIRemoveDocument {
    name: string
}

struct (0xb10b5c66) OMNISetAddr {
    OMNIDigital: address
    Tokenise: address
    InvessHK: address
}

struct (0xf2f95dea) OMNIMint {
    to: address?
    amount: coins
    allToDistributed: bool
    enableDistributed: bool
    forward_ton_amount: coins
}

struct (0xfdd8ad67) OMNISetIssuer {
    issuer: address
    isIssuer: bool
}

struct (0x69e69fcf) OMNIClaimFee {
    amount: coins
    forward_ton_amount: coins
}

struct OMNIData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    total_supply: coins
    owner: address
    content: cell
    mintable: bool
    stopped: bool
    documents: map<int257, Cell<OMNIDocumentData>>
    tactContinuation: Cell<OMNIDataContinuation>
}

struct OMNIDataContinuation {
    nameHashs: map<int257, int257>
    documentLength: coins
    transferFee: coins
    issuerList: map<address, bool>
    OMNIDigital: address
    Tokenise: address
    tactContinuation: Cell<OMNIDataContinuation2>
}

struct OMNIDataContinuation2 {
    InvessHK: address
}

type OMNIIncomingMessage =
    | OMNIMint
    | OMNISetIssuer
    | OMNIClaimFee
    | OMNISetAddr
    | OMNIFrozenToken
    | OMNISetAddressFrozen
    | OMNIForcedBurnToken
    | OMNIForcedTransferToken
    | OMNITokenUpdateContent
    | OMNITokenBurnNotification
    | OMNIProvideWalletAddress
    | OMNISetDocument
    | OMNIRemoveDocument
    | OMNIChangeOwner
    | OMNIDeploy

enum OMNIErrors {
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
    /// Invalid sender
    InvalidSender = 4429
    /// Invalid value
    InvalidValue = 16059
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Insufficient gas
    InsufficientGas = 23951
    /// caller is not the issuer
    CallerIsNotTheIssuer = 24583
    /// wallet is frozen
    WalletIsFrozen = 28550
    /// Document not found
    DocumentNotFound = 28978
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

get fun isIssuer(issuer: address): bool {
    throw 0;
}

get fun IssuerList(): map<address, bool> {
    throw 0;
}

get fun FeAddr(): OMNISetAddr {
    throw 0;
}

get fun get_jetton_data(): OMNIJettonData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun get_document(name: string): OMNIDocumentData? {
    throw 0;
}

get fun get_document_by_index(index: int257): OMNIDocumentData? {
    throw 0;
}

get fun get_all_names(): map<int257, cell> {
    throw 0;
}

get fun get_all_documents(): map<int257, Cell<OMNIDocumentData>> {
    throw 0;
}

get fun get_document_length(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}
