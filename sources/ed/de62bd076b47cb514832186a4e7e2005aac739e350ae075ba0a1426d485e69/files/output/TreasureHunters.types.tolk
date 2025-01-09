// Generated from the verified Tact contract ABI.
contract TreasureHunters {
    storage: TreasureHuntersData
    incomingMessages: TreasureHuntersIncomingMessage
    thrownErrors: TreasureHuntersErrors
}

struct (0x946a98b6) TreasureHuntersDeploy {
    queryId: uint64
}

struct TreasureHuntersConfig {
    numberOfPlayers: int257
    ticketPrice: coins
    treasurePercent: coins
    referrerBonusPercent: int257
}

struct TreasureHuntersWinner {
    treasure: int257
    player: address
}

struct (0xda384e42) TreasureHuntersExpeditionResultInternal {
    address: address
    winners: map<int257, Cell<TreasureHuntersWinner>>
}

struct (0x2ec2704b) TreasureHuntersBuyTicket {
    referrer: address?
}

struct (0xfc264fcd) TreasureHuntersClaim {
}

struct TreasureHuntersExpeditionResult {
    address: address
    winners: map<int257, Cell<TreasureHuntersWinner>>
}

struct (0x2365d020) TreasureHuntersWithdraw {
}

struct (0x6e45bb82) TreasureHuntersRequestReferralBonus {
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
    currentExpedition: address?
    currentExpeditionLength: int257
    expeditionResultsLength: int257
    expeditionResults: map<int257, Cell<TreasureHuntersExpeditionResult>>
    toBeClaimed: map<address, int257>
    referralBonus: map<address, int257>
    oncePlayed: map<address, bool>
}

type TreasureHuntersIncomingMessage =
    | TreasureHuntersWithdraw
    | TreasureHuntersClaim
    | TreasureHuntersBuyTicket
    | TreasureHuntersExpeditionResultInternal
    | TreasureHuntersRequestReferralBonus
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
    /// You have no prize claim
    YouHaveNoPrizeClaim = 7477
    /// Not enough funds
    NotEnoughFunds = 8086
    /// Only owner can check contract balance
    OnlyOwnerCanCheckContractBalance = 34660
    /// Only owner can check available for withdraw
    OnlyOwnerCanCheckAvailableForWithdraw = 36445
    /// You have no referral bonus
    YouHaveNoReferralBonus = 39439
    /// Only winner can claim
    OnlyWinnerCanClaim = 43564
    /// Expedition is already started
    ExpeditionIsAlreadyStarted = 54739
}

get fun expeditionHistory(): map<int257, Cell<TreasureHuntersExpeditionResult>> {
    throw 0;
}

get fun contractBalance(address: address): int257 {
    throw 0;
}

get fun availableForWithdraw(address: address): int257 {
    throw 0;
}

get fun canBeClaimed(address: address): int257? {
    throw 0;
}

get fun referralBonusBalance(address: address): int257? {
    throw 0;
}

get fun currentExpedition(): address? {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
