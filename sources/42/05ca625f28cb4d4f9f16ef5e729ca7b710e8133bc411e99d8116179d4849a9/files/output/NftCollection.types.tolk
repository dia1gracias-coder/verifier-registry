// Generated from the verified Tact contract ABI.
contract NftCollection {
    storage: NftCollectionData
    incomingMessages: NftCollectionIncomingMessage
    thrownErrors: NftCollectionErrors
}

struct (0x946a98b6) NftCollectionDeploy {
    queryId: uint64
}

struct (0x57b22753) NftCollectionUpdateCosts {
    storage: coins
    consumption: coins
    value: coins
}

struct (0x81188cb4) NftCollectionWithdrawSafe {
    idx: uint256
}

struct (0xd305256e) NftCollectionAddYear {
    item_id: uint256
}

struct NftCollectionCollectionData {
    next_item_index: int257
    collection_content: cell
    owner_address: address
}

struct NftCollectionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    id: uint32
    owner: address
    wd_idx: uint256
    next_item: uint256
    minTonsForStorage: coins
    tactContinuation: Cell<NftCollectionDataContinuation>
}

struct NftCollectionDataContinuation {
    gasConsumption: coins
    myValue: coins
    collection_content: cell
}

type NftCollectionIncomingMessage =
    | NftCollectionWithdrawSafe
    | NftCollectionAddYear
    | NftCollectionDeploy
    | NftCollectionUpdateCosts

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
    /// Item: Not the owner to add 1 year
    ItemNotTheOwnerToAdd1Year = 2931
    /// Access Denied!
    AccessDenied2 = 26930
    /// Not active yet
    NotActiveYet = 42679
    /// not from collection
    NotFromCollection = 49469
}

get fun get_collection_data(): NftCollectionCollectionData {
    throw 0;
}

get fun get_nft_address_by_index(item_index: int257): address {
    throw 0;
}

get fun get_nft_content(index: int257, individual_content: cell): cell {
    throw 0;
}

get fun get_next_item(): int257 {
    throw 0;
}

get fun get_value(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
