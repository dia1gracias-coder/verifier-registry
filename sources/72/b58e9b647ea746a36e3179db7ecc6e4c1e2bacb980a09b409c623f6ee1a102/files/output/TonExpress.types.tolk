// Generated from the verified Tact contract ABI.
contract TonExpress {
    storage: TonExpressData
    incomingMessages: TonExpressIncomingMessage
    thrownErrors: TonExpressErrors
}

struct (0x946a98b6) TonExpressDeploy {
    queryId: uint64
}

struct TonExpressPlayer {
    epoch: uint32
    shares: coins
    divDebt: int257
    claimableDiv: coins
    lastBuyTs: uint32
    lastSellTs: uint32
    t0: coins
    t1: coins
    t2: coins
    activeCount: uint8
    everBought: bool
}

struct (0x5f44d8e7) TonExpressSetReferrer {
    referrer: address
}

struct (0x64a04fc7) TonExpressBuy {
}

struct (0x52c858c2) TonExpressSell {
    slot: uint8
}

struct (0x4552d708) TonExpressClaimAll {
}

struct (0x8b0cd1ae) TonExpressWithdrawDev {
    to: address
    amount: coins
}

struct TonExpressData {
    tactDeploymentCompleted: bool
    owner: address
    status: uint8
    roundId: uint32
    roundStartTs: uint32
    endedAt: uint32
    timer: uint32
    lastUpdateTs: uint32
    capCurrent: uint32
    soft10Triggered: bool
    chaosTriggered: bool
    passengers: uint32
    activePlayers: uint32
    totalShares: coins
    divPerShare: int257
    tactContinuation: Cell<TonExpressDataContinuation>
}

struct TonExpressDataContinuation {
    devPool: coins
    nextRoundPotStored: coins
    lastBuy1: address?
    lastBuy2: address?
    tactContinuation: Cell<TonExpressDataContinuation2>
}

struct TonExpressDataContinuation2 {
    lastBuy3: address?
    players: map<address, Cell<TonExpressPlayer>>
    referrerOf: map<address, address>
}

type TonExpressIncomingMessage =
    | TonExpressSetReferrer
    | TonExpressBuy
    | TonExpressSell
    | TonExpressClaimAll
    | TonExpressWithdrawDev
    | TonExpressDeploy

enum TonExpressErrors {
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
    /// NOT_ACTIVE
    NOTACTIVE = 8869
    /// INSUFFICIENT_BAL_AFTER_DEV_WITHDRAW
    INSUFFICIENTBALAFTERDEVWITHDRAW = 9114
    /// CLAIM_OVER
    CLAIMOVER = 9218
    /// DEV_WITHDRAW_ONLY_ENDED
    DEVWITHDRAWONLYENDED = 10306
    /// BAD_REF
    BADREF = 20753
    /// NOTHING
    NOTHING = 22080
    /// SELL_CD
    SELLCD = 24455
    /// GT_DEVPOOL
    GTDEVPOOL = 26221
    /// BAD_AMOUNT
    BADAMOUNT = 29392
    /// BAD_PRICE
    BADPRICE = 35867
    /// NOT_ENDED
    NOTENDED = 36298
    /// ONLY_OWNER
    ONLYOWNER = 37469
    /// BUY_CD
    BUYCD = 40774
    /// ENDED_BY_DECAY
    ENDEDBYDECAY = 41920
    /// EMPTY_SLOT
    EMPTYSLOT = 52410
    /// MAX_TICKETS
    MAXTICKETS = 57655
    /// REF_LOCKED
    REFLOCKED = 57789
    /// DEV_WITHDRAW_WINDOW_OVER
    DEVWITHDRAWWINDOWOVER = 61231
}

get fun getRound(): int257 {
    throw 0;
}

get fun getStatus(): int257 {
    throw 0;
}

get fun getTimer(): int257 {
    throw 0;
}

get fun getPrice(): int257 {
    throw 0;
}

get fun getPot(): int257 {
    throw 0;
}

get fun getJackpot(): int257 {
    throw 0;
}
