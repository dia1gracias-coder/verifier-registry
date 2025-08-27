// Generated from the verified Tact contract ABI.
contract Bridge {
    storage: BridgeData
    incomingMessages: BridgeIncomingMessage
    thrownErrors: BridgeErrors
}

struct (0x946a98b6) BridgeDeploy {
    queryId: uint64
}

struct (0xc01d9831) BridgeWithdrawError {
    receiver: address
    errorCode: int257
    hash: int257
}

struct (0x12312323) BridgeMsgUpdateAdminKey {
    h: uint8
    x1: uint256
    x2: uint256
}

struct (0x13131444) BridgeMsgUpdateBridgeJettonWallets {
    jettons: map<address, address>
}

struct (0x13131555) BridgeMsgUpdateWrappedJetton {
    wrappedMasters: map<address, address>
}

struct (0x7187b179) BridgeMsgChangeJettonMasterOwner {
    newOwner: address
}

struct (0xd53276db) BridgeMsgExcesses {
    queryId: uint64
}

struct BridgeEcrecoverKey {
    h: uint8
    x1: uint256
    x2: uint256
}

struct (0xdcbd3cd5) BridgeUpgrade {
    code: cell?
    data: cell?
}

struct BridgeData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    bridgeJettonWallets: map<address, address>
    tactContinuation: Cell<BridgeDataContinuation>
}

struct BridgeDataContinuation {
    wrappedJetton: map<address, address>
    owner: address
    adminKeys: map<int257, Cell<BridgeEcrecoverKey>>
    _version: int257
}

type BridgeIncomingMessage =
    | BridgeMsgUpdateBridgeJettonWallets
    | BridgeMsgUpdateWrappedJetton
    | BridgeUpgrade
    | BridgeMsgChangeJettonMasterOwner
    | BridgeMsgUpdateAdminKey
    | BridgeWithdrawError
    | BridgeMsgExcesses
    | BridgeDeploy

enum BridgeErrors {
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
    /// NativeHandler: zero value
    NativeHandlerZeroValue = 8444
    /// Store: provided sender is not the same as the contract sender
    StoreProvidedSenderIsNotTheSameAsTheContractSender = 9531
    /// JettonHandler: amount is zero
    JettonHandlerAmountIsZero = 17683
    /// Bridge: insufficient value for validate hash
    BridgeInsufficientValueForValidateHash = 25557
    /// JettonHandler: totalTonAmount must be greater than forwardTonAmount
    JettonHandlerTotalTonAmountMustBeGreaterThanForwardTonAmount = 27248
    /// Store: only owner can call this function
    StoreOnlyOwnerCanCallThisFunction = 28655
    /// NativeHandler: amount is zero
    NativeHandlerAmountIsZero = 29767
    /// Bridge: insufficient value for upgrade
    BridgeInsufficientValueForUpgrade = 35287
    /// JettonHandler: insufficient value for message
    JettonHandlerInsufficientValueForMessage = 35643
    /// Bridge: only owner can set admin key
    BridgeOnlyOwnerCanSetAdminKey = 37185
    /// Store: insufficient value for response
    StoreInsufficientValueForResponse = 38966
    /// JettonHandler: JETTON_FEE must be less than totalTonAmount
    JettonHandlerJETTONFEEMustBeLessThanTotalTonAmount = 39722
    /// Bridge: sender is not the wrapped jetton wallet
    BridgeSenderIsNotTheWrappedJettonWallet = 42734
    /// Invalid signature length
    InvalidSignatureLength = 43253
    /// Bridge: sender is not the store address
    BridgeSenderIsNotTheStoreAddress = 46607
    /// Invalid signature
    InvalidSignature = 48401
    /// Bridge: sender is not a valid jetton wallet
    BridgeSenderIsNotAValidJettonWallet = 48748
    /// Bridge: only owner can upgrade
    BridgeOnlyOwnerCanUpgrade = 50762
    /// Bridge: only owner can update wrapped jetton
    BridgeOnlyOwnerCanUpdateWrappedJetton = 55349
    /// Bridge: only owner can update jetton wallets
    BridgeOnlyOwnerCanUpdateJettonWallets = 56014
    /// JettonHandler: insufficient value for message
    JettonHandlerInsufficientValueForMessage2 = 59260
    /// JettonHandler: zero requestHash
    JettonHandlerZeroRequestHash = 62717
}

get fun balance(): int257 {
    throw 0;
}

get fun code(): cell {
    throw 0;
}

get fun adminKeys(): map<int257, Cell<BridgeEcrecoverKey>> {
    throw 0;
}

get fun bridgeJettonWallets(): map<address, address> {
    throw 0;
}

get fun wrappedJetton(): map<address, address> {
    throw 0;
}

get fun pubkeyFromSignature(hash: int257, signature: slice): BridgeEcrecoverKey? {
    throw 0;
}

get fun jettonHash(amount_: int257, receiver_: address, txHash_: int257, txNonce_: int257, network_: slice, isWrapped_: bool, token_: address): int257 {
    throw 0;
}

get fun nativeHash(amount_: int257, receiver_: address, txHash_: int257, txNonce_: int257, network: slice): int257 {
    throw 0;
}

get fun isUpgradable(): bool {
    throw 0;
}

get fun version(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
