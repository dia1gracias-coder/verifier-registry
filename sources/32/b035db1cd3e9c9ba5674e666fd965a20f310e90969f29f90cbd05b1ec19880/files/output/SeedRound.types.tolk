// Generated from the verified Tact contract ABI.
contract SeedRound {
    storage: SeedRoundData
    incomingMessages: SeedRoundIncomingMessage
    thrownErrors: SeedRoundErrors
}

struct (0x946a98b6) SeedRoundDeploy {
    queryId: uint64
}

struct (0x819dbe99) SeedRoundChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x7362d09c) SeedRoundJettonTransferNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0x9beaebb2) SeedRoundSetParams {
    priceUsdtPerToken: coins
    tokenDecimals: uint8
    hardCap: coins
    minBuy: coins
    maxBuy: coins
    startTime: uint64
    endTime: uint64
    whitelistEnabled: bool
}

struct (0x228b96ab) SeedRoundSetTiers {
    access: coins
    priority: coins
    strategic: coins
}

struct (0xe74952ec) SeedRoundSetFounder {
    investor: address
    level: uint8
    founderUsdt: coins
}

struct (0xaa5cb43d) SeedRoundSetFounderMax {
    maxBuy: coins
}

struct (0x115956e2) SeedRoundSetFounderBonus {
    bonusPct: uint16
}

struct (0xc767e87a) SeedRoundSetUsdtWallet {
    wallet: address
}

struct (0x44d2d05c) SeedRoundSetWhitelist {
    investor: address
    allowed: bool
}

struct (0x3cb2a5a0) SeedRoundWithdrawUsdt {
    amount: coins
    destination: address
}

struct (0xef1cd4fb) SeedRoundSweepUsdt {
    amount: coins
    destination: address
}

struct (0xcfc66cbd) SeedRoundSetTreasury {
    treasury: address
}

struct SeedRoundAllocation {
    usdtContributed: int257
    tokenAllocation: int257
}

struct SeedRoundInvestorStatus {
    founderLevel: int257
    founderUsdt: int257
    seedContributed: int257
    tactContinuation: Cell<SeedRoundInvestorStatusContinuation>
}

struct SeedRoundInvestorStatusContinuation {
    seedTier: int257
    effectiveStatus: int257
}

struct SeedRoundRoundInfo {
    owner: address
    treasury: address
    usdtWallet: address?
    stopped: bool
    tactContinuation: Cell<SeedRoundRoundInfoContinuation>
}

struct SeedRoundRoundInfoContinuation {
    withdrawn: int257
    priceUsdtPerToken: int257
    tokenDecimals: int257
    tactContinuation: Cell<SeedRoundRoundInfoContinuation2>
}

struct SeedRoundRoundInfoContinuation2 {
    hardCap: int257
    minBuy: int257
    maxBuy: int257
    tactContinuation: Cell<SeedRoundRoundInfoContinuation3>
}

struct SeedRoundRoundInfoContinuation3 {
    maxBuyFounder: int257
    founderBonusPct: int257
    startTime: int257
    tactContinuation: Cell<SeedRoundRoundInfoContinuation4>
}

struct SeedRoundRoundInfoContinuation4 {
    endTime: int257
    whitelistEnabled: bool
    tierAccess: int257
    tierPriority: int257
    tactContinuation: Cell<SeedRoundRoundInfoContinuation5>
}

struct SeedRoundRoundInfoContinuation5 {
    tierStrategic: int257
    totalRaised: int257
    investorsCount: int257
}

struct SeedRoundData {
    tactDeploymentCompleted: bool
    owner: address
    treasury: address
    stopped: bool
    withdrawn: coins
    usdtWallet: address?
    tactContinuation: Cell<SeedRoundDataContinuation>
}

struct SeedRoundDataContinuation {
    priceUsdtPerToken: coins
    tokenDecimals: uint8
    hardCap: coins
    minBuy: coins
    maxBuy: coins
    maxBuyFounder: coins
    founderBonusPct: uint16
    startTime: uint64
    endTime: uint64
    whitelistEnabled: bool
    tierAccess: coins
    tierPriority: coins
    tactContinuation: Cell<SeedRoundDataContinuation2>
}

struct SeedRoundDataContinuation2 {
    tierStrategic: coins
    totalRaised: coins
    investorsCount: uint32
    investors: map<address, int257>
    whitelist: map<address, bool>
    founderLevel: map<address, int257>
    founderUsdt: map<address, int257>
}

type SeedRoundIncomingMessage =
    | SeedRoundJettonTransferNotification
    | SeedRoundSetParams
    | SeedRoundSetTiers
    | SeedRoundSetFounderMax
    | SeedRoundSetFounderBonus
    | SeedRoundSetFounder
    | SeedRoundSetUsdtWallet
    | SeedRoundSetWhitelist
    | SeedRoundWithdrawUsdt
    | SeedRoundSweepUsdt
    | SeedRoundSetTreasury
    | SeedRoundDeploy
    | SeedRoundChangeOwner

enum SeedRoundErrors {
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
    /// price < 0
    Price0 = 2641
    /// price frozen after first buy
    PriceFrozenAfterFirstBuy = 5359
    /// bonus frozen after first buy
    BonusFrozenAfterFirstBuy = 19071
    /// minBuy > maxBuy
    MinBuyMaxBuy = 19993
    /// amount > available
    AmountAvailable = 25871
    /// amount <= 0
    Amount0 = 38540
    /// bonus too large
    BonusTooLarge = 40951
    /// tiers not monotonic
    TiersNotMonotonic = 44685
    /// Contract not stopped
    ContractNotStopped = 53296
    /// decimals too large
    DecimalsTooLarge = 59469
    /// startTime >= endTime
    StartTimeEndTime = 61720
}

get fun allocationOf(investor: address): SeedRoundAllocation {
    throw 0;
}

get fun statusOf(investor: address): SeedRoundInvestorStatus {
    throw 0;
}

get fun isFounder(investor: address): bool {
    throw 0;
}

get fun isWhitelisted(investor: address): bool {
    throw 0;
}

get fun roundInfo(): SeedRoundRoundInfo {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}
