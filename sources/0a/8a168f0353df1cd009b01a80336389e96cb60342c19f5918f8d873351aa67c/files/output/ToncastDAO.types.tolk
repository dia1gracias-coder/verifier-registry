// Generated from the verified Tact contract ABI.
contract ToncastDAO {
    storage: ToncastDAOData
    incomingMessages: ToncastDAOIncomingMessage
    thrownErrors: ToncastDAOErrors
}

struct (0x946a98b6) ToncastDAODeploy {
    queryId: uint64
}

struct (0x8d4b6e9f) ToncastDAOProcessEpochPayouts {
    userAddress: address
    withdrawnAmount: coins
    startEpoch: uint32
    endEpoch: uint32
}

struct (0x7362d09c) ToncastDAOJettonTransferNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0x05138d91) ToncastDAONftTransferNotification {
    queryId: uint64
    prevOwner: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0x7b7b7b7b) ToncastDAONftReportAllData {
    queryId: uint64
    index: uint64
    data: cell
}

struct (0x53544f50) ToncastDAOStopAndRedirect {
    newDaoAddress: address
}

struct ToncastDAODAOEpochData {
    deployTime: uint64
    currentRealTimeEpoch: uint32
    epochDuration: uint32
    currentStoredEpochNumber: uint32
    totalCurrentlyStaked: coins
}

struct ToncastDAODAOConfigData {
    nextItemIndex: uint64
    nftCollectionAddress: address?
    jettonMasterAddress: address
    jettonWalletAddress: address
    minDepositAmount: coins
    nftNamePrefix: string
    nftImageUrl: string
    isReadyToAcceptDeposits: bool
    stopped: bool
    tactContinuation: Cell<ToncastDAODAOConfigDataContinuation>
}

struct ToncastDAODAOConfigDataContinuation {
    newDaoAddress: address?
}

struct ToncastDAOData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    stopped: bool
    nftCollectionAddress: address?
    jettonMasterAddress: address
    minDepositAmount: coins
    nextItemIndex: uint64
    nftNamePrefix: string
    tactContinuation: Cell<ToncastDAODataContinuation>
}

struct ToncastDAODataContinuation {
    nftImageUrl: string
    pendingWithdrawals: map<address, int257>
    pendingWithdrawalOwners: map<address, address>
    collectionMetadata: cell
    seq: uint32
    newDaoAddress: address?
    deployTime: uint64
    epochDuration: uint32
    lastProcessedEpoch: uint32
    totalCurrentlyStaked: coins
}

type ToncastDAOIncomingMessage =
    | ToncastDAOJettonTransferNotification
    | ToncastDAONftTransferNotification
    | ToncastDAONftReportAllData
    | ToncastDAOProcessEpochPayouts
    | ToncastDAODeploy
    | ToncastDAOStopAndRedirect

enum ToncastDAOErrors {
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
}

get fun getDAOConfigData(): ToncastDAODAOConfigData {
    throw 0;
}

get fun getDAOEpochData(): ToncastDAODAOEpochData {
    throw 0;
}

get fun getEpochContractAddress(epochNumber: int257): address {
    throw 0;
}

get fun getCollectionMetadata(): cell {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
