// Generated from the verified Tact contract ABI.
contract BondingJettonWallet {
    storage: BondingJettonWalletData
    incomingMessages: BondingJettonWalletIncomingMessage
    thrownErrors: BondingJettonWalletErrors
}

struct (0x0f8a7ea5) BondingJettonWalletJettonTransfer {
    queryId: uint64
    amount: coins
    destination: address
    responseDestination: address
    customPayload: cell?
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x178d4519) BondingJettonWalletJettonInternalTransfer {
    queryId: uint64
    amount: coins
    from: address
    responseAddress: address
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x595f07bc) BondingJettonWalletJettonBurn {
    queryId: uint64
    amount: coins
    responseDestination: address
    customPayload: cell?
}

struct BondingJettonWalletWalletData {
    balance: coins
    owner: address
    master: address
    walletCode: cell
}

struct BondingJettonWalletData {
    tactDeploymentCompleted: bool
    balance: coins
    owner: address
    master: address
}

type BondingJettonWalletIncomingMessage =
    | BondingJettonWalletJettonInternalTransfer
    | BondingJettonWalletJettonTransfer
    | BondingJettonWalletJettonBurn

enum BondingJettonWalletErrors {
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
    /// Zero mint
    ZeroMint = 2570
    /// Insufficient value
    InsufficientValue = 2805
    /// Reserves drained
    ReservesDrained = 3494
    /// Invalid sender
    InvalidSender = 4429
    /// Underflow
    Underflow = 9946
    /// Below min buy
    BelowMinBuy = 12230
    /// Cooldown active
    CooldownActive = 16483
    /// Curve closed
    CurveClosed = 22776
    /// Zero burn
    ZeroBurn = 26371
    /// Only owner
    OnlyOwner = 35499
    /// Invalid wallet
    InvalidWallet = 36088
    /// Zero payout
    ZeroPayout = 44049
    /// Insufficient balance
    InsufficientBalance = 54615
}

get fun get_wallet_data(): BondingJettonWalletWalletData {
    throw 0;
}
