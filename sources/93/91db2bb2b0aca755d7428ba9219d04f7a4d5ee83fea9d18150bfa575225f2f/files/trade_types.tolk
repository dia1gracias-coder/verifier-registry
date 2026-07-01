enum TradeErrors {
    InvalidMessage = 0xFFFF
    SameUsers = 100
    NotParticipant = 101
    SideAlreadyAccepted = 103
    EmptyTonDeposit = 104
    AlreadyCompleted = 109
    AlreadyCancelled = 110
    InsufficientMessageValue = 112
    InvalidAmount = 113
    NotOwner = 114
    TradeNotClosed = 115
    NothingToSweep = 116
    TradeNotCompleted = 117
    TradeNotCancelled = 118
    TradeNotStuck = 119
    StuckTimeoutNotReached = 120
    TradeNotExpired = 121
}

const MAX_NFTS_PER_SIDE = 6
const NFT_TRANSFER_VALUE = 30000000
const MIN_ESCROW_DEPLOY_VALUE = 50000000
const MIN_CREATE_TRADE_VALUE = 10000000
const MIN_TRADE_ACTION_VALUE = 10000000
const TRADE_FEE_BPS = 50
const BPS_DENOMINATOR = 10000
const MIN_ESCROW_DUST_RESERVE = 30000000
const MIN_FACTORY_DUST_RESERVE = 30000000
const SWEEP_FEE_BUFFER = 10000000
// I-05: schema/behaviour version, exposed via getVersion() on both contracts so the indexer can route
// by version after a code upgrade. Bump whenever a deployed code change must be distinguishable
// off-chain (existing on-chain instances keep the version they were deployed with).
const CONTRACT_VERSION: uint16 = 1
// H-01: a settlement that keeps bouncing (an NFT whose item contract permanently rejects the transfer
// to the counterparty) would otherwise sit in SETTLING forever. After this timeout from the moment
// settlement began, anyone may call ForceResolveStuck to return the undeliverable NFTs to their
// depositors and move the trade to TRADE_STATUS_SETTLE_STUCK. 7 days = 604800 seconds.
const STUCK_SETTLEMENT_TIMEOUT = 604800
// M-03: an OPEN trade where every participant goes silent (both ghost, or a depositor loses their key
// and the counterparty never appears) would otherwise lock its deposited TON and NFTs forever — neither
// can be cancelled by anyone who is still around. After this much inactivity (`lastActivityAt` is reset
// on every participant deposit/accept, so only genuinely-abandoned trades qualify), anyone may call
// ExpireTrade to refund all assets to their depositors. 30 days = 2592000 seconds — generous, because
// OPEN is the negotiation phase where legitimate pauses happen, and an active trade resets the clock.
const OPEN_TRADE_TIMEOUT = 2592000
// N-2: minimum forwarded value for OwnershipAssigned. The SDK always sends 20 mTON
// (NFT_OWNERSHIP_NOTIFICATION_VALUE); this floor ensures a rejected deposit has adequate
// budget for the mode-64 return without requiring escrow-funded top-up (which would reopen C-03).
const MIN_NFT_FORWARD_VALUE = 5000000
const TRADE_STATUS_OPEN: uint8 = 0
const TRADE_STATUS_SETTLING: uint8 = 1
const TRADE_STATUS_COMPLETED: uint8 = 2
const TRADE_STATUS_REFUNDING: uint8 = 3
const TRADE_STATUS_REFUNDED: uint8 = 4
// Terminal degraded outcome: both parties' TON was distributed by settlement, but at least one NFT
// could not be delivered to the counterparty and was force-returned to its depositor after the
// stuck-settlement timeout. Distinct from COMPLETED so the indexer/UI can flag the failed delivery.
const TRADE_STATUS_SETTLE_STUCK: uint8 = 5
const NFT_STATUS_DEPOSITED: uint8 = 0
const NFT_STATUS_TRANSFER_SENT: uint8 = 1
const NFT_STATUS_TRANSFER_BOUNCED: uint8 = 2

struct TradeFactoryStorage {
    owner: address
    nextTradeId: uint64
    escrowCode: cell
    // C-01/H-03: allowlist of tradable NFT collections → that collection's NFT item code cell.
    // An escrow authenticates a deposit by recomputing the sender's expected item address from
    // (itemCode, index, collection) and requiring it to match; only genuine items of an allowlisted
    // collection pass. Snapshotted into each escrow at CreateTrade.
    allowedCollections: map<address, cell>
}

fun TradeFactoryStorage.load(): TradeFactoryStorage {
    return TradeFactoryStorage.fromCell(contract.getData());
}

fun TradeFactoryStorage.save(self) {
    contract.setData(self.toCell());
}

struct TradeEscrowStorage {
    tradeId: uint64
    factory: address
    feeRecipient: address
    participants: Cell<TradeParticipants>
    acceptedA: bool
    acceptedB: bool
    depositedTonA: coins
    depositedTonB: coins
    assets: Cell<TradeAssets>
    status: uint8
    // H-01: Unix time (seconds) when the trade first left OPEN — set once when settlement begins
    // (completeTrade) or a refund begins (refundAll), never updated by retries/bounces. The
    // stuck-settlement escape is time-gated against this. Initialised to 0 at deploy (a constant, so
    // the deterministic escrow address never depends on wall-clock time).
    statusChangedAt: uint32
    // M-03: Unix time of the last participant action while OPEN (TON deposit, NFT deposit, or accept).
    // 0 until the first such action. The OPEN-trade expiry escape is time-gated against this, so any
    // genuine activity pushes the deadline out and only a truly-abandoned trade can be expired.
    lastActivityAt: uint32
    // C-01/H-03: snapshot of the factory allowlist at creation time (collection → item code cell).
    // A deposit is authenticated by recomputing the sender's expected TEP-62 item address from
    // (itemCode, index, collection) carried in the transfer's forward payload and requiring a match.
    allowedCollections: map<address, cell>
}

struct TradeParticipants {
    userA: address
    userB: address
}

fun TradeEscrowStorage.load(): TradeEscrowStorage {
    return TradeEscrowStorage.fromCell(contract.getData());
}

fun TradeEscrowStorage.save(self) {
    contract.setData(self.toCell());
}

struct TradeState {
    tradeId: uint64
    factory: address
    feeRecipient: address
    userA: address
    userB: address
    acceptedA: bool
    acceptedB: bool
    depositedTonA: coins
    depositedTonB: coins
    nftCountA: uint16
    nftCountB: uint16
    pendingNftCount: uint16
    status: uint8
    statusChangedAt: uint32
    lastActivityAt: uint32
    completed: bool
    cancelled: bool
    // True when status == TRADE_STATUS_SETTLE_STUCK: settlement completed but an NFT could not be
    // delivered and was force-returned to its depositor. Lets the app flag the degraded outcome
    // without hard-coding the magic status value.
    stuck: bool
}

struct TradeAssets {
    nftA: map<address, uint8>
    nftB: map<address, uint8>
    nftCountA: uint16
    nftCountB: uint16
}

struct EscrowConfig {
    minTradeActionValue: coins
    nftTransferValue: coins
    minEscrowDeployValue: coins
    minCreateTradeValue: coins
    maxNftsPerSide: uint8
    tradeFeeBps: uint16
    stuckSettlementTimeout: uint32
    openTradeTimeout: uint32
}

struct (0x54524352) CreateTrade {
    userA: address
    userB: address
    deployValue: coins
}

struct (0x544f4e44) DepositTon {}

struct (0x41434350) AcceptTrade {}

struct (0x43414e43) CancelTrade {}

struct (0x53574550) SweepDust {}

struct (0x46535750) SweepFactoryDust {}

struct (0x41444443) AddCollection {
    collection: address
    itemCode: cell
}

struct (0x524d5643) RemoveCollection {
    collection: address
}

struct (0x544f574e) TransferOwnership {
    newOwner: address
}

struct (0x52455452) RetryPending {}

// H-01: permissionless, timeout-gated escape from a permanently-stuck SETTLING trade. Carries no
// fields — the escrow is per-trade and reads everything it needs from its own storage.
struct (0x46525356) ForceResolveStuck {}

// M-03: permissionless, timeout-gated refund of an abandoned OPEN trade. Carries no fields.
struct (0x45585052) ExpireTrade {}

struct (0x05138d91) OwnershipAssigned {
    queryId: uint64
    prevOwner: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0x5fcc3d14) NftTransfer {
    queryId: uint64
    newOwner: address
    responseDestination: address
    customPayload: bool
    forwardAmount: coins
    forwardPayload: bool
}

// TEP-62 NFT item initial state data. An item's address is the address of
// StateInit{ code: itemCode, data: NftItemInitData{ index, collection } }. The escrow recomputes
// this from the allowlisted collection's item code to authenticate a deposit's sender.
struct NftItemInitData {
    index: uint64
    collection: address
}

// S-1: shared between TradeFactory and TradeEscrow so the two copies can't drift. These are free
// functions invoked inside a contract transaction, so `contract.*` resolves to whichever contract is
// executing and `createMessage` queues from its action phase.
fun sweepableBalance(inValue: coins, minReserve: coins): coins {
    val originalBalance = contract.getOriginalBalance();
    if (originalBalance <= inValue) {
        return 0;
    }
    val balance = originalBalance - inValue;
    if (balance <= minReserve + SWEEP_FEE_BUFFER) {
        return 0;
    }
    return balance - minReserve - SWEEP_FEE_BUFFER;
}

fun sendTon(to: address, amount: coins) {
    if (amount > 0) {
        createMessage({
            bounce: BounceMode.NoBounce,
            value: amount,
            dest: to,
        }).send(SEND_MODE_PAY_FEES_SEPARATELY);
    }
}
