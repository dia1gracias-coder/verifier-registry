import "types"

/// Winner-takes-all prize pool on a PURE ROLLING WINDOW.
///
/// The rule in one sentence: **bid more than the current leader and you are the leader; every
/// accepted bid restarts the clock at `extensionWindow` seconds; the round ends when that long
/// passes with no accepted bid, and the last leader takes the pool.**
///
/// There is NO scheduled prize date. The `deadline` in the state init is the OPENING WINDOW only —
/// how long an empty pool waits for its VERY FIRST bid before it closes with no leader — and every
/// accepted bid overwrites it with `now() + extensionWindow`. So a round can end minutes after it
/// opens if exactly one person bids, and a funded pair can hold the clock for as long as they keep
/// bidding: the entry price does not rise on its own. What a hold costs is not an increment but
/// the WHOLE bid — every accepted bid is added to the pool in full — plus the protocol fee out of
/// the final payout, which is the only economic brake; at `feeBps = 0` there is none beyond the
/// bid itself and gas.
contract PrizePool {
    author: "Acton User"
    version: "1.1.0"
    description: "Winner-takes-all prize pool on a rolling window: bid more than the current leader and you are the leader, every accepted bid restarts the clock at extensionWindow seconds; the round ends when that long passes with no bid, and the last leader takes the pool"
    storage: Storage
    incomingMessages: AllowedMessage
}

/// `PrizePaid` and `FeePaid` are outgoing only, so they are deliberately not part of this union.
type AllowedMessage = PlaceBid | ClaimPrize

/// Validates a bid and, on success, records the new leader, accrues the protocol fee and
/// EXTENDS THE DEADLINE. `InMessage` may not be passed around as an object, so the two fields we
/// need are passed explicitly. `bidValue` is `in.valueCoins`, i.e. the amount actually credited
/// to this account after forward fees — the contract can never record more than it got.
fun registerBid(bidder: address, bidValue: coins) {
    var storage = lazy Storage.load();

    // Order matters: it makes every rejection map to exactly one exit code. The three original
    // checks keep their original order, so every pre-fee rejection keeps its original code, and
    // every check added since is appended BELOW them for the same reason.
    assert (blockchain.now() < storage.deadline) throw Errors.DeadlinePassed;
    // The settled-round latch, and the FIRST reason the extension can never reopen a paid-out
    // pool. It is checked AFTER the deadline, not before, so that the ordinary post-payout bid
    // keeps answering `DeadlinePassed` (101) exactly as it did before this rule existed: a pool
    // that settled honestly has `now() >= deadline` by construction (`payOutPrize` requires it),
    // so 101 is the code it has always produced and still produces. What this line adds is the
    // one shape the deadline check cannot catch — a hand-built state init with `paidOut: true`
    // AND a deadline still in the future. Without it such a pool would accept bids, extend its
    // clock forever and strand every one of them, because `payOutPrize` can never run again.
    assert (!storage.paidOut) throw Errors.AlreadyPaidOut;
    // THE WINNING RULE, and the only comparison against `bestBid`: strictly greater. One nanoton
    // over the leader is a legal bid, and it costs its full value like any other — `poolAmount`
    // grows by the whole bid below, so there is no cheap way to move the clock at any step size.
    assert (bidValue > storage.bestBid) throw Errors.BidTooLow;
    // `MIN_BID` is a FLOOR, not a raise rule: it gates the FIRST bid of a round (where `bestBid`
    // is 0, so the assert above is satisfied by a single nanoton) and it keeps dust out — below
    // the network's bounce floor a rejected bid is swallowed instead of returned. Against a
    // non-zero `bestBid` it can never be the binding rule: the leader had to clear it too.
    assert (bidValue >= MIN_BID) throw Errors.BidBelowMinimum;
    // The fee ceiling is checked HERE, on the only path that can ever make `feeBps` earn
    // anything, so that no bidder can ever put a nanoton into an over-fee pool. There is no
    // constructor to guard — `Storage` is whatever the deployer put in the state init — so
    // `payOutPrize` re-checks it as well: a pool whose state init ALSO bakes in a `leader` would
    // otherwise skip this path entirely and pay an over-ceiling fee out of top-ups.
    assert (storage.feeBps <= MAX_FEE_BPS) throw Errors.FeeTooHigh;
    // Same reasoning for the destination: `feeRecipient` is frozen into the state init, and only
    // workchains 0 and -1 exist. A message to any other workchain is not a message TON can route
    // — the ACTION phase aborts with the raw TVM code 36 and, unlike a compute-phase throw,
    // swallows the claimer's value instead of bouncing it. Refusing the BID keeps such a pool
    // empty in the first place, so nobody's coins are ever trapped behind an unroutable fee.
    assert (storage.feeRecipient.isDeliverable()) throw Errors.FeeRecipientUnreachable;
    // And the same reasoning once more for the anti-snipe window, which this function is about to
    // write into the deadline. `extensionWindow` comes out of a state init nobody validated: 0
    // would end the round on its first bid (a deadline of `now()`), and an enormous value would
    // let one bid hold every bidder's funds for years. Both bounds are therefore enforced where
    // the value is USED, so a pool outside them cannot take a single nanoton and no bidder can be
    // trapped in one. It is the LAST check on purpose: every rejection that existed before this
    // feature still reaches its own assert first and keeps its own code.
    assert (
        storage.extensionWindow >= MIN_EXTENSION_WINDOW &&
        storage.extensionWindow <= MAX_EXTENSION_WINDOW
    ) throw Errors.ExtensionWindowOutOfRange;

    storage.leader = bidder;
    storage.bestBid = bidValue;
    storage.poolAmount += bidValue;
    // The comparison above stayed on the GROSS value, and so does the accounting: `bestBid` and
    // `poolAmount` mean exactly what they always did. The fee is only ACCRUED — no message is
    // produced on this hot path. Integer division rounds DOWN, and the remainder is deliberately
    // not tracked: it stays in the pool and leaves with the prize.
    storage.feeAccrued += bidValue * storage.feeBps / BPS_DENOMINATOR;
    // THE ANTI-SNIPE RULE, and the whole point of this revision. Under a hard deadline, bidding
    // early is strictly dominated — you get outbid and lose the round anyway — so the equilibrium
    // is "everybody waits, one sniper bids in the last block", the pool never accumulates and
    // 10 -> 20 -> 30 never happens. Resetting the clock on every ACCEPTED bid removes the last
    // block as a strategy: whoever is beaten always has `extensionWindow` seconds to answer, so
    // bidding early is safe and the pool can actually grow.
    //
    // It is an ASSIGNMENT, not a `max(deadline, ...)`: the round always ends exactly
    // `extensionWindow` after the last accepted bid, whether that bid arrived one second or one
    // month before the initial deadline. A bid FAR from the deadline therefore pulls the end IN,
    // which is the same promise read forwards — "the round ends when it goes quiet". The initial
    // deadline is only the OPENING WINDOW: what a round NOBODY has bid on expires at. There is no
    // scheduled prize date anywhere in this contract.
    //
    // It is reached only by an ACCEPTED bid: every rejection above threw before this line, so a
    // bid that does not beat the leader, is below `MIN_BID` or is late cannot move the clock by a
    // second. Stalling with junk bids is therefore not free — it is impossible. Moving it with a
    // REAL bid is not free either: `poolAmount += bidValue` above adds the whole bid, not the
    // increment, so one more window always costs one more full bid.
    //
    // `now() + extensionWindow` must fit the `uint32` field: with `MAX_EXTENSION_WINDOW` the last
    // moment that is true is 4294880895 (2106-02-06), i.e. one day short of what a `uint32`
    // deadline can express anyway.
    storage.deadline = blockchain.now() + storage.extensionWindow;
    storage.save();
}

/// Pays the accrued fee to the STORED fee recipient and the rest of the balance (minus the
/// storage reserve) to the STORED leader. Anyone may trigger it; the money never follows the
/// sender.
fun payOutPrize(queryId: uint64) {
    var storage = lazy Storage.load();

    assert (blockchain.now() >= storage.deadline) throw Errors.DeadlineNotReached;
    assert (!storage.paidOut) throw Errors.AlreadyPaidOut;
    val winner = storage.leader;
    assert (winner != null) throw Errors.NoBids;
    // The bid path is NOT the only way a `leader` can come to exist: a state init may bake one
    // in, and then `registerBid` — where the storage-level ceilings live — is never executed at
    // all. Both of them are therefore re-checked here, so that no hand-built state init can buy
    // itself a payout the bid path would have refused. `MAX_FEE_BPS` first: an over-fee pool is
    // dead on BOTH paths, which is exactly what makes the ceiling unbypassable.
    assert (storage.feeBps <= MAX_FEE_BPS) throw Errors.FeeTooHigh;
    // Only workchains 0 (basechain) and -1 (masterchain) exist. A message to any other one is
    // not routable: the ACTION phase aborts with the raw TVM code 36 and, unlike a compute-phase
    // throw, that does NOT bounce — the claimer's attached value is swallowed, `paidOut` stays
    // false and the next claimer walks into the same trap. A named refusal bounces instead, and
    // no amount of attached value could ever have made an unroutable address deliverable.
    assert (winner.isDeliverable()) throw Errors.LeaderUnreachable;

    // Both payout messages have to be able to leave. `SEND_MODE_CARRY_ALL_BALANCE` after the
    // reserve and after the fee carries `balance - STORAGE_RESERVE - fee - feeForwardFee`,
    // so a balance that does not exceed `STORAGE_RESERVE + fee` by at least the required
    // headroom would produce a message that cannot pay its own forward fee: the ACTION phase
    // would abort with the nameless TVM code 37 and, worse, swallow the claimer's coins instead
    // of bouncing them. Failing here instead keeps the transaction a clean compute-phase
    // rejection: nothing is committed, the claim bounces back, and the prize stays claimable.
    // `contract.getOriginalBalance()` already includes what this claim attached, so attaching the
    // missing amount is exactly how a rent-starved or under-deployed pool is settled.
    //
    // The payable fee is `feeAccrued` CLAMPED to what `feeBps` could honestly have accrued on
    // `poolAmount`. `Storage` is chosen by whoever builds the state init, so `feeAccrued` is an
    // untrusted number: a pool could be published with `feeBps = 1` and 9.9 TON already
    // "accrued", and paying that out would be a ~99% fee on a pool whose `feeBps()` get-method
    // advertises 0.01%. The clamp is exact, not conservative: `registerBid` adds
    // `floor(v * feeBps / BPS)` per bid and a sum of floors is never above the floor of the sum,
    // so an honestly accrued fee is ALWAYS <= this ceiling and is never touched by the clamp.
    // Together with the `MAX_FEE_BPS` assert above it also bounds the fee at half of `poolAmount`
    // — the on-chain ceiling holds no matter what the state init says. `feeBps = 0` yields a
    // ceiling of 0, i.e. "no fee, unconditionally", whatever `feeAccrued` a state init contains.
    val honestCeiling: coins = storage.poolAmount * storage.feeBps / BPS_DENOMINATOR;
    val fee: coins = min(storage.feeAccrued, honestCeiling);
    val balanceAtClaim = contract.getOriginalBalance();
    // `PAYOUT_HEADROOM` covers the prize message to a BASECHAIN destination — the pre-fee
    // requirement, unchanged, so a pool that pays no fee accepts and refuses exactly the balances
    // it did before the fee existed. `FEE_MESSAGE_HEADROOM` is added only when the fee message is
    // actually emitted. A message to the masterchain is forwarded at masterchain prices, which
    // are ~24x higher, and BOTH destinations here are chosen by somebody else: `feeRecipient` by
    // the deployer, `winner` by whoever bid. Each masterchain destination therefore adds its own
    // measured surcharge, so that TVM code 37 stays unreachable for every routable address.
    var required = STORAGE_RESERVE + PAYOUT_HEADROOM + fee;
    if (winner.getWorkchain() == MASTERCHAIN) {
        required += MASTERCHAIN_PAYOUT_SURCHARGE;
    }
    if (fee > 0) {
        // An unroutable fee recipient is the same code-36 trap as an unroutable leader, and it
        // only matters when a fee message is actually emitted.
        assert (storage.feeRecipient.isDeliverable()) throw Errors.FeeRecipientUnreachable;
        required += FEE_MESSAGE_HEADROOM;
        if (storage.feeRecipient.getWorkchain() == MASTERCHAIN) {
            required += MASTERCHAIN_PAYOUT_SURCHARGE;
        }
    }
    assert (balanceAtClaim >= required) throw Errors.PayoutUnfunded;

    // The replay latch is committed to c4 BEFORE any action is produced.
    storage.paidOut = true;
    storage.save();

    // Storage survival, not a naive "send everything": `RESERVE_MODE_AT_MOST` reserves
    // min(STORAGE_RESERVE, balance), so the reserve action can never fail on a thin balance and
    // the account is never drained to zero — whatever the bid count, whatever the claimer
    // attaches. One year of rent costs ~0.0016 TON, so 0.05 TON covers decades of post-mortem
    // get-method reads. Everything above the reserve leaves with the fee and the prize.
    reserveToncoinsOnBalance(STORAGE_RESERVE, RESERVE_MODE_AT_MOST);

    // The fee action comes FIRST, because the prize below carries whatever is left. The guard is
    // on `fee`, the CLAMPED amount, so a pool that owes nothing produces byte-for-byte the
    // actions of the pre-fee contract: one reserve, one mode-128 send, no fee message at all —
    // whatever `feeAccrued` its state init happens to contain.
    if (fee > 0) {
        val feeMessage = createMessage({
            // NON-BOUNCEABLE, and this is the whole point of the message. A fee collector is by
            // construction an account that has never SENT anything, so on chain it is
            // `uninitialized` — and TON bounces a BOUNCEABLE message to an uninitialized (or
            // frozen) account back to the sender, because there is no code to run. `paidOut` is
            // already latched and the deadline has passed, so the returned fee could never be
            // sent again: the operator lost 100% of the fee on the very first round. Reproduced
            // against the field report in `tests/fee.test.tolk`
            // (`test an uninitialized fee recipient is paid in full and nothing is stranded`):
            // with `Only256BitsOfBody` the pool kept 169908599 nanoton instead of the 50000000
            // reserve, exactly the on-chain figure. Non-bounceable delivery instead CREATES the
            // recipient account and credits it, which is what "the fee must reach the recipient"
            // means. `PrizePaid` stays bounceable — see the audit note on it below.
            bounce: BounceMode.NoBounce,
            value: fee,
            dest: storage.feeRecipient,
            body: FeePaid {
                queryId,
                recipient: storage.feeRecipient,
                feeAmount: fee,
            },
        });
        // `SEND_MODE_PAY_FEES_SEPARATELY` is what makes "the recipient receives exactly
        // `feeAccrued`" true: the forward fee is taken from the balance instead of from the
        // message value. It comes out of what the winner would otherwise get, which is the same
        // side of the trade the claim gas is already on.
        feeMessage.send(SEND_MODE_PAY_FEES_SEPARATELY);
    }

    val payoutMessage = createMessage({
        // BOUNCEABLE, deliberately — but NOT because a bounce is a safe outcome here. It is not:
        // a bounced prize lands back on the balance of a pool whose `paidOut` is already latched,
        // and `payOutPrize` is the only code path that moves value out, so those coins are
        // stranded exactly the way the bounced fee was. Three rounds where a SUCCESSFUL claim
        // therefore leaves the pool above `STORAGE_RESERVE` are measured and pinned in
        // `tests/fee.test.tolk`: a leader CONTRACT that throws on `PrizePaid`, a hand-built state
        // init whose `leader` is an uninitialized account and which never takes a bid, and the
        // same state init after third parties topped it up. The bid path itself cannot produce an
        // uninitialized leader — `storage.leader` is only ever assigned in `registerBid` from
        // `in.senderAddress` of an ACCEPTED bid, and an internal message comes from the compute
        // phase of a transaction, which an account with no code does not have — but a leader that
        // is a CONTRACT can arise from the bid path, and a baked-in leader is never overwritten on
        // a pool that takes no bid.
        //
        // The flag stays because for the PRIZE the two sides of the trade are not the fee's. The
        // fee destination is the operator's own address, so unconditional delivery is a trade the
        // operator makes with themselves. The prize destination is `storage.leader`, which an
        // outsider chooses — by bidding, or by baking one into a state init. Measured on the third
        // round above with the flag flipped to `NoBounce`: the deployer's baked-in address
        // collects 10349336401 nanoton of THIRD-PARTY top-ups instead of the coins being returned
        // to a pool nobody can drain. Bounceable keeps that shape a griefing loss; non-bounceable
        // would make it a profitable rug-pull, which is a strictly worse failure than the strand.
        // The strand is pre-existing: all three rounds produce byte-identical figures on the tree
        // before this repair (measured on `main` @ 472e1d0), so it is not created or widened by
        // the fee, and it is disclosed in "Residual fund risks" in README.md.
        bounce: BounceMode.Only256BitsOfBody,
        value: 0,
        dest: winner,
        body: PrizePaid {
            queryId,
            winner,
            poolAmount: storage.poolAmount,
        },
    });
    // SAFETY: draining the balance is the whole point of the payout, and it is bounded:
    // `reserveToncoinsOnBalance` above keeps STORAGE_RESERVE for rent, the destination is the
    // stored leader (never the sender), and `paidOut` is already committed so this runs at most
    // once. No ignore-errors flag is set on either message, so a failing action phase reverts the
    // latch as well and the transaction stays atomic.
    payoutMessage.send(SEND_MODE_CARRY_ALL_BALANCE);
}

fun onInternalMessage(in: InMessage) {
    if (in.body.isEmpty()) {
        // An empty body is a documented plain TOP-UP, not a bid: it changes no state and
        // is what lets the deploy message (which carries an empty body) through.
        val storage = lazy Storage.load();
        // Once the prize is gone the coins could never leave again, and once the deadline has
        // passed the round is closed — a top-up could then only be swept to the leader, or be
        // locked forever if nobody ever bid. Both cases throw, so the coins bounce back.
        assert (!storage.paidOut) throw Errors.AlreadyPaidOut;
        assert (blockchain.now() < storage.deadline) throw Errors.DeadlinePassed;
        return;
    }

    // The opcode is matched BEFORE the body shape, so that EVERY unrecognised prefix maps to
    // `UnknownOp` — a body too short to carry an opcode and the most common real-world
    // accident, a wallet transfer with a text comment (op `0x00000000`), included.
    assert (in.body.remainingBitsCount() >= OPCODE_BITS) throw Errors.UnknownOp;
    val opcode = in.body.preloadUint(OPCODE_BITS);
    assert (opcode == OP_PLACE_BID || opcode == OP_CLAIM_PRIZE) throw Errors.UnknownOp;

    // Both accepted bodies are exactly `opcode: uint32` + `queryId: uint64` and carry no refs.
    // Without this a bare `PlaceBid` opcode would be silently accepted as a bid (the lazy parse
    // never touches `queryId`), and a bare `ClaimPrize` opcode would abort with the raw TVM
    // "cell underflow" code 9. A known opcode with a broken payload is still a body this
    // protocol does not accept, so it shares the `UnknownOp` code (the ABI freezes the set).
    assert (in.body.remainingBitsCount() == BODY_BITS) throw Errors.UnknownOp;
    assert (in.body.remainingRefsCount() == 0) throw Errors.UnknownOp;

    val msg = lazy AllowedMessage.fromSlice(
        in.body,
        { throwIfOpcodeDoesNotMatch: Errors.UnknownOp },
    );

    match (msg) {
        PlaceBid => {
            registerBid(in.senderAddress, in.valueCoins);
        }
        ClaimPrize => {
            payOutPrize(msg.queryId);
        }
    }
}

/// A payout that comes back (a leader contract refusing `PrizePaid`, or a bounceable prize to an
/// uninitialized leader baked into a state init) credits the coins to the balance again. Storage
/// is intentionally left untouched: `paidOut` stays true, the leader is unchanged and `feeAccrued`
/// is unchanged, so a bounce can never be used to replay the prize or the fee. The returned coins
/// are then UNRECOVERABLE — `payOutPrize` is the only path that moves value out and it is gated on
/// `!paidOut` — which is the pre-existing residual risk documented in README.md, not a safe
/// outcome. `FeePaid` is sent non-bounceable, so the network can no longer produce a bounce for
/// the fee at all; this handler stays inert for that opcode too.
fun onBouncedMessage(_in: InMessageBounced) {}

get fun leader(): address? {
    val storage = lazy Storage.load();
    return storage.leader;
}

get fun bestBid(): coins {
    val storage = lazy Storage.load();
    return storage.bestBid;
}

get fun poolAmount(): coins {
    val storage = lazy Storage.load();
    return storage.poolAmount;
}

get fun deadline(): uint32 {
    val storage = lazy Storage.load();
    return storage.deadline;
}

get fun isPaidOut(): bool {
    val storage = lazy Storage.load();
    return storage.paidOut;
}

get fun feeRecipient(): address {
    val storage = lazy Storage.load();
    return storage.feeRecipient;
}

get fun feeBps(): uint16 {
    val storage = lazy Storage.load();
    return storage.feeBps;
}

get fun feeAccrued(): coins {
    val storage = lazy Storage.load();
    return storage.feeAccrued;
}

/// Seconds an accepted bid pushes the deadline to (`deadline = now() + this`). Fixed at deploy.
get fun extensionWindow(): uint32 {
    val storage = lazy Storage.load();
    return storage.extensionWindow;
}

/// The live countdown: `deadline - now()`, clamped at 0.
///
/// A UI must not compute this from the browser clock — a device that is a few minutes fast would
/// tell a bidder the round is over while it still accepts bids, which under this mechanic is
/// exactly the mistake that loses a round. Reading it here answers against the same clock the
/// contract itself compares against. 0 means bidding is closed and `ClaimPrize` is the next move.
get fun secondsLeft(): uint32 {
    val storage = lazy Storage.load();
    val now = blockchain.now();
    return now >= storage.deadline ? 0 : storage.deadline - now;
}

/// The smallest value a bid must carry RIGHT NOW to be accepted: `MIN_BID` while nobody has bid,
/// and `bestBid + 1` nanoton once there is a leader.
///
/// It is the same pair of rules `registerBid` enforces read as a single number, so a UI that
/// pre-fills its amount field with it always offers a bid the contract accepts.
get fun minimumNextBid(): coins {
    val storage = lazy Storage.load();
    return minimumBidAfter(storage.bestBid);
}

get fun poolState(): PoolState {
    val storage = lazy Storage.load();
    val now = blockchain.now();
    return PoolState {
        deadline: storage.deadline,
        leader: storage.leader,
        bestBid: storage.bestBid,
        poolAmount: storage.poolAmount,
        paidOut: storage.paidOut,
        feeRecipient: storage.feeRecipient,
        feeBps: storage.feeBps,
        feeAccrued: storage.feeAccrued,
        extensionWindow: storage.extensionWindow,
        secondsLeft: now >= storage.deadline ? 0 : storage.deadline - now,
        minimumNextBid: minimumBidAfter(storage.bestBid),
    };
}
