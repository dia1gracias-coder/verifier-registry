// Generated from the verified Tact contract ABI.
contract Treasury {
    storage: TreasuryData
    incomingMessages: TreasuryDeploy
    thrownErrors: TreasuryErrors
}

struct (0x946a98b6) TreasuryDeploy {
    queryId: uint64
}

struct TreasuryRoomData {
    entry_fee: int257
    winners_count: int257
    status: int257
    tactContinuation: Cell<TreasuryRoomDataContinuation>
}

struct TreasuryRoomDataContinuation {
    pool: int257
    total_entries: int257
    paid_hash: int257
    tactContinuation: Cell<TreasuryRoomDataContinuation2>
}

struct TreasuryRoomDataContinuation2 {
    created_at: int257
    closed_at: int257
}

struct TreasuryData {
    tactDeploymentCompleted: bool
    owner: address
    upgrade_authority: address
    airdrop_pool: int257
    tactContinuation: Cell<TreasuryDataContinuation>
}

struct TreasuryDataContinuation {
    airdrop_id: int257
    rooms: map<int257, Cell<TreasuryRoomData>>
    current_room_id: int257
    winner_rewards: map<address, int257>
    claimed_rewards: map<address, int257>
    HOUSE_FEE_BPS: int257
    tactContinuation: Cell<TreasuryDataContinuation2>
}

struct TreasuryDataContinuation2 {
    HOUSE_FEE_DENOMINATOR: int257
}

enum TreasuryErrors {
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
    /// Entry fee must be positive
    EntryFeeMustBePositive = 2493
    /// Room is not open
    RoomIsNotOpen = 5883
    /// No reward for this address
    NoRewardForThisAddress = 6225
    /// Room is not paid
    RoomIsNotPaid = 10215
    /// Room not found
    RoomNotFound = 14103
    /// Too many winners
    TooManyWinners = 14506
    /// Room already paid
    RoomAlreadyPaid = 16751
    /// Room does not exist
    RoomDoesNotExist = 20618
    /// Room already exists
    RoomAlreadyExists = 27407
    /// Winners count must be positive
    WinnersCountMustBePositive = 39893
    /// Room key must be positive
    RoomKeyMustBePositive = 40266
    /// No remaining reward to claim
    NoRemainingRewardToClaim = 43137
    /// No airdrop pool available
    NoAirdropPoolAvailable = 49080
    /// Room is not closed
    RoomIsNotClosed = 50845
    /// Entry fee must be exact amount
    EntryFeeMustBeExactAmount = 51351
    /// Entry fee mismatch
    EntryFeeMismatch = 58501
    /// Winners count mismatch
    WinnersCountMismatch = 62631
}
