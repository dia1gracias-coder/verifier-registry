// Generated from the verified Tact contract ABI.
contract JettonMinterFeatureRich {
    storage: JettonMinterFeatureRichData
    incomingMessages: JettonMinterFeatureRichIncomingMessage
    thrownErrors: JettonMinterFeatureRichErrors
}

struct JettonMinterFeatureRichStateInit {
    code: cell
    data: cell
}

struct (0x00000004) JettonMinterFeatureRichJettonUpdateContent {
    queryId: uint64
    content: cell
}

struct (0x00000006) JettonMinterFeatureRichChangeBurnable {
    queryId: uint64
    burnable: bool
}

struct (0x1fdde72e) JettonMinterFeatureRichJettonTransferInternalV2 {
    queryId: uint64
    amount: coins
    sender: address
    responseDestination: address?
    forwardTonAmount: coins
    forwardStateInit: JettonMinterFeatureRichStateInit?
    forwardPayload: RemainingBitsAndRefs
}

struct (0x7bdd97de) JettonMinterFeatureRichJettonBurnNotification {
    queryId: uint64
    amount: coins
    sender: address
    responseDestination: address?
}

struct (0x2c76b973) JettonMinterFeatureRichProvideWalletAddress {
    queryId: uint64
    ownerAddress: address
    includeAddress: bool
}

struct (0x642b7d07) JettonMinterFeatureRichMint {
    queryId: uint64
    receiver: address
    tonAmount: coins
    tactContinuation: Cell<JettonMinterFeatureRichMintContinuation>
}

struct JettonMinterFeatureRichMintContinuation {
    mintMessage: JettonMinterFeatureRichJettonTransferInternalV2
}

struct (0x00000016) JettonMinterFeatureRichCloseMinting {
}

struct (0x0393b1ce) JettonMinterFeatureRichClaimTON {
    receiver: address
}

struct (0x819dbe99) JettonMinterFeatureRichChangeOwner {
    queryId: uint64
    newOwner: address
}

struct JettonMinterFeatureRichJettonMinterState {
    totalSupply: coins
    mintable: bool
    adminAddress: address
    jettonContent: cell
    jettonWalletCode: cell
    burnable: bool
}

struct JettonMinterFeatureRichData {
    tactSystemCell: cell
    totalSupply: coins
    owner: address
    jettonContent: cell
    mintable: bool
    maxSupply: coins
    burnable: bool
}

type JettonMinterFeatureRichIncomingMessage =
    | JettonMinterFeatureRichMint
    | JettonMinterFeatureRichProvideWalletAddress
    | JettonMinterFeatureRichJettonBurnNotification
    | JettonMinterFeatureRichJettonUpdateContent
    | JettonMinterFeatureRichChangeOwner
    | JettonMinterFeatureRichCloseMinting
    | JettonMinterFeatureRichClaimTON
    | JettonMinterFeatureRichChangeBurnable

enum JettonMinterFeatureRichErrors {
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
    /// Not enough Toncoin
    NotEnoughToncoin = 37
    /// Not enough extra currencies
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
    /// Invalid standard address
    InvalidStandardAddress = 136
    /// Not a basechain address
    NotABasechainAddress = 138
    /// Incorrect balance after send
    IncorrectBalanceAfterSend = 2366
    /// Incorrect sender
    IncorrectSender = 9215
    /// Unauthorized burn
    UnauthorizedBurn = 10363
    /// Forward state init is null with deploy send mode
    ForwardStateInitIsNullWithDeploySendMode = 18073
    /// Insufficient amount of TON attached
    InsufficientAmountOfTONAttached = 32113
    /// Only owner
    OnlyOwner = 35499
    /// Only deployer can change burn flag
    OnlyDeployerCanChangeBurnFlag = 35681
    /// Insufficient gas for mint
    InsufficientGasForMint = 37629
    /// Cannot change metadata after minting is closed
    CannotChangeMetadataAfterMintingIsClosed = 41194
    /// Max supply reached
    MaxSupplyReached = 47714
    /// Deploy address doesn't match owner address
    DeployAddressDoesnTMatchOwnerAddress = 51864
    /// Mint is closed
    MintIsClosed = 51950
    /// Incorrect send amount
    IncorrectSendAmount = 52281
    /// Burning is not allowed
    BurningIsNotAllowed = 60460
}

get fun get_jetton_data(): JettonMinterFeatureRichJettonMinterState {
    throw 0;
}

get fun get_wallet_address(ownerAddress: address): address {
    throw 0;
}
