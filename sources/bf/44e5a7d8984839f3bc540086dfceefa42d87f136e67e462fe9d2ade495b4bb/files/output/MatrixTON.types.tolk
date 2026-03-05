// Generated from the verified Tact contract ABI.
contract MatrixTON {
    storage: MatrixTONData
    incomingMessages: MatrixTONIncomingMessage
    thrownErrors: MatrixTONErrors
}

struct (0x946a98b6) MatrixTONDeploy {
    queryId: uint64
}

struct (0x00000100) MatrixTONRegister {
    referrer: address
}

struct (0x00000101) MatrixTONBuyTable {
    tableNum: uint8
}

struct (0x00000200) MatrixTONChangeMaster {
    newMaster: address
    coSigner: address
}

struct (0x00000201) MatrixTONConfirmAdminAction {
    actionId: uint32
}

struct (0x00000202) MatrixTONChangeSystemWallet {
    newSystemWallet: address
    coSigner: address
}

struct (0x00000203) MatrixTONUpgradeLogic {
    newCode: cell
    coSigner: address
}

struct (0x00000204) MatrixTONEmergencyWithdraw {
    amount: coins
    to: address
    coSigner: address
}

struct (0x00000205) MatrixTONSetPaused {
    paused: bool
}

struct (0x00000206) MatrixTONSetCoSigner {
    coSigner: address
}

struct (0x00000207) MatrixTONWithdrawExcess {
}

struct MatrixTONUserTable {
    active: bool
    slotsFilled: uint8
    slot1: address?
    slot2: address?
    slot3: address?
    tactContinuation: Cell<MatrixTONUserTableContinuation>
}

struct MatrixTONUserTableContinuation {
    slot4: address?
    frozen2Amount: coins
    cycleCount: uint32
}

struct MatrixTONUserData {
    registered: bool
    upline: address
    isMaster: bool
}

struct MatrixTONPendingAction {
    actionType: uint8
    initiator: address
    coSigner: address
    newAddress: address?
    amount: coins
    newCode: cell?
    expiry: uint32
}

struct MatrixTONData {
    tactDeploymentCompleted: bool
    owner: address
    masterWallet: address
    systemWallet: address
    stopped: bool
    tactContinuation: Cell<MatrixTONDataContinuation>
}

struct MatrixTONDataContinuation {
    coSigner: address
    processing: bool
    users: map<address, Cell<MatrixTONUserData>>
    userTables1: map<address, Cell<MatrixTONUserTable>>
    userTables2: map<address, Cell<MatrixTONUserTable>>
    tactContinuation: Cell<MatrixTONDataContinuation2>
}

struct MatrixTONDataContinuation2 {
    userTables3: map<address, Cell<MatrixTONUserTable>>
    userTables4: map<address, Cell<MatrixTONUserTable>>
    userTables5: map<address, Cell<MatrixTONUserTable>>
    tactContinuation: Cell<MatrixTONDataContinuation3>
}

struct MatrixTONDataContinuation3 {
    userTables6: map<address, Cell<MatrixTONUserTable>>
    userTables7: map<address, Cell<MatrixTONUserTable>>
    userTables8: map<address, Cell<MatrixTONUserTable>>
    tactContinuation: Cell<MatrixTONDataContinuation4>
}

struct MatrixTONDataContinuation4 {
    userTables9: map<address, Cell<MatrixTONUserTable>>
    userTables10: map<address, Cell<MatrixTONUserTable>>
    userTables11: map<address, Cell<MatrixTONUserTable>>
    tactContinuation: Cell<MatrixTONDataContinuation5>
}

struct MatrixTONDataContinuation5 {
    userTables12: map<address, Cell<MatrixTONUserTable>>
    pendingActions: map<int257, Cell<MatrixTONPendingAction>>
    nextActionId: uint32
    version: uint32
    bouncedPayouts: map<address, int257>
    totalUsers: uint32
    totalPayouts: coins
    totalSystemFees: coins
}

type MatrixTONIncomingMessage =
    | MatrixTONRegister
    | MatrixTONBuyTable
    | MatrixTONSetCoSigner
    | MatrixTONSetPaused
    | MatrixTONChangeMaster
    | MatrixTONChangeSystemWallet
    | MatrixTONUpgradeLogic
    | MatrixTONEmergencyWithdraw
    | MatrixTONConfirmAdminAction
    | MatrixTONWithdrawExcess
    | MatrixTONDeploy

enum MatrixTONErrors {
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
    /// Table not found
    TableNotFound = 7026
    /// Not registered
    NotRegistered = 9603
    /// Table already active
    TableAlreadyActive = 9746
    /// Table not active
    TableNotActive = 16763
    /// Invalid amount
    InvalidAmount = 17062
    /// Insufficient balance now
    InsufficientBalanceNow = 17715
    /// Only co-signer can confirm
    OnlyCoSignerCanConfirm = 18133
    /// Already registered
    AlreadyRegistered = 21101
    /// Reentrant call detected
    ReentrantCallDetected = 25547
    /// Action expired
    ActionExpired = 31854
    /// Insufficient payment
    InsufficientPayment = 46647
    /// Table full
    TableFull = 47952
    /// Action not found
    ActionNotFound = 48966
    /// Contract not stopped
    ContractNotStopped = 53296
    /// Invalid table number
    InvalidTableNumber = 53969
    /// Invalid co-signer
    InvalidCoSigner = 61115
    /// Previous table not active
    PreviousTableNotActive = 61139
    /// Owner not registered
    OwnerNotRegistered = 61400
}

get fun getUserData(user: address): MatrixTONUserData? {
    throw 0;
}

get fun getUserTable(user: address, tableNum: int257): MatrixTONUserTable? {
    throw 0;
}

get fun isRegistered(user: address): bool {
    throw 0;
}

get fun getUpline(user: address): address? {
    throw 0;
}

get fun getTablePrice(tableNum: int257): int257 {
    throw 0;
}

get fun getPayoutAmount(tableNum: int257): int257 {
    throw 0;
}

get fun getSystemFee(tableNum: int257): int257 {
    throw 0;
}

get fun getMasterWallet(): address {
    throw 0;
}

get fun getSystemWallet(): address {
    throw 0;
}

get fun getCoSigner(): address {
    throw 0;
}

get fun getContractBalance(): int257 {
    throw 0;
}

get fun isStopped(): bool {
    throw 0;
}

get fun getBouncedPayouts(user: address): int257 {
    throw 0;
}

get fun findSpilloverTarget(startUser: address, tableNum: int257): address {
    throw 0;
}

get fun getPendingAction(actionId: int257): MatrixTONPendingAction? {
    throw 0;
}

get fun getStats(): map<int257, int257> {
    throw 0;
}

get fun getUserAllTables(user: address): map<int257, int257> {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}
