// Generated from the verified Tact contract ABI.
contract AdvancedGiftWallet {
    storage: AdvancedGiftWalletData
    incomingMessages: AdvancedGiftWalletIncomingMessage
    thrownErrors: AdvancedGiftWalletErrors
}

struct (0x0f8a7ea5) AdvancedGiftWalletTokenTransfer {
    query_id: uint64
    amount: coins
    destination: address
    response_destination: address?
    custom_payload: cell?
    forward_ton_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x178d4519) AdvancedGiftWalletTokenTransferInternal {
    query_id: uint64
    amount: coins
    from: address
    response_destination: address?
    forward_ton_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x595f07bc) AdvancedGiftWalletTokenBurn {
    query_id: uint64
    amount: coins
    response_destination: address?
    custom_payload: cell?
}

struct AdvancedGiftWalletJettonWalletData {
    balance: int257
    ownerAddress: address
    masterAddress: address
    walletCode: cell
}

struct AdvancedGiftWalletData {
    tactDeploymentCompleted: bool
    balance: coins
    owner: address
    master: address
}

type AdvancedGiftWalletIncomingMessage =
    | AdvancedGiftWalletTokenTransfer
    | AdvancedGiftWalletTokenTransferInternal
    | AdvancedGiftWalletTokenBurn

enum AdvancedGiftWalletErrors {
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
    /// Not mintable
    NotMintable = 3688
    /// Not Owner
    NotOwner = 3734
    /// Invalid sender
    InvalidSender = 4429
    /// Invalid value
    InvalidValue = 16059
    /// Contract paused
    ContractPaused = 53793
    /// Invalid balance
    InvalidBalance = 62972
}

get fun get_wallet_data(): AdvancedGiftWalletJettonWalletData {
    throw 0;
}
