// Generated from the verified Tact contract ABI.
contract RezaToken {
    storage: RezaTokenData
    incomingMessages: RezaTokenIncomingMessage
    thrownErrors: RezaTokenErrors
}

struct (0x819dbe99) RezaTokenChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0xfc708bd2) RezaTokenMint {
    amount: int257
    receiver: address
}

struct (0x152087bf) RezaTokenMintPublic {
    amount: int257
}

struct (0x9dd31253) RezaTokenDiscover {
    queryId: uint64
}

struct (0x69a83aaa) RezaTokenSetTransactionLimit {
    limit: coins
}

struct (0xaaa56b9f) RezaTokenCheckTransactionLimit {
    queryId: uint64
    amount: coins
    sender: address
}

struct (0x8eb6c2bb) RezaTokenAddExcludedAddress {
    address: address
}

struct (0xc2abae41) RezaTokenRemoveExcludedAddress {
    address: address
}

struct RezaTokenJettonData {
    totalSupply: int257
    mintable: bool
    owner: address
    content: cell
    walletCode: cell
}

struct (0x7bdd97de) RezaTokenTokenBurnNotification {
    queryId: uint64
    amount: coins
    owner: address
    response_destination: address?
}

struct (0xaf1ca26a) RezaTokenTokenUpdateContent {
    content: cell
}

struct RezaTokenData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    totalSupply: int257
    owner: address
    content: cell
    mintable: bool
    max_supply: int257
    tactContinuation: Cell<RezaTokenDataContinuation>
}

struct RezaTokenDataContinuation {
    name: string
    symbol: string
    decimals: int257
    transactionLimit: int257
    excludedAddresses: map<address, bool>
}

type RezaTokenIncomingMessage =
    | RezaTokenMint
    | RezaTokenMintPublic
    | RezaTokenDiscover
    | RezaTokenSetTransactionLimit
    | RezaTokenAddExcludedAddress
    | RezaTokenRemoveExcludedAddress
    | RezaTokenCheckTransactionLimit
    | RezaTokenTokenUpdateContent
    | RezaTokenTokenBurnNotification
    | RezaTokenChangeOwner

enum RezaTokenErrors {
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
    /// Not Owner
    NotOwner = 3734
    /// Invalid value!!
    InvalidValue = 4159
    /// Invalid sender
    InvalidSender = 4429
    /// Cannot remove owner from exclusions
    CannotRemoveOwnerFromExclusions = 6158
    /// The total supply will be overlapping.
    TheTotalSupplyWillBeOverlapping = 6898
    /// Exceeds max supply
    ExceedsMaxSupply = 14796
    /// Invalid amount
    InvalidAmount = 17062
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Invalid limit
    InvalidLimit = 23048
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// Invalid balance
    InvalidBalance = 62972
}

get fun get_name(): string {
    throw 0;
}

get fun get_symbol(): string {
    throw 0;
}

get fun get_decimals(): int257 {
    throw 0;
}

get fun get_total_supply(): int257 {
    throw 0;
}

get fun get_mintable(): bool {
    throw 0;
}

get fun get_content(): cell {
    throw 0;
}

get fun get_transaction_limit(): int257 {
    throw 0;
}

get fun is_excluded_address(address: address): bool {
    throw 0;
}

get fun get_jetton_data(): RezaTokenJettonData {
    throw 0;
}

get fun get_wallet_address(owner: address): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
