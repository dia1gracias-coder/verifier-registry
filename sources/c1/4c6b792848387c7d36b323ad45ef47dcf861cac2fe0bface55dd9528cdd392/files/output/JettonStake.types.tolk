// Generated from the verified Tact contract ABI.
contract JettonStake {
    storage: JettonStakeData
    incomingMessages: JettonStakeIncomingMessage
    thrownErrors: JettonStakeErrors
}

struct (0x946a98b6) JettonStakeDeploy {
    queryId: uint64
}

struct JettonStakeArray {
    list: map<uint16, int257>
    length: int257
}

struct (0x46c7667f) JettonStakeDeposit {
    txId: int257
    jetton: address
    userAddr: address
    userId: uint64
    refId: uint64
    tactContinuation: Cell<JettonStakeDepositContinuation>
}

struct JettonStakeDepositContinuation {
    amount: coins
}

struct (0xee6eeb4e) JettonStakeWithdraw {
    jetton: address
    userId: uint64
}

struct (0x7362d09c) JettonStakeTokenNotification {
    query_id: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct (0x7970d16b) JettonStakeAddToJettonList {
    jettonAddr: address
}

struct (0xb1819fa4) JettonStakeRemoveFromJettonList {
    jettonAddr: address
}

struct (0x1dc4a8ae) JettonStakeSetContPlan {
    jettonAddr: address
    contPlans: JettonStakeContPlanArray
}

struct (0x1ce635ef) JettonStakeSetRefPlan {
    refPlan: JettonStakeUint16Array
}

struct (0x6b48d8de) JettonStakeAddToAccessList {
    userAddr: address
}

struct (0x5272c854) JettonStakeRemoveFromAccessList {
    userAddr: address
}

struct JettonStakeAddrArray {
    list: map<uint16, address>
    length: uint16
}

struct JettonStakeUint16Array {
    list: map<uint16, uint16>
    length: uint16
}

struct JettonStakePaymentArray {
    amount: map<uint16, int257>
    profit: map<uint16, int257>
    timestamp: map<uint16, int257>
    length: uint16
}

struct JettonStakeContPlanArray {
    minValue: map<uint16, int257>
    profit: map<uint16, uint16>
    limit: map<uint16, uint16>
    length: uint16
}

struct JettonStakeData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    accessList: JettonStakeAddrArray
    hasAccess: map<address, bool>
    isActive: bool
    tactContinuation: Cell<JettonStakeDataContinuation>
}

struct JettonStakeDataContinuation {
    jettonList: JettonStakeAddrArray
    hasJetton: map<address, bool>
    txExists: map<int257, bool>
    tactContinuation: Cell<JettonStakeDataContinuation2>
}

struct JettonStakeDataContinuation2 {
    userDepositList: map<address, Cell<JettonStakeArray>>
    userIdToAddr: map<int257, address>
    userReferral: map<address, address>
    tactContinuation: Cell<JettonStakeDataContinuation3>
}

struct JettonStakeDataContinuation3 {
    userJettonBanned: map<int257, bool>
    refPlan: JettonStakeUint16Array
    contPlans: map<address, Cell<JettonStakeContPlanArray>>
    tactContinuation: Cell<JettonStakeDataContinuation4>
}

struct JettonStakeDataContinuation4 {
    userJettonDeposits: map<int257, Cell<JettonStakePaymentArray>>
    userJettonClaims: map<int257, Cell<JettonStakePaymentArray>>
    userJettonTotalClaimed: map<int257, int257>
    tactContinuation: Cell<JettonStakeDataContinuation5>
}

struct JettonStakeDataContinuation5 {
    userJettonMaxClaimFraction: map<int257, int257>
    userJettonClaimableTemp: map<int257, int257>
}

type JettonStakeIncomingMessage =
    | JettonStakeTokenNotification
    | JettonStakeDeposit
    | JettonStakeWithdraw
    | JettonStakeDeploy
    | JettonStakeAddToJettonList
    | JettonStakeRemoveFromJettonList
    | JettonStakeSetContPlan
    | JettonStakeSetRefPlan
    | JettonStakeAddToAccessList
    | JettonStakeRemoveFromAccessList

enum JettonStakeErrors {
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
    /// Not mintable
    NotMintable = 3688
    /// Invalid value!!
    InvalidValue = 4159
    /// Invalid sender
    InvalidSender = 4429
    /// jetton does not exist
    JettonDoesNotExist = 6572
    /// No items in the array!
    NoItemsInTheArray = 6947
    /// there is no deposit
    ThereIsNoDeposit = 9987
    /// Max supply exceeded
    MaxSupplyExceeded = 12241
    /// already exists
    AlreadyExists = 14101
    /// Not owner
    NotOwner = 14534
    /// No items in the array to delete!
    NoItemsInTheArrayToDelete = 17848
    /// Can't Mint Anymore
    CanTMintAnymore = 18668
    /// Index of the item cannot be negative!
    IndexOfTheItemCannotBeNegative = 19333
    /// Insufficient gas
    InsufficientGas = 23951
    /// Index is out of array bounds!
    IndexIsOutOfArrayBounds = 24006
    /// referral does not exist
    ReferralDoesNotExist = 34980
    /// contract is not active
    ContractIsNotActive = 35041
    /// Invalid sender!
    InvalidSender2 = 42708
    /// Invalid value - Burn
    InvalidValueBurn = 43422
    /// does not exist
    DoesNotExist = 46740
    /// user does not exist
    UserDoesNotExist = 53231
    /// insufficient amount to claim
    InsufficientAmountToClaim = 59680
    /// this tx has been set before.
    ThisTxHasBeenSetBefore = 60254
    /// Invalid balance
    InvalidBalance = 62972
}

get fun get_jetton_list(): JettonStakeAddrArray? {
    throw 0;
}

get fun get_profit_plan(jetton: address): JettonStakeContPlanArray? {
    throw 0;
}

get fun get_referral_plan(): JettonStakeUint16Array? {
    throw 0;
}

get fun get_user_address(userId: int257): address? {
    throw 0;
}

get fun get_user_deposits(userId: int257, jetton: address): JettonStakePaymentArray? {
    throw 0;
}

get fun get_user_withdraws(userId: int257, jetton: address): JettonStakePaymentArray? {
    throw 0;
}

get fun get_user_withdrawable(userId: int257, jetton: address): int257? {
    throw 0;
}

get fun get_is_active(): bool {
    throw 0;
}

get fun get_has_jetton(jettonAddr: address): bool? {
    throw 0;
}

get fun get_jetton_exists(jettonAddr: address): bool? {
    throw 0;
}

get fun get_access_list(): JettonStakeAddrArray {
    throw 0;
}

get fun get_has_access(userAddr: address): bool? {
    throw 0;
}

get fun get_admin_exists(userAddr: address): bool? {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
