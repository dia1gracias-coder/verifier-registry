// Generated from the verified Tact contract ABI.
contract DepositJetton {
    storage: DepositJettonData
    incomingMessages: DepositJettonIncomingMessage
    thrownErrors: DepositJettonErrors
}

struct (0xe737c304) DepositJettonNotifyDepositEvent {
    user: address
    before: coins
    after: coins
    counter: uint32
}

struct (0xd4071e7b) DepositJettonTakeFund {
    amount: coins?
}

struct (0xd1735400) DepositJettonTakeWalletAddress {
    queryId: uint64
    walletAddress: address
    ownerAddress: cell
}

struct (0x7362d09c) DepositJettonJettonTransferNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: cell?
}

struct DepositJettonData {
    tactSystemCell: cell
    admin: address
    jettonMaster: address
    jettonWallet: address?
}

type DepositJettonIncomingMessage =
    | DepositJettonTakeWalletAddress
    | DepositJettonJettonTransferNotification
    | DepositJettonTakeFund
    | DepositJettonNotifyDepositEvent

enum DepositJettonErrors {
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
    /// Invalid Message
    InvalidMessage = 13521
    /// Jetton Inited
    JettonInited = 16625
    /// Invalid Amount
    InvalidAmount = 30404
    /// Unautorized
    Unautorized = 37558
    /// Unauthorized
    Unauthorized = 49729
    /// Not my address
    NotMyAddress = 58630
    /// Not Jetton Master
    NotJettonMaster = 61190
}
