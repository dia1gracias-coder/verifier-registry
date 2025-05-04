// Generated from the verified Tact contract ABI.
contract NFTMinerItemsSettings {
    storage: NFTMinerItemsSettingsData
    incomingMessages: NFTMinerItemsSettingsIncomingMessage
    thrownErrors: NFTMinerItemsSettingsErrors
}

struct (0x946a98b6) NFTMinerItemsSettingsDeploy {
    queryId: uint64
}

struct NFTMinerItemsSettingsGetgemsAttribute {
    trait_type: string
    value: string
}

struct (0x80c2b257) NFTMinerItemsSettingsSetServerAddress {
    address: address
}

struct NFTMinerItemsSettingsNFTMinerItemData {
    code: string
    name: string
    tactContinuation: Cell<NFTMinerItemsSettingsNFTMinerItemDataContinuation>
}

struct NFTMinerItemsSettingsNFTMinerItemDataContinuation {
    description: string
    image: string
    mint_limit: uint32
    attributes: map<uint16, Cell<NFTMinerItemsSettingsGetgemsAttribute>>
    price_usd: uint32
    price_stars: uint32
    price_coins: uint32
}

struct (0xfb1be3fa) NFTMinerItemsSettingsNFTSetMinerItemData {
    code: string
    name: string
    tactContinuation: Cell<NFTMinerItemsSettingsNFTSetMinerItemDataContinuation>
}

struct NFTMinerItemsSettingsNFTSetMinerItemDataContinuation {
    description: string
    image: string
    mint_limit: uint32
    attributes: map<uint16, Cell<NFTMinerItemsSettingsGetgemsAttribute>>
    price_usd: uint32
    price_stars: uint32
    price_coins: uint32
}

struct NFTMinerItemsSettingsData {
    tactDeploymentCompleted: bool
    owner: address
    server_address: address?
    nft_miner_list: map<int257, Cell<NFTMinerItemsSettingsNFTMinerItemData>>
}

type NFTMinerItemsSettingsIncomingMessage =
    | NFTMinerItemsSettingsSetServerAddress
    | NFTMinerItemsSettingsNFTSetMinerItemData
    | NFTMinerItemsSettingsDeploy

enum NFTMinerItemsSettingsErrors {
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

get fun getServerAddress(): address? {
    throw 0;
}

get fun getMinerItems(): map<int257, Cell<NFTMinerItemsSettingsNFTMinerItemData>> {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
