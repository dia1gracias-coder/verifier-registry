// Generated from the verified Tact contract ABI.
contract JettonWallet {
    storage: JettonWalletData2
    incomingMessages: JettonWalletIncomingMessage
    thrownErrors: JettonWalletErrors
}

struct JettonWalletJettonFullInfo {
    balance: coins
    airdropAmount: coins
    transferableBalance: coins
    startUnlockTime: uint32
    perSecond: coins
    unlockByTime: coins
    unlockByActivity: coins
}

struct JettonWalletData {
    balance: int257
    owner: address
    minter: address
    code: cell
}

struct (0x0f8a7ea5) JettonWalletJettonTransfer {
    queryId: uint64
    amount: coins
    destination: address
    responseDestination: address?
    customPayload: cell?
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x178d4519) JettonWalletJettonTransferInternal {
    queryId: uint64
    amount: coins
    sender: address
    responseDestination: address?
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x595f07bc) JettonWalletJettonBurn {
    queryId: uint64
    amount: coins
    responseDestination: address?
    customPayload: cell?
}

struct (0x7ac8d559) JettonWalletProvideWalletBalance {
    receiver: address
    includeVerifyInfo: bool
}

struct (0x0393b1ce) JettonWalletClaimTON {
    receiver: address
}

struct (0x05670686) JettonWalletUpdateUnlockByActivity {
    unlockValue: coins
}

struct (0x41a1bacd) JettonWalletClaimAirdrop {
    queryId: uint64
    destination: address
    responseDestination: address?
    airdropProof: cell
}

struct JettonWalletData2 {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    minter: address
    airdrop: address
    balance: coins
    tactContinuation: Cell<JettonWalletDataContinuation>
}

struct JettonWalletDataContinuation {
    airdropAmount: coins
    transferableBalance: coins
    startUnlockTime: uint32
    lastUnlockTime: uint32
    unlockByTime: coins
    unlockByActivity: coins
}

type JettonWalletIncomingMessage =
    | JettonWalletUpdateUnlockByActivity
    | JettonWalletClaimAirdrop
    | JettonWalletJettonTransfer
    | JettonWalletJettonTransferInternal
    | JettonWalletProvideWalletBalance
    | JettonWalletJettonBurn
    | JettonWalletClaimTON

enum JettonWalletErrors {
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
    /// Airdrop proof expired
    AirdropProofExpired = 2130
    /// Incorrect balance after send
    IncorrectBalanceAfterSend = 2366
    /// Airdrop already setup
    AirdropAlreadySetup = 4571
    /// Incorrect sender
    IncorrectSender = 9215
    /// Incorrect destination
    IncorrectDestination = 9968
    /// Unauthorized burn
    UnauthorizedBurn = 10363
    /// Vesting contract already setup
    VestingContractAlreadySetup = 10383
    /// Cannot stop airdrop yet
    CannotStopAirdropYet = 15730
    /// Requested amount exceeds available
    RequestedAmountExceedsAvailable = 20380
    /// Unlock proof expired
    UnlockProofExpired = 20452
    /// Cliff period active
    CliffPeriodActive = 21078
    /// Airdrop proof not started
    AirdropProofNotStarted = 22520
    /// Airdrop already claimed
    AirdropAlreadyClaimed = 25675
    /// Insufficient amount of TON attached
    InsufficientAmountOfTONAttached = 32113
    /// Insufficient gas for mint
    InsufficientGasForMint = 37629
    /// Incorrect transferableBalance after send
    IncorrectTransferableBalanceAfterSend = 43119
    /// Airdrop not configured
    AirdropNotConfigured = 45961
    /// Airdrop is stopped
    AirdropIsStopped = 49077
    /// Mint is closed
    MintIsClosed = 51950
    /// Not avalible tokens for transfer
    NotAvalibleTokensForTransfer = 54948
    /// Airdrop already initialized
    AirdropAlreadyInitialized = 56981
    /// Airdrop not stopped
    AirdropNotStopped = 57254
    /// Unlock proof not started
    UnlockProofNotStarted = 57934
    /// Unlock not configured
    UnlockNotConfigured = 61468
}

get fun get_wallet_data(): JettonWalletData {
    throw 0;
}

get fun fullData(): JettonWalletJettonFullInfo {
    throw 0;
}
