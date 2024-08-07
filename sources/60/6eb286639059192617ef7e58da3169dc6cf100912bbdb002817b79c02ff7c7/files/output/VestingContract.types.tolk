// Generated from the verified Tact contract ABI.
contract VestingContract {
    storage: VestingContractData
    incomingMessages: VestingContractIncomingMessage
    thrownErrors: VestingContractErrors
}

struct (0x946a98b6) VestingContractDeploy {
    queryId: uint64
}

struct (0x34ac44b7) VestingContractOrderJetton {
    sponsorAddress: address
}

struct (0x037994b8) VestingContractActivateReferralLink {
    sponsorAddress: address
}

struct (0xaf4da7cd) VestingContractActivateReferralLinkByOwner {
    referralAddress: address
    sponsorAddress: address
}

struct (0xf4547bd3) VestingContractClaim {
    amount: int257
    hash: int257
}

struct (0xab48554a) VestingContractRevokeVesting {
    address: address
    index: uint8
}

struct (0x8f673d32) VestingContractSetCrowdsaleStage {
    stage: uint8
}

struct (0x80807f40) VestingContractSetTonRate {
    rate: coins
}

struct (0x6992b272) VestingContractSetMinimalAmount {
    minAmount: coins
}

struct (0x51d24d14) VestingContractAddVestingScheduleByManual {
    cliff: uint32
    start: uint32
    beneficiary: address
    jettonAmount: uint256
    durationVesting: uint256
}

struct (0x24c6438e) VestingContractSetJettonAddress {
    jettonAddress: address
}

struct VestingContractVestingSchedule {
    beneficiary: address
    start: uint32
    duration: uint32
    amountTotal: coins
    released: coins
}

struct VestingContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    jettonAddress: address
    recipient: address
    vestingSchedules: map<uint256, Cell<VestingContractVestingSchedule>>
    holdersVestingCount: map<address, uint8>
    tactContinuation: Cell<VestingContractDataContinuation>
}

struct VestingContractDataContinuation {
    referralTree: map<address, address>
    vestingSchedulesTotalAmount: coins
    stage: uint8
    rate: uint32
    durationVesting: uint32
    cliff: uint32
    slicePeriod: uint32
    tonRate: coins
    minAmount: coins
}

type VestingContractIncomingMessage =
    | VestingContractOrderJetton
    | VestingContractClaim
    | VestingContractRevokeVesting
    | VestingContractActivateReferralLink
    | VestingContractActivateReferralLinkByOwner
    | VestingContractSetCrowdsaleStage
    | VestingContractSetTonRate
    | VestingContractSetJettonAddress
    | VestingContractSetMinimalAmount
    | VestingContractAddVestingScheduleByManual
    | VestingContractDeploy

enum VestingContractErrors {
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
    /// address same as yours
    AddressSameAsYours = 4486
    /// only owner can use this method
    OnlyOwnerCanUseThisMethod = 37776
    /// minimal amount is 1000 usdt
    MinimalAmountIs1000Usdt = 63464
}

get fun get_sponsor(referral: address): address? {
    throw 0;
}

get fun get_vested_hash(address: address, index: int257): int257 {
    throw 0;
}

get fun get_count_vesting(address: address): int257 {
    throw 0;
}

get fun get_vested_jettons_info(address: address, index: int257): VestingContractVestingSchedule? {
    throw 0;
}

get fun get_vested_jettons_all(): map<uint256, Cell<VestingContractVestingSchedule>> {
    throw 0;
}

get fun referral_tree(): map<address, address> {
    throw 0;
}

get fun get_vested_jettons(address: address, index: int257): int257 {
    throw 0;
}

get fun get_vested_jettons_start(address: address, index: int257): int257 {
    throw 0;
}

get fun get_vested_jettons_released(address: address, index: int257): int257 {
    throw 0;
}

get fun get_vested_jettons_claim(hash: int257): int257 {
    throw 0;
}

get fun get_total_vested_jettons(): int257 {
    throw 0;
}

get fun balance(): string {
    throw 0;
}

get fun ton_rate(): int257 {
    throw 0;
}

get fun rate(): int257 {
    throw 0;
}

get fun stage(): int257 {
    throw 0;
}

get fun min_amount(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
