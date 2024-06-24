// Generated from the verified Tact contract ABI.
contract VirusTonRaffle {
    storage: VirusTonRaffleData
    incomingMessages: VirusTonRaffleIncomingMessage
    thrownErrors: VirusTonRaffleErrors
}

struct (0xa4618023) VirusTonRaffleSendRewards {
    winners: map<int257, address>
}

struct (0xc3e1973a) VirusTonRaffleClaimIfSeasonFailed {
}

struct (0x2df889db) VirusTonRaffleUpdateSettings {
    season_end_date: int257
    days_for_claim: int257
}

struct VirusTonRaffleData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    state: uint8
    infected: uint32
    tickets: uint64
    season_end_date: uint32
    season_target_infections: uint32
    days_for_claim: int257
    winners: map<int257, int257>
    state_start_date: uint32
    seqno: uint32
    owner: address
    pubkey: uint256
}

type VirusTonRaffleIncomingMessage =
    | VirusTonRaffleSendRewards
    | VirusTonRaffleUpdateSettings
    | VirusTonRaffleClaimIfSeasonFailed

enum VirusTonRaffleErrors {
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
    /// Wrong stage for claim operation
    WrongStageForClaimOperation = 8770
    /// New season end date must be greater
    NewSeasonEndDateMustBeGreater = 21510
    /// Wrong stage for rewards operation
    WrongStageForRewardsOperation = 24634
    /// Sequence number is not correct
    SequenceNumberIsNotCorrect = 28262
    /// Signature not valid
    SignatureNotValid = 29566
    /// Season is not finished yet
    SeasonIsNotFinishedYet = 31015
    /// Epidemia stage passed
    EpidemiaStagePassed = 32067
    /// New infected must be greater
    NewInfectedMustBeGreater = 53228
}

get fun seq_no(): int257 {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}

get fun state(): int257 {
    throw 0;
}

get fun season_end_date(): int257 {
    throw 0;
}

get fun days_for_claim(): int257 {
    throw 0;
}

get fun state_start_date(): int257 {
    throw 0;
}

get fun claim_end_date(): int257 {
    throw 0;
}

get fun season_target_infections(): int257 {
    throw 0;
}

get fun contract_time(): int257 {
    throw 0;
}

get fun tickets(): int257 {
    throw 0;
}

get fun infected(): int257 {
    throw 0;
}

get fun winners(): map<int257, int257> {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
