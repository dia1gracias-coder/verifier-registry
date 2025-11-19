// Generated from the verified Tact contract ABI.
contract PartnerNftCollection {
    storage: PartnerNftCollectionData
    incomingMessages: PartnerNftCollectionIncomingMessage
    thrownErrors: PartnerNftCollectionErrors
}

struct (0xb803b08d) PartnerNftCollectionIncrementSuccessfulTx {
    wallet: address
}

struct (0x157c62bb) PartnerNftCollectionMint {
    to: address
    shareBps: int257
    uri: string
}

struct (0xca9e378a) PartnerNftCollectionBurn {
    tokenId: int257
}

struct (0x791c083b) PartnerNftCollectionSetTxProcessor {
    processor: address
    allowed: bool
}

struct (0x1599f05f) PartnerNftCollectionSetWalletWhitelist {
    wallet: address
    allowed: bool
}

struct PartnerNftCollectionCollectionData {
    next_item_index: int257
    collection_content: cell
    owner_address: slice
}

struct PartnerNftCollectionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    nextItemIndex: int257
    collectionContent: cell
    tactContinuation: Cell<PartnerNftCollectionDataContinuation>
}

struct PartnerNftCollectionDataContinuation {
    itemCode: cell
    walletWhitelist: map<address, bool>
    walletIndex: map<address, int257>
    tactContinuation: Cell<PartnerNftCollectionDataContinuation2>
}

struct PartnerNftCollectionDataContinuation2 {
    tokenShareBps: map<int257, int257>
    successfulTxCount: map<int257, int257>
    txProcessors: map<address, bool>
    indexToAddress: map<int257, address>
}

type PartnerNftCollectionIncomingMessage =
    | PartnerNftCollectionMint
    | PartnerNftCollectionBurn
    | PartnerNftCollectionSetWalletWhitelist
    | PartnerNftCollectionSetTxProcessor
    | PartnerNftCollectionIncrementSuccessfulTx

enum PartnerNftCollectionErrors {
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
}

get fun get_collection_data(): PartnerNftCollectionCollectionData {
    throw 0;
}

get fun get_nft_address_by_index(index: int257): address {
    throw 0;
}

get fun get_nft_content(index: int257, individual_content: cell): cell {
    throw 0;
}

get fun successfulTxCountOf(wallet: address): int257 {
    throw 0;
}

get fun tokenOf(owner: address): int257 {
    throw 0;
}

get fun isWalletWhitelisted(wallet: address): bool {
    throw 0;
}

get fun platformShareBpsForWallet(wallet: address): int257? {
    throw 0;
}

get fun isPaymentProccesorAllowed(processor: address): bool {
    throw 0;
}

get fun get_version(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
