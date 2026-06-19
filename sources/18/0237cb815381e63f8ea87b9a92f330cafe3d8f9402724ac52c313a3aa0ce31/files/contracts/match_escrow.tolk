const MAX_RAKE_BPS        = 1000
const SHOWDOWN_ROUNDS     = 5
const SHOWDOWN_BUDGET     = 50
const TIMEOUT_SECONDS     = 3600
const MIN_STAKE_NANOTON   = 100000000      // 0.1 TON
const MAX_STAKE_NANOTON   = 100000000000   // 100 TON

const OP_JOIN             = 0x5c53b6a7
const OP_PLAYER_REVEAL    = 0xa1b2c3d4    // HIGH-2: replaces OP_SUBMIT_RESULT
const OP_CANCEL           = 0x3b2c1d0e
const OP_TIMEOUT_REFUND   = 0x9f8e7d6c
const OP_SET_RAKE         = 0x1a2b3c4d

const STATUS_OPEN         = 0
const STATUS_LOCKED       = 1
const STATUS_RESOLVED     = 2
const STATUS_REFUNDED     = 3

// winner encoding: 0=unresolved, 1=p1 wins, 2=p2 wins, 3=tie
const TIE_RESULT          = 3

const ERR_WRONG_STATUS    = 128
const ERR_WRONG_SENDER    = 129
const ERR_WRONG_STAKE     = 130
const ERR_ALREADY_JOINED  = 131
const ERR_INVALID_COMMIT  = 132
const ERR_INVALID_BID     = 133
const ERR_WRONG_RAKE      = 134

// ── structs ───────────────────────────────────────────────────────────────────

// Stored as a separate cell to keep PlayersData under 1023 bits.
struct Player2Data {
    player2:     address?
    commitRoot2: uint256
}

// Bit budget: player1(267) + commitRoot1(256) = 523 bits + 1 ref — safe.
struct PlayersData {
    player1:     address?
    commitRoot1: uint256
    p2Data:      Cell<Player2Data>
}

// HIGH-2: per-player reveal state. 8+8+64+64 = 144 bits — safe.
// bids packed as 5×8-bit values (bids are 0..50, fit in 6 bits each).
struct RevealData {
    p1Revealed: uint8
    p2Revealed: uint8
    p1BidsPack: uint64
    p2BidsPack: uint64
}

// Bit budget: owner(267)+stake(~124)+rakeBps(16)+status(8)+createdAt(32)+
//             transcriptRoot(256)+winner(8)+prizePack(64) = ~775 bits + 2 refs — safe.
struct Storage {
    owner:          address
    stake:          coins
    rakeBps:        uint16
    status:         uint8
    createdAt:      uint32
    transcriptRoot: uint256
    winner:         uint8
    prizePack:      uint64
    players:        Cell<PlayersData>
    reveals:        Cell<RevealData>
}

fun loadStorage(): Storage {
    return Storage.fromCell(contract.getData());
}

fun saveStorage(st: Storage): void {
    contract.setData(st.toCell());
}

fun sendTons(dest: address, amount: int): void {
    createMessage({
        bounce: BounceMode.NoBounce,
        value: amount as coins,
        dest: dest,
    }).send(SEND_MODE_REGULAR);
}

// Pack 5 prizes into a uint64: prize[0] in bits 39..32, ..., prize[4] in bits 7..0
fun packPrizes(p0: int, p1: int, p2: int, p3: int, p4: int): int {
    return (p0 << 32) | (p1 << 24) | (p2 << 16) | (p3 << 8) | p4;
}

// Extract prize for round r (0-indexed)
fun getPrize(prizePack: int, round: int): int {
    return (prizePack >> ((4 - round) * 8)) & 0xFF;
}

// Returns 1 (p1 wins), 2 (p2 wins), or TIE_RESULT=3.
fun scoreShowdown(p1Bids: array<int>, p2Bids: array<int>, prizePack: int): int {
    var score1 = 0;
    var score2 = 0;
    var carry  = 0;
    var i = 0;
    while (i < SHOWDOWN_ROUNDS) {
        val prize = getPrize(prizePack, i) + carry;
        val bid1  = p1Bids.get(i);
        val bid2  = p2Bids.get(i);
        if (bid1 > bid2) {
            score1 = score1 + prize;
            carry = 0;
        } else if (bid2 > bid1) {
            score2 = score2 + prize;
            carry = 0;
        } else {
            if (i == SHOWDOWN_ROUNDS - 1) {
                carry = 0;
            } else {
                carry = prize;
            }
        }
        i = i + 1;
    }
    if (score1 > score2) { return 1; }
    if (score2 > score1) { return 2; }
    return TIE_RESULT;
}

// Iterative commit chain root: root_n = sha256(root_{n-1} XOR commit_n), root_0 = 0.
// Each step fits in one cell (256 bits). Byte-identical to the TS computeCommitRoot helper.
fun computeCommitRoot(commits: array<int>): int {
    var root = 0;
    var i = 0;
    while (i < SHOWDOWN_ROUNDS) {
        val xored = root ^ commits.get(i);
        root = beginCell()
            .storeUint(xored, 256)
            .endCell()
            .beginParse()
            .bitsHash();
        i = i + 1;
    }
    return root;
}

// Called when both players have revealed. Unpacks bids, scores, pays out.
// MED-1: transcriptRoot computed from on-chain commitRoots — never accepted from submitter.
fun doFinalizeResult(
    st: Storage,
    reveals: RevealData,
    p1: address, p2: address,
    p1CommitRoot: int, p2CommitRoot: int
): void {
    var p1Bids: array<int> = [];
    var p2Bids: array<int> = [];
    val p1Pack = reveals.p1BidsPack as int;
    val p2Pack = reveals.p2BidsPack as int;
    var i = 0;
    while (i < SHOWDOWN_ROUNDS) {
        val shift = (4 - i) * 8;
        p1Bids.push((p1Pack >> shift) & 0xFF);
        p2Bids.push((p2Pack >> shift) & 0xFF);
        i = i + 1;
    }

    val winner = scoreShowdown(p1Bids, p2Bids, st.prizePack as int);
    val pool   = st.stake * 2;
    val rake   = mulDivFloor(pool, st.rakeBps as int, 10000);
    val payout = pool - rake;

    if (winner == 1) {
        sendTons(p1, payout);
        if (rake > 0) { sendTons(st.owner, rake); }
    } else if (winner == 2) {
        sendTons(p2, payout);
        if (rake > 0) { sendTons(st.owner, rake); }
    } else {
        sendTons(p1, st.stake as int);
        sendTons(p2, st.stake as int);
    }

    // MED-1 fix: transcriptRoot = sha256(p1CommitRoot XOR p2CommitRoot)
    // Computed entirely from on-chain data; no submitter input accepted.
    val combined = p1CommitRoot ^ p2CommitRoot;
    st.transcriptRoot = beginCell()
        .storeUint(combined, 256)
        .endCell()
        .beginParse()
        .bitsHash();

    st.winner  = winner;
    st.status  = STATUS_RESOLVED;
    saveStorage(st);
}

// ── handlers ─────────────────────────────────────────────────────────────────

// Join body: op(32) + commitRoot(256)
// commitRoot = iterative_hash(sha256(c0..c4)) anchored on-chain before seeing opponent bids.
fun handleJoin(sender: address, value: coins, body: slice): void {
    var st = loadStorage();
    if (st.rakeBps > MAX_RAKE_BPS)         { throw ERR_WRONG_RAKE; }    // HIGH-1 fix
    if (st.status != STATUS_OPEN)          { throw ERR_WRONG_STATUS; }
    if (value < st.stake)                  { throw ERR_WRONG_STAKE; }
    if (st.stake < MIN_STAKE_NANOTON)      { throw ERR_WRONG_STAKE; }
    if (st.stake > MAX_STAKE_NANOTON)      { throw ERR_WRONG_STAKE; }

    var cs = body;
    cs.skipBits(32);
    val commitRoot = cs.loadUint(256);

    var players = st.players.load();

    if (players.player1 == null) {
        players.player1 = sender;
        players.commitRoot1 = commitRoot;
        st.createdAt = blockchain.now();  // timeout begins at first join
    } else {
        if (players.player1! == sender) { throw ERR_ALREADY_JOINED; }
        var p2data = players.p2Data.load();
        if (p2data.player2 != null)    { throw ERR_WRONG_STATUS; }
        p2data.player2 = sender;
        p2data.commitRoot2 = commitRoot;
        players.p2Data = p2data.toCell();
        st.status = STATUS_LOCKED;
    }

    st.players = players.toCell();
    saveStorage(st);
}

fun handleSetRake(sender: address, body: slice): void {
    var st = loadStorage();
    if (sender != st.owner)       { throw ERR_WRONG_SENDER; }
    if (st.status != STATUS_OPEN)  { throw ERR_WRONG_STATUS; }
    var cs = body;
    cs.skipBits(32);
    val newRakeBps = cs.loadUint(16);
    if (newRakeBps > MAX_RAKE_BPS) { throw ERR_WRONG_RAKE; }
    st.rakeBps = newRakeBps;
    saveStorage(st);
}

fun handleCancel(sender: address): void {
    var st = loadStorage();
    if (sender != st.owner)       { throw ERR_WRONG_SENDER; }
    if (st.status != STATUS_OPEN)  { throw ERR_WRONG_STATUS; }
    val players = st.players.load();
    if (players.player1 != null) {
        sendTons(players.player1!, st.stake as int);
    }
    st.status = STATUS_REFUNDED;
    saveStorage(st);
}

fun handleTimeoutRefund(sender: address): void {
    var st = loadStorage();
    val players = st.players.load();

    // H1 fix: player1 can self-refund if no second player joins within timeout
    if (st.status == STATUS_OPEN) {
        if (players.player1 == null)      { throw ERR_WRONG_STATUS; }
        if (players.player1! != sender)   { throw ERR_WRONG_SENDER; }
        if (blockchain.now() < st.createdAt + TIMEOUT_SECONDS) { throw ERR_WRONG_STATUS; }
        sendTons(players.player1!, st.stake as int);
        st.status = STATUS_REFUNDED;
        saveStorage(st);
        return;
    }

    if (st.status != STATUS_LOCKED) { throw ERR_WRONG_STATUS; }
    if (blockchain.now() < st.createdAt + TIMEOUT_SECONDS) { throw ERR_WRONG_STATUS; }

    val p2data = players.p2Data.load();
    val p1 = players.player1!;
    val p2 = p2data.player2!;
    val reveals = st.reveals.load();

    val pool   = st.stake * 2;
    val rake   = mulDivFloor(pool, st.rakeBps as int, 10000);
    val payout = pool - rake;

    // Compute transcriptRoot from on-chain data (MED-1 pattern, consistent)
    val combined = (players.commitRoot1 as int) ^ (p2data.commitRoot2 as int);
    st.transcriptRoot = beginCell()
        .storeUint(combined, 256)
        .endCell()
        .beginParse()
        .bitsHash();

    if (reveals.p1Revealed == 1 && reveals.p2Revealed == 0) {
        // HIGH-2 forfeit: P1 revealed, P2 griefed → P1 wins
        sendTons(p1, payout);
        if (rake > 0) { sendTons(st.owner, rake); }
        st.winner = 1;
        st.status = STATUS_RESOLVED;
    } else if (reveals.p2Revealed == 1 && reveals.p1Revealed == 0) {
        // HIGH-2 forfeit: P2 revealed, P1 griefed → P2 wins
        sendTons(p2, payout);
        if (rake > 0) { sendTons(st.owner, rake); }
        st.winner = 2;
        st.status = STATUS_RESOLVED;
    } else {
        // Neither revealed — MED-2 fix: only p1/p2/owner may trigger refund
        if (sender != p1 && sender != p2 && sender != st.owner) { throw ERR_WRONG_SENDER; }
        sendTons(p1, st.stake as int);
        sendTons(p2, st.stake as int);
        st.winner = TIE_RESULT;
        st.status = STATUS_REFUNDED;
    }

    saveStorage(st);
}

// OP_PLAYER_REVEAL: each player reveals their OWN 5 entries independently.
// Body: op(32) + ref → 5 entry cells for this player only.
// Entry: playerIdx(8)+round(8)+bid(32)+salt(256)+commit(256) [+ref to next]
// After both players reveal, winner is computed and funds paid automatically.
fun handlePlayerReveal(sender: address, body: slice): void {
    var st = loadStorage();
    if (st.status == STATUS_RESOLVED) { return; }   // idempotent
    if (st.status != STATUS_LOCKED)   { throw ERR_WRONG_STATUS; }

    val players = st.players.load();
    val p1 = players.player1!;
    val p2data = players.p2Data.load();
    val p2 = p2data.player2!;

    if (sender != p1 && sender != p2) { throw ERR_WRONG_SENDER; }

    val isP1 = sender == p1;
    val expectedPlayerIdx = isP1 ? 0 : 1;
    val storedCommitRoot = isP1 ? (players.commitRoot1 as int) : (p2data.commitRoot2 as int);

    var reveals = st.reveals.load();

    // Idempotent: already revealed
    if (isP1 && reveals.p1Revealed == 1) { return; }
    if (!isP1 && reveals.p2Revealed == 1) { return; }

    var cs = body;
    cs.skipBits(32);
    var entryCell: cell? = cs.loadRef();

    var bids:    array<int> = [];
    var commits: array<int> = [];
    var expectedRound = 0;
    var count = 0;

    while (count < SHOWDOWN_ROUNDS) {
        if (entryCell == null) { throw 9; }
        var entry = entryCell!.beginParse();

        val playerIdx = entry.loadUint(8);
        val round     = entry.loadUint(8);
        val bid       = entry.loadUint(32);
        val salt      = entry.loadUint(256);
        val commit    = entry.loadUint(256);

        if (round != expectedRound)         { throw ERR_INVALID_COMMIT; }
        if (playerIdx != expectedPlayerIdx) { throw ERR_INVALID_COMMIT; }

        // per-entry: sha256(bid_32BE ‖ salt_256) — byte-identical to TS serializeBidSalt
        val computedCommit = beginCell()
            .storeUint(bid, 32)
            .storeUint(salt, 256)
            .endCell()
            .beginParse()
            .bitsHash();

        if (computedCommit != commit) { throw ERR_INVALID_COMMIT; }
        if (bid > SHOWDOWN_BUDGET)    { throw ERR_INVALID_BID; }

        bids.push(bid);
        commits.push(commit);
        expectedRound = expectedRound + 1;

        if (entry.remainingRefsCount() > 0) {
            entryCell = entry.loadRef();
        } else {
            entryCell = null;
        }
        count = count + 1;
    }

    // C1 fix: revealed commits must match the root anchored on-chain at join time
    val computedRoot = computeCommitRoot(commits);
    if (computedRoot != storedCommitRoot) { throw ERR_INVALID_COMMIT; }

    // Pack bids as 5×8-bit (bids 0..50 fit in 8 bits)
    var bidsPack = 0;
    var i = 0;
    while (i < SHOWDOWN_ROUNDS) {
        bidsPack = bidsPack | (bids.get(i) << ((4 - i) * 8));
        i = i + 1;
    }

    if (isP1) {
        reveals.p1Revealed = 1;
        reveals.p1BidsPack = bidsPack;
    } else {
        reveals.p2Revealed = 1;
        reveals.p2BidsPack = bidsPack;
    }

    st.reveals = reveals.toCell();

    if (reveals.p1Revealed == 1 && reveals.p2Revealed == 1) {
        doFinalizeResult(st, reveals, p1, p2,
            players.commitRoot1 as int, p2data.commitRoot2 as int);
    } else {
        saveStorage(st);
    }
}

// ── getters ───────────────────────────────────────────────────────────────────

get fun get_status(): int {
    return loadStorage().status;
}

get fun get_rake_bps(): int {
    return loadStorage().rakeBps;
}

get fun get_winner(): int {
    return loadStorage().winner;
}

get fun get_transcript_root(): int {
    return loadStorage().transcriptRoot;
}

get fun get_prize_pack(): int {
    return loadStorage().prizePack;
}

// ── entry point ───────────────────────────────────────────────────────────────

fun onInternalMessage(in: InMessage) {
    val sender = in.senderAddress;
    val value  = in.valueCoins;
    val body   = in.body;
    if (body.remainingBitsCount() < 32) { return; }
    val op = body.preloadUint(32);
    if      (op == OP_JOIN)           { handleJoin(sender, value, body); }
    else if (op == OP_PLAYER_REVEAL)  { handlePlayerReveal(sender, body); }
    else if (op == OP_CANCEL)         { handleCancel(sender); }
    else if (op == OP_TIMEOUT_REFUND) { handleTimeoutRefund(sender); }
    else if (op == OP_SET_RAKE)       { handleSetRake(sender, body); }
}
