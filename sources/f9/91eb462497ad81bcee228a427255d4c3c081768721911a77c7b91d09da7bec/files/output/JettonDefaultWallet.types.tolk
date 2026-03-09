// Generated from the verified Tact contract ABI.
contract JettonDefaultWallet {
    storage: JettonDefaultWalletData
    incomingMessages: JettonDefaultWalletIncomingMessage
    thrownErrors: JettonDefaultWalletErrors
}

struct JettonDefaultWalletJettonWalletData {
    balance: int257
    owner: address
    master: address
    walletCode: cell
}

struct (0xe54bcffe) JettonDefaultWalletTokenTransfer {
    queryId: uint64
    amount: coins
    destination: address
    response_destination: address
    custom_payload: cell?
    forward_ton_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0xd72cdde0) JettonDefaultWalletTokenTransferInternal {
    queryId: uint64
    amount: coins
    from: address
    response_destination: address?
    forward_ton_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x595f07bc) JettonDefaultWalletTokenBurn {
    queryId: uint64
    amount: coins
    owner: address
    response_destination: address
}

struct JettonDefaultWalletData {
    tactDeploymentCompleted: bool
    balance: int257
    owner: address
    master: address
}

type JettonDefaultWalletIncomingMessage =
    | JettonDefaultWalletTokenTransfer
    | JettonDefaultWalletTokenTransferInternal
    | JettonDefaultWalletTokenBurn

enum JettonDefaultWalletErrors {
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
    /// Invalid value!!
    InvalidValue = 4159
    /// Invalid sender
    InvalidSender = 4429
    /// The total supply will be overlapping.
    TheTotalSupplyWillBeOverlapping = 6898
    /// Minting is disabled
    MintingIsDisabled = 26288
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// Exceed supply
    ExceedSupply = 59310
    /// Invalid balance
    InvalidBalance = 62972
}

get fun msgValue(value: int257): int257 {
    throw 0;
}

get fun get_wallet_data(): JettonDefaultWalletJettonWalletData {
    throw 0;
}
