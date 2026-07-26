/// Shared types, opcodes and error codes of the `PrizePool` "winner takes all" pool.
///
/// In one sentence, the rule a player has to understand: **bid more than the current leader and
/// you are the leader; every accepted bid restarts the clock at `extensionWindow` seconds; the
/// round ends when that long passes with no accepted bid, and the last leader takes the pool.**
///
/// The pool is therefore a PURE ROLLING WINDOW. There is NO scheduled prize date and no
/// calendar moment at which the prize is awarded: bidders send `PlaceBid` with TON attached,
/// every accepted bid must be STRICTLY GREATER than the current best bid, its value stays
/// in the pool and it sets `deadline = now() + extensionWindow`, unconditionally. Once the
/// stored deadline passes anyone may send `ClaimPrize`, and the whole balance (minus
/// `STORAGE_RESERVE` and minus the accrued protocol fee) is paid to the stored leader exactly
/// once, while the fee goes to `feeRecipient`.
///
/// `MIN_BID` is the floor for the FIRST bid of a round and the dust floor, nothing else: it
/// never participates in a comparison against a non-zero `bestBid`, so once a leader exists the
/// only rule is "more than the leader".
///
/// Two consequences of that, stated honestly because both are reachable:
///   * a round can END MINUTES AFTER IT OPENS. One bid, nobody answers within
///     `extensionWindow`, and the single bidder takes the pool;
///   * the entry price does NOT rise on its own — one nanoton over the leader is a legal bid —
///     so a round ends only when the bidders stop, and a funded pair can hold the clock for as
///     long as they keep bidding. What that costs them is not the increment but the WHOLE bid:
///     every accepted bid is added to the pool in full, so moving the clock is never cheap at any
///     step size. The protocol fee, taken out of the final payout, is the only economic brake;
///     at `feeBps = 0` there is none beyond the bid itself and gas.
///
/// The deadline stored in the state init answers exactly ONE question: how long an EMPTY pool
/// waits for its VERY FIRST bid before it closes with no leader — see `DEFAULT_OPENING_WINDOW`.

/// Recommended OPENING WINDOW, as a DURATION in SECONDS: 3600 (one hour).
///
/// It is NOT a timestamp and NOT a prize date. The only thing it bounds is how long a pool
/// nobody has bid on yet waits for its FIRST bid: an operator deploys with an initial
/// `deadline` of `now() + DEFAULT_OPENING_WINDOW`, and if that hour passes with no accepted
/// bid the pool closes with no leader (`ClaimPrize` then answers `NoBids`, 104). From the
/// first accepted bid on, the initial value is irrelevant to the round — `registerBid` writes
/// `now() + extensionWindow` over it — and it survives only as the number the pool's
/// deterministic address was derived from, which every operator script keeps addressing it by
/// (`tests/extension.test.tolk` pins both halves of that).
///
/// WHY ABOUT AN HOUR. Too short and an operator who announces a pool cannot get the
/// announcement in front of anybody before it closes empty; too long and a pool that nobody
/// ever bids on sits there advertising a live round for days, which is the misreading this
/// framing exists to kill. An hour is long enough to publish the address and for the first
/// bidder to act on it, and short enough that a stillborn pool is visibly over the same
/// afternoon. Nothing on chain enforces it — the initial deadline is a plain script argument,
/// and a longer or shorter one is a legitimate deploy-time choice — so this is a default, not
/// a bound: it is `MIN_EXTENSION_WINDOW`/`MAX_EXTENSION_WINDOW` that the CONTRACT enforces, on
/// the window that actually decides the round.
///
/// Absolute timestamps belong on the command line, not in this file:
/// `acton run deploy-testnet <feeRecipient> 2000 $(( $(date +%s) + 3600 )) 900`.
const DEFAULT_OPENING_WINDOW = 3600

/// Nanotons kept on the balance after the payout, so the contract survives storage rent.
/// Measured with `testing.getAccountStorageFee(pool, 31536000)`, one year of rent costs
/// 1624054 nanoton (~0.0016 TON, up from ~0.0012 before the three fee fields widened the
/// storage cell), so this still covers decades. `payOutPrize` reserves it unconditionally with
/// `RESERVE_MODE_AT_MOST`, i.e. min(STORAGE_RESERVE, balance): the account is never drained.
const STORAGE_RESERVE = ton("0.05")

/// How far the balance must exceed `STORAGE_RESERVE` plus the payable fee at claim time for the
/// PRIZE message to be sendable to a BASECHAIN destination. The fee message adds
/// `FEE_MESSAGE_HEADROOM` on top when it is emitted, and each masterchain destination adds
/// `MASTERCHAIN_PAYOUT_SURCHARGE` — see both below.
///
/// UNCHANGED from the pre-fee contract, deliberately. `payOutPrize` emits up to two actions after
/// the reserve: the fee message carries the payable fee with `SEND_MODE_PAY_FEES_SEPARATELY` (so
/// the recipient gets exactly that amount and the forward fee comes off the balance), and the
/// prize leaves with `SEND_MODE_CARRY_ALL_BALANCE`, i.e. it carries `balance - STORAGE_RESERVE -
/// fee - feeForwardFee`. If that does not cover this transaction's gas plus the forward fee of
/// the prize message, the ACTION phase aborts with the raw TVM code 37 ("Not enough Toncoin")
/// instead of a named error. `payOutPrize` checks the balance up front and throws
/// `Errors.PayoutUnfunded` instead, which keeps the claim bounceable and the prize claimable.
///
/// MEASURED, not guessed. The floor below is the smallest `balance - STORAGE_RESERVE - fee` at
/// which the ACTION phase still executes, found by binary search with the guards temporarily
/// disabled (`PAYOUT_HEADROOM = 1`, `FEE_MESSAGE_HEADROOM = 0`, `MASTERCHAIN_PAYOUT_SURCHARGE =
/// 0`) and a FRESH pool per candidate — a claim that passes the guard and dies in the action
/// phase does NOT bounce, it keeps the attached value, so re-probing one pool would measure a
/// moving balance:
///
///   | contract                        | claim gas | floor (nanoton) | requirement | factor |
///   | ------------------------------- | --------- | --------------- | ----------- | ------ |
///   | pre-fee (main), one message     |      4617 |          407869 |  0.002      |  4.90x |
///   | this contract, no payable fee   |      5723 |          481654 |  0.002      |  4.15x |
///   | this contract, feeBps = 2000    |      7581 |          694322 |  0.003      |  4.32x |
///   | this contract, feeBps = 5000    |      7581 |          694855 |  0.003      |  4.32x |
///
/// The second message costs 213201 nanoton of floor (694855 - 481654) and is charged for
/// separately (`FEE_MESSAGE_HEADROOM`), so the fee-free requirement stays exactly what it was:
/// measured on both trees with the same construction, a fee-free pool holding 52000000 nanoton at
/// claim time pays out and one holding 51999999 is refused, on `main` and here alike.
/// `tests/fee.test.tolk` pins both ends of both thresholds. Any claimer can satisfy them by
/// attaching value to `ClaimPrize` (that value counts towards the balance).
const PAYOUT_HEADROOM = ton("0.002")

/// Added to the claim-time requirement ONLY when the fee message is actually emitted, i.e. only
/// when the payable fee is above zero.
///
/// It is a separate constant on purpose. `feeBps = 0` (and any pool that owes nothing) must
/// accept and refuse EXACTLY the balances the pre-fee contract did, down to the nanoton — a
/// single merged headroom of 0.003 TON would have created a 1000000-nanoton band in which the
/// old contract paid out and this one answers `PayoutUnfunded`, which is a behavioural difference
/// on the fee-free path, not just a gas one. Splitting the term keeps the fee-free decision
/// identical and charges the second message to the rounds that actually produce it.
///
/// MEASURED: the second message costs 213201 nanoton of action-phase floor (694855 - 481654), so
/// 0.001 TON is 4.69x that increment, and the two terms together are 4.32x the worst measured
/// two-message floor.
const FEE_MESSAGE_HEADROOM = ton("0.001")

/// Added to the claim-time balance requirement for EACH payout message whose destination is not
/// in the basechain (workchain 0).
///
/// A message to or from the masterchain is forwarded at masterchain prices (config param 24
/// instead of 25), which are ~24x higher — and both destinations are chosen by somebody other
/// than this contract: `feeRecipient` is frozen into the state init by the deployer, `winner` is
/// whoever bid the most. Without this term the guard would pass on a thin pool and the ACTION
/// phase would then abort with the raw TVM code 37: no bounce, the claimer's whole attached value
/// swallowed, `paidOut` still false, and repeatable for the next claimer. `PAYOUT_HEADROOM` alone
/// only ever covered basechain destinations — on `main`, where the leader is the only
/// destination, a masterchain leader had the same hole (reproduced: raw code 37, 0.005 TON
/// swallowed). This surcharge is the one part of this contract that is NOT in the mandated fee
/// design; it is kept, and disclosed here and in README.md, because the fee gave the payout a
/// second attacker-chosen destination and the raw code 37 it prevents is the same class of defect
/// as the raw code 36 `address.isDeliverable` prevents.
///
/// MEASURED the same way (binary search, fresh pool per candidate, `PAYOUT_HEADROOM = 1`,
/// `FEE_MESSAGE_HEADROOM = 0` and this surcharge 0), one `MIN_BID` bid at `feeBps = MAX_FEE_BPS`:
///
///   | destinations                       | floor (nanoton) | delta vs all-basechain |
///   | ---------------------------------- | --------------- | ---------------------- |
///   | leader BC, recipient BC (2 msgs)   |          694855 |                      — |
///   | leader BC, recipient MC (2 msgs)   |        15585988 |               14891133 |
///   | leader MC, recipient BC (2 msgs)   |        15585988 |               14891133 |
///   | leader MC, recipient MC (2 msgs)   |        30477120 |            2x 14891133 |
///   | leader MC, no fee      (1 msg)     |        15372787 |               14891133 |
///   | main, leader MC        (1 msg)     |        15297935 |               14890066 |
///
/// The surcharge is the same ~14891133 nanoton per masterchain destination in every combination
/// (14890066 on main, where the message body is one field shorter), and it is dominated by the
/// masterchain lump price (0.01 TON), which is a config constant rather than a gas figure.
/// 0.03 TON is 2.01x it, so a full doubling of masterchain forward prices is still covered.
/// `tests/fee.test.tolk` pins both ends of this threshold too, for a masterchain recipient, a
/// masterchain leader, and both at once.
const MASTERCHAIN_PAYOUT_SURCHARGE = ton("0.03")

/// Smallest accepted bid value: a gas and rent floor, ~300x the ~0.00016 TON dust window that
/// TON absorbs before a rejected bid can bounce (see "Dust below the bounce floor" in README.md)
/// and ~300x the ~0.00017 TON of gas the pool burns while accepting a bid.
///
/// WHAT IT GATES, and what it does NOT. It is the floor for the FIRST bid of a round and the
/// dust floor — a bid below the bounce floor is silently swallowed by the network rather than
/// returned, so the floor is real protection and not a courtesy. It is NOT a raise rule: once a
/// leader exists the only comparison against `bestBid` is the strictly-greater one, and `MIN_BID`
/// never enters it (a bid that beats a non-zero `bestBid` is above `MIN_BID` anyway, because the
/// leader itself had to clear it).
///
/// This value is part of the cross-unit ABI, so a dApp may advertise it verbatim;
/// `tests/deploy-state.test.tolk` pins the literal so it can never drift again.
const MIN_BID = ton("0.05")

/// Denominator of `Storage.feeBps`: the fee is quoted in basis points, so 2000 = 20%.
const BPS_DENOMINATOR = 10000

/// Smallest value that would be ACCEPTED right now on a pool whose current best bid is
/// `bestBid`: `MIN_BID` while nobody has bid, and `bestBid + 1` nanoton once there is a leader.
///
/// It is exactly the two asserts `registerBid` runs (`bidValue > bestBid` and
/// `bidValue >= MIN_BID`) read as a number, which is why `max()` and not a special case: at
/// `bestBid = 0` the strictly-greater term is 1 and the floor wins, and at any `bestBid` a real
/// round can reach (>= `MIN_BID`, because the leader had to clear the floor) the floor is
/// irrelevant and the answer is one nanoton more than the leader.
///
/// ONE definition, shared by the `minimumNextBid()` get method a UI reads and the operator
/// scripts — so the number a dApp shows in its input field and the number the chain enforces can
/// never drift apart. `tests/extension.test.tolk` pins the exact literal at several magnitudes.
fun minimumBidAfter(bestBid: coins): coins {
    return max(bestBid + 1, MIN_BID);
}

/// The `extensionWindow` baked into the canonical deployed storage AND the default of the
/// `Storage` field: 900 seconds = 15 minutes.
///
/// It is the anti-snipe window: an accepted bid moves the deadline to `now() + 900`, so a round
/// ends 15 minutes after the last accepted bid. Long enough for a human on a phone to see the
/// notification, sign and land a counter-bid; short enough that a quiet round settles the same
/// afternoon.
const DEFAULT_EXTENSION_WINDOW = 900

/// On-chain FLOOR for `Storage.extensionWindow`: 60 seconds.
///
/// The floor is what stops the mechanic from being silently disabled. `extensionWindow = 0` would
/// serialize, deploy and read back perfectly while setting `deadline = now()` on every accepted
/// bid — i.e. the round would END on the first bid, which is worse than no extension at all, and
/// no getter would say anything was wrong. A one-second window would be the same defect with a
/// nicer number: TON blocks are ~5 s on the masterchain and 2-3 s on a basechain shard, so any
/// window shorter than a handful of blocks cannot be reacted to at all and the sniper wins by
/// construction. 60 s is >= 12 masterchain blocks, which is the smallest window in which "see the
/// bid, sign, land the counter-bid" is physically possible for a human.
///
/// `registerBid` refuses EVERY bid on a pool outside `[MIN_EXTENSION_WINDOW,
/// MAX_EXTENSION_WINDOW]` with `Errors.ExtensionWindowOutOfRange`, so such a pool can never take
/// a nanoton — `Storage` is whatever the deployer put in the state init, exactly like `feeBps`,
/// so this is the guard that makes the bound unbypassable rather than a deploy-script courtesy.
const MIN_EXTENSION_WINDOW = 60

/// On-chain CEILING for `Storage.extensionWindow`: 86400 seconds = 24 hours.
///
/// WHAT IT BOUNDS: the deadline is reset to `now() + extensionWindow` by every accepted bid, so
/// this constant is the maximum time ONE accepted bid can hold everyone else's funds locked in
/// the pool. It is not a bound on the round (a contested round is extended as often as bidders
/// keep bidding) — it is the bound on what a SINGLE bid buys, which is the only thing the
/// contract can bound at all.
///
/// MEASURED, not guessed. Three independent numbers say 86400 is defensible, all of them pinned
/// in `tests/extension.test.tolk`:
///
///   1. What the hold COSTS THE HOLDER. Holding the pool for one more maximum window costs ONE
///      MORE ACCEPTED BID, and an accepted bid costs its FULL value — `poolAmount += bidValue`,
///      not the increment. The cheapest possible stall therefore still puts a whole entry bid on
///      the table per window, in a pool the staller may lose. MEASURED on chain
///      (`tests/extension.test.tolk`, always raising by ONE NANOTON from a `MIN_BID` start, i.e.
///      the cheapest legal ladder there is):
///
///        | accepted bids | days held at the ceiling | pool (nanoton) | factor vs MIN_BID |
///        | ------------- | ------------------------ | -------------- | ----------------- |
///        |             1 |                        1 |       50000000 |             1.00x |
///        |             8 |                        8 |      400000028 |             8.00x |
///        |            20 |                       20 |     1000000190 |            20.00x |
///        |           320 |                      320 |    16000051040 |           320.00x |
///
///      A stall is therefore not free the way a `sleep()` is: it is linear in the number of
///      windows held, at one full bid each, and every one of those bids is added to the prize
///      the staller is trying to deny everybody else. What it is NOT is self-accelerating — the
///      entry price does not rise on its own, so the brake is the capital tied up plus the
///      protocol fee, and at `feeBps = 0` there is no fee brake at all.
///   2. What the hold COSTS THE POOL. Storage rent for one maximum window, measured with
///      `testing.getAccountStorageFee(pool, 86400)` on a live two-bid pool, is 5874 nanoton —
///      0.0117% of `STORAGE_RESERVE` (50000000). Even an unbroken chain of maximum-length
///      extensions running for years cannot eat the reserve that keeps the post-mortem state
///      readable (the same measurement over a full year reads 2143752).
///   3. What the CLOCK can take. `Storage.deadline` is a `uint32`, so `now() + extensionWindow`
///      must stay below 4294967296 or the `save()` would abort with a raw serialization error
///      rather than a named one. With this ceiling the last safe moment is 4294880895
///      (2106-02-06), i.e. the ceiling costs the contract exactly one day of its natural uint32
///      lifetime and cannot be the thing that breaks it.
///
/// Why not longer: 24 h is the point past which a single bid stops being an auction move and
/// becomes a lockup — a bidder who has to be able to answer within one day can plan around it,
/// one who may be locked for a week cannot. Why not shorter: a deployer running a weekend-long
/// round for a global audience needs a window that survives one night of sleep, and 86400 is the
/// smallest number that does. The bounds cost 274 gas units per accepted bid and the deadline
/// write another 60 — measured, see the table on `Storage.extensionWindow`.
const MAX_EXTENSION_WINDOW = 86400

/// Whether TON can route a message to this address at all.
///
/// Only two workchains exist: 0 (basechain) and -1 (masterchain). An address in any other one is
/// a well-formed `MsgAddressInt` that no shard is responsible for, so an outgoing message to it
/// does not fail in the compute phase — it aborts the ACTION phase with the raw TVM code 36,
/// which does not bounce and swallows whatever the incoming message attached. Both payout
/// destinations are chosen outside this contract (`feeRecipient` by the deployer, `leader` by
/// whoever bid), so both are checked against this before a message is ever built.
fun address.isDeliverable(self): bool {
    val workchain = self.getWorkchain();
    return workchain == BASECHAIN || workchain == MASTERCHAIN;
}

/// Hard on-chain ceiling for `Storage.feeBps`: 5000 bps = 50%.
///
/// A new leader's profit is `(1 - f) * previousPoolTotal - f * bid` (the winner receives the whole
/// accounted pool minus the fee on it, and paid `bid` for that), so at `f = 1/2` a bid is only
/// profitable while `previousPoolTotal > bid`, which the strictly-greater rule already makes hard
/// to reach.
///
/// CORRECTION to the product spec, proven rather than assumed: above 50% the profitable window
/// NARROWS, it does not close. The spec's "above 50% the game is structurally dead, because the
/// profitable window vs the strictly-greater rule closes" is false as stated. Its own profit
/// formula is what disproves it — at `f = 0.8` the bids 10, 11, ..., 24 leave
/// `previousPoolTotal = 255`, and a strictly-greater bid of 25 yields
/// `0.2 * 255 - 0.8 * 25 = +31`. In general a profitable bid reappears once the bid count exceeds
/// about `2f / (1 - f)`. (Also note the FIRST bidder can never profit at any `f > 0`:
/// `previousPoolTotal = 0` makes the profit `-f * bid`.) 5000 bps is therefore a POLICY ceiling —
/// the point past which the pool takes more of a round than the winner does — and it is enforced
/// as an absolute on-chain rule regardless of the economics argument behind the number.
///
/// It is enforced on BOTH paths that a fee can flow through, because either one alone is
/// bypassable. `Storage` is chosen by whoever builds the state init, so there is no constructor
/// to guard:
///   * `registerBid` — the only place `feeBps` can start earning honestly. Refusing the bid keeps
///     an over-fee pool empty, so no bidder can lose a nanoton to one;
///   * `payOutPrize` — because a state init can bake in a `leader` as well, and then the bid path
///     is never executed at all. Guarding only the bid path left exactly that hole: such a pool
///     still accepted empty-body top-ups and then paid a 90% fee out of them.
/// With both, an over-ceiling pool can never move a nanoton: bids are refused with `FeeTooHigh`,
/// and so is the claim. `payOutPrize` additionally CLAMPS the payable fee to
/// `poolAmount * feeBps / BPS_DENOMINATOR`, which bounds a `feeAccrued` baked into the state init
/// by what `feeBps` could honestly have accrued — without it, `feeBps = 1` plus 9.9 TON of
/// phantom accrual paid a ~99% fee on a pool advertising 0.01%.
///
/// The cost of putting the ceiling on the hot path is MEASURED, not assumed. `PlaceBid` gas, same
/// pool, same bid, only the contract source changed:
///
///   | variant                                             | gas  | delta |
///   | --------------------------------------------------- | ---- | ----- |
///   | pre-fee contract (main)                             | 2591 |     — |
///   | fee storage fields added, nothing read on the path   | 2591 |    +0 |
///   | + `feeAccrued` accrual                              | 3019 |  +428 |
///   | + this ceiling assert                               | 3123 |  +104 |
///   | + `feeRecipient.isDeliverable()` assert (shipped)    | 3332 |  +209 |
///
/// So the bid-path half of the ceiling costs **104 gas units per accepted bid**, 3.3% on top of
/// the accrual and 4.0% of the 2591 the bid used to cost, and the routability check that keeps
/// bids out of a pool with an unroutable `feeRecipient` costs another 209. The payout-path half
/// (the ceiling re-check, the clamp and the two routability checks) costs 638 gas units on a
/// fee-bearing claim and 329 on a fee-free one — measured the same way, by removing them and
/// re-running the same probe. `tests/fee.test.tolk` pins 3332, 7581 and 5723 so neither path can
/// silently get more expensive.
const MAX_FEE_BPS = 5000

/// The fee baked into the canonical deployed storage: 2000 bps = 20%.
/// `scripts/deploy.tolk` takes `feeBps` as an argument, so this is the value to pass for a
/// canonical pool; tests and docs must use this constant instead of the literal.
const DEPLOY_FEE_BPS = 2000

/// One distinct exit code per failure mode.
/// Every one of them is thrown from the compute phase, so a bounceable incoming
/// message returns its coins to the sender instead of being silently kept.
enum Errors {
    /// A bid arrived at or after `Storage.deadline`.
    DeadlinePassed = 101
    /// A bid value is not STRICTLY greater than `Storage.bestBid`.
    BidTooLow = 102
    /// `ClaimPrize` arrived before `Storage.deadline`.
    DeadlineNotReached = 103
    /// `ClaimPrize` arrived, but nobody ever bid (`Storage.leader` is null).
    NoBids = 104
    /// A second `ClaimPrize`, or a top-up after the pool was already paid out.
    AlreadyPaidOut = 105
    /// A bid strictly greater than `bestBid`, but below `MIN_BID`.
    BidBelowMinimum = 106
    /// `ClaimPrize` on a pool whose balance does not exceed `STORAGE_RESERVE` plus the accrued
    /// fee by at least `PAYOUT_HEADROOM` (plus `MASTERCHAIN_PAYOUT_SURCHARGE` for each payout
    /// message that leaves the basechain), so a payout message could not pay its own forward fee
    /// and the transaction would die in the ACTION phase with the nameless TVM code 37. Reachable
    /// only when the pool was deployed with far less than the reserve, or when storage rent
    /// eroded a minimal pool for years. The prize stays claimable: attach the missing value to
    /// the claim.
    PayoutUnfunded = 107
    /// `PlaceBid` or `ClaimPrize` on a pool whose stored `feeBps` exceeds `MAX_FEE_BPS`
    /// (5000 = 50%). Reachable only on a pool somebody deployed with an out-of-range fee:
    /// `Storage` is chosen by whoever builds the state init, so this is the guard that makes the
    /// ceiling unbypassable, and it is checked on BOTH paths. Such a pool can never move a
    /// nanoton: every bid bounces back untouched (`leader` stays null, so a claim would answer
    /// `NoBids` (104) as well), and a claim on a pool whose state init baked a `leader` in is
    /// refused with this code instead of paying an over-ceiling fee. No BIDDER can lose anything
    /// to it. It is not inert, though: like any pool that never got a bid it still accepts
    /// empty-body top-ups before the deadline, and those are then stranded forever, because
    /// nothing can ever pay out. Do not bid on it and do not top it up — deploy a new pool.
    FeeTooHigh = 108
    /// A payout destination that TON cannot route to. Only workchains 0 (basechain) and -1
    /// (masterchain) exist; a message to any other one aborts the ACTION phase with the raw TVM
    /// code 36 ("invalid destination address"), which does NOT bounce — it swallows the claimer's
    /// attached value, leaves `paidOut` false and traps the next claimer the same way.
    ///
    /// `FeeRecipientUnreachable` is thrown by `PlaceBid` on ANY pool whose stored `feeRecipient`
    /// is unroutable (so no bid can ever be trapped behind one, the bid bounces back untouched)
    /// and by `ClaimPrize` when a fee is payable to one. Reachable only on a pool somebody
    /// deployed with such an address: `scripts/deploy.tolk` refuses to publish one.
    FeeRecipientUnreachable = 109
    /// `ClaimPrize` on a pool whose stored `leader` is unroutable — see
    /// `FeeRecipientUnreachable` for what the raw TVM code 36 would have done instead. A real
    /// bid can never produce this (a message sender always lives in workchain 0 or -1), so it
    /// takes a hand-built state init with a `leader` baked in. Nothing can settle such a pool,
    /// which is exactly why the claim must be a bounced, named refusal rather than a trap.
    LeaderUnreachable = 110
    // 111 is RETIRED and deliberately left UNUSED — nothing below is renumbered. It was
    // `RaiseTooSmall`, thrown when a bid beat `bestBid` but not by the minimum raise step. The
    // step is gone (the only rule against a non-zero `bestBid` is the strictly-greater one
    // again), and the code is NOT reused for anything else, so an old client that still decodes
    // 111 can never be told a new meaning by this contract.
    /// `PlaceBid` on a pool whose stored `extensionWindow` is outside
    /// `[MIN_EXTENSION_WINDOW, MAX_EXTENSION_WINDOW]` (60..86400 seconds). Reachable only on a
    /// pool somebody deployed with an out-of-range window: `Storage` is chosen by whoever builds
    /// the state init, so — exactly like `FeeTooHigh` — this is the guard that makes the bounds
    /// unbypassable rather than a courtesy of `scripts/deploy.tolk`. Such a pool can never take a
    /// bid, so it can never fill up and no bidder can lose anything to it; every bid bounces back
    /// untouched and `leader` stays null, so a claim answers `NoBids` (104).
    ///
    /// It is deliberately NOT re-checked on the claim path, unlike `FeeTooHigh`: the window
    /// cannot misdirect or inflate a payment, it can only decide when bidding stops, so refusing
    /// the CLAIM would strand the funds of a hand-built pool instead of protecting anybody.
    ExtensionWindowOutOfRange = 112
    /// A non-empty body this contract cannot interpret, in either of the two ways:
    ///   * the leading 32 bits are not a known opcode — including a body too short to carry
    ///     one, and the usual wallet transfer with a text comment (op `0x00000000`);
    ///   * the opcode IS known but the payload is not exactly `opcode + queryId` with no refs
    ///     (truncated, padded, or ref-carrying). Without that shape check a truncated
    ///     `PlaceBid` would be accepted as a bid (the lazy parse never reads `queryId`) and a
    ///     truncated `ClaimPrize` would abort with the raw TVM "cell underflow" code 9.
    /// One code, because from the sender's point of view it is one failure: the body is not a
    /// message of this protocol. The error set is frozen by the cross-unit ABI.
    UnknownOp = 0xFFFF
}

/// Width of the leading opcode of every message body.
const OPCODE_BITS = 32

/// Exact size of every accepted message body: `opcode: uint32` + `queryId: uint64`.
const BODY_BITS = OPCODE_BITS + 64

/// Message opcodes, so that `onInternalMessage` can match an incoming prefix against the
/// accepted set BEFORE it looks at the body shape. A struct prefix must be a literal, so these
/// mirror the `struct (0x...)` headers below; `tests/funds.test.tolk` pins them to the real
/// wrapper-built bodies so the two can never drift apart.
const OP_PLACE_BID = 0x70626964
const OP_CLAIM_PRIZE = 0x70636c6d
const OP_PRIZE_PAID = 0x70706169
const OP_FEE_PAID = 0x70666565

/// Contract storage. FIELD ORDER IS PART OF THE ABI (it is the serialization order).
struct Storage {
    /// Bids are accepted while `blockchain.now() < deadline`, and the payout while
    /// `blockchain.now() >= deadline`. NOT immutable, and NOT a prize date: every ACCEPTED bid
    /// resets it to `blockchain.now() + extensionWindow`, so from the first bid on it is a
    /// rolling window and nothing else. The value baked into the state init is therefore only
    /// the OPENING WINDOW — the moment an empty pool that never gets a bid closes with no
    /// leader (see `DEFAULT_OPENING_WINDOW`) — but it is the one that fixes the deterministic
    /// address, so operator scripts keep addressing a pool by it forever.
    deadline: uint32
    /// Current leader; null means nobody has bid yet.
    leader: address?
    /// Value of the current best (highest) accepted bid.
    bestBid: coins
    /// Monotonic sum of all accepted bid values: 10 -> 20 -> 30 reads back as 60.
    poolAmount: coins
    /// Replay latch: set once the prize has been sent, never cleared.
    paidOut: bool
    /// Where the accrued protocol fee is sent at claim time. Fixed at deploy time, and must be
    /// ROUTABLE (workchain 0 or -1): `registerBid` refuses every bid on a pool that stores an
    /// address in any other workchain, so no bidder can be trapped behind an undeliverable fee.
    feeRecipient: address
    /// Protocol fee in basis points (2000 = 20%), capped on the bid path at `MAX_FEE_BPS`.
    feeBps: uint16
    /// Monotonic sum of `value * feeBps / BPS_DENOMINATOR` over all accepted bids, rounded DOWN.
    /// It is ACCRUED here and never sent per bid: the hot bid path emits no message at all. The
    /// rounding remainder is not tracked — it simply stays in the pool and goes to the winner.
    /// UNTRUSTED at payout time, because a state init can contain any value: `payOutPrize` pays
    /// `min(feeAccrued, poolAmount * feeBps / BPS_DENOMINATOR)`, so a pool deployed with
    /// `feeBps = 0` pays no fee whatever this says, and one deployed with a phantom accrual pays
    /// at most what its advertised `feeBps` could honestly have earned.
    feeAccrued: coins
    /// Anti-snipe window in SECONDS: every ACCEPTED bid sets `deadline = now() + extensionWindow`.
    /// Fixed at deploy time (there is no setter — it is part of the state init and therefore of
    /// the address), defaulted to `DEFAULT_EXTENSION_WINDOW` (900 = 15 minutes) so that every
    /// construction that does not mention it deploys the canonical mechanic, and bounded ON CHAIN
    /// to `[MIN_EXTENSION_WINDOW, MAX_EXTENSION_WINDOW]` by `registerBid`: a pool outside that
    /// range refuses every bid with `Errors.ExtensionWindowOutOfRange`, so a zero window can never
    /// silently switch the mechanic off.
    ///
    /// APPENDED at the end of the struct on purpose: the eight fields above keep their exact
    /// serialization offsets, so a parser written against the previous layout still reads all of
    /// them correctly and only misses the new tail. The deterministic ADDRESS still changes (the
    /// storage cell is one field longer, and the code cell changed too) — see docs/OPERATIONS.md.
    ///
    /// WHAT THE MECHANIC COSTS on the hot path, MEASURED the same way the fee guards were (same
    /// pool, same bid, only the contract source changed; `tests/fee.test.tolk` pins the shipped
    /// number so it cannot silently grow):
    ///
    ///   | variant                                              | gas  | delta |
    ///   | ---------------------------------------------------- | ---- | ----- |
    ///   | pre-fee contract                                     | 2591 |     — |
    ///   | + the protocol fee accrual and its two storage guards | 3332 |  +741 |
    ///   | + the anti-snipe mechanic WITH a minimum raise step   | 4095 |  +763 |
    ///   | − the minimum raise step (SHIPPED)                    | 3844 |  −251 |
    ///
    /// So the rolling window costs 512 gas units per accepted bid over the pre-extension 3332,
    /// and dropping the raise step gave 251 of them back. The CLAIM path is untouched by both:
    /// 7581 with a fee message and 5723 without, unchanged to the unit.
    extensionWindow: uint32 = DEFAULT_EXTENSION_WINDOW
}

fun Storage.load(): Storage {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self) {
    contract.setData(self.toCell());
}

/// Incoming: place a bid, the attached value is the bid.
struct (0x70626964) PlaceBid {
    queryId: uint64
}

/// Incoming: pay the whole pool out to the stored leader. Callable by anyone.
struct (0x70636c6d) ClaimPrize {
    queryId: uint64
}

/// Outgoing only (carried by the payout message, never accepted as input), so that
/// indexers, dApps and `onBouncedMessage` can recognise the prize transfer.
struct (0x70706169) PrizePaid {
    queryId: uint64
    winner: address
    poolAmount: coins
}

/// Outgoing only (carried by the fee message, never accepted as input), so that indexers, dApps
/// and `onBouncedMessage` can tell the fee transfer apart from the prize transfer. Emitted at
/// most once per round, and only when the PAYABLE fee is above zero.
///
/// The message carrying it is sent NON-BOUNCEABLE (`BounceMode.NoBounce`) with
/// `SEND_MODE_PAY_FEES_SEPARATELY`. A fee collector is by construction an account that has never
/// SENT anything, so on chain it is `uninitialized`, and TON bounces a bounceable message to such
/// an account straight back — which, after `paidOut` is latched, stranded the whole fee in the
/// pool forever. Non-bounceable delivery creates the recipient account and credits it instead.
/// The trade: a recipient CONTRACT that throws on this opcode now keeps the coins rather than
/// returning them. See "The fee must reach an uninitialized recipient" in README.md.
struct (0x70666565) FeePaid {
    queryId: uint64
    recipient: address
    feeAmount: coins
}

/// Aggregate get-method reply; the first eight fields mirror `Storage`, the rest is what a UI
/// needs to render the round in ONE call instead of five.
struct PoolState {
    deadline: uint32
    leader: address?
    bestBid: coins
    poolAmount: coins
    paidOut: bool
    feeRecipient: address
    feeBps: uint16
    feeAccrued: coins
    /// Seconds an accepted bid adds to the clock, straight out of storage.
    extensionWindow: uint32
    /// `deadline - now()`, clamped at 0 — the countdown itself, computed against the CHAIN's
    /// clock rather than the browser's, so a dApp does not have to trust (or correct) the
    /// user's device to say "4:32 left". Zero means the round is over and `ClaimPrize` is the
    /// next move.
    secondsLeft: uint32
    /// The smallest value a bid must carry right now to be accepted: `minimumBidAfter(bestBid)`,
    /// i.e. `MIN_BID` while nobody has bid and `bestBid + 1` nanoton once there is a leader.
    /// A UI that pre-fills its input with this number always offers a winning bid.
    minimumNextBid: coins
}
