// Generated from the verified Tact contract ABI.
contract GiveHelpManagerV37 {
    storage: GiveHelpManagerV37Data
    incomingMessages: GiveHelpManagerV37IncomingMessage
    thrownErrors: GiveHelpManagerV37Errors
}

struct (0x7362d09c) GiveHelpManagerV37JettonTransferNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0xd53276db) GiveHelpManagerV37JettonExcesses {
    queryId: uint64
}

struct (0xf0baae40) GiveHelpManagerV37JoinGiveHelp {
    giveawayId: uint64
    code: string
    referrer: address?
}

struct (0xfbc54a21) GiveHelpManagerV37Distribute {
    giveawayId: uint64
}

struct (0xb286b41d) GiveHelpManagerV37WithdrawUnspent {
    giveawayId: uint64
}

struct (0xe8cc08cf) GiveHelpManagerV37Cleanup {
    giveawayId: uint64
    cursor: uint64
}

struct (0xcd685c50) GiveHelpManagerV37ClaimReferrals {
}

struct (0xa79a1045) GiveHelpManagerV37UpdateMinimums {
    minTotalAmount: coins
    minPerWinner: coins
}

struct (0x5a5a7283) GiveHelpManagerV37SetPayoutFee {
    newFee: coins
}

struct (0x5dc58e69) GiveHelpManagerV37SetMinDuration {
    newMinMinutes: uint32
}

struct (0x3d043912) GiveHelpManagerV37SetDustSweepThreshold {
    newThreshold: coins
}

struct (0x31f59d24) GiveHelpManagerV37SetAirdropWallet {
    wallet: address
}

struct (0x7a4508d9) GiveHelpManagerV37Pause {
}

struct (0x8dcb2d19) GiveHelpManagerV37Unpause {
}

struct (0x70373fea) GiveHelpManagerV37TransferOwnership {
    newOwner: address
}

struct (0xb8e34b79) GiveHelpManagerV37SetJettonWallet {
    wallet: address
}

struct (0x425d66d0) GiveHelpManagerV37RescueRequest {
    to: address
    amount: coins
}

struct (0x01fcb345) GiveHelpManagerV37ExecuteRescue {
}

struct (0xe6750f60) GiveHelpManagerV37CancelRescue {
}

struct (0x351df3a9) GiveHelpManagerV37ClaimFor {
    user: address
}

struct GiveHelpManagerV37GiveHelp {
    giver: address
    codeHash: uint256
    totalAmount: int257
    tactContinuation: Cell<GiveHelpManagerV37GiveHelpContinuation>
}

struct GiveHelpManagerV37GiveHelpContinuation {
    supportedAmount: int257
    perWinner: int257
    declaredWinners: int257
    tactContinuation: Cell<GiveHelpManagerV37GiveHelpContinuation2>
}

struct GiveHelpManagerV37GiveHelpContinuation2 {
    supportSlots: int257
    airdropIncluded: bool
    participantCount: int257
    endsAt: int257
    tactContinuation: Cell<GiveHelpManagerV37GiveHelpContinuation3>
}

struct GiveHelpManagerV37GiveHelpContinuation3 {
    tonReserveLeft: int257
    status: int257
    distCursor: int257
    tactContinuation: Cell<GiveHelpManagerV37GiveHelpContinuation4>
}

struct GiveHelpManagerV37GiveHelpContinuation4 {
    seed: int257
    createDust: int257
}

struct GiveHelpManagerV37PendingPayout {
    to: address
    amount: coins
}

struct GiveHelpManagerV37Data {
    tactDeploymentCompleted: bool
    owner: address
    platformVault: address
    airdropWallet: address
    tactContinuation: Cell<GiveHelpManagerV37DataContinuation>
}

struct GiveHelpManagerV37DataContinuation {
    riseJettonMaster: address
    riseJettonWallet: address
    minTotalAmount: coins
    minPerWinner: coins
    payoutFee: coins
    tactContinuation: Cell<GiveHelpManagerV37DataContinuation2>
}

struct GiveHelpManagerV37DataContinuation2 {
    minDurationMin: int257
    dustSweepRiseThreshold: coins
    paused: bool
    nextGiveawayId: int257
    accumulatedDust: int257
    tactContinuation: Cell<GiveHelpManagerV37DataContinuation3>
}

struct GiveHelpManagerV37DataContinuation3 {
    accumulatedRiseDust: int257
    payoutSeq: int257
    pendingRescueTo: address?
    pendingRescueAmount: coins
    tactContinuation: Cell<GiveHelpManagerV37DataContinuation4>
}

struct GiveHelpManagerV37DataContinuation4 {
    pendingRescueAfter: int257
    giveaways: map<int257, Cell<GiveHelpManagerV37GiveHelp>>
    usedCodeHashes: map<int257, bool>
    participants: map<int257, address>
    tactContinuation: Cell<GiveHelpManagerV37DataContinuation5>
}

struct GiveHelpManagerV37DataContinuation5 {
    joinedKeys: map<int257, bool>
    participantReferrer: map<int257, address>
    shuffleMap: map<int257, int257>
    tactContinuation: Cell<GiveHelpManagerV37DataContinuation6>
}

struct GiveHelpManagerV37DataContinuation6 {
    held: map<address, int257>
    claimable: map<address, int257>
    pendingRing: map<int257, Cell<GiveHelpManagerV37PendingPayout>>
}

type GiveHelpManagerV37IncomingMessage =
    | GiveHelpManagerV37SetJettonWallet
    | GiveHelpManagerV37JettonTransferNotification
    | GiveHelpManagerV37JoinGiveHelp
    | GiveHelpManagerV37Distribute
    | GiveHelpManagerV37Cleanup
    | GiveHelpManagerV37WithdrawUnspent
    | GiveHelpManagerV37ClaimReferrals
    | GiveHelpManagerV37JettonExcesses
    | GiveHelpManagerV37UpdateMinimums
    | GiveHelpManagerV37SetPayoutFee
    | GiveHelpManagerV37SetMinDuration
    | GiveHelpManagerV37SetDustSweepThreshold
    | GiveHelpManagerV37SetAirdropWallet
    | GiveHelpManagerV37Pause
    | GiveHelpManagerV37Unpause
    | GiveHelpManagerV37TransferOwnership
    | GiveHelpManagerV37RescueRequest
    | GiveHelpManagerV37ExecuteRescue
    | GiveHelpManagerV37CancelRescue
    | GiveHelpManagerV37ClaimFor

enum GiveHelpManagerV37Errors {
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
    /// Rescue already pending
    RescueAlreadyPending = 2264
    /// Wallet not set
    WalletNotSet = 5673
    /// Total >= per winner
    TotalPerWinner = 10256
    /// Above max
    AboveMax = 10881
    /// Not withdrawable
    NotWithdrawable = 11186
    /// Amount > 0
    Amount0 = 11977
    /// Ended
    Ended = 13550
    /// Fee too small
    FeeTooSmall = 15299
    /// Bad code hash
    BadCodeHash = 15418
    /// Zero top-up
    ZeroTopUp = 17535
    /// Only giver
    OnlyGiver = 17601
    /// Threshold > 0
    Threshold0 = 18565
    /// Already set
    AlreadySet = 22230
    /// Has support
    HasSupport = 22333
    /// Not found
    NotFound = 25534
    /// Already joined
    AlreadyJoined = 25931
    /// Below minimum total
    BelowMinimumTotal = 26157
    /// Platform paused
    PlatformPaused = 31828
    /// Self only
    SelfOnly = 32573
    /// Code already used
    CodeAlreadyUsed = 33637
    /// Only owner
    OnlyOwner = 35499
    /// Insufficient TON reserve
    InsufficientTONReserve = 37192
    /// Fee outside safe band
    FeeOutsideSafeBand = 39005
    /// Has participants
    HasParticipants = 39030
    /// Top-up mismatch
    TopUpMismatch = 42381
    /// Nothing to claim
    NothingToClaim = 44799
    /// Not ended
    NotEnded = 45652
    /// Winners > 0
    Winners0 = 47344
    /// No pending rescue
    NoPendingRescue = 48208
    /// Minimums > 0
    Minimums0 = 48923
    /// Below min duration
    BelowMinDuration = 49358
    /// Finished
    Finished = 49463
    /// Below minimum per winner
    BelowMinimumPerWinner = 51310
    /// Not RISE wallet
    NotRISEWallet = 53091
    /// Giver cannot join
    GiverCannotJoin = 55522
    /// Max 7 days
    Max7Days = 57043
    /// Reserve exhausted
    ReserveExhausted = 61437
    /// Not active
    NotActive = 61530
    /// Bad destination
    BadDestination = 62226
    /// Wrong code
    WrongCode = 62340
    /// Timelock not expired
    TimelockNotExpired = 62971
    /// Below 5-min floor
    Below5MinFloor = 63014
}

get fun getGiveHelp(id: int257): GiveHelpManagerV37GiveHelp? {
    throw 0;
}

get fun getTotalGiveHelps(): int257 {
    throw 0;
}

get fun isCodeHashUsed(codeHash: int257): bool {
    throw 0;
}

get fun hashCode(code: string): int257 {
    throw 0;
}

get fun hasJoined(giveawayId: int257, user: address): bool {
    throw 0;
}

get fun getParticipant(giveawayId: int257, index: int257): address? {
    throw 0;
}

get fun getHeldBalance(user: address): int257 {
    throw 0;
}

get fun getClaimable(user: address): int257 {
    throw 0;
}

get fun getMinimums(): int257 {
    throw 0;
}

get fun getMinPerWinner(): int257 {
    throw 0;
}

get fun getPayoutFee(): int257 {
    throw 0;
}

get fun getPayoutFeeBounds(): int257 {
    throw 0;
}

get fun getPayoutFeeMax(): int257 {
    throw 0;
}

get fun getBasePayoutFee(): int257 {
    throw 0;
}

get fun getRequiredReserve(totalSlots: int257): int257 {
    throw 0;
}

get fun getRequiredSupportReserve(newSlots: int257): int257 {
    throw 0;
}

get fun getAccumulatedDust(): int257 {
    throw 0;
}

get fun getAccumulatedRiseDust(): int257 {
    throw 0;
}

get fun getDustSweepRiseThreshold(): int257 {
    throw 0;
}

get fun getMinDurationMin(): int257 {
    throw 0;
}

get fun getAirdropWallet(): address {
    throw 0;
}

get fun getPendingRescue(): GiveHelpManagerV37PendingPayout? {
    throw 0;
}

get fun getPendingRescueAfter(): int257 {
    throw 0;
}

get fun isPaused(): bool {
    throw 0;
}

get fun getOwner(): address {
    throw 0;
}

get fun getPlatformVault(): address {
    throw 0;
}

get fun getRiseJettonMaster(): address {
    throw 0;
}

get fun getRiseJettonWallet(): address {
    throw 0;
}

get fun getTonBalance(): int257 {
    throw 0;
}

get fun getVersion(): int257 {
    throw 0;
}
