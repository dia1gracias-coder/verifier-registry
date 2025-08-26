// Generated from the verified Tact contract ABI.
contract MasterContract {
    storage: MasterContractData
    incomingMessages: MasterContractIncomingMessage
    thrownErrors: MasterContractErrors
}

struct (0x946a98b6) MasterContractDeploy {
    queryId: uint64
}

struct (0x85548561) MasterContractUpdateDetails {
    dealAddress: address
    deadlineUNIX: uint64?
    referralCustomerAddress: address?
    referralFreelancerAddress: address?
}

struct (0x7362d09c) MasterContractTokenNotification {
    queryId: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct (0xd53276db) MasterContractTokenExcesses {
    queryId: uint64
}

struct MasterContractCommissions {
    transfershipCommissionPercentage: uint256
    referralCustomerCommissionPercentage: uint256
    referralFreelancerCommissionPercentage: uint256
}

struct (0x4b486165) MasterContractSetCommissions {
    commissions: MasterContractCommissions
    tactContinuation: Cell<MasterContractSetCommissionsContinuation>
}

struct MasterContractSetCommissionsContinuation {
    dealAddress: address?
}

struct (0x56548561) MasterContractSetOracleAddress {
    oracleAddress: address
    dealAddress: address?
}

struct (0x70958879) MasterContractGetFunds {
    amount: coins
    usdt: bool?
    dealAddress: address?
}

struct (0x55548561) MasterContractSetUsdtAddress {
    usdtAddress: address
}

struct (0x67548561) MasterContractUpgrade {
    code: cell?
    data: cell?
}

struct MasterContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    oracleAddress: address?
    stopped: bool
    usdtAddress: address?
    tactContinuation: Cell<MasterContractDataContinuation>
}

struct MasterContractDataContinuation {
    commissions: MasterContractCommissions
    version: uint32
}

type MasterContractIncomingMessage =
    | MasterContractUpgrade
    | MasterContractSetUsdtAddress
    | MasterContractSetOracleAddress
    | MasterContractTokenNotification
    | MasterContractTokenExcesses
    | MasterContractSetCommissions
    | MasterContractUpdateDetails
    | MasterContractGetFunds
    | MasterContractDeploy

enum MasterContractErrors {
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
    /// Only parent or oracle can update the details
    OnlyParentOrOracleCanUpdateTheDetails = 1318
    /// Referral customer commission percentage can't be greater than 1000
    ReferralCustomerCommissionPercentageCanTBeGreaterThan1000 = 4141
    /// Only parent or oracle can set the commissions
    OnlyParentOrOracleCanSetTheCommissions = 6136
    /// Not enough funds
    NotEnoughFunds = 8086
    /// Only owner can upgrade
    OnlyOwnerCanUpgrade = 9559
    /// Either parent or oracle can resume
    EitherParentOrOracleCanResume = 10035
    /// Referral freelancer commission percentage can't be less than 0
    ReferralFreelancerCommissionPercentageCanTBeLessThan0 = 11488
    /// Referral customer commission percentage can't be less than 0
    ReferralCustomerCommissionPercentageCanTBeLessThan0 = 14520
    /// Only client or parent or oracle can return funds
    OnlyClientOrParentOrOracleCanReturnFunds = 16186
    /// Either parent or oracle can stop
    EitherParentOrOracleCanStop = 19296
    /// Only owner can set the commissions
    OnlyOwnerCanSetTheCommissions = 19858
    /// Transfership commission percentage can't be less than 0
    TransfershipCommissionPercentageCanTBeLessThan0 = 23942
    /// Only exclusive rights owner or parent can get funds
    OnlyExclusiveRightsOwnerOrParentCanGetFunds = 24737
    /// Only oracle or master contract can set finished
    OnlyOracleOrMasterContractCanSetFinished = 26605
    /// Only master contract can set the oracle address
    OnlyMasterContractCanSetTheOracleAddress = 27419
    /// Transfership commission percentage can't be greater than 1000
    TransfershipCommissionPercentageCanTBeGreaterThan1000 = 31610
    /// Only owner can set the oracle address
    OnlyOwnerCanSetTheOracleAddress = 31643
    /// Referral freelancer commission percentage can't be greater than 1000
    ReferralFreelancerCommissionPercentageCanTBeGreaterThan1000 = 43950
    /// Incorrect commissions for the milestone enclosement
    IncorrectCommissionsForTheMilestoneEnclosement = 48569
    /// Contract not stopped
    ContractNotStopped = 53296
    /// Only owner can set the usdt address
    OnlyOwnerCanSetTheUsdtAddress = 56947
    /// Only owner can update the details
    OnlyOwnerCanUpdateTheDetails = 57838
    /// Only owner can get funds
    OnlyOwnerCanGetFunds = 61678
}

get fun version(): int257 {
    throw 0;
}

get fun getOwner(): address {
    throw 0;
}

get fun getUsdtAddress(): address? {
    throw 0;
}

get fun getOracleAddress(): address? {
    throw 0;
}

get fun currentCommissions(): MasterContractCommissions? {
    throw 0;
}

get fun currentTransfershipCommissionPercentage(): int257 {
    throw 0;
}

get fun currentReferralCustomerCommissionPercentage(): int257 {
    throw 0;
}

get fun currentReferralFreelancerCommissionPercentage(): int257 {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
