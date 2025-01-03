// Generated from the verified Tact contract ABI.
contract TreasureHunters {
    storage: TreasureHuntersData
    incomingMessages: TreasureHuntersIncomingMessage
    thrownErrors: TreasureHuntersErrors
}

struct (0x946a98b6) TreasureHuntersDeploy {
    queryId: uint64
}

struct TreasureHuntersExpeditionHistory {
    winners: map<int257, address>
    losers: map<int257, address>
}

struct TreasureHuntersHistoricalData {
    playedAtLeastOnce: map<address, bool>
    expeditionLogLength: int257
    expeditionLog: map<int257, Cell<TreasureHuntersExpeditionHistory>>
}

struct TreasureHuntersConfig {
    numberOfPlayers: int257
    ticketPrice: coins
    treasurePercent: coins
    discountTicketPrice: coins
    referrerBonusPercent: int257
}

struct (0xb4b86e5a) TreasureHuntersBuyTicket {
}

struct (0x2365d020) TreasureHuntersWithdraw {
}

struct (0x694dcb5c) TreasureHuntersBuyFirstTicketAfterReferral {
    referrer: address
}

struct TreasureHuntersCurrentExpedition {
    players: map<int257, address>
    playersLength: int257
}

struct TreasureHuntersData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    tactContinuation: Cell<TreasureHuntersDataContinuation>
}

struct TreasureHuntersDataContinuation {
    config: TreasureHuntersConfig
    tactContinuation: Cell<TreasureHuntersDataContinuation2>
}

struct TreasureHuntersDataContinuation2 {
    currentExpedition: TreasureHuntersCurrentExpedition
    historicalData: TreasureHuntersHistoricalData
}

type TreasureHuntersIncomingMessage =
    | TreasureHuntersBuyFirstTicketAfterReferral
    | TreasureHuntersBuyTicket
    | TreasureHuntersWithdraw
    | TreasureHuntersDeploy

enum TreasureHuntersErrors {
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
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
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
    /// Invalid address
    InvalidAddress = 136
    /// Masterchain support is not enabled for this contract
    MasterchainSupportIsNotEnabledForThisContract = 137
    /// Expedition is full
    ExpeditionIsFull = 26592
}

get fun expeditionLog(): map<int257, Cell<TreasureHuntersExpeditionHistory>> {
    throw 0;
}

get fun contractBalance(): int257 {
    throw 0;
}

get fun numberOfCurrentPlayers(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
