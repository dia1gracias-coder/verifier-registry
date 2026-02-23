// Generated from the verified Tact contract ABI.
contract JettonWallet {
    storage: JettonWalletData
    incomingMessages: JettonWalletIncomingMessage
    thrownErrors: JettonWalletErrors
}

struct (0xdb8393ac) JettonWalletJettonTransferInternal {
    queryId: uint64
    amount: coins
    from: address
    responseDestination: address
    forwardAmount: coins
}

struct (0x84cc682d) JettonWalletJettonTransfer {
    queryId: uint64
    amount: coins
    destination: address
    responseDestination: address
    forwardAmount: coins
}

struct (0xfa22a8a4) JettonWalletJettonBurn {
    queryId: uint64
    amount: coins
    responseDestination: address
}

struct JettonWalletData {
    tactDeploymentCompleted: bool
    balance: coins
    owner: address
    minter: address
}

type JettonWalletIncomingMessage =
    | JettonWalletJettonTransferInternal
    | JettonWalletJettonTransfer
    | JettonWalletJettonBurn

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
    /// Only owner can burn
    OnlyOwnerCanBurn = 21543
    /// Only owner can transfer
    OnlyOwnerCanTransfer = 36952
    /// Only minter can mint
    OnlyMinterCanMint = 41652
    /// Insufficient balance
    InsufficientBalance = 54615
    /// Only owner can mint
    OnlyOwnerCanMint = 57579
    /// Amount must be positive
    AmountMustBePositive = 61135
}

get fun balance(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
