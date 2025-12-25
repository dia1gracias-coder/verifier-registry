// Generated from the verified Tact contract ABI.
contract JettonMinter {
    storage: JettonMinterData
    incomingMessages: JettonMinterIncomingMessage
    thrownErrors: JettonMinterErrors
}

struct JettonMinterStateInit {
    code: cell
    data: cell
}

struct (0x00000004) JettonMinterJettonUpdateContent {
    queryId: uint64
    content: cell
}

struct (0x178d4519) JettonMinterJettonTransferInternal {
    queryId: uint64
    amount: coins
    sender: address
    responseDestination: address?
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x7bdd97de) JettonMinterJettonBurnNotification {
    queryId: uint64
    amount: coins
    sender: address
    responseDestination: address?
}

struct (0x2c76b973) JettonMinterProvideWalletAddress {
    queryId: uint64
    ownerAddress: address
    includeAddress: bool
}

struct (0x00000016) JettonMinterCloseMinting {
}

struct (0x00000003) JettonMinterChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x0393b1ce) JettonMinterClaimTON {
    receiver: address
}

struct (0x7574f80a) JettonMinterClaimTONAirdrop {
    receiver: address
}

struct (0x591036cb) JettonMinterVestingDistribution {
    queryId: uint64
    vestingId: uint8
    transferMessage: JettonMinterJettonTransferInternal
    tactContinuation: Cell<JettonMinterVestingDistributionContinuation>
}

struct JettonMinterVestingDistributionContinuation {
    setupVestingMessage: JettonMinterSetupVesting
}

struct (0x4e760299) JettonMinterAirdropDistribution {
    queryId: uint64
    transferMessage: JettonMinterJettonTransferInternal
}

struct (0xcb9a581a) JettonMinterSetupUnlockRoot {
    unlockRoot: uint256
}

struct (0x4fcb6581) JettonMinterUpdateUnlock {
    unlockProof: cell
}

struct (0xeacf51e2) JettonMinterSetupVesting {
    name: string
    owner: address
    amount: coins
    deployTime: uint32?
    cliffDuration: uint32
    vestingDuration: uint32
}

struct (0x763493ce) JettonMinterSetupAirdrop {
    hashRoot: uint256
}

struct (0x202c3dc3) JettonMinterStopAirdrop {
}

struct (0x065eafcc) JettonMinterAirdropBurn {
    queryId: uint64
    amount: coins
    responseDestination: address?
    customPayload: cell?
}

struct JettonMinterState {
    totalSupply: coins
    mintable: bool
    adminAddress: address
    jettonContent: cell
    jettonWalletCode: cell
}

struct JettonMinterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    totalSupply: coins
    owner: address
    jettonContent: cell
    mintable: bool
    isAirdropInitialized: bool
    merkleRoot: uint256
}

type JettonMinterIncomingMessage =
    | JettonMinterJettonBurnNotification
    | JettonMinterJettonUpdateContent
    | JettonMinterChangeOwner
    | JettonMinterCloseMinting
    | JettonMinterClaimTON
    | JettonMinterClaimTONAirdrop
    | JettonMinterProvideWalletAddress
    | JettonMinterVestingDistribution
    | JettonMinterAirdropDistribution
    | JettonMinterSetupUnlockRoot
    | JettonMinterUpdateUnlock
    | JettonMinterSetupAirdrop
    | JettonMinterStopAirdrop
    | JettonMinterAirdropBurn

enum JettonMinterErrors {
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

get fun get_jetton_data(): JettonMinterState {
    throw 0;
}

get fun get_wallet_address(ownerAddress: address): address {
    throw 0;
}

get fun vestingAddress(id: int257): address {
    throw 0;
}

get fun jettonVestingInit(id: int257): JettonMinterStateInit {
    throw 0;
}

get fun unlockMerkleRoot(): int257 {
    throw 0;
}

get fun airdropInitialized(): bool {
    throw 0;
}

get fun airdropAddress(): address {
    throw 0;
}
