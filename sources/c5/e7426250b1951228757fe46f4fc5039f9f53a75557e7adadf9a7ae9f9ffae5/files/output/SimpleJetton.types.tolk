// Generated from the verified Tact contract ABI.
contract SimpleJetton {
    storage: SimpleJettonData
    incomingMessages: SimpleJettonIncomingMessage
    thrownErrors: SimpleJettonErrors
}

struct (0x946a98b6) SimpleJettonDeploy {
    queryId: uint64
}

struct (0x819dbe99) SimpleJettonChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x49079133) SimpleJettonMint {
    amount: coins
    receiver: address
}

struct SimpleJettonJettonData {
    totalSupply: int257
    mintable: bool
    owner: address
    content: cell
    walletCode: cell
}

struct (0x7bdd97de) SimpleJettonTokenBurnNotification {
    queryId: uint64
    amount: coins
    owner: address
    response_destination: address?
}

struct (0xaf1ca26a) SimpleJettonTokenUpdateContent {
    content: cell
}

struct SimpleJettonData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    totalSupply: int257
    owner: address
    content: cell
    mintable: bool
    maxSupply: int257
}

type SimpleJettonIncomingMessage =
    | SimpleJettonMint
    | SimpleJettonTokenUpdateContent
    | SimpleJettonTokenBurnNotification
    | SimpleJettonChangeOwner
    | SimpleJettonDeploy

enum SimpleJettonErrors {
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
    /// Exceeds max supply
    ExceedsMaxSupply = 14796
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Exceeds max supply of 10M tokens
    ExceedsMaxSupplyOf10MTokens = 22558
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// Invalid balance
    InvalidBalance = 62972
}

get fun get_max_supply(): int257 {
    throw 0;
}

get fun get_jetton_data(): SimpleJettonJettonData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
