// OpenRaff v1 — shared types, storage layout, errors and helpers.
//
// See docs/versions/v1/{specification,messages}.md for the design of record.
// v1 implements the native-TON payment path; the jetton path is the next
// increment and is intentionally left out here (storage/handlers are shaped so
// it can be added without reshuffling the core).

// ---------------------------------------------------------------------------
// Lifecycle status (stored as uint8). See specification §6.
// ---------------------------------------------------------------------------
const STATUS_SCHEDULED = 0
const STATUS_ACTIVE = 1
const STATUS_SALES_CLOSED = 2
const STATUS_DRAWING = 3
const STATUS_DRAWN = 4
const STATUS_COMPLETED = 5
const STATUS_REFUNDING = 6
// Terminal-settlement retry state: the protocol fee has been paid to the
// treasury, but the organizer payout bounced and is awaiting a `Settle` retry.
// See Raffle.onBouncedMessage.
const STATUS_SETTLING = 7

// Max winners a single `draw` call resolves before yielding; the draw resumes
// across further calls via `drawCounter`. Sampling is without replacement (see
// Raffle.handleDraw), so each call does exactly this many sha256 samples — gas
// per transaction is bounded regardless of K vs N. Calibrated in
// tests/gas.test.tolk: a full batch of 48 winners costs ~444k gas — comfortably
// under the 1,000,000 basechain limit. A draw call should attach ~1 TON to
// cover gas plus up to 48 winner-event actions.
const DRAW_BATCH = 48

// Small ton buffer the raffle keeps for storage rent / outgoing gas.
const GAS_RESERVE = 20000000 // 0.02 TON

// TON attached to a single TEP-74 jetton `transfer` to fund the two-hop wallet
// chain; the unused remainder returns to the recipient via `excesses`. Paid out
// of the value of the message that triggered the transfer (buy/refund/settle).
const JETTON_SEND_GAS = 50000000 // 0.05 TON

// TON for the TEP-89 provide/take wallet-discovery handshake.
const WALLET_DISCOVERY_GAS = 30000000 // 0.03 TON

// ---------------------------------------------------------------------------
// Error / exit codes. See messages.md §7.
// ---------------------------------------------------------------------------
enum Errors {
    WrongStatus = 0x101
    NotOrganizer = 0x102
    SaleNotOpen = 0x103
    SaleEnded = 0x104
    SoldOut = 0x105
    InsufficientValue = 0x106
    UnauthorizedPublisher = 0x107
    WrongRound = 0x108
    BadSignature = 0x109
    DrawTimeout = 0x10A
    NothingToRefund = 0x10B
    NotJettonWallet = 0x10C
    InvalidConfig = 0x10D
    NotOwner = 0x10E
    InvalidMessage = 0xFFFF
}

// ---------------------------------------------------------------------------
// Domain types.
// ---------------------------------------------------------------------------

// A prize is off-chain metadata (an obligation of the organizer), never an
// on-chain asset. `title` and `metadata` are refs (URI + hash / inline).
struct Prize {
    title: cell
    metadata: cell
}

// DRAND network parameters. `publicKey` (BLS) is stored for off-chain / future
// on-chain verification; the contract itself does not verify BLS in v1.
struct Beacon {
    chainHash: uint256
    genesisTime: uint32
    period: uint32
    publicKey: cell
}

// Immutable, organizer-provided configuration of a raffle.
struct RaffleConfig {
    organizer: address
    ticketPrice: coins
    softCap: coins
    hardCap: coins
    saleStart: uint32
    saleDeadline: uint32
    metadata: cell
    beacon: Cell<Beacon>
    prizes: map<uint32, Prize>
    // Payment asset: null => native TON; set => the jetton master this raffle is
    // priced in (one asset per raffle; participants swap in the UI if needed).
    paymentJetton: address?
}

// Ledger entry: a single purchase covering tickets [startIndex .. startIndex+count).
struct LedgerEntry {
    count: uint32
    buyer: address
}

// Per-participant aggregate, keyed by sha256(address) — for refunds.
struct Participant {
    tickets: uint32
    contributed: coins
    refundClaimed: bool
}

// A resolved winner: prize `rank` goes to the owner of `ticketIndex`.
struct Winner {
    ticketIndex: uint32
    owner: address
}

// ---------------------------------------------------------------------------
// Raffle storage (root cell = status + 3 refs). See messages.md §5.1.
// ---------------------------------------------------------------------------

// Immutable bundle. `protocolFeeBps`/`drawTimeout`/`treasury` are protocol
// parameters stamped by the factory; the organizer does not set them.
struct RaffleMeta {
    raffleId: uint64
    factory: address
    protocolFeeBps: uint16
    drawTimeout: uint32
    treasury: address
    config: Cell<RaffleConfig>
    // ed25519 publisher allowlist; the organizer's key is added by the factory.
    publishers: map<uint256, uint8>
    // Number of prizes K, counted by the factory once at creation.
    prizeCount: uint32
}

// Mutable scalar state.
struct RaffleRuntime {
    totalCollected: coins
    ticketsSold: uint32
    salesClosedAt: uint32
    targetRound: uint64
    randomness: uint256
    drandSignature: cell?
    drawCounter: uint64 // draw sample cursor, persists across draw batches
    winnersDrawn: uint32
    // The raffle's own jetton wallet for `config.paymentJetton`, discovered
    // post-deploy via TEP-89. Null until discovered / in native mode.
    jettonWallet: address?
}

// The four dictionaries, grouped so the root stays within 4 refs.
struct RaffleMaps {
    ledgerByIndex: map<uint32, LedgerEntry> // startIndex -> (count, buyer)
    participants: map<uint256, Participant> // sha256(addr) -> aggregate
    winners: map<uint32, Winner>            // rank -> winner
    // Sparse Fisher-Yates state for sampling winners WITHOUT replacement:
    // position -> ticket index that currently lives there. Absent key => identity
    // (position p holds ticket p). See Raffle.handleDraw and specification §7.5.
    drawSwap: map<uint32, uint32>
}

struct RaffleStorage {
    status: uint8
    meta: Cell<RaffleMeta>
    runtime: Cell<RaffleRuntime>
    maps: Cell<RaffleMaps>
}

fun RaffleStorage.load(): RaffleStorage {
    return RaffleStorage.fromCell(contract.getData());
}

fun RaffleStorage.save(self) {
    contract.setData(self.toCell());
}

// ---------------------------------------------------------------------------
// Factory storage. See messages.md §4.1.
// ---------------------------------------------------------------------------
struct FactoryStorage {
    owner: address         // v1: protocol admin; future: DAO address
    protocolFeeBps: uint16 // v1: 30 (0.3%)
    drawTimeout: uint32    // v1: 259200 (72h)
    treasury: address
    raffleCount: uint64    // source of raffle_id
}

fun FactoryStorage.load(): FactoryStorage {
    return FactoryStorage.fromCell(contract.getData());
}

fun FactoryStorage.save(self) {
    contract.setData(self.toCell());
}

// ---------------------------------------------------------------------------
// Fairness helpers. See specification §7.5.
// ---------------------------------------------------------------------------

// Deterministic draw index for a given counter, uniform in [0, n):
//   idx = sha256(randomness ‖ le64(counter)) mod n
// In handleDraw `n` is the shrinking pool size `remaining` (sampling without
// replacement), so this yields the position to pick, never a rejected sample.
fun computeDrawIndex(randomness: uint256, counter: uint64, n: int): int {
    val h = beginCell()
        .storeUint(randomness, 256)
        .storeUint(counter, 64)
        .endCell()
        .beginParse()
        .bitsHash();
    return h % n;
}

// Authorization preimage signed by a publisher (ed25519):
//   auth = (raffleId ‖ targetRound ‖ randomness)
// The signer signs sha256(auth); CHKSIGNS verifies against that.
fun buildAuthSlice(raffleId: uint64, targetRound: uint64, randomness: uint256): slice {
    return beginCell()
        .storeUint(raffleId, 64)
        .storeUint(targetRound, 64)
        .storeUint(randomness, 256)
        .endCell()
        .beginParse();
}

// Counts prize entries in the config (K). Done once by the factory at creation.
fun countPrizes(prizes: map<uint32, Prize>): int {
    var cnt = 0;
    var e = prizes.findFirst();
    while (e.isFound) {
        cnt += 1;
        e = prizes.iterateNext(e);
    }
    return cnt;
}

// DRAND target round fixed at sales close. See specification §7.2.
//   round_at(t)  = floor((t - genesis) / period) + 1
//   target_round = round_at(t) + 1   (first round strictly after t)
fun computeTargetRound(closedAt: int, genesisTime: int, period: int): int {
    val roundAt = (closedAt - genesisTime) / period + 1;
    return roundAt + 1;
}

// An empty TEP-74 `forward_payload` (Either Cell ^Cell): a single 0 bit selects
// the inline variant with no data. Used when we forward jettons without a note.
fun emptyForwardPayload(): slice {
    return beginCell().storeUint(0, 1).endCell().beginParse();
}

// Emits an opcode-tagged event as an external-out log message (dest = addr_none):
// no value, cannot change state, visible to indexers/UI. IGNORE_ERRORS so a
// failed log action never reverts the real state transition. See messages.md §5.10.
fun emitEvent<T>(body: T) {
    val ev = createExternalLogMessage({ dest: createAddressNone(), body });
    ev.send(SEND_MODE_IGNORE_ERRORS);
}
