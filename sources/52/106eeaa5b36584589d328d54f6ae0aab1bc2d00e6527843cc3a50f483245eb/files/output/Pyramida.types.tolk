// Generated from the verified Tact contract ABI.
contract Pyramida {
    storage: PyramidaData
    incomingMessages: PyramidaIncomingMessage
    thrownErrors: PyramidaErrors
}

struct (0x946a98b6) PyramidaDeploy {
    queryId: uint64
}

struct (0x960f4697) PyramidaUpdateJettonMasterAddress {
    queryId: uint64
    address: address
}

struct (0x358d8b73) PyramidaMintInitJettonsToOwner {
    queryId: uint64
    mint: bool
}

struct (0x888bbb88) PyramidaChangePyramidaOwner {
    queryId: uint64
    owner: address
}

struct (0xd2a7c100) PyramidaDrawLottery {
    queryId: uint64
}

struct (0x4cb3b22d) PyramidaJettonsBurned {
    queryId: uint64
    amount: coins
    totalSupply: coins
}

struct (0xd53276db) PyramidaExcesses {
    queryId: uint64
}

struct PyramidaUserData {
    referrerKey: int257
    address: address
    referralsCount: int257
    tactContinuation: Cell<PyramidaUserDataContinuation>
}

struct PyramidaUserDataContinuation {
    earningsFromReferrals: int257
    lastActivity: int257
}

struct PyramidaUsers {
    userData: map<int257, Cell<PyramidaUserData>>
    addresses: map<address, int257>
    lastKey: int257
    userIndex: map<int257, int257>
    userCount: int257
}

struct PyramidaPruneState {
    cursor: int257
}

struct PyramidaLotteryBank {
    balance: int257
}

struct PyramidaPastLotteryInformation {
    lastLotteryTime: int257
    lastWinnerKey: int257
    lastWinnerAddress: address
    tactContinuation: Cell<PyramidaPastLotteryInformationContinuation>
}

struct PyramidaPastLotteryInformationContinuation {
    lastWinAmount: int257
    totalWinners: int257
    totalWinsAmount: int257
}

struct PyramidaCurrentLotteryRound {
    endTime: int257
    ticketMap: map<int257, int257>
    participantList: map<int257, int257>
    totalTickets: int257
    participantsCount: int257
}

struct PyramidaDrawState {
    isDrawing: bool
    cursor: int257
    accumulated: int257
    randomTarget: int257
    tactContinuation: Cell<PyramidaDrawStateContinuation>
}

struct PyramidaDrawStateContinuation {
    winnerKey: int257
    winnerFound: bool
    snapshotParticipants: int257
    prizeAmount: int257
    tactContinuation: Cell<PyramidaDrawStateContinuation2>
}

struct PyramidaDrawStateContinuation2 {
    ownerShareAmount: int257
    lastProgressTime: int257
}

struct PyramidaJettonRewardsStats {
    lastMintTime: int257
    totalMinted: int257
}

struct PyramidaGasDeductionResult {
    initialAmount: int257
    gasAmount: int257
    remainingAmount: int257
    isEnough: bool
}

struct PyramidaStorageStats {
    lastUpdateTime: int257
    transactionCount: int257
    totalTimeInterval: int257
    tactContinuation: Cell<PyramidaStorageStatsContinuation>
}

struct PyramidaStorageStatsContinuation {
    totalStorageDueCollected: int257
    reservedStorage: int257
    storageLimit: int257
    tactContinuation: Cell<PyramidaStorageStatsContinuation2>
}

struct PyramidaStorageStatsContinuation2 {
    lastTonsReserve: int257
    storageTonsDeficit: int257
}

struct PyramidaCurrentRoundSummary {
    endTime: int257
    totalTickets: int257
    participantsCount: int257
}

struct PyramidaUsersSummary {
    lastKey: int257
    userCount: int257
}

struct PyramidaState {
    lotteryBank: PyramidaLotteryBank
    tactContinuation: Cell<PyramidaStateContinuation>
}

struct PyramidaStateContinuation {
    pastLotteryInfo: PyramidaPastLotteryInformation
    tactContinuation: Cell<PyramidaStateContinuation2>
}

struct PyramidaStateContinuation2 {
    currentRound: PyramidaCurrentRoundSummary
    tactContinuation: Cell<PyramidaStateContinuation3>
}

struct PyramidaStateContinuation3 {
    drawState: PyramidaDrawState
    tactContinuation: Cell<PyramidaStateContinuation4>
}

struct PyramidaStateContinuation4 {
    pruneState: PyramidaPruneState
    users: PyramidaUsersSummary
    tactContinuation: Cell<PyramidaStateContinuation5>
}

struct PyramidaStateContinuation5 {
    jettonRewardsStats: PyramidaJettonRewardsStats
    owner: address
    tactContinuation: Cell<PyramidaStateContinuation6>
}

struct PyramidaStateContinuation6 {
    jettonMasterAddress: address
    availableForPrize: int257
}

struct PyramidaUserView {
    registered: bool
    key: int257
    referrerKey: int257
    address: address
    tactContinuation: Cell<PyramidaUserViewContinuation>
}

struct PyramidaUserViewContinuation {
    referralsCount: int257
    earningsFromReferrals: int257
    lastActivity: int257
}

struct PyramidaData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    jettonContent: cell
    jettonMasterAddress: address
    tactContinuation: Cell<PyramidaDataContinuation>
}

struct PyramidaDataContinuation {
    jettonRewardsStats: PyramidaJettonRewardsStats
    ownerJettonMinted: bool
    oldIncrement: int257
    tactContinuation: Cell<PyramidaDataContinuation2>
}

struct PyramidaDataContinuation2 {
    increment: int257
    tactContinuation: Cell<PyramidaDataContinuation3>
}

struct PyramidaDataContinuation3 {
    gasStats: PyramidaStorageStats
    tactContinuation: Cell<PyramidaDataContinuation4>
}

struct PyramidaDataContinuation4 {
    gasResults: PyramidaGasDeductionResult
    tactContinuation: Cell<PyramidaDataContinuation5>
}

struct PyramidaDataContinuation5 {
    users: PyramidaUsers
    lotteryBank: PyramidaLotteryBank
    tactContinuation: Cell<PyramidaDataContinuation6>
}

struct PyramidaDataContinuation6 {
    pastLotteryInfo: PyramidaPastLotteryInformation
    tactContinuation: Cell<PyramidaDataContinuation7>
}

struct PyramidaDataContinuation7 {
    currentRound: PyramidaCurrentLotteryRound
    tactContinuation: Cell<PyramidaDataContinuation8>
}

struct PyramidaDataContinuation8 {
    pendingRound: PyramidaCurrentLotteryRound
    tactContinuation: Cell<PyramidaDataContinuation9>
}

struct PyramidaDataContinuation9 {
    drawState: PyramidaDrawState
    tactContinuation: Cell<PyramidaDataContinuation10>
}

struct PyramidaDataContinuation10 {
    pruneState: PyramidaPruneState
}

type PyramidaIncomingMessage =
    | PyramidaJettonsBurned
    | PyramidaUpdateJettonMasterAddress
    | PyramidaChangePyramidaOwner
    | PyramidaDrawLottery
    | PyramidaExcesses
    | PyramidaMintInitJettonsToOwner
    | PyramidaDeploy

enum PyramidaErrors {
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
    /// Amount too small for owner change
    AmountTooSmallForOwnerChange = 3571
    /// Not mintable
    NotMintable = 3688
    /// Invalid sender
    InvalidSender = 4429
    /// Incorrect sender
    IncorrectSender = 9215
    /// Not owner
    NotOwner = 14534
    /// DrawLottery can only be sent by the contract itself
    DrawLotteryCanOnlyBeSentByTheContractItself = 14901
    /// receiverCount must be positive
    ReceiverCountMustBePositive = 17821
    /// Owner cannot be the same
    OwnerCannotBeTheSame = 18152
    /// Invalid receiver
    InvalidReceiver = 21516
    /// Only owner can change owner
    OnlyOwnerCanChangeOwner = 27145
    /// Insufficient amount of TON attached
    InsufficientAmountOfTONAttached = 32113
    /// Only Pyramida JettonMaster contract can update total amount
    OnlyPyramidaJettonMasterContractCanUpdateTotalAmount = 33296
    /// Insufficient gas for mint
    InsufficientGasForMint = 37629
    /// Owner cannot be zero
    OwnerCannotBeZero = 38148
    /// No enough TON
    NoEnoughTON = 47154
    /// User already exists
    UserAlreadyExists = 47804
    /// Only owner can mint initial jettons
    OnlyOwnerCanMintInitialJettons = 49429
    /// Insufficient ton amount
    InsufficientTonAmount = 49755
    /// Owner jettons already minted
    OwnerJettonsAlreadyMinted = 53531
    /// Only owner can set jetton master
    OnlyOwnerCanSetJettonMaster = 53922
    /// Amount should be positive
    AmountShouldBePositive = 54379
    /// Insufficient balance
    InsufficientBalance = 54615
}

get fun getPyramidaState(): PyramidaState {
    throw 0;
}

get fun getUserByAddress(userAddress: address): PyramidaUserView {
    throw 0;
}

get fun getUsersState(): PyramidaUsers {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
