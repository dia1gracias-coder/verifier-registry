// Generated from the verified Tact contract ABI.
contract JettonMasterTemplate {
    storage: JettonMasterTemplateData
    incomingMessages: JettonMasterTemplateIncomingMessage
    thrownErrors: JettonMasterTemplateErrors
}

struct (0x946a98b6) JettonMasterTemplateDeploy {
    queryId: uint64
}

struct (0xa593886f) JettonMasterTemplateMintJetton {
    queryId: uint64
    amount: int257
    receiver: address
    responseDestination: address
    forwardAmount: coins
    forwardPayload: cell?
}

struct (0xe78d9033) JettonMasterTemplateMultiMint {
    queryId: uint64
    receivers: map<uint32, Cell<JettonMasterTemplateMultiMintReceiver>>
    receiverCount: uint32
}

struct JettonMasterTemplateJettonMasterData {
    totalSupply: int257
    mintable: bool
    owner: address
    content: cell
    walletCode: cell
}

struct JettonMasterTemplateMultiMintReceiver {
    receiver: address
    amount: int257
    tonAmount: coins
    responseDestination: address
    tactContinuation: Cell<JettonMasterTemplateMultiMintReceiverContinuation>
}

struct JettonMasterTemplateMultiMintReceiverContinuation {
    forwardAmount: coins
    forwardPayload: cell?
}

struct (0x7bdd97de) JettonMasterTemplateTokenBurnNotification {
    queryId: uint64
    amount: coins
    sender: address
    responseDestination: address
}

struct (0xd53276db) JettonMasterTemplateExcesses {
    queryId: uint64
}

struct (0x2c76b973) JettonMasterTemplateProvideWalletAddress {
    queryId: uint64
    ownerAddress: address
    includeAddress: bool
}

struct (0x1509a420) JettonMasterTemplateSetStaticTax {
    staticTax: coins
}

struct JettonMasterTemplateData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    staticTax: coins
    lockedValue: coins
    content: cell
    totalSupply: coins
    mintable: bool
}

type JettonMasterTemplateIncomingMessage =
    | JettonMasterTemplateMintJetton
    | JettonMasterTemplateMultiMint
    | JettonMasterTemplateTokenBurnNotification
    | JettonMasterTemplateProvideWalletAddress
    | JettonMasterTemplateExcesses
    | JettonMasterTemplateSetStaticTax
    | JettonMasterTemplateDeploy

enum JettonMasterTemplateErrors {
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
    /// 'Unknown' error
    UnknownError = 11
    /// Fatal error
    FatalError = 12
    /// Out of gas error
    OutOfGasError = 13
    /// Virtualization error
    VirtualizationError = 14
    /// Action list is invalid
    ActionListIsInvalid = 32
    /// Action list is too long
    ActionListIsTooLong = 33
    /// Action is invalid or not supported
    ActionIsInvalidOrNotSupported = 34
    /// Invalid source address in outbound message
    InvalidSourceAddressInOutboundMessage = 35
    /// Invalid destination address in outbound message
    InvalidDestinationAddressInOutboundMessage = 36
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
    NotEnoughExtraCurrencies = 38
    /// Outbound message does not fit into a cell after rewriting
    OutboundMessageDoesNotFitIntoACellAfterRewriting = 39
    /// Cannot process a message
    CannotProcessAMessage = 40
    /// Library reference is null
    LibraryReferenceIsNull = 41
    /// Library change action error
    LibraryChangeActionError = 42
    /// Exceeded maximum number of cells in the library or the maximum depth of the Merkle tree
    ExceededMaximumNumberOfCellsInTheLibraryOrTheMaximumDepthOfTheMerkleTree = 43
    /// Account state size exceeded limits
    AccountStateSizeExceededLimits = 50
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
    /// Invaid sender
    InvaidSender = 30311
    /// Contract stopped
    ContractStopped2 = 40368
    /// Contract not stopped
    ContractNotStopped = 53296
}

get fun get_jetton_data(): JettonMasterTemplateJettonMasterData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}

get fun staticTax(): int257 {
    throw 0;
}
