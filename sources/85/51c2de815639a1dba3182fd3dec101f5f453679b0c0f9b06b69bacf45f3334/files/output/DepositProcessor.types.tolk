// Generated from the verified Tact contract ABI.
contract DepositProcessor {
    storage: DepositProcessorData
    incomingMessages: DepositProcessorIncomingMessage
    thrownErrors: DepositProcessorErrors
}

struct (0x7362d09c) DepositProcessorJettonTransferNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0xd53276db) DepositProcessorJettonExcesses {
    queryId: uint64
}

struct (0xd1735400) DepositProcessorTakeWalletAddress {
    queryId: uint64
    walletAddress: address
    ownerAddress: cell?
}

struct (0xfa45c39a) DepositProcessorDiscoverJettonWallet {
    queryId: uint64
}

struct (0x5ab8a8f4) DepositProcessorSetJettonWalletAddress {
    jettonWalletAddress: address
}

struct (0xb0e5476e) DepositProcessorUpdateSystemAddress {
    newSystemAddress: address
}

struct (0x096819ff) DepositProcessorSetPaused {
    paused: bool
}

struct (0xa85f1821) DepositProcessorSweepJettons {
    queryId: uint64
    amount: coins
    transferTonAmount: coins
}

struct (0xfabed8e6) DepositProcessorWithdrawTon {
    amount: coins
}

struct (0x70373fea) DepositProcessorTransferOwnership {
    newOwner: address
}

struct (0x10f842bd) DepositProcessorAcceptOwnership {
}

struct (0x70d25280) DepositProcessorCancelOwnershipTransfer {
}

struct (0x56414f0b) DepositProcessorRenounceOwnership {
    confirmation: uint32
}

struct DepositProcessorData {
    tactDeploymentCompleted: bool
    owner: address
    pendingOwner: address?
    renounced: bool
    systemAddress: address
    tactContinuation: Cell<DepositProcessorDataContinuation>
}

struct DepositProcessorDataContinuation {
    jettonMaster: address
    jettonWalletAddress: address?
    paused: bool
    nonce: uint64
}

type DepositProcessorIncomingMessage =
    | DepositProcessorJettonTransferNotification
    | DepositProcessorJettonExcesses
    | DepositProcessorDiscoverJettonWallet
    | DepositProcessorTakeWalletAddress
    | DepositProcessorSetJettonWalletAddress
    | DepositProcessorSweepJettons
    | DepositProcessorUpdateSystemAddress
    | DepositProcessorSetPaused
    | DepositProcessorWithdrawTon
    | DepositProcessorTransferOwnership
    | DepositProcessorAcceptOwnership
    | DepositProcessorCancelOwnershipTransfer
    | DepositProcessorRenounceOwnership

enum DepositProcessorErrors {
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
    /// DepositProcessor: invalid system address
    DepositProcessorInvalidSystemAddress = 4758
    /// DepositProcessor: already the owner
    DepositProcessorAlreadyTheOwner = 5111
    /// DepositProcessor: invalid new owner
    DepositProcessorInvalidNewOwner = 5164
    /// DepositProcessor: pending transfer exists
    DepositProcessorPendingTransferExists = 6788
    /// DepositProcessor: Jetton wallet already configured
    DepositProcessorJettonWalletAlreadyConfigured = 8000
    /// DepositProcessor: amount exceeds available
    DepositProcessorAmountExceedsAvailable = 8884
    /// DepositProcessor: ownership renounced
    DepositProcessorOwnershipRenounced = 10155
    /// DepositProcessor: invalid transfer TON amount
    DepositProcessorInvalidTransferTONAmount = 13975
    /// DepositProcessor: Jetton wallet not configured
    DepositProcessorJettonWalletNotConfigured = 16921
    /// DepositProcessor: invalid sweep amount
    DepositProcessorInvalidSweepAmount = 23655
    /// DepositProcessor: paused
    DepositProcessorPaused = 28699
    /// DepositProcessor: unauthorized Jetton master
    DepositProcessorUnauthorizedJettonMaster = 29916
    /// DepositProcessor: insufficient attached TON
    DepositProcessorInsufficientAttachedTON = 37315
    /// DepositProcessor: invalid Jetton wallet
    DepositProcessorInvalidJettonWallet = 38857
    /// DepositProcessor: not the pending owner
    DepositProcessorNotThePendingOwner = 42583
    /// DepositProcessor: nothing to withdraw
    DepositProcessorNothingToWithdraw = 45731
    /// DepositProcessor: unauthorized Jetton wallet
    DepositProcessorUnauthorizedJettonWallet = 47071
    /// DepositProcessor: pause status unchanged
    DepositProcessorPauseStatusUnchanged = 47185
    /// DepositProcessor: invalid amount
    DepositProcessorInvalidAmount = 56239
    /// DepositProcessor: wrong renounce confirmation
    DepositProcessorWrongRenounceConfirmation = 59162
    /// DepositProcessor: system address unchanged
    DepositProcessorSystemAddressUnchanged = 59924
    /// DepositProcessor: pause before renouncing
    DepositProcessorPauseBeforeRenouncing = 62268
    /// DepositProcessor: no pending owner
    DepositProcessorNoPendingOwner = 63960
}

get fun systemAddress(): address {
    throw 0;
}

get fun token(): address {
    throw 0;
}

get fun jettonWalletAddress(): address? {
    throw 0;
}

get fun pendingOwner(): address? {
    throw 0;
}

get fun renounced(): bool {
    throw 0;
}

get fun paused(): bool {
    throw 0;
}

get fun nonce(): int257 {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
