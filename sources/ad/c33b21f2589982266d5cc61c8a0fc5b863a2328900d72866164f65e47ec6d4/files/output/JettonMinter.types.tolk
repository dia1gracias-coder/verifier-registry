// Generated from the verified Tact contract ABI.
contract JettonMinter {
    storage: JettonMinterData
    incomingMessages: JettonMinterIncomingMessage
    thrownErrors: JettonMinterErrors
}

struct (0x7bdd97de) JettonMinterTokenBurnNotification {
    queryId: uint64
    amount: coins
    sender: address
    responseDestination: address?
}

struct (0x642b7d07) JettonMinterTokenUpdateContent {
    content: cell
}

struct (0x00000001) JettonMinterMint {
    queryId: uint64
    amount: coins
    receiver: address
}

struct (0x4a6f7e8f) JettonMinterFreezeWallet {
    target: address
    frozen: bool
}

struct (0x5b7c8d9e) JettonMinterProposeOwner {
    newOwner: address
}

struct (0x6c8d9eaf) JettonMinterAcceptOwnership {
    queryId: uint64
}

struct (0x11223344) JettonMinterTokenTransferViaRouter {
    queryId: uint64
    amount: coins
    from: address
    destination: address
    responseDestination: address?
    customPayload: cell?
    tactContinuation: Cell<JettonMinterTokenTransferViaRouterContinuation>
}

struct JettonMinterTokenTransferViaRouterContinuation {
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct JettonMinterJettonMasterData {
    totalSupply: coins
    mintable: bool
    adminAddress: address
    content: cell
    walletCode: cell
}

struct JettonMinterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    pendingOwner: address?
    totalSupply: coins
    maxSupply: coins
    mintable: bool
    burnable: bool
    pausable: bool
    freezable: bool
    transfersPaused: bool
    frozen: map<address, bool>
    content: cell
    ownershipRenounced: bool
}

type JettonMinterIncomingMessage =
    | JettonMinterMint
    | JettonMinterTokenTransferViaRouter
    | JettonMinterTokenBurnNotification
    | JettonMinterFreezeWallet
    | JettonMinterTokenUpdateContent
    | JettonMinterProposeOwner
    | JettonMinterAcceptOwnership

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
    /// JettonWallet: insufficient balance
    JettonWalletInsufficientBalance = 3189
    /// JettonMinter: same owner
    JettonMinterSameOwner = 4902
    /// JettonMinter: already renounced
    JettonMinterAlreadyRenounced = 5918
    /// JettonMinter: zero amount
    JettonMinterZeroAmount = 7463
    /// JettonFactory: platform is paused
    JettonFactoryPlatformIsPaused = 9311
    /// JettonMinter: no pending owner
    JettonMinterNoPendingOwner = 13300
    /// JettonMinter: token is not pausable
    JettonMinterTokenIsNotPausable = 14201
    /// JettonMinter: token is not freezable
    JettonMinterTokenIsNotFreezable = 15274
    /// JettonMinter: unauthorized router sender
    JettonMinterUnauthorizedRouterSender = 16455
    /// JettonMinter: invalid wallet sender
    JettonMinterInvalidWalletSender = 17824
    /// JettonWallet: zero amount
    JettonWalletZeroAmount = 18219
    /// JettonWallet: credit must come from minter
    JettonWalletCreditMustComeFromMinter = 23655
    /// JettonMinter: not paused
    JettonMinterNotPaused = 24355
    /// JettonFactory: nothing to withdraw
    JettonFactoryNothingToWithdraw = 25780
    /// JettonMinter: transfers are paused
    JettonMinterTransfersArePaused = 26881
    /// JettonWallet: not owner
    JettonWalletNotOwner = 27205
    /// JettonMinter: already minted
    JettonMinterAlreadyMinted = 32287
    /// JettonFactory: caller is not owner
    JettonFactoryCallerIsNotOwner = 32947
    /// JettonFactory: insufficient fee attached
    JettonFactoryInsufficientFeeAttached = 34058
    /// JettonMinter: exceeds max supply
    JettonMinterExceedsMaxSupply = 34064
    /// JettonMinter: not pending owner
    JettonMinterNotPendingOwner = 34169
    /// JettonMinter: token is not mintable
    JettonMinterTokenIsNotMintable = 35454
    /// JettonMinter: caller is not owner
    JettonMinterCallerIsNotOwner = 43532
    /// JettonMinter: destination wallet is frozen
    JettonMinterDestinationWalletIsFrozen = 46900
    /// JettonMinter: token is not burnable
    JettonMinterTokenIsNotBurnable = 51376
    /// JettonMinter: ownership renounced
    JettonMinterOwnershipRenounced = 53315
    /// JettonMinter: sender wallet is frozen
    JettonMinterSenderWalletIsFrozen = 54759
    /// JettonWallet: mint must come from minter
    JettonWalletMintMustComeFromMinter = 55951
    /// JettonMinter: zero address
    JettonMinterZeroAddress = 61271
    /// JettonMinter: wallet is frozen
    JettonMinterWalletIsFrozen = 63392
    /// JettonMinter: already paused
    JettonMinterAlreadyPaused = 63783
}

get fun get_jetton_data(): JettonMinterJettonMasterData {
    throw 0;
}

get fun get_wallet_address(ownerAddress: address): address {
    throw 0;
}

get fun isBurnable(): bool {
    throw 0;
}

get fun isMintable(): bool {
    throw 0;
}

get fun isPausable(): bool {
    throw 0;
}

get fun isFreezable(): bool {
    throw 0;
}

get fun isTransfersPaused(): bool {
    throw 0;
}

get fun isOwnershipRenounced(): bool {
    throw 0;
}

get fun maxSupply(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun pendingOwner(): address? {
    throw 0;
}

get fun isWalletFrozen(addr: address): bool {
    throw 0;
}
