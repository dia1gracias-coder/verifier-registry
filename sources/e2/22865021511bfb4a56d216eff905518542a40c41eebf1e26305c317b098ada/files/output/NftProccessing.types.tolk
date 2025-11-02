// Generated from the verified Tact contract ABI.
contract NftProccessing {
    storage: NftProccessingData
    incomingMessages: NftProccessingIncomingMessage
    thrownErrors: NftProccessingErrors
}

struct (0x946a98b6) NftProccessingDeploy {
    queryId: uint64
}

struct (0x05138d91) NftProccessingNftOwnershipAssigned {
    queryId: uint64
    prev_owner: address
    forward_payload: RemainingBitsAndRefs
}

struct (0x00000001) NftProccessingStartCredit {
    creditAmount: coins
    lender: address
    originalOwner: address
    nft: address
}

struct (0x8b771735) NftProccessingNFTReportStaticData {
    queryId: uint64
    index: uint256
    collection: address
}

struct NftProccessingData {
    tactDeploymentCompleted: bool
    nftCollectionAddress: address
    nftItemIndex: uint64
    nftCode: cell
    owner: address
    original_owner: address
    tactContinuation: Cell<NftProccessingDataContinuation>
}

struct NftProccessingDataContinuation {
    lender: address
    nft: address
    loan_amount: coins
    receivedAll: coins
    nft_received: bool
    status: uint8
}

type NftProccessingIncomingMessage =
    | NftProccessingNftOwnershipAssigned
    | NftProccessingStartCredit
    | NftProccessingNFTReportStaticData
    | NftProccessingDeploy

enum NftProccessingErrors {
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
    /// уже запуще
    Error17699 = 17699
    /// кредит: 0
    _0 = 37195
    /// NFT contract is not the sender
    NFTContractIsNotTheSender = 45373
}

get fun get_status(): cell {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
