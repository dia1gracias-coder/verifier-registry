// Generated from the verified Tact contract ABI.
contract NftItem {
    storage: NftItemData
    incomingMessages: NftItemIncomingMessage
    thrownErrors: NftItemErrors
}

struct (0x5fcc3d14) NftItemTransfer {
    query_id: uint64
    new_owner: address
    response_destination: address?
    custom_payload: cell?
    forward_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x2fcb26a2) NftItemGetStaticData {
    query_id: uint64
}

struct NftItemGetNftData {
    is_initialized: bool
    index: int257
    collection_address: address
    owner_address: address
    individual_content: cell
}

struct NftItemData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    collection_address: address
    item_index: int257
    is_initialized: bool
    owner: address?
    individual_content: cell?
}

type NftItemIncomingMessage =
    | NftItemTransfer
    | NftItemGetStaticData

enum NftItemErrors {
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

get fun get_nft_data(): NftItemGetNftData {
    throw 0;
}
