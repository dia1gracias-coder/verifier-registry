// Generated from the verified Tact contract ABI.
contract PRMDJettonMaster {
    storage: PRMDJettonMasterData
    incomingMessages: PRMDJettonMasterIncomingMessage
    thrownErrors: PRMDJettonMasterErrors
}

struct (0x7bdd97de) PRMDJettonMasterTokenBurnNotification {
    queryId: uint64
    amount: coins
    sender: address
    responseDestination: address?
}

struct (0x2c76b973) PRMDJettonMasterProvideWalletAddress {
    queryId: uint64
    ownerAddress: address
    includeAddress: bool
}

struct (0xa593886f) PRMDJettonMasterMintJetton {
    queryId: uint64
    amount: coins
    receiver: address
    responseDestination: address
    forwardAmount: coins
    forwardPayload: cell?
}

struct (0xe78d9033) PRMDJettonMasterMultiMint {
    queryId: uint64
    receivers: map<uint32, Cell<PRMDJettonMasterMultiMintReceiver>>
    receiverCount: uint32
}

struct (0x080b2bc1) PRMDJettonMasterChangeJettonMasterOwner {
    queryId: uint64
    owner: address
}

struct (0x6d8210b2) PRMDJettonMasterStopMinting {
    queryId: uint64
}

struct (0x1e4cce92) PRMDJettonMasterUpdateJettonContent {
    queryId: uint64
    content: cell
}

struct PRMDJettonMasterMultiMintReceiver {
    receiver: address
    amount: coins
    tonAmount: coins
    responseDestination: address
    forwardAmount: coins
    forwardPayload: cell?
}

struct PRMDJettonMasterJettonMasterData {
    totalSupply: coins
    mintable: bool
    owner: address
    content: cell
    walletCode: cell
}

struct PRMDJettonMasterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    pyramidaAddress: address
    content: cell
    totalSupply: coins
    mintable: bool
}

type PRMDJettonMasterIncomingMessage =
    | PRMDJettonMasterChangeJettonMasterOwner
    | PRMDJettonMasterUpdateJettonContent
    | PRMDJettonMasterStopMinting
    | PRMDJettonMasterMintJetton
    | PRMDJettonMasterMultiMint
    | PRMDJettonMasterTokenBurnNotification
    | PRMDJettonMasterProvideWalletAddress

enum PRMDJettonMasterErrors {
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
    /// Amount too small for owner change
    AmountTooSmallForOwnerChange = 3571
    /// Not mintable
    NotMintable = 3688
    /// Invalid sender
    InvalidSender = 4429
    /// Incorrect sender
    IncorrectSender = 9215
    /// Not owner
    NotOwner = 14534
    /// DrawLottery can only be sent by the contract itself
    DrawLotteryCanOnlyBeSentByTheContractItself = 14901
    /// receiverCount must be positive
    ReceiverCountMustBePositive = 17821
    /// Owner cannot be the same
    OwnerCannotBeTheSame = 18152
    /// Invalid receiver
    InvalidReceiver = 21516
    /// Only owner can change owner
    OnlyOwnerCanChangeOwner = 27145
    /// Insufficient amount of TON attached
    InsufficientAmountOfTONAttached = 32113
    /// Only Pyramida JettonMaster contract can update total amount
    OnlyPyramidaJettonMasterContractCanUpdateTotalAmount = 33296
    /// Insufficient gas for mint
    InsufficientGasForMint = 37629
    /// Owner cannot be zero
    OwnerCannotBeZero = 38148
    /// No enough TON
    NoEnoughTON = 47154
    /// User already exists
    UserAlreadyExists = 47804
    /// Only owner can mint initial jettons
    OnlyOwnerCanMintInitialJettons = 49429
    /// Insufficient ton amount
    InsufficientTonAmount = 49755
    /// Owner jettons already minted
    OwnerJettonsAlreadyMinted = 53531
    /// Only owner can set jetton master
    OnlyOwnerCanSetJettonMaster = 53922
    /// Amount should be positive
    AmountShouldBePositive = 54379
    /// Insufficient balance
    InsufficientBalance = 54615
}

get fun get_jetton_data(): PRMDJettonMasterJettonMasterData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
