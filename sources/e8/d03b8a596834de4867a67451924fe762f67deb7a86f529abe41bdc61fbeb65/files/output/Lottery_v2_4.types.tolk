// Generated from the verified Tact contract ABI.
contract Lottery_v2_4 {
    storage: Lottery_v2_4Data
    incomingMessages: Lottery_v2_4IncomingMessage
    thrownErrors: Lottery_v2_4Errors
}

struct (0x946a98b6) Lottery_v2_4Deploy {
    queryId: uint64
}

struct (0xc37ec5d4) Lottery_v2_4BuyTickets {
    ltype: uint8
    qty: uint32
}

struct Lottery_v2_4Pool {
    tickets: map<uint256, address>
    total_tickets: uint256
    prize_pool: coins
    last_draw_id: uint64
}

struct Lottery_v2_4DrawLog {
    payload_hash: uint256
    winner: address
    ltype: uint8
    prize: coins
    timestamp: uint32
}

struct Lottery_v2_4PurchaseWindow {
    count: uint32
    window_start: uint32
}

struct Lottery_v2_4Data {
    tactDeploymentCompleted: bool
    owner_address: address
    tax_address: address
    app_pubkey: uint256
    network_id: uint32
    paused: bool
    tax_reserve: coins
    tactContinuation: Cell<Lottery_v2_4DataContinuation>
}

struct Lottery_v2_4DataContinuation {
    owner_reserve: coins
    failed_payouts: map<address, coins>
    pools: map<uint8, Cell<Lottery_v2_4Pool>>
    draw_logs: map<uint64, Cell<Lottery_v2_4DrawLog>>
    per_address_window: map<address, Cell<Lottery_v2_4PurchaseWindow>>
    max_per_window: uint32
    locked: bool
}

type Lottery_v2_4IncomingMessage =
    | Lottery_v2_4BuyTickets
    | Lottery_v2_4Deploy

enum Lottery_v2_4Errors {
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
    /// invalid ltype
    InvalidLtype = 2366
    /// invalid type
    InvalidType = 5828
    /// rate limit
    RateLimit = 16051
    /// locked
    Locked = 19671
    /// insufficient funds
    InsufficientFunds = 30251
    /// paused
    Paused = 41067
    /// qty
    Qty = 52130
}

get fun poolInfo(ltype: int257): Lottery_v2_4Pool? {
    throw 0;
}

get fun drawLog(draw_id: int257): Lottery_v2_4DrawLog? {
    throw 0;
}

get fun failedPayout(addr: address): int257 {
    throw 0;
}

get fun taxReserve(): int257 {
    throw 0;
}

get fun ownerReserve(): int257 {
    throw 0;
}

get fun ownerAddress(): address {
    throw 0;
}

get fun taxAddress(): address {
    throw 0;
}

get fun appPubkey(): int257 {
    throw 0;
}

get fun networkId(): int257 {
    throw 0;
}

get fun isPaused(): bool {
    throw 0;
}

get fun rateLimitInfo(addr: address): Lottery_v2_4PurchaseWindow? {
    throw 0;
}
