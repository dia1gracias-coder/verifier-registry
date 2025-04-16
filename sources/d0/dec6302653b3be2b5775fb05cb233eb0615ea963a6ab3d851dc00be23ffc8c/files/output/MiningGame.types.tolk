// Generated from the verified Tact contract ABI.
contract MiningGame {
    storage: MiningGameData
    incomingMessages: MiningGameDeploy
    thrownErrors: MiningGameErrors
}

struct (0x946a98b6) MiningGameDeploy {
    queryId: uint64
}

struct MiningGameMinerStats {
    name: string
    level: int257
    level_title: string
    mining_rate: int257
    pickaxe_power: int257
    tactContinuation: Cell<MiningGameMinerStatsContinuation>
}

struct MiningGameMinerStatsContinuation {
    minerals: int257
    max_storage: int257
}

struct MiningGameLevelRequirement {
    next_level: int257
    cost: int257
    cost_string: string
}

struct MiningGameData {
    tactDeploymentCompleted: bool
    minerals: uint32
    max_storage: uint32
    last_mined: uint64
    mining_rate: uint32
    pickaxe_power: uint32
    mining_cooldown: int257
    last_manual_mine: int257
    miner_level: uint16
    miner_name: string
    owner_address: address
    tactContinuation: Cell<MiningGameDataContinuation>
}

struct MiningGameDataContinuation {
    commission_rate: int257
}

enum MiningGameErrors {
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
    /// Only the owner can update commission rate
    OnlyTheOwnerCanUpdateCommissionRate = 18284
    /// Storage full! Upgrade storage or sell minerals
    StorageFullUpgradeStorageOrSellMinerals = 18991
    /// Insufficient payment for upgrade
    InsufficientPaymentForUpgrade = 24565
    /// Contract doesn't have enough TON to pay for minerals
    ContractDoesnTHaveEnoughTONToPayForMinerals = 35789
    /// Commission rate must be between 0% and 30%
    CommissionRateMustBeBetween0And30 = 53341
    /// Mining too soon! Wait for cooldown to finish
    MiningTooSoonWaitForCooldownToFinish = 61093
}

get fun total_minerals(): int257 {
    throw 0;
}

get fun collected_minerals(): int257 {
    throw 0;
}

get fun storage_capacity(): int257 {
    throw 0;
}

get fun mining_rate(): int257 {
    throw 0;
}

get fun pickaxe_power(): int257 {
    throw 0;
}

get fun uncollected_minerals(): int257 {
    throw 0;
}

get fun storage_fullness(): int257 {
    throw 0;
}

get fun contract_balance(): string {
    throw 0;
}

get fun contract_balance_raw(): int257 {
    throw 0;
}

get fun miner_level(): int257 {
    throw 0;
}

get fun miner_name(): string {
    throw 0;
}

get fun miner_level_title(): string {
    throw 0;
}

get fun miner_stats(): MiningGameMinerStats {
    throw 0;
}

get fun next_level_requirement(): MiningGameLevelRequirement {
    throw 0;
}

get fun owner_address(): address {
    throw 0;
}

get fun commission_rate(): int257 {
    throw 0;
}
