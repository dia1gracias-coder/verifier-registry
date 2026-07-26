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
//   v1 → initial testnet release.
//   v2 → 2026-07-20 review H-1: the MIN_NFT_FORWARD_VALUE floor no longer gates a *successful* NFT
//        deposit (only the reject/return paths). A valid deposit forwarding below the floor is now
//        recorded instead of being reverted-and-stranded — a behaviour change, hence a new version.
//   v3 → 2026-07-22 review H-1: an inbound NFT that cannot join the trade (late deposit, or an
//        authenticated-but-unrecordable one) is now recorded as a PendingReturn before its return is
//        attempted, so a bounced return is recoverable via RetryPending instead of silently stranding
//        the item. Adds the `pendingReturns` map to storage — a new deterministic escrow address.
const CONTRACT_VERSION: uint16 = 3
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
// N-2 / H-1: minimum inbound value required to fund the mode-64 *return* of a rejected or late NFT
// deposit. The return carries only the inbound value (mode 64, never escrow balance — C-03), so an
// underfunded return would revert AFTER the item already (non-bounceably) moved ownership to the
// escrow, stranding the NFT. This floor is enforced ONLY on the reject/return branches of
// OwnershipAssigned — never on a successful deposit, which sends no message and needs no value (that
// over-broad early gate was H-1: it reverted-and-stranded valid low-value deposits). The SDK always
// forwards 20 mTON (NFT_OWNERSHIP_NOTIFICATION_VALUE), comfortably above this floor.
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

// H-1: a durable record of an inbound NFT the escrow could not add to the trade (a late deposit that
// arrived after OPEN, or an authenticated deposit that could not be recorded — side full, side already
// accepted, duplicate, or a genuine item whose prevOwner is not a participant). Such an item has already
// moved ownership to the escrow non-bounceably, and its return is inbound-funded (mode 64) and can
// itself bounce. Recording (item -> depositor) BEFORE the return means a bounced return is no longer
// silently lost: `onBouncedMessage` flips it to BOUNCED and `RetryPending` re-attempts it, exactly like
// a bounced settlement transfer. Only AUTHENTICATED items are ever recorded here — a forged notification
// moved no real asset, and recording it would reopen the escrow-drain vector (C-03), so it is never
// added. `target` is the depositor (msg.prevOwner, trustworthy only once authentication has proven the
// sender is a genuine item that set it). `status` reuses the transfer lifecycle: SENT after an attempt,
// BOUNCED once a return bounces (the only state RetryPending re-sends).
struct PendingReturn {
    target: address
    status: uint8
}

// C-01/H-03: NFT item address-recompute schemas. An allowlist entry declares which item init-data
// layout its collection uses; the escrow parses the deposit's index at that width and recomputes the
// item address accordingly. The only confirmed structural difference between a standard TEP-62 item and
// a Telegram DNS-family (telemint) item is the index bit-width — both pack `index ++ collection` and
// nothing else — so a schema is essentially "how wide is the index."
//   STANDARD → NftItemInitData    { index: uint64,  collection } — reference TEP-62 items, incl. gifts.
//   DNS      → DnsNftItemInitData { index: uint256, collection } — telemint usernames / +888 numbers,
//              where index = string_hash(token_name).
// Keep STANDARD = 0 so an entry with a defaulted/zero schema field behaves exactly as before the rework.
const NFT_SCHEMA_STANDARD: uint8 = 0
const NFT_SCHEMA_DNS: uint8 = 1

// An allowlist entry pairs a collection's NFT item code with the schema needed to recompute an item's
// address from it. Snapshotted (per entry) into every escrow at CreateTrade, so its layout is part of the
// escrow's deterministic address.
struct CollectionEntry {
    schema: uint8
    itemCode: cell
}

struct TradeFactoryStorage {
    owner: address
    nextTradeId: uint64
    escrowCode: cell
    // C-01/H-03: allowlist of tradable NFT collections → that collection's (schema, item code).
    // An escrow authenticates a deposit by recomputing the sender's expected item address from
    // (itemCode, schema-dictated index width, collection) and requiring it to match; only genuine items
    // of an allowlisted collection pass. Snapshotted into each escrow at CreateTrade.
    allowedCollections: map<address, CollectionEntry>
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
    // C-01/H-03: snapshot of the factory allowlist at creation time (collection → (schema, item code)).
    // A deposit is authenticated by recomputing the sender's expected item address from
    // (itemCode, schema-dictated index width, collection) carried in the transfer's forward payload and
    // requiring a match.
    allowedCollections: map<address, CollectionEntry>
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
    // H-1: number of recorded pending returns (items held by the escrow that could not join the trade
    // and are awaiting return to their depositor). Non-zero means RetryPending still has work to do,
    // independent of trade status. Distinct from `pendingNftCount`, which counts only tradable side NFTs.
    pendingReturnCount: uint16
}

struct TradeAssets {
    nftA: map<address, uint8>
    nftB: map<address, uint8>
    nftCountA: uint16
    nftCountB: uint16
    // H-1: items the escrow holds but could not add to either side, recorded so a bounced return stays
    // recoverable via RetryPending. Kept OUT of nftA/nftB (which drive settlement direction) and out of
    // `pendingNftCount` (the settlement-reserve driver, which must only count tradable side assets).
    pendingReturns: map<address, PendingReturn>
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
    // Item address-recompute schema for this collection (NFT_SCHEMA_STANDARD / NFT_SCHEMA_DNS). Standard
    // callers pass NFT_SCHEMA_STANDARD (0), which reproduces pre-rework behaviour.
    schema: uint8
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
// Used by NFT_SCHEMA_STANDARD (reference TEP-62 items, incl. Telegram gifts).
struct NftItemInitData {
    index: uint64
    collection: address
}

// Telegram DNS-family (telemint) NFT item initial state data. Byte-identical to NftItemInitData except
// the index is the 256-bit `string_hash(token_name)` rather than a 64-bit serial (confirmed against
// TelegramMessenger/telemint + ton-blockchain/dns-contract: packed data is exactly
// `store_uint(index, 256) ++ store_slice(collection)` and nothing else). Used by NFT_SCHEMA_DNS
// (usernames, +888 anonymous numbers). See docs/contracts/nft-support-rework.md.
struct DnsNftItemInitData {
    index: uint256
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
