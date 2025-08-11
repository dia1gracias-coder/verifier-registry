// Generated from the verified Tact contract ABI.
contract VouchContract {
    storage: VouchContractData
    incomingMessages: VouchContractIncomingMessage
    thrownErrors: VouchContractErrors
}

struct (0x00000001) VouchContractVouchProfile {
    profileOwner: address
}

struct (0x00000002) VouchContractSetTreasuryAddress {
    treasuryAddress: address
}

struct (0x00000003) VouchContractWithdrawFunds {
    amount: int257
}

struct (0x00000004) VouchContractWithdrawAll {
}

struct VouchContractVouchRecord {
    voucher: address
    amount: int257
    timestamp: int257
}

struct VouchContractProfileStats {
    totalVouches: int257
    totalAmount: int257
    lastVouchTime: int257
}

struct VouchContractVouchHistoryEntry {
    records: map<int257, Cell<VouchContractVouchRecord>>
}

struct VouchContractData {
    tactDeploymentCompleted: bool
    owner: address
    treasuryAddress: address
    salt: int257
    tactContinuation: Cell<VouchContractDataContinuation>
}

struct VouchContractDataContinuation {
    basePrice: int257
    step: int257
    profileOwnerShare: int257
    tactContinuation: Cell<VouchContractDataContinuation2>
}

struct VouchContractDataContinuation2 {
    vouchersShare: int257
    treasuryShare: int257
    burnShare: int257
    profileStats: map<address, Cell<VouchContractProfileStats>>
    vouchHistory: map<address, Cell<VouchContractVouchHistoryEntry>>
}

type VouchContractIncomingMessage =
    | VouchContractVouchProfile
    | VouchContractSetTreasuryAddress
    | VouchContractWithdrawFunds
    | VouchContractWithdrawAll

enum VouchContractErrors {
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
    /// Insufficient payment for vouch
    InsufficientPaymentForVouch = 28118
    /// Only owner can withdraw funds
    OnlyOwnerCanWithdrawFunds = 36127
    /// Only owner can withdraw all funds
    OnlyOwnerCanWithdrawAllFunds = 46363
    /// Only owner can set treasury address
    OnlyOwnerCanSetTreasuryAddress = 52179
    /// Insufficient contract balance
    InsufficientContractBalance = 55591
    /// Cannot vouch for yourself
    CannotVouchForYourself = 59462
}

get fun getProfileStats(profileOwner: address): VouchContractProfileStats? {
    throw 0;
}

get fun getVouchHistory(profileOwner: address, index: int257): VouchContractVouchRecord? {
    throw 0;
}

get fun getNextVouchPrice(profileOwner: address): int257 {
    throw 0;
}

get fun getBalance(): int257 {
    throw 0;
}

get fun getBasePrice(): int257 {
    throw 0;
}

get fun getStep(): int257 {
    throw 0;
}

get fun getRevenueSplit(): int257 {
    throw 0;
}
