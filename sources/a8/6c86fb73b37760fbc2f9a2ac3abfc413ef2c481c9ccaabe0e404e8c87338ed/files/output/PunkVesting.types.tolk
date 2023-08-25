// Generated from the verified Tact contract ABI.
contract PunkVesting {
    storage: PunkVestingData
    incomingMessages: PunkVestingIncomingMessage
    thrownErrors: PunkVestingErrors
}

struct (0x946a98b6) PunkVestingDeploy {
    queryId: uint64
}

struct (0x4cee6246) PunkVestingPutHoldersMsg {
    count: uint8
    holders: map<uint8, Cell<PunkVestingHolderDto>>
}

struct (0x88af4a34) PunkVestingSetPeriodsMsg {
    count: uint8
    percentFactor: int257
    periods: map<int257, Cell<PunkVestingPeriod>>
}

struct (0xf54bae82) PunkVestingSetOwnerWallet {
    address: address
}

struct (0x119cb7b9) PunkVestingSetVestingRound {
    vestingRound: uint8
}

struct (0x72c5cfe2) PunkVestingTopupBalance {
}

struct PunkVestingBalance {
    starting: coins
    current: coins
}

struct PunkVestingHolderDto {
    address: address
    starting: coins
}

struct PunkVestingHolderInfo {
    common: coins
    current: coins
    available: coins
    currentPeriod: PunkVestingPeriod?
}

struct PunkVestingPeriod {
    startTime: uint32
    percent: uint16
}

struct PunkVestingPeriodsSet {
    count: uint8
    periods: map<int257, Cell<PunkVestingPeriod>>
}

struct PunkVestingData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    jettonWallet: address?
    holdersCount: uint8
    holdersMap: map<int257, Cell<PunkVestingBalance>>
    periodsCount: uint8
    periodsMap: map<int257, Cell<PunkVestingPeriod>>
    percentFactor: int257
    vestingRound: uint8
}

type PunkVestingIncomingMessage =
    | PunkVestingSetVestingRound
    | PunkVestingPutHoldersMsg
    | PunkVestingSetOwnerWallet
    | PunkVestingTopupBalance
    | PunkVestingSetPeriodsMsg
    | PunkVestingDeploy

enum PunkVestingErrors {
    /// Stack undeflow
    StackUndeflow = 2
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
    /// Rejected by reason: jetton wallet is not set
    RejectedByReasonJettonWalletIsNotSet = 12383
    /// Periods is not set
    PeriodsIsNotSet = 18919
    /// Holders map already set
    HoldersMapAlreadySet = 19226
    /// There are no tokens available for withdrawal at the moment.
    ThereAreNoTokensAvailableForWithdrawalAtTheMoment = 19719
    /// Rejected by reason: the minimum volume is not enough
    RejectedByReasonTheMinimumVolumeIsNotEnough = 28347
    /// Round already set
    RoundAlreadySet = 32652
    /// Only basechain is supported
    OnlyBasechainIsSupported = 44310
    /// Jetton wallet already set
    JettonWalletAlreadySet = 49291
    /// Rejected by reason: unknown wallet
    RejectedByReasonUnknownWallet = 59712
}

get fun getHolderInfo(adr: address): PunkVestingHolderInfo {
    throw 0;
}

get fun Periods(): PunkVestingPeriodsSet {
    throw 0;
}

get fun AllHolders(): map<int257, Cell<PunkVestingBalance>> {
    throw 0;
}

get fun JettonWallet(): address? {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
