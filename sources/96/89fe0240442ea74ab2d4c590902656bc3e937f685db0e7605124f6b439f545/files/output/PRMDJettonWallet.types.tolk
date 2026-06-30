// Generated from the verified Tact contract ABI.
contract PRMDJettonWallet {
    storage: PRMDJettonWalletData
    incomingMessages: PRMDJettonWalletIncomingMessage
    thrownErrors: PRMDJettonWalletErrors
}

struct (0x0f8a7ea5) PRMDJettonWalletTokenTransfer {
    queryId: uint64
    amount: coins
    destination: address
    responseDestination: address?
    customPayload: cell?
    forwardAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x178d4519) PRMDJettonWalletTokenTransferInternal {
    queryId: uint64
    amount: coins
    from: address
    responseDestination: address?
    forwardAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x595f07bc) PRMDJettonWalletBurn {
    queryId: uint64
    amount: coins
    responseDestination: address?
    customPayload: cell?
}

struct PRMDJettonWalletJettonWalletData {
    balance: coins
    owner: address
    master: address
    walletCode: cell
}

struct PRMDJettonWalletData {
    tactDeploymentCompleted: bool
    balance: coins
    owner: address
    master: address
}

type PRMDJettonWalletIncomingMessage =
    | PRMDJettonWalletTokenTransfer
    | PRMDJettonWalletTokenTransferInternal
    | PRMDJettonWalletBurn

enum PRMDJettonWalletErrors {
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

get fun get_wallet_data(): PRMDJettonWalletJettonWalletData {
    throw 0;
}
