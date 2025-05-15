// Generated from the verified Tact contract ABI.
contract NftCollection {
    storage: NftCollectionData
    incomingMessages: NftCollectionIncomingMessage
    thrownErrors: NftCollectionErrors
}

struct NftCollectionCollectionData {
    next_item_index: int257
    collection_content: cell
    owner_address: address
}

struct (0x65ae5ee8) NftCollectionStop_Time {
    seconds: int257
    query_id: uint64
}

struct (0x4e6760a3) NftCollectionStopped {
    query_id: uint64
}

struct (0x7aa9a724) NftCollectionUnstopped {
    query_id: uint64
}

struct (0xe3f0fd90) NftCollectionRemoveToWhitelist {
    address: address
    query_id: uint64
}

struct (0xc7aaf20e) NftCollectionAddToWhitelist {
    address: address
    query_id: uint64
}

struct NftCollectionList {
    _map: map<address, bool>
}

struct (0x79f8d455) NftCollectionWithdrawSafe {
    query_id: uint64
}

struct (0x43620644) NftCollectionWithdrawAll {
    query_id: uint64
}

struct (0xb4f84869) NftCollectionFreeMint {
    query_id: uint64
    to_address: address?
    custom_payload: cell?
}

struct (0x02fe6b9d) NftCollectionFreeManyMint {
    query_id: uint64
    to_addresses: map<int257, address>
    length: int257
}

struct (0x3666ce90) NftCollectionTransferOwnership {
    new_owner: address
    query_id: uint64
}

struct NftCollectionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    next_item_index: int257
    collection_content: cell
    owner_address: address
    stop: bool
    time_passed: int257
    list: NftCollectionList
}

type NftCollectionIncomingMessage =
    | NftCollectionFreeManyMint
    | NftCollectionFreeMint
    | NftCollectionTransferOwnership
    | NftCollectionStopped
    | NftCollectionUnstopped
    | NftCollectionStop_Time
    | NftCollectionRemoveToWhitelist
    | NftCollectionAddToWhitelist
    | NftCollectionWithdrawSafe
    | NftCollectionWithdrawAll

enum NftCollectionErrors {
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
    /// Stoppable: blocked
    StoppableBlocked = 14620
    /// Only owner
    OnlyOwner = 35499
    /// Stoppable: no time has passed
    StoppableNoTimeHasPassed = 37237
    /// Only the collection can initialize the NFT item
    OnlyTheCollectionCanInitializeTheNFTItem = 41017
    /// Stoppable: not blocked
    StoppableNotBlocked = 43262
    /// Stoppable: time passed
    StoppableTimePassed = 44743
    /// Not in whitelist
    NotInWhitelist = 49113
}

get fun balance(): int257 {
    throw 0;
}

get fun get_collection_data(): NftCollectionCollectionData {
    throw 0;
}

get fun get_nft_address_by_index(index: int257): address {
    throw 0;
}

get fun get_current_index(): int257 {
    throw 0;
}

get fun is_stop(): bool {
    throw 0;
}

get fun is_stopped(): bool {
    throw 0;
}

get fun stop_time(): int257 {
    throw 0;
}

get fun get_list(): NftCollectionList {
    throw 0;
}
