// Generated from the verified Tact contract ABI.
contract NftGenesisItem {
    storage: NftGenesisItemData
    incomingMessages: NftGenesisItemIncomingMessage
    thrownErrors: NftGenesisItemErrors
}

struct (0x5fcc3d14) NftGenesisItemNftTransfer {
    query_id: uint64
    new_owner: address
    response_destination: address
    custom_payload: cell?
    forward_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct NftGenesisItemNftData {
    init: bool?
    index: uint256
    collection_address: address
    owner_address: address
    individual_content: cell
}

struct (0x2fcb26a2) NftGenesisItemNftGetStaticData {
    query_id: uint64
}

struct NftGenesisItemData {
    tactDeploymentCompleted: bool
    deployed: bool
    owner: address
    collection: address
    index: uint64
    individual_content: cell
}

type NftGenesisItemIncomingMessage =
    | NftGenesisItemNftGetStaticData
    | NftGenesisItemNftTransfer

enum NftGenesisItemErrors {
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
    /// Invalid royalty numerator
    InvalidRoyaltyNumerator = 8761
    /// Not Deployed
    NotDeployed = 11850
    /// Invalid royalty denominator
    InvalidRoyaltyDenominator = 14760
    /// Invalid Sender
    InvalidSender = 23263
    /// Invalid Amount
    InvalidAmount = 30404
    /// Invalid Owner
    InvalidOwner = 42491
    /// Invalid Index
    InvalidIndex = 44083
    /// Unknown op
    UnknownOp = 48532
}

get fun get_nft_data(): NftGenesisItemNftData {
    throw 0;
}
