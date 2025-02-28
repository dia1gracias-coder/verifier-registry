// Generated from the verified Tact contract ABI.
contract NftItem {
    storage: NftItemData
    incomingMessages: NftItemIncomingMessage
    thrownErrors: NftItemErrors
}

struct (0x946a98b6) NftItemDeploy {
    queryId: uint64
}

struct NftItemNftData {
    index: int257
    collection_address: address
    owner_address: address
    content: string
}

struct (0x4b1fecbf) NftItemNftDeploy {
    index: uint32
    content: string
    owner: address
}

struct (0xe392c557) NftItemNftTransfer {
    query_id: uint64
    new_owner: address
    response_destination: address
    custom_payload: cell?
    forward_amount: coins
    forward_payload: RemainingBitsAndRefs
}

struct (0x6a0b1714) NftItemNftGetStaticData {
    query_id: uint64
}

struct NftItemData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    deployed: bool
    collection: address
    owner: address
    index: uint32
    content: string
}

type NftItemIncomingMessage =
    | NftItemNftDeploy
    | NftItemNftTransfer
    | NftItemNftGetStaticData
    | NftItemDeploy

enum NftItemErrors {
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
    /// Not Deployed
    NotDeployed = 11850
    /// Invalid Sender
    InvalidSender = 23263
    /// Invalid Amount
    InvalidAmount = 30404
    /// New max supply cannot be less than current supply
    NewMaxSupplyCannotBeLessThanCurrentSupply = 33019
    /// Invalid Owner
    InvalidOwner = 42491
    /// Invalid Index
    InvalidIndex = 44083
    /// Max supply reached
    MaxSupplyReached = 47714
    /// Already Deployed
    AlreadyDeployed = 50324
    /// Upgradable: Sender is not a contract owner
    UpgradableSenderIsNotAContractOwner = 51409
    /// Insufficient contract balance
    InsufficientContractBalance = 55591
    /// Amount must be positive
    AmountMustBePositive = 61135
}

get fun get_nft_data(): NftItemNftData {
    throw 0;
}
