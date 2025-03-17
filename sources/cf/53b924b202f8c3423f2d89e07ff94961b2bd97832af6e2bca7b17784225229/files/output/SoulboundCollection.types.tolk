// Generated from the verified Tact contract ABI.
contract SoulboundCollection {
    storage: SoulboundCollectionData
    incomingMessages: SoulboundCollectionIncomingMessage
    thrownErrors: SoulboundCollectionErrors
}

struct SoulboundCollectionStateInit {
    code: cell
    data: cell
}

struct (0xad43343a) SoulboundCollectionMint {
    new_owner: address
    anima_collection: string
}

struct (0xbaf05107) SoulboundCollectionBurn {
    owner: address
    anima_collection: string
    response_destination: address
}

struct (0x397d0cd8) SoulboundCollectionAddAdmin {
    admin_to_add: address
}

struct (0x3537587e) SoulboundCollectionRemoveAdmin {
    admin_to_remove: address
}

struct (0x946a98b6) SoulboundCollectionDeploy {
    queryId: uint64
}

struct SoulboundCollectionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    next_item_index: uint32
    collection_content: cell
    admin_list: map<address, int257>
}

type SoulboundCollectionIncomingMessage =
    | SoulboundCollectionMint
    | SoulboundCollectionBurn
    | SoulboundCollectionAddAdmin
    | SoulboundCollectionRemoveAdmin
    | SoulboundCollectionDeploy

enum SoulboundCollectionErrors {
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
    /// Already initialized
    AlreadyInitialized = 2977
    /// Address not found in admin list
    AddressNotFoundInAdminList = 3382
    /// Only admin can add admin
    OnlyAdminCanAddAdmin = 40478
    /// Only admin can burn
    OnlyAdminCanBurn = 41393
    /// Only admin can remove admin
    OnlyAdminCanRemoveAdmin = 46044
    /// Only admin can mint
    OnlyAdminCanMint = 49384
    /// Not from collection contract
    NotFromCollectionContract = 57163
    /// non-sequential NFTs
    NonSequentialNFTs = 62742
}

get fun get_nft_address_by_owner_and_anima_collection(owner: address, anima_collection: string): address {
    throw 0;
}

get fun get_nft_item_init(owner: address, anima_collection: string): SoulboundCollectionStateInit {
    throw 0;
}

get fun next_nft_id(): int257 {
    throw 0;
}

get fun admins_list(): map<address, int257> {
    throw 0;
}

get fun get_collection_data(): cell {
    throw 0;
}
