// Generated from the verified Tact contract ABI.
contract NftCollection {
    storage: NftCollectionData2
    incomingMessages: NftCollectionIncomingMessage
    thrownErrors: NftCollectionErrors
}

struct (0x946a98b6) NftCollectionDeploy {
    queryId: uint64
}

struct NftCollectionData {
    next_item_index: uint64
    content: cell
    owner_address: address
}

struct NftCollectionRoyaltyParams {
    numerator: uint16
    denominator: uint16
    destination: address
}

struct NftCollectionSpecialData {
    nft_basic: int257
    nft_silver: int257
    nft_gold: int257
    tactContinuation: Cell<NftCollectionSpecialDataContinuation>
}

struct NftCollectionSpecialDataContinuation {
    nft_platinum: int257
    next_basic_index: uint64
    next_silver_index: uint64
    next_gold_index: uint64
    next_platinum_index: uint64
    coin_minial: coins
    address_check: bool
    address_mint: map<address, int257>
}

struct (0x693d3950) NftCollectionGetRoyaltyParams {
    query_id: uint64
}

struct (0x00000001) NftCollectionDeployNewNft {
    query_id: uint64
    new_owner: address?
    nft_content: cell
}

struct (0x00000003) NftCollectionChangeOwner {
    query_id: uint64
    new_owner: address
}

struct (0x00000004) NftCollectionReturnBalance {
    query_id: uint64
}

struct (0x00000005) NftCollectionChangeSecondOwner {
    query_id: uint64
    new_second_owner: address
}

struct (0x00000006) NftCollectionChangeContent {
    query_id: uint64
    content: cell
    nft_item_content_common: cell
}

struct (0x00000007) NftCollectionChangeItemContent {
    query_id: uint64
    item_index: uint64
    individual_content: cell
}

struct (0x00000008) NftCollectionChangeSpecialDataItem {
    query_id: uint64
    nft_basic: uint64
    nft_silver: uint64
    nft_gold: uint64
    nft_platinum: uint64
}

struct (0x00000009) NftCollectionChangeSpecialDataTonMin {
    query_id: uint64
    value: coins
}

struct (0x0000000a) NftCollectionChangeSpecialDataAddAddress {
    query_id: uint64
    length_list: uint64
    count_list: map<int257, int257>
    address_list: map<int257, address>
}

struct (0x0000000b) NftCollectionChangeSpecialDataClearAddress {
    query_id: uint64
}

struct (0x0000000c) NftCollectionChangeSpecialDataCheckAddress {
    query_id: uint64
    address_check: bool
}

struct NftCollectionData2 {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    next_item_index: uint64
    content: cell
    nft_item_content_common: cell
    royalty_params: NftCollectionRoyaltyParams
    second_owner: address?
    tactContinuation: Cell<NftCollectionDataContinuation>
}

struct NftCollectionDataContinuation {
    specialData: NftCollectionSpecialData
}

type NftCollectionIncomingMessage =
    | NftCollectionGetRoyaltyParams
    | NftCollectionDeployNewNft
    | NftCollectionChangeOwner
    | NftCollectionChangeSecondOwner
    | NftCollectionReturnBalance
    | NftCollectionChangeContent
    | NftCollectionChangeItemContent
    | NftCollectionChangeSpecialDataItem
    | NftCollectionChangeSpecialDataTonMin
    | NftCollectionChangeSpecialDataAddAddress
    | NftCollectionChangeSpecialDataClearAddress
    | NftCollectionChangeSpecialDataCheckAddress
    | NftCollectionDeploy

enum NftCollectionErrors {
    /// Stack undeflow
    StackUndeflow = 2
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
    /// Out of gas error
    OutOfGasError = 13
    /// Method ID not found
    MethodIDNotFound = 32
    /// Action is invalid or not supported
    ActionIsInvalidOrNotSupported = 34
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
    NotEnoughExtraCurrencies = 38
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
    /// Invalid address
    InvalidAddress = 136
    /// Masterchain support is not enabled for this contract
    MasterchainSupportIsNotEnabledForThisContract = 137
}

get fun get_special_info_data(): NftCollectionSpecialData {
    throw 0;
}

get fun get_special_list_data(): map<address, int257> {
    throw 0;
}

get fun get_special_use_list_data(address: address): int257 {
    throw 0;
}

get fun get_collection_data(): NftCollectionData {
    throw 0;
}

get fun get_nft_address_by_index(index: int257): address {
    throw 0;
}

get fun royalty_params(): NftCollectionRoyaltyParams {
    throw 0;
}

get fun get_second_owner_address(): address {
    throw 0;
}

get fun get_nft_content(index: int257, individual_nft_content: cell): cell {
    throw 0;
}

get fun get_balance(): int257 {
    throw 0;
}
