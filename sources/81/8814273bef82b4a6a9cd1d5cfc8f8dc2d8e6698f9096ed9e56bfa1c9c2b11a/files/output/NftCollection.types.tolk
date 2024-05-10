// Generated from the verified Tact contract ABI.
contract NftCollection {
    storage: NftCollectionData
    incomingMessages: NftCollectionIncomingMessage
    thrownErrors: NftCollectionErrors
}

struct NftCollectionStateInit {
    code: cell
    data: cell
}

struct (0x693d3950) NftCollectionGetRoyaltyParams {
    query_id: uint64
}

struct NftCollectionCollectionData {
    next_item_index: int257
    collection_content: cell
    owner_address: address
}

struct NftCollectionRoyaltyParams {
    numerator: int257
    denominator: int257
    destination: address
}

struct (0x8b771734) NftCollectionChangeJetton {
    query_id: uint64
    jetton: address
}

struct (0x8b771731) NftCollectionRecharge {
    query_id: uint64
    amount: int257
}

struct (0x819dbe99) NftCollectionChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x7362d09c) NftCollectionTokenNotification {
    query_id: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct NftCollectionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    next_item_index: uint32
    max_supply: uint32
    owner_address: address
    tactContinuation: Cell<NftCollectionDataContinuation>
}

struct NftCollectionDataContinuation {
    royalty_params: NftCollectionRoyaltyParams?
    collection_content: cell
    balance: uint32
    tactContinuation: Cell<NftCollectionDataContinuation2>
}

struct NftCollectionDataContinuation2 {
    price: uint256
    jetton_address: address
}

type NftCollectionIncomingMessage =
    | NftCollectionChangeJetton
    | NftCollectionRecharge
    | NftCollectionTokenNotification
    | NftCollectionGetRoyaltyParams
    | NftCollectionChangeOwner

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
    /// Invalid sender
    InvalidSender = 4429
    /// Not end of item
    NotEndOfItem = 7053
    /// Invalid value
    InvalidValue = 16059
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Not match price
    NotMatchPrice = 22741
    /// Insufficient gas
    InsufficientGas = 23951
    /// initialized tx need from collection
    InitializedTxNeedFromCollection = 27499
    /// Not the owner of item
    NotTheOwnerOfItem = 40373
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// not owner
    NotOwner = 49280
    /// not from collection
    NotFromCollection = 49469
    /// This item has claimed.
    ThisItemHasClaimed = 52734
    /// non-sequential NFTs
    NonSequentialNFTs = 62742
    /// Invalid balance
    InvalidBalance = 62972
}

get fun get_collection_data(): NftCollectionCollectionData {
    throw 0;
}

get fun get_nft_address_by_index(item_index: int257): address? {
    throw 0;
}

get fun getNftItemInit(item_index: int257): NftCollectionStateInit {
    throw 0;
}

get fun get_nft_content(index: int257, individual_content: cell): cell {
    throw 0;
}

get fun royalty_params(): NftCollectionRoyaltyParams {
    throw 0;
}

get fun get_jetton_address(): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
