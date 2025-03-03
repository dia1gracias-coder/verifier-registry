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

struct (0x946a98b6) NftCollectionDeploy {
    queryId: uint64
}

struct (0x23799c2a) NftCollectionUpgradeContract {
    code: cell
    data: cell?
}

struct NftCollectionCollectionData {
    next_item_index: int257
    collection_content: cell
    owner_address: address
}

struct NftCollectionSupplyInfo {
    current_index: int257
    max_supply: int257
}

struct (0x47d117e7) NftCollectionMint {
    content: cell
    recipient: address
}

struct (0x232f2eee) NftCollectionUpdateSettings {
    queryId: uint64
    max_supply: uint32
}

struct (0xec65ec83) NftCollectionWithdraw {
    queryId: uint64
    amount: coins
    destination: address
}

struct NftCollectionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    max_supply: uint32
    next_item_index: uint32
    collection_content: cell
}

type NftCollectionIncomingMessage =
    | NftCollectionMint
    | NftCollectionUpdateSettings
    | NftCollectionWithdraw
    | NftCollectionDeploy
    | NftCollectionUpgradeContract

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
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
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
    /// Invalid address
    InvalidAddress = 136
    /// Masterchain support is not enabled for this contract
    MasterchainSupportIsNotEnabledForThisContract = 137
    /// initialized tx need from collection
    InitializedTxNeedFromCollection = 27499
    /// New max supply cannot be less than current supply
    NewMaxSupplyCannotBeLessThanCurrentSupply = 33019
    /// Max supply reached
    MaxSupplyReached = 47714
    /// not owner
    NotOwner = 49280
    /// not from collection
    NotFromCollection = 49469
    /// Upgradable: Sender is not a contract owner
    UpgradableSenderIsNotAContractOwner = 51409
    /// Insufficient contract balance
    InsufficientContractBalance = 55591
    /// Amount must be positive
    AmountMustBePositive = 61135
    /// non-sequential NFTs
    NonSequentialNFTs = 62742
}

get fun get_supply_info(): NftCollectionSupplyInfo {
    throw 0;
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

get fun owner(): address {
    throw 0;
}
