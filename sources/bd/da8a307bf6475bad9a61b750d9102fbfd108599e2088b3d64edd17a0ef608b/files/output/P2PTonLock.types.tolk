// Generated from the verified Tact contract ABI.
contract P2PTonLock {
    storage: P2PTonLockData
    incomingMessages: P2PTonLockIncomingMessage
    thrownErrors: P2PTonLockErrors
}

struct (0x946a98b6) P2PTonLockDeploy {
    queryId: uint64
}

struct P2PTonLockTrade {
    state: uint8
    amount: coins
    seller: address
    buyer: address
    jetton: address
    tactContinuation: Cell<P2PTonLockTradeContinuation>
}

struct P2PTonLockTradeContinuation {
    feeAmount: coins
    feeRecipient: address
}

struct P2PTonLockTradeView {
    state: int257
    amount: int257
    seller: address
    tactContinuation: Cell<P2PTonLockTradeViewContinuation>
}

struct P2PTonLockTradeViewContinuation {
    buyer: address
    jetton: address
    feeAmount: int257
    tactContinuation: Cell<P2PTonLockTradeViewContinuation2>
}

struct P2PTonLockTradeViewContinuation2 {
    feeRecipient: address
}

struct (0x7362d09c) P2PTonLockJettonTransferNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0x9a3b1c2d) P2PTonLockRelease {
    tradeId: uint256
}

struct (0x4c8d2e01) P2PTonLockDispute {
    tradeId: uint256
}

struct (0x2b7a9f55) P2PTonLockResolve {
    tradeId: uint256
    toBuyer: bool
}

struct (0x1e9c4a77) P2PTonLockRescueCompleted {
    tradeId: uint256
    to: address
    amount: coins
}

struct (0x5e8f1a03) P2PTonLockSetJettonWallet {
    wallet: address
}

struct P2PTonLockData {
    tactDeploymentCompleted: bool
    trades: map<uint256, Cell<P2PTonLockTrade>>
    arbiter: address
    jettonMaster: address
    myJettonWallet: address
    jettonWalletSet: bool
    payoutNonce: uint64
    tactContinuation: Cell<P2PTonLockDataContinuation>
}

struct P2PTonLockDataContinuation {
    payoutTrade: map<uint64, uint256>
    payoutRestore: map<uint64, uint8>
}

type P2PTonLockIncomingMessage =
    | P2PTonLockSetJettonWallet
    | P2PTonLockJettonTransferNotification
    | P2PTonLockRelease
    | P2PTonLockDispute
    | P2PTonLockResolve
    | P2PTonLockRescueCompleted
    | P2PTonLockDeploy

enum P2PTonLockErrors {
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
    /// exists
    Exists = 6585
    /// state
    State = 11885
    /// seller
    Seller = 15950
    /// amount
    Amount = 18372
    /// party
    Party = 26265
    /// payload
    Payload = 28805
    /// fee
    Fee = 32158
    /// set
    Set = 34057
    /// wallet
    Wallet = 36208
    /// arbiter
    Arbiter = 36389
    /// missing
    Missing = 43755
    /// op
    Op = 50178
    /// treasury
    Treasury = 52893
    /// buyer
    Buyer = 58728
}

get fun get_trade(tradeId: int257): P2PTonLockTradeView {
    throw 0;
}

get fun jetton_master(): address {
    throw 0;
}

get fun jetton_wallet(): address {
    throw 0;
}

get fun jetton_wallet_set(): bool {
    throw 0;
}
