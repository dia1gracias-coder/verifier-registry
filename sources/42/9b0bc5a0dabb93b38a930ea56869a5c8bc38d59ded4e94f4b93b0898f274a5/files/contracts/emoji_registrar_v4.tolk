// Emoji Name Service — Registrar v4
//   v3 + singles-by-auction release policy + AdminMint (July 23 decisions)
//
// Emojiverse · Emoji Name Service on TON
//   Website : https://emojiverse.xyz
//   X       : https://x.com/emojiverse_xyz
//   Zone    : emojiverse.ton   ·   Publisher: Hyperborea LLC
//
// SINGLES POLICY (reversed July 23):
//   - 33 curated singles stay RESERVED (foundation / emojicoin bridge).
//   - ALL other singles are a LOCKED POOL. They are never publicly registrable
//     — not at launch, not after a lapse. The only doors into a single are:
//       (a) an admin-run English AUCTION drop, or (b) AdminMint.
//     This kills the launch-day bot race and preserves singles as staged,
//     price-anchored drop events (Fragment's staged-wave playbook).
//   - Lapsed singles RETURN to the locked pool after grace (spec decision 2).
//   - Singles renewal is a flat 50 GRAM/yr (RENEW_1; the ½-rule does not apply).
//     V7-34: this header said 10 GRAM. It is the one number an auction bidder
//     underwrites a 150 GRAM reserve against, and it was wrong by 5x inside the
//     deployed artifact's own policy statement.
//
// AUCTION (spec decision 1): lives INSIDE the registrar so settlement is atomic
// — the winning bid, the name record, the NFT mint and the resolver sync all
// happen in one message. No new trust boundary, no escrow contract holding
// third-party assets. Note this is a PRIMARY sale of project inventory, which is
// a different posture from operating a secondary marketplace.
//
// ADMINMINT: free promotional/partnership mints, any tier, 1-5yr or permanent.
// Still requires signer attestation (spec decision 3) so the canonical
// normalization invariant holds for every record in the registry.
// TON / GRAM · Tolk 1.4.2
//
// v2 supersedes the standalone registrar. Adds:
//   - NFT layer wiring: mints a TEP-62 item on registration, pushes expiry on
//     renewal, receives OwnerSynced when an item transfers (NFT is the single
//     authoritative ownership path post-mint; legacy direct transfer removed).
//   - Multi-resolver sync: a SET of resolver addresses, each receiving
//     SyncNameOwner (bind owner + wipe records) on register / re-register /
//     transfer. Supports running resolver v2 + a future v3 in parallel and
//     gradual migration (business decision #4: flexibility in resolvers).
//   - Bounded admin-adjustable first-year pricing (decision #1): admin may set
//     first-year price per tier within hardcoded [floor, ceiling]; renewal
//     prices are immutable constants (holders' carrying cost can never rise).
//   - Reserved-vs-premium singles (decision #3): 33 admin-curated singles are
//     reserved (foundation-held, note "Reserved for a Emojiverse Expansion",
//     non-registrable/non-renewable). All OTHER singles are publicly
//     registrable at 75 GRAM first / 10 GRAM renewal.
//   - Content attestation (decision #2): the signer additionally attests the
//     item content cell, so the displayed emoji string can't diverge from the
//     hashed one.
//
// Trust/ops note: admin ops (pricing, resolver set, fee destination, signer,
// reservations) should be wrapped by a multisig + timelock on MAINNET. That is
// an ops-layer decision left to deployment; the contract keeps admin as a
// single address for test flexibility and documents where the wrap belongs.

tolk 1.4.2

// ---------- commit-reveal ----------
// Public registration is TWO steps to defeat mempool front-running (ENS model):
//   1. Commit  — submit commitmentHash = H(nameHash ‖ salt ‖ committer). Reveals
//                nothing about the name. Stored with its block timestamp.
//   2. Reveal  — submit (nameHash, salt, ...register args). Contract recomputes
//                the commitment from the SENDER address and checks it exists,
//                is older than commitMinDelay, and younger than commitMaxAge.
// A front-runner watching the reveal can't reuse it: the commitment is bound to
// the committer's address, and racing a fresh commit resets their delay clock.
// Direct one-step registration is REMOVED — every public registration is protected.

// ---------- constants ----------

const YEAR: int  = 31536000;   // 365 days
const GRACE: int = 7776000;    // 90 days (ENS parity)
const MAX_YEARS: int = 5;
// F-2: maximum TOTAL term any name may hold, measured from now. Renewal may
// extend up to this horizon and no further, so the 2-7 tiers can never be
// converted into de-facto permanence by repeated renewal.
const MAX_TOTAL_TERM: int = 315360000;   // 10 years

// commit-reveal timing (admin-set within [floor, ceiling])
const COMMIT_MIN_DELAY_FLOOR: int = 60;        // 1 min — front-runner reaction window ceiling
const COMMIT_MIN_DELAY_CEIL: int  = 3600;      // 1 hour
const COMMIT_MAX_AGE_FLOOR: int   = 3600;      // 1 hour
const COMMIT_MAX_AGE_CEIL: int    = 604800;    // 7 days
// R17-25: the DERIVED window, which is the thing a registrant actually needs and
// the thing neither bound above constrains. See SetCommitTiming.
const COMMIT_WINDOW_MIN: int      = 900;       // 15 min between "may reveal" and "too late"

// admin-transfer timelock (two-step handover; the window to catch a stolen-key
// takeover). Admin-configurable within [floor, ceiling].
const ADMIN_TIMELOCK_FLOOR: int   = 0;         // 0 = expedited (planned live sale)
const ADMIN_TIMELOCK_CEIL: int    = 2592000;   // 30 days

// R14B1-9. THE ONE DEFAULT_* CONSTANT THAT IS BEHAVIOUR, NOT DOCUMENTATION.
//
// (The note directly below applies to the others; this one is READ, by
// `AcceptAdminTransfer`. See the long comment there for the finding.) 48 hours is
// the same figure the deploy wrapper writes at genesis
// (wrappers/EmojiRegistrarV4.ts DEFAULT_ADMIN_TIMELOCK) and the same figure the
// NFT collection uses for HANDOVER_TIMELOCK, so a successor lands on the value
// the whole system is documented around rather than on whatever their
// predecessor left behind.
const DEFAULT_ADMIN_TIMELOCK: int = 172800;    // 48h

// NOTE ON DEFAULT_* CONSTANTS BELOW
// They are documentation, not behaviour: initial values are written by the
// deploy wrapper into storage, not read from here. Kept deliberately so the
// intended launch configuration is legible in the contract an auditor reads.
//
// contract version (bump on any deployed logic change; surfaced via version())
const CONTRACT_VERSION: int = 4;

// --- singles auction (dns.ton.org conventions, per July 23 decisions) ---
const MIN_RAISE_BPS: int       = 500;      // each bid must beat the high by +5%

// SOFT CLOSE: every bid guarantees at least one more hour of bidding. The lot
// therefore runs its base window from the first bid, and can never close less
// than BID_EXTENSION after the most recent bid — so a snipe in the closing
// seconds always reopens the floor to the underbidder.
const BID_EXTENSION: int        = 3600;     // 1 hour guaranteed after ANY bid
const AUCTION_MIN_DURATION: int = 21600;   // 6 hours
const AUCTION_MAX_DURATION: int = 2592000; // 30 days
const AUCTION_SETTLE_VALUE: int = 50000000; // 0.05 GRAM headroom on settle
// R10-2: raised 0.03 -> 0.05. At mainnet gas (400 nanoton/gas, vs the sandbox's
// 66.67) the old floor bought 75,000 gas against a measured worst-case settle of
// 42,150 — a 1.78x margin, the thinnest of any per-hop budget here, on a
// PERMISSIONLESS op whose floor is a published interface that can never be raised
// after launch. 0.05 buys 125,000 gas (~3x) and is the figure the V7-16 comment
// and the integrator docs already quote.

// R10-2. THE COMPUTE BUDGET THE ADMIN ISSUANCE PATHS NEVER RESERVED.
//
// On TON the compute-phase gas limit is bought with the INCOMING MESSAGE VALUE,
// not the account balance. AdminMint/AdminImport asserted only
// `opsBudgetRegister(...)` = 0.144 GRAM, which budgets OUTGOING message value and
// nothing else — while `assertCanonicalName` walks the name at ~3,215 gas/byte.
//
// Measured at mainnet gas, funded at exactly 0.144 (a 360,000-gas ceiling):
//     83-byte name -> 359,436 gas   minted, with 564 gas of margin (0.16%)
//     91-byte name -> exit -14, name NOT issued
//    100-byte name -> exit -14, name NOT issued
// The whole registry is migrated through AdminImport (MIGRATION_RUNBOOK phase C),
// so a batch funded at the contract's own stated minimum silently drops every long
// name in the snapshot. Invisible for nine rounds because the sandbox's fee
// schedule is 6x cheaper than mainnet's, giving these paths 2.16M gas instead.
//
// 0.3 GRAM buys 750,000 gas — 1.77x the measured 111-byte worst case of 424,566.
// Admin-only paths, and the excess stays with the registrar, so this costs nothing.
const ADMIN_COMPUTE_BUDGET: int = 300000000;   // 0.3 GRAM

// Permanent reserve for every singles lot. Admin may set a HIGHER start bid for
// a blue-chip, never a lower one — the floor is immutable, so no future admin
// can quietly dump the singles inventory.
const MIN_AUCTION_START_BID: int = 150000000000;   // 150 GRAM
const BID_REFUND_DUST: int      = 10000000;

// AdminMint: 0 years = permanent (never expires)
// Shared sentinel. Both the registrar and the NFT item treat this as
// "effectively never expires" — it is uint32 max (Feb 2106), the furthest a
// 32-bit timestamp reaches. The AUTHORITATIVE marker is NameRecord.isPermanent;
// this timestamp is defence in depth so that even a missed guard cannot expire
// a permanent name this century.
const PERMANENT_EXPIRY: int = 0xFFFFFFFF;

// R15-9. THE LAST FINITE SECOND, AND WHY IT NEEDS A NAME.
//
// `expiresAt` is a uint32, so any computed term above 0xFFFFFFFF is a raw TVM
// range check — exit 5, aborted, uncatalogued — on a PAID transaction. Measured:
// at `now = 4137287296` a 5-year renewal on a 50 GRAM payment is exit 5 and the
// holder loses the gas. `RenewName`'s F-2 bound does NOT catch it: `nowTime +
// MAX_TOTAL_TERM` is 4,452,647,296 there, comfortably above the value that
// overflows, so the domain error its comment promises never fires.
//
// One below the sentinel, deliberately: 0xFFFFFFFF means PERMANENT, and a finite
// term that happened to land exactly on it would be indistinguishable from a name
// the contract guarantees can never lapse.
const EXPIRY_HORIZON: int = 0xFFFFFFFE;   // 2106-02-07T06:28:14Z

// Permanent upgrade, offered ONLY on single-emoji names (auction winners).
// Admin-adjustable within bounds, like every other first-party price.
const PERMANENT_PRICE_FLOOR: int   = 250000000000;   //   250 GRAM (1,000 / 4)
const PERMANENT_PRICE_CEIL: int    = 4000000000000;  // 4,000 GRAM (1,000 x 4)

// NAMESPACE LENGTH CAP — fixed at deploy, no setter, no lock op.
// 7 emoji maximum from launch. Deliberately immutable: an adjustable cap meant
// a user could not know what the namespace was, and a lockable one still left
// the question open. One number, forever, is simpler to explain and a stronger
// commitment than any amount of admin machinery.
const MAX_EMOJI_COUNT: int = 7;

// F-9: TEP-81 caps the WHOLE internal representation of a domain at 127 bytes
// ("ton\0emojiverse\0<label>\0"). The emoji count alone does not bound this —
// seven family-ZWJ sequences are 175 bytes and could never be resolved by any
// client. A name is refused at issuance rather than minted into an unresolvable
// state.
//
// R24-3. THE DERIVATION WAS ONE BYTE SHORT: IT FORGOT THE SELF BYTE.
//
// The old budget was `127 - len("ton\0emojiverse\0") - len("\0") = 111`, which
// accounts for the parent, the label and the trailing separator — but NOT the
// leading "\0" that TEP-81 calls the self byte and that every root-walking
// client prepends. The real query is:
//
//   "\0" + "ton\0" + "emojiverse\0" + "<label>" + "\0"
//     1  +   4     +      11        +     N     +   1     = 17 + N
//
// and a byte-aligned cell holds 127 bytes, so N <= 110. At N = 111 the query is
// 128 bytes = 1024 bits and THE CLIENT CANNOT EVEN BUILD THE CELL — tonweb
// throws `BitString overflow` before anything is sent. So a 111-byte name was
// registrable, mintable and permanently unresolvable from the config-#4 root.
//
// Why the guard that should have caught it does not: tonweb and MyTonWallet
// prepend the self byte only `if (rawDomain.length < 126)` — and `length` is
// UTF-16 CODE UNITS, a guard written for ASCII. An emoji label is roughly two
// units per four bytes, so a 111-byte label measures ~55 units, the guard reads
// ~71 < 126, and the self byte goes on anyway. The accommodation that exists to
// prevent this overflow is exactly what causes it for us.
//
// This is not hypothetical elsewhere: `.ton` has the same class of bug at its
// own cap — its 126-byte names are registrable but root-relative resolution is
// impossible above 121 characters. We can simply not have it. Nothing is
// deployed, so the cost is a one-byte sliver of a namespace whose widest single
// unit is 42 bytes; the benefit is that EVERY legal name resolves from EVERY
// path, including the two shorter zone labels:
//
//   "\0ton\0emojiverse\0<110>\0"   = 127  <= 127  ok  (root -> .ton -> parent)
//   "\0emoji\0<110>\0"             = 118  <= 127  ok  (zone-walking clients)
//   "\0emj\0<110>\0"               = 116  <= 127  ok  (the R23 alias)
//   "\0<110>\0"                    = 112  <= 127  ok  (suffix-stripping clients)
const MAX_NAME_BYTES: int = 110;

// R20-6. THE URI SUFFIX IS A BOUNDED TEP-64 SNAKE CHAIN.
//
// A cell holds 1023 bits, so a byte-aligned payload caps at 127 bytes = 1016
// bits. Full percent-encoding is 3 bytes for every byte >= 0x80 (plus `#`/`?`),
// so `MAX_NAME_BYTES` produces at most 333 bytes and the worst name actually in
// the frozen table — 🏴󠁧󠁢󠁥󠁮󠁧󠁿🏴󠁧󠁢󠁳󠁣󠁴󠁿🏴󠁧󠁢󠁷󠁬󠁳󠁿, three tag-sequence flags at 84 raw bytes —
// produces 252. Three cells is 381: it covers the whole reachable space with one
// cell to spare and makes a fourth UNREACHABLE rather than merely unused, which
// is what lets `checkUriSuffix` bound its walk without ever refusing a name.
const URI_CELL_BITS: int  = 1016;      // 127 bytes, the byte-aligned cell ceiling
const URI_MAX_CELLS: int  = 3;         // 381 bytes >= 333 = MAX_NAME_BYTES fully encoded

// R15-1: the largest sync nonce an import may carry. See AdminImport.
const MAX_IMPORT_SYNC_NONCE: int = 1000000;

// R24-6. How long an UNBID lot blocks its name before anyone may free it.
// 30 days = AUCTION_MAX_DURATION, so a lot always gets at least as long to
// attract its first bid as the longest competitive window it could ever run —
// the reclaim can never cut short a listing that was going to work.
const UNBID_RECLAIM_WINDOW: int = 2592000;

// R17-5 (MEDIUM). A HARD CAPACITY WALL WHERE `Commit` FAILS *SILENTLY*.
//
// TON's config param 43 caps an account at `max_acc_state_cells = 65,536`. This
// registrar measures 281 cells wired and empty, and 2.000 cells per registered
// name, so the wall is at
//
//     (65,536 - 281) / 2 = 32,627 names
//
// and `st.names` has no delete anywhere in this contract, so the wall NEVER
// recedes. Past it the failure is in the ACTION phase, which is the part nothing
// can catch: a 0.1 GRAM `Commit` measures `exit 0, aborted=true,
// actionSuccess=false, actionCode 50, sent 0` — no `RejectedRefund`, so the front
// end sees a successful transaction, and the committer is out their deposit.
// `isAvailable()` still answers `true` for every unregistered name.
//
// A soft cap 627 names below the wall converts that into an ordinary, legible
// refusal with the money returned. 627 names is ~1,254 cells of margin, which is
// also what keeps CONCURRENT COMMITMENTS from reaching the wall on their own —
// they cost ~2 cells each and are only reclaimed by SweepCommitment.
//
// It is a cap on ISSUANCE, not on the registry: renewals, transfers, permanents,
// auctions and every read keep working at the cap, and the documented answer is
// the v5 migration `AdminImport` exists for. R11-1 records the scaling decision;
// this failure MODE was documented nowhere.
const NAMES_SOFT_CAP: int = 32000;

// R24-5 (HIGH, operability). THE SOFT CAP COUNTED THE WRONG THING.
//
// ===========================================================================
// WHY A NAME COUNT CANNOT BE THE GUARD
// ===========================================================================
// The derivation above reserves "627 names ~ 1,254 cells of margin, which is
// also what keeps CONCURRENT COMMITMENTS from reaching the wall on their own".
// That margin is shared between two populations with completely different
// controllers, and only one of them is counted:
//
//   names        grow only through a PAID issuance, are counted by
//                `totalNames`, and never shrink.
//   commitments  cost 0.05 GRAM, are permissionless, live for `commitMaxAge`
//                (up to 7 days), measure ~2.000 cells each — and were counted
//                by nothing at all.
//
// So at the cap the account holds 64,281 cells and roughly 627 concurrent
// unswept commitments put it over 65,536. That is ordinary launch-day traffic,
// or about 31 GRAM of deliberate spam. Past the wall EVERY state write fails in
// the action phase with code 50 — including, as R14-2 records, "the admin ops
// the operator would use to respond". `names` cannot shrink, so the only lever
// back under the ceiling is `SweepCommitment`, itself rate-limited by
// `commitMaxAge`.
//
// A static name cap cannot express this, because the quantity that matters is
// not names — it is CELLS, and cells are a function of three populations that
// move independently.
//
// ===========================================================================
// THE GUARD: MEASURE THE ACTUAL BUDGET, O(1)
// ===========================================================================
// Every population is already counted or is cheap to count (`totalNames`,
// `liveLots`, and R24-5's new `liveCommitments`), and each has a MEASURED
// per-entry cell cost. So the account's cell footprint is an arithmetic
// expression over three integers — no dict walk, no `calculateSize` over 60,000
// cells on the hot path, constant gas at any registry size.
//
// This is strictly more fault-resistant than lowering the static cap would be:
//   * it adapts to the REAL composition rather than to a guess about it, so a
//     commitment surge is refused before it reaches the wall instead of
//     silently consuming the names' margin;
//   * it does not shrink the sellable namespace to buy that safety;
//   * the failure is a legible refusal with the money returned, at the exact
//     point the budget is actually threatened, rather than an action-phase 50
//     that also disables the recovery ops.
//
// WHICH BOUND ACTUALLY BINDS, STATED HONESTLY. `hasStateHeadroom` is
//
//   STATE_BASE_CELLS + 2*N + 2*C + 6*L + CELLS_PER_NAME <= STATE_CELL_CEILING
//
// so it closes at 2N + 2C + 6L = 60,414, i.e. at **N + C + 3L = 30,207**. A lot
// is worth THREE name-slots of headroom after R25-1, not one.
//
// WITH NO COMMITMENTS AND NO LOTS THAT IS STILL EXACTLY 30,207 NAMES
// (1,024 + 2*30,207 + 2 = 61,440 exactly) — 1,793 below `NAMES_SOFT_CAP` and
// 2,420 below the measured 32,627 wall. R25-1 raised `CELLS_PER_LOT` and
// deliberately did NOT move the public cap: the lot term is multiplied by
// `st.liveLots`, which is 0 on the path that sells names, so the number the
// business plan rests on is untouched and only the lot exchange rate changed.
// Pinned by `audit/round25/R25_1_cells_per_lot.spec.ts`.
//
// So on `Commit` the cell guard is the ONLY bound that can fire and the name cap
// is dead there; an earlier draft of this note claimed the two were independent
// backstops for each other, which is false for that op and is corrected here
// rather than quietly left standing.
//
// `NAMES_SOFT_CAP` remains live, and is the SOLE guard, on `AdminMint` and
// `AdminImport` — the admin doors, which are deliberately outside the cell guard
// so that recovery and migration are never blocked by the same condition they
// exist to resolve. That asymmetry is the design: a bound that stops issuance
// must never be able to stop repair.
//
// Measured with @ton/core over sha256-distributed keys: names 2.000 cells,
// commitments 2.000, and 281 cells wired-and-empty.
const CELLS_PER_NAME: int       = 2;
const CELLS_PER_COMMITMENT: int = 2;
// R25-1 (MEDIUM). A LOT IS NOT A NAME, BECAUSE A LOT CARRIES REFS.
//
// This was 2, copied from the other two populations. `names` and `commitments`
// are ref-free dict values, so 2.000 cells each is exact for them. `Auction` is
// not: `content` and `label` are REF fields and are PER-LOT UNIQUE, so they
// cannot be shared between leaves the way a repeated value would be. Measured on
// this build by walking the real account state after each listing:
//
//   1-emoji lot (4 raw bytes, 1-cell URI)     3 cells for the first, 4 after
//   longest legal lot (100 raw bytes, 7 units) 6 cells, twice, on two hashes
//
// which is 3.5-6.0 across the reachable range and was reproduced on a second,
// independent rig. So the old 2 UNDER-counted by up to 4 cells per lot — the
// exact opposite of the "deliberately an OVER-estimate" doctrine written on
// `estimatedStateCells` below, and blind on the only one of the three counted
// populations that carries refs at all.
//
// 6 IS BOUNDED BY CONSTRUCTION, NOT BY MEASUREMENT — which is why it is the
// right number to freeze into immutable code. A lot's cell footprint is
//
//   1 dict fork node + 1 dict leaf + `URI_MAX_CELLS` (3, and `checkUriShape`
//   refuses a 4th) + 1 `label` cell (bounded by MAX_NAME_BYTES = 110 < 127)
//
// = 6, and no reachable input can exceed it. The measured 6 is that bound being
// hit, not a sample that happened to be the largest one tried.
const CELLS_PER_LOT: int        = 6;
// The wired-and-empty floor plus room for everything that is NOT one of the
// three counted populations and can still move: `resolvers` (<=3),
// `referrerRates`, `partners` (<=4), `prices`, `aux`, the staged-handover slots,
// and the outbound action list. Rounded up hard — this reserve is the whole
// safety margin, and it costs nothing until the registry is enormous.
//
// R25-8 (LOW). ONE OF THOSE IS UNBOUNDED, AND THIS IS THE NUMBER AT WHICH THAT
// MATTERS. `referrerRates` is a map with no cap, grown one entry at a time by
// `SetReferrerRate`. Re-measured on this build in
// audit/round25/R25C_state_base.spec.ts:
//
//   wired and empty                 304 cells (the "281" above was stale)
//   spare inside this reserve       720 cells
//   one KOL override                1.992 cells, dead flat from 20 to 120
//   overrides that fit              361
//
// Past 361 the estimate under-reports by ~2 cells each — but the estimate is
// not the wall. `STATE_CELL_CEILING` refuses issuance 4,096 cells BELOW config
// 43's `max_acc_state_cells`, so the under-report has to eat that entire gap
// before anything real breaks: 361 + 4,096/1.992 = **2,417 overrides**. At a
// thousand it has consumed 31% of the gap and the guard is still refusing
// ~2,800 cells early.
//
// LEFT UNCOUNTED, DELIBERATELY. R24-5 gave `commitments` a `liveCommitments`
// counter maintained at three sites; the same discipline was considered here and
// rejected, because the two populations are not alike in the way that matters:
//
//   commitments     PERMISSIONLESS, 0.05 GRAM each, up to 7 days, counted by
//                   nothing — a stranger could move the number faster than an
//                   operator could watch it.
//   referrerRates   ADMIN-ONLY, one signed message per entry, and REVERSIBLE:
//                   `RemoveReferrerRate` returns every cell (measured, 304 ->
//                   383 -> 304 across 40 add/remove pairs).
//
// A counter here would add three more mutation sites — three more places for the
// drift R24-5's own counter exists to prevent — to defend a number an admin has
// to type 2,417 times, on a path that undoes itself. The proportionate answer is
// this paragraph: **`referrerRates` is assumed to stay under ~360 entries, and
// `stateBudget()` is the instrument that says otherwise.** Its `used` field is
// this constant plus the three counted terms, so an operator comparing it with
// the account's real cell count sees the reserve being consumed years before it
// binds. If a KOL program ever genuinely needs thousands of individually
// negotiated rates, the answer is a tier lookup, not a per-address map.
const STATE_BASE_CELLS: int     = 1024;
// TON config param 43, `max_acc_state_cells`.
const MAX_ACC_STATE_CELLS: int  = 65536;
// The refusal point. 4,096 cells below the wall is ~2,048 further names OR
// ~2,048 further commitments of headroom AFTER the guard starts refusing — which
// is what keeps renewals, transfers, settlements, sweeps and every admin op
// working past the point where new issuance stops. The guard bounds ISSUANCE;
// it must never be able to bound RECOVERY.
const STATE_CELL_CEILING: int   = 61440;   // 65,536 - 4,096

/// R24-5. Estimated account-state cells, O(1) in the registry size.
///
/// An ESTIMATE by construction, and deliberately an OVER-estimate: every term is
/// a worst case and the base is rounded up from 281 to 1,024. Erring high means
/// the guard closes early, which costs a sliver of namespace; erring low would
/// mean it closes late, which costs the contract its ability to respond. Only
/// one of those is recoverable.
///
/// R25-1 — AND THE DOCTRINE HELD ON TWO TERMS OUT OF THREE, WHICH IS THE LESSON.
/// The paragraph above shipped saying "every term is a MEASURED worst case".
/// It was not: `CELLS_PER_LOT` was 2, an assumption carried over from the two
/// ref-free populations rather than a measurement of the one population that
/// holds refs, and it under-counted a full lot by up to 4 cells. A stated
/// doctrine does not enforce itself. Each term is now a worst case that is
/// bounded by CONSTRUCTION — 2 by the dict shape for a ref-free value, 6 by
/// `URI_MAX_CELLS` + `MAX_NAME_BYTES` for a lot — so a future field added to
/// `Auction` has to move a number here for the arithmetic to keep holding.
fun estimatedStateCells(st: Storage): int {
    return STATE_BASE_CELLS
         + CELLS_PER_NAME * (st.totalNames as int)
         + CELLS_PER_COMMITMENT * (st.auxData().liveCommitments as int)
         + CELLS_PER_LOT * (st.liveLots as int);
}

/// True while the account has room to grow by one more entry.
fun hasStateHeadroom(st: Storage): bool {
    return estimatedStateCells(st) + CELLS_PER_NAME <= STATE_CELL_CEILING;
}

// Outbid refunds carry an opcode so a bidder's wallet/indexer can label the
// incoming payment instead of showing an unexplained transfer. Mirrors TON DNS's
// op::outbid_notification.

// ---- NORMALIZATION POLICY (PERMANENT, no setter exists) ----
// Skin-tone modifiers U+1F3FB..U+1F3FF encode in UTF-8 as F0 9F 8F BB..BF.
// Every issuance path proves the raw name bytes hash to nameHash, then scans
// them for that sequence and REJECTS. Because this is enforced in TVM (not by
// the off-chain signer), a compromised or malicious signer still cannot mint a
// skin-toned name. There is deliberately NO admin op to disable this.
//   policy id 1 = "skin-tone collapsed; ZWJ sequences remain distinct"
const NORMALIZATION_POLICY: int = 1;
const SKINTONE_B0: int = 0xF0;
const SKINTONE_B1: int = 0x9F;
const SKINTONE_B2: int = 0x8F;
const SKINTONE_LO: int = 0xBB;
const SKINTONE_HI: int = 0xBF;

// referral/affiliate: a bounded share of the LICENSE FEE paid to a referrer at
// registration. Basis points (1/10000). Admin-set within [0, ceiling].
const REFERRAL_BPS_CEIL: int      = 2000;      // public referral max 20%
const REFERRAL_KOL_BPS_CEIL: int  = 3300;
// Partner revenue share: a standing cut of every name sale paid to one address,
// for ecosystem integration deals. Bounded so that even at the maximum KOL
// referral (33%) the combined outflow stays well under the fee.
// Partner revenue share. Up to MAX_PARTNERS ecosystem partners may hold a
// standing cut, and their COMBINED share is capped. Both bounds are immutable,
// so no admin can add partners until the fee is consumed, and the per-sale gas
// cost cannot grow without limit.
const PARTNER_BPS_CEIL: int  = 3000;      // 30% COMBINED across all partners
const MAX_PARTNERS: int      = 4;      // per-address KOL override max 33% (absolute hard cap)
const BPS_DENOM: int              = 10000;

const REFUND_DUST: int = 10000000;      // 0.01 GRAM
// R17-10 (MEDIUM). 0.05 GRAM WAS SIZED AGAINST *ONE* PARAM-18 ROW, AND THE
// REGISTRAR FROZE INSIDE ITS OWN OPERATING PROCEDURE.
//
// Param 18 still ships BOTH rows in the live config dictionary and has already
// moved once: `utime 0 -> bit_price 1 / cell_price 500` and
// `utime 1777500000 -> bit_price 0 / cell_price 135`. A revert to the older row
// is a 5.85x increase, not the ~2x the reserve comments claimed to absorb.
//
// Measured account state x the price table read from the config dictionary, on
// the PESSIMISTIC row (bit 1 / cell 500), following MIGRATION_RUNBOOK step 4 as
// written — "withdraw only freeBalance()" — and then going quiet:
//
//     registrar, n=0        rent 0.132483 GRAM/yr   FROZEN in 413 days
//     registrar, n=1,000    rent 0.904868 GRAM/yr   FROZEN in 706 days
//     registrar, n=32,000   rent 24.778758 GRAM/yr  FROZEN in 756 days
//
// and frozen is not a state you top up out of: a 50 GRAM transfer to the frozen
// account did NOT revive it — every get method throws and every name in the
// registry becomes unresolvable and unrenewable.
//
// 0.15 GRAM buys 1.13 years of the n=0 row on its own and, combined with the
// per-name term below, moves the n=32,000 case past a decade. It is a RESERVE,
// not a fee: it changes no user-visible price, only how much of its own balance
// the contract refuses to let the admin take.
const MIN_STORAGE: int = 150000000;     // 0.15 GRAM rent buffer (R17-10, was 0.05)

// V7-1: MIN_STORAGE alone was NOT a sufficient withdrawal reserve. Every inbound
// OwnerSynced (an NFT transfer) obliges this contract to fan out SYNC_VALUE per
// resolver, funded only by the item's fixed NOTIFY_VALUE. From two resolvers up
// the contract subsidises each transfer from its own balance, and freeBalance()
// knew nothing about it — so withdrawing exactly what freeBalance() sanctioned
// left the registrar unable to follow its own NFTs. Reserve a burst of transfers
// on top of the rent floor.
const SYNC_RESERVE_TRANSFERS: int = 16;

// V7-16: the resolver set was UNBOUNDED, and every resolver adds a message to
// the fan-out plus an iteration to countResolvers(). Past a few hundred, a
// SettleAuction could no longer complete — it exceeds TVM's 255-action limit and
// the gas the settle value can buy — while CancelAuction still refuses any lot
// that holds a bid, "so as never to strand a bidder". The two together stranded
// the bidder's >=150 GRAM permanently, with no op able to release it.
//
// This also closes the open item in AUDIT_CHANGELOG ("two admin-controlled loops
// have no ceiling ... document a working limit") with a bound rather than a
// document. MAX_PARTNERS is 4; there is no reason for resolvers to be unbounded
// when the design case is "v2 and a future v3 in parallel".
// V7-1b: this must be consistent with the NFT item's NOTIFY_VALUE floor, which
// is what funds the fan-out. At 8 the two disagreed: the item's minimum funded
// ONE resolver while this allowed eight, so a legitimate sale at the item's own
// asserted minimum left 6 of 8 resolvers still answering with the SELLER — and
// IGNORE_ERRORS made that silent (exit 0). 3 is the stated design case ("v2 and
// a future v3 in parallel") and the item's floor is now sized to fund it.
const MAX_RESOLVERS: int = 3;

// commit anti-spam floor (V7-11). Commit is permissionless and every commitment
// is a permanent map entry this contract pays rent on until it is swept.
// FRONTEND_TOUCHPOINTS documented 0.1 GRAM; nothing enforced it.
//
// R14-2 (HIGH, availability). COMMITMENT BLOAT CLOSED REGISTRATIONS FOR EVERYONE,
// AND `totalNames()` NEVER MOVED WHILE IT HAPPENED.
//
// A commitment is 2 cells of account state — exactly what a NAME costs — and it
// was priced at 0.02 GRAM against a name's 1.5 GRAM floor. A 75x discount on the
// one resource in this system that is genuinely finite: TON caps an account at
// 65,536 cells, and tests/R11Scale.spec.ts measured what happens on the far side
// of it. Every STATE-WRITING message aborts in the ACTION phase with result code
// 50 — not the compute phase, so the exit code still reads 0 — and that is
// registrations, renewals, MakePermanent, auction settlement and every admin op
// alike. Measured fill cost at the old floor: ~721 GRAM, one-off, permissionless,
// and invisible to any monitor watching `totalNames()` because no name is created.
//
// TWO CHANGES, AND THE SECOND IS THE IMPORTANT ONE.
//
// 1. This floor rises 0.02 -> 0.05. It lifts the one-off fill cost to ~1,704 GRAM
//    and is invisible to an honest buyer, who is about to spend between 1.5 and
//    110 GRAM on the very next message. It also widens the gap over SWEEP_BOUNTY,
//    so the bounty can be sized against MAINNET gas with room to spare — the
//    property that has to survive a gas-price change.
//
// 2. Sweeping now PAYS (see SWEEP_BOUNTY). That is what turns the attack from a
//    one-off purchase into a rent: `SweepCommitment` already existed and was
//    already permissionless, but it paid nothing, so in practice nobody ran it
//    and the cells sat there forever. With a bounty, every commitment becomes
//    profitably removable the moment it passes `commitMaxAge`, so an attacker
//    must re-buy the entire fill every window, indefinitely, against sweepers who
//    are now paid to undo it. At the 24h default that is ~1,704 GRAM/day; with
//    the operational lever already available (`SetCommitTiming` to the 1h floor)
//    it is ~1,704 GRAM/hour.
//
// The floor is also the Commit handler's GAS CEILING — value buys gas at 400
// nanoton/gas — so raising it moves 50,000 gas to 125,000 against a measured
// handler cost of 4,746. Headroom, not exposure.
const COMMIT_MIN_VALUE: int = 50000000;   // 0.05 GRAM

// R14-2. THE BOUNTY THAT MAKES CLEANUP AUTOMATIC RATHER THAN ASPIRATIONAL.
//
// Paid to whoever sweeps an expired commitment, out of the balance the swept
// commitment itself put there: `Commit` asserts >= COMMIT_MIN_VALUE, and this is
// strictly less than COMMIT_MIN_VALUE, so the payout can never exceed the deposit
// BY CONSTRUCTION rather than by a runtime comparison. The contract keeps the
// remaining 0.04, comfortably more than the rent it paid to hold the two cells.
//
// SIZED AGAINST THE EXPENSIVE ROW, WHICH IS NOT THE ONE MAINNET RUNS.
//
// R25 CORRECTION — THIS PARAGRAPH HAD BOTH SIDES BACKWARDS. It read "the sandbox
// runs at 1/6 of mainnet's 400 nanoton/gas". R23 established the opposite:
// basechain gas has been **66.667 nanoton/gas since 2026-04-29** (config 21,
// fetched and decoded, a clean 6x cut) and it is this repo's own TEST HARNESS
// that is pinned at 400. The sandbox therefore runs the CHEAP row unless a spec
// asks for `legacyFees()`, and "measured on the mainnet schedule" below means the
// pessimistic PRE-cut row, not what mainnet charges today.
//
// SIZING IS UNAFFECTED, AND THAT IS DELIBERATE RATHER THAN LUCKY: every constant
// in this file was re-derived by R23 against the pessimistic row precisely
// because the contracts are immutable and a 6x rise is one config vote away. So
// the numbers below stand as worst-case figures; what was wrong was the story
// told about which machine charges which. See `tests/_chainfees.ts`, which now
// carries both rows with their provenance.
//
// Measured on the pessimistic (400 nanoton/gas) row: the handler — a
// dict lookup, a dict delete, the escrow/ops reserve walk, one storage write and
// one send — costs 12,733 gas ≈ 0.0051 GRAM of compute plus forwarding. At the
// first draft's 0.01 that left the sweeper 0.0022, which is positive but thin
// enough that a bot's own RPC and wallet overhead eats it, and thin enough to
// flip negative on any gas-price rise. 0.02 leaves ~0.0122, a ~2.5x margin, and
// is still well under the 0.05 deposit it is funded from — so the contract keeps
// ~0.03 per swept commitment, comfortably more than the rent it paid for the two
// cells.
//
// A larger bounty makes sweep-RACING rational, which is why the "no such
// commitment" arm below had to stop confiscating the loser's value.
const SWEEP_BOUNTY: int = 20000000;   // 0.02 GRAM

// NFT / resolver sync budgets
//
// R25-4 (MEDIUM). `MINT_VALUE` — 0.08 GRAM, the bare deploy floor `AdoptItem`
// used to send — IS DELETED, AND THE SPLIT WITH IT.
//
// R20-5b introduced the split on a stated premise: "a REPAIR sends the bare
// deploy floor, because AdoptItem is permissionless and its caller is not the
// beneficiary". That reasoned entirely about the repair's AFFORDABILITY and
// never once about the REPAIRED ITEM'S SOLVENCY. Measured on this build, on the
// exact R17-1 cohort the op exists for (name sold while the registrar was not
// yet pointed at the collection; collection wired afterwards; a stranger pays):
//
//   healer pays 0.110358  ->  item lands at 0.077815
//   item: 44 cells / 18,311 bits -> 0.019398 GRAM/yr on the pessimistic
//   param-18 row  ->  FREEZE HORIZON 9.17 YEARS
//
// measured against a variant registrar that RESTORES the split, so the BEFORE
// column stays reproducible on this build. The round that found it read 9.41 y
// on the pre-R25-5 item, which was two cells smaller.
//
// against a term the registrar had just sold for TEN. Nothing signals it: every
// getter reads healthy, `get_nft_data` answers, `dnsresolve` resolves, and the
// name goes dark in year nine. audit/round25/R25A_rent_coupling.spec.ts.
//
// AND A GENEROUS CALLER COULD NOT FIX IT. The value was hardcoded in `sendMint`,
// so a healer sending 5 GRAM still landed the item on 0.077829 while the
// registrar kept the other 4.9 — measured. The one funding level a caller could
// reach was the one that is short.
//
// THREE FIXES WERE PRICED, ALL THREE DRIVEN IN audit/round25:
//
//   raise MINT_VALUE to ~0.12  lands 0.118, horizon 11.2 y, healer pays 0.14.
//                              REJECTED: it creates a THIRD funding level that
//                              must be re-derived every time the item grows, and
//                              that drift is exactly how `ITEM_FULL_RENT` went
//                              stale twice (0.33 in R20-5b, 0.36 in R21-I10,
//                              0.48 in R22-1). A fix must not create the next
//                              finding.
//   raise ITEM_MIN_STORAGE     REJECTED — see `ITEM_MIN_STORAGE` in
//   to 0.116 (R25-3)           emoji_nft_item.tolk. It is also `AskTransfer`'s
//                              RAWRESERVE floor, so raising it makes an ordinary
//                              record-full item unsellable at a wallet's standard
//                              transfer value after 7.65 years, with an
//                              ACTION-PHASE failure (code 37, compute exit 0, no
//                              ownership move) that a marketplace reads as
//                              success.
//   DELETE THE SPLIT           TAKEN. `MINT_VALUE_FUNDED` is already derived
//                              (ITEM_FULL_RENT + MINT_HOP_GAS), already pinned on
//                              BOTH fee schedules by
//                              audit/round20/item/M1_mint_funding_and_rent.spec.ts,
//                              and already moves whenever the item grows. The
//                              adopt leg inherits all of that for free, and
//                              "every item this system creates arrives funded to
//                              ITEM_FULL_RENT" becomes an invariant with no
//                              exception instead of a rule with one.
//
// WHAT IT COSTS, PLAINLY. `ADOPT_ITEM_MIN_VALUE` goes 0.1 -> 0.52 GRAM. R20-5b
// called that "pricing out the good samaritan"; that actor does not exist,
// because `AdoptItem` pays NO bounty at any price. The caller is always the
// stranded owner (who paid 1.5-20 GRAM for the name), the foundation, or an
// operator healing a cohort its own runbook stranded — 0.52 prices out none of
// them, and what they get for it is a fully funded item instead of one that dies
// in year nine. A repeat adopt now donates 0.5 rather than 0.08 into the item
// (the item keeps it; anything above ITEM_FULL_RENT comes back out on the next
// transfer), which is the one real regression and it is the caller's own.
//
// THE CHEAP REPAIR IS NOT GONE — it is simply not this op. The item accepts a
// plain-GRAM top-up from ANYONE through its `remainingBitsCount() < 32` arm:
// measured on the pre-fix item, 0.077829 -> 0.577778 at exit 0, which moves the
// freeze horizon 9.41 y -> 35.85 y. Any stranger, any amount, no op required.
// Funding and reconciliation are two acts and only one of them needs a registrar
// op to perform it.
//
// R20-5b. WHAT AN ISSUANCE SENDS — AND, SINCE R25-4, WHAT A REPAIR SENDS TOO.
//
// The deleted `MINT_VALUE` was the bare cost of getting an item deployed and
// alive, and it was believed to be the right number for `AdoptItem` — a
// PERMISSIONLESS repair whose whole value is that a stranger can pay 0.1 GRAM
// to un-strand somebody else's name.
// It is the wrong number for an issuance, and R19/T7 measured why: the item's
// `SetRecord` requires `balance >= ITEM_MIN_STORAGE + n * RECORD_RENT_RESERVE`
// (R17-10, so the name stays resolvable for the full ten years it can be sold
// for), MyTonWallet's `TON_GAS.changeDns` is 15,000,000 nanoton and Tonkeeper's
// `nftLinkAmount` is 0.02 — both hardcoded, neither overridable — so on a
// 0.08-funded item the first "link my wallet" fails 412 from both wallets.
//
// At the MINT there is no such constraint: the buyer is paying 1.5-20 GRAM and
// the registrar chooses this value. So an issuance prepays the item's whole
// eight-record allowance and `SetRecord` needs gas only, forever, from any
// wallet. See ITEM_FULL_RENT in emoji_nft_item.tolk for the rent arithmetic and
// for the AskTransfer reserve that carries it across a sale.
//
//   ITEM_FULL_RENT   0.48   what must ARRIVE at the item   (R22-1, was 0.36)
//   MINT_HOP_GAS     0.02   what the two hops eat on the way (R22-2, was 0.006)
//
// R22-2. THE HOP BUDGET WAS SIZED ON MAINNET GAS AND SANDBOX FORWARD FEES, WHICH
// IS NEITHER SCHEDULE.
//
// The paragraph this replaces opened "MINT_HOP_GAS IS SIZED ON THE MAINNET
// SCHEDULE, NOT THE SANDBOX" and then priced the two compute phases at mainnet's
// 400 nanoton/gas and the forward fee at 0.001333 — "config-driven, same both
// ways". It is not the same both ways. ConfigParam 25 is part of the schedule
// too, and basechain's is lump 400,000 + 40,000/cell + 400/bit, where the
// sandbox's zerostate row is ~6x cheaper. So the one term that scales with the
// SIZE of the mint message — the term R20-6's 3-cell suffix and R20-7's label
// cell had just grown — was the term left on the cheap row.
//
// Measured on this build by differencing the two hops (registrar -> collection
// carries the value intact; the collection's action phase pays the forward fee
// for collection -> item, and both compute phases come out of the value):
//
//   schedule                     col gas    col->item fwd   item gas    TOTAL
//   sandbox                      0.000376      0.001777     0.000228   0.002381
//   mainnet GAS only (param 21)  0.002258      0.001777     0.001365   0.005401
//   mainnet GAS + FWD (21 + 25)  0.002258      0.010663     0.001365   0.014287
//
// (worst-case message: the 111-byte name, 3-cell percent-encoded suffix, label
// cell. The 2-emoji name measures 0.012888 the same way.)
//
// The middle row is what the old comment measured — 0.005401 against a 0.006
// budget, and its claimed "0.004637, 29% under" is that same row with the
// forward fee counted once and low. The bottom row is mainnet, and 0.006 covers
// 42% of it. On mainnet the item would have arrived at 0.4717 instead of 0.48:
// not fatal (the freeze horizon at 0.4717 is still 11.63 y, over the 11 y pin),
// but the funding claim would have been false, and the next round to grow the
// mint message would have widened the gap silently.
//
// 0.02 is 1.40x the measured 0.014287 worst case. In the unit that moves it —
// cells of mint message — the surplus absorbs ~12 further FULL (1023-bit) cells
// at basechain's 40,000/cell + 400/bit before the item lands short again. It is
// pinned at BOTH schedules by audit/round20/item/M1_mint_funding_and_rent.spec.ts,
// which is the fix for how this went unnoticed: the arrival was only ever
// asserted in the sandbox, where the number is 6x too kind.
//
// It was a separate constant from `MINT_VALUE` rather than a raise of it because
// the two were held to answer different questions, and conflating them "would
// have quietly raised the permissionless repair floor from 0.1 to 0.5 GRAM —
// pricing out the good samaritan R17-1's fix exists for."
//
// R25-4 conflated them on purpose. The two do NOT answer different questions:
// both answer "how much rent must this item hold to survive the term the
// registry has recorded for it", and the registry records the same ten-year
// maximum on both paths. The good samaritan was the wrong actor to design
// around — see the deletion note above.
//
// R22-1/R22-2. "MEASURED, NOT COMPUTED" — THIS TIME IT IS, AND IT IS PINNED.
//
// R20-5b's own note records that the previous version of this paragraph claimed
// the arriving balance had been measured when it had not, and the item landed on
// 0.078 instead of 0.33. The claim is a test now, not a comment: both issuance
// doors are driven end to end, on both fee schedules, and the ARRIVING balance
// is asserted. Measured on this build at ITEM_FULL_RENT = 0.48:
//
//                               sandbox      mainnet gas + fwd
//   paid Reveal, 2-emoji name   0.497852     0.487112
//   paid Reveal, 111-byte name  0.497619     0.485713
//   AdminMint                   0.497871     0.487224
//
// all six above ITEM_FULL_RENT.
const MINT_HOP_GAS: int      = 20000000;   // 0.02 GRAM — 1.40x the measured mainnet 0.014287
const MINT_VALUE_FUNDED: int = 500000000;  // ITEM_FULL_RENT (0.48) + MINT_HOP_GAS (0.02)
// R7-1. RIGHT-SIZED, DELIBERATELY, INSTEAD OF ADDING A WITHDRAWAL PATH.
//
// The resolver contains ZERO send instructions — no SENDRAWMSG, no SENDMSG, no
// RAWRESERVE, verified at the bytecode level. That is why its drain-check result
// is structural rather than lucky: a contract that cannot send cannot leak. It
// is the strongest property any contract in this system has.
//
// It also means nothing can ever come back out, and this value is what goes in,
// on every registration and every transfer, forever. Measured: 0.04 in, ~0.0003
// of that consumed as gas, so ~0.0397 of pure accumulation per sync — against a
// real storage cost of 0.00061 per name-year. That endowed every name with
// roughly SIXTY-FIVE years of rent for a term that cannot exceed ten, and would
// have stranded ~1,300 GRAM at registry capacity.
//
// The obvious fix — an admin withdrawal op — would give the resolver its first
// send path and destroy the property above to recover money nobody can steal
// anyway. Shrinking the INFLOW gets most of the benefit and costs nothing: users
// pay less per registration, the resolver still cannot leak by construction, and
// the endowment is still ~16 years of rent at current prices, comfortably more
// than the 10-year maximum term.
//
// If TON's storage prices ever rise far enough that this is thin, the answer is
// to raise it for FUTURE registrations, not to add a way out.
const SYNC_VALUE: int      = 12000000;  // 0.012 GRAM per resolver SyncNameOwner
const EXPIRY_VALUE: int    = 50000000;  // 0.05 GRAM to collection for UpdateExpiryReq
// R13X-1. PushTerm forwards EXPIRY_VALUE with PAY_FEES_SEPARATELY, so the caller
// must also cover this contract's own compute and the forward fee. R10-2's lesson
// applies: the assert is worthless unless it sits BEFORE the expensive work, and
// the budget must exceed what the handler actually costs at the PESSIMISTIC gas
// row — 400 nanoton/gas. 0.02 GRAM buys 50k gas at that price; the handler is a
// dict lookup and one send.
//
// R25 CORRECTION, same as the one on SWEEP_BOUNTY above: this said "MAINNET gas
// (400 nanoton/gas, 6x the sandbox default)" and had both halves wrong. Live
// basechain has charged **66.667 nanoton/gas since 2026-04-29**; 400 is the
// PRE-cut row, and it is this repo's harness — not the sandbox — that pins 400.
// The 0.02 does not move: R23 re-derived every budget here against the expensive
// row on purpose, because this contract is immutable and the cut is one config
// vote from being reverted. Sizing unaffected; only the provenance was wrong.
const PUSH_TERM_GAS: int   = 20000000;  // 0.02 GRAM compute+fwd budget for PushTerm

// Renewal prices — IMMUTABLE constants. No setter compiles, so a holder's
// carrying cost can never be raised. These must survive GRAM's full historical
// band ($0.52 - $8.26); see docs/LAUNCH_PRICING.md.
const RENEW_1: int   = 50000000000;    // 50   GRAM  Mythic    (single, auction-only)
const RENEW_2: int   = 10000000000;    // 10   GRAM  Legendary
const RENEW_3: int   =  7500000000;    //  7.5 GRAM  Epic
const RENEW_4: int   =  3000000000;    //  3   GRAM  Rare
const RENEW_5: int   =  1500000000;    //  1.5 GRAM  Uncommon
const RENEW_6_7: int =   750000000;    //  0.75 GRAM Common (6 and 7 share a tier)

// First-year price BOUNDS: each tier may be moved to a QUARTER or 4x its launch
// price and no further. Wide enough to absorb GRAM volatility across its
// historical 16x band and to price future integrations; narrow enough that a
// compromised admin cannot make the namespace unaffordable or free.
// These bounds are themselves immutable.
const FLOOR_2: int  = 5000000000;  const CEIL_2: int  = 80000000000;  // 20  -> [5,     80]
const FLOOR_3: int  = 3750000000;  const CEIL_3: int  = 60000000000;  // 15  -> [3.75,  60]
const FLOOR_4: int  = 1250000000;  const CEIL_4: int  = 20000000000;  //  5  -> [1.25,  20]
const FLOOR_5: int  =  750000000;  const CEIL_5: int  = 12000000000;  //  3  -> [0.75,  12]
const FLOOR_67: int =  375000000;  const CEIL_67: int =  6000000000;  //  1.5-> [0.375,  6]

// default first-year prices (used at deploy via storage init in the wrapper)

// error codes
const ERR_NOT_ADMIN: int            = 401;
const ERR_BAD_SIGNATURE: int        = 402;
const ERR_BAD_YEARS: int            = 404;
const ERR_NAME_TAKEN: int           = 405;
const ERR_INSUFFICIENT_PAYMENT: int = 406;
const ERR_NAME_NOT_FOUND: int       = 407;
const ERR_NAME_EXPIRED: int         = 408;
const ERR_BAD_PRICE_BOUND: int      = 410;   // admin price outside [floor, ceiling]
const ERR_NOT_COLLECTION: int       = 411;   // OwnerSynced from non-collection
const ERR_BAD_EMOJI_COUNT: int      = 412;
const ERR_NO_COMMITMENT: int        = 413;   // reveal without a matching prior commit
const ERR_COMMIT_TOO_NEW: int       = 414;   // min delay not elapsed
const ERR_COMMIT_EXPIRED: int       = 415;   // past max age
const ERR_BAD_COMMIT_TIMING: int    = 416;   // admin timing outside bounds
const ERR_COMMIT_EXISTS: int        = 417;   // duplicate active commitment
const ERR_NO_PENDING_ADMIN: int     = 418;   // accept with no pending transfer
const ERR_NOT_PENDING_ADMIN: int    = 419;   // accept from wrong address
const ERR_TIMELOCK_ACTIVE: int      = 420;   // accept before timelock elapsed
const ERR_BAD_ADMIN_TIMELOCK: int   = 421;   // timelock outside bounds
const ERR_ZERO_ADDRESS: int         = 422;   // refuse transfer to a null/none address
const ERR_BAD_REFERRAL_BPS: int     = 423;   // public referral share above ceiling
const ERR_BAD_KOL_BPS: int          = 424;
const ERR_BAD_PARTNER_BPS: int      = 441;   // combined partner share above 30%
const ERR_TOO_MANY_PARTNERS: int    = 445;
const ERR_PARTNER_NOT_FOUND: int    = 446;
const ERR_PRICES_LOCKED: int        = 447;   // buy-side prices frozen forever
const ERR_NOT_NAME_OWNER: int       = 409;   // reinstated for MakePermanent
const ERR_ALREADY_PERMANENT: int    = 442;
const ERR_PERMANENT_SINGLES_ONLY: int = 443; // only single-emoji names may be made permanent
const ERR_BAD_PERMANENT_PRICE: int  = 444;   // KOL override above 33% hard cap
const ERR_SIG_EXPIRED: int          = 425;   // attestation past its validity window
const ERR_COMMIT_NOT_EXPIRED: int   = 426;   // sweep attempted on a still-valid commitment
const ERR_SINGLE_LOCKED: int        = 427;   // singles are auction/AdminMint only
const ERR_AUCTION_EXISTS: int       = 428;
const ERR_NO_AUCTION: int           = 429;
const ERR_AUCTION_ENDED: int        = 430;
const ERR_AUCTION_LIVE: int         = 431;   // settle/cancel before the end
const ERR_BID_TOO_LOW: int          = 432;
const ERR_BAD_AUCTION_DURATION: int = 433;
const ERR_NAME_UNAVAILABLE: int     = 434;   // active/reserved/in-auction
const ERR_TOO_MANY_EMOJI: int       = 435;   // above the current namespace cap
const ERR_POLICY_LOCKED: int        = 438;   // normalization policy frozen forever
const ERR_NAME_BYTES_MISMATCH: int  = 439;   // rawName does not hash to nameHash
const ERR_SKIN_TONE_BLOCKED: int    = 440;   // name contains a skin-tone modifier
const ERR_TERM_TOO_LONG: int        = 448;   // renewal would exceed MAX_TOTAL_TERM
const ERR_WITHDRAW_EXCEEDS_FREE: int = 449;  // withdrawal would touch bidder escrow
const ERR_CONFUSABLE_VARIANT: int   = 450;   // F-3: a blocked look-alike; its class has a survivor
const ERR_NAME_TOO_LONG: int        = 451;   // F-9: exceeds the TEP-81 127-byte budget
const ERR_IMPORTS_LOCKED: int       = 452;   // migration window closed, one-way
const ERR_BAD_IMPORT_TERM: int      = 453;   // imported term exceeds MAX_TOTAL_TERM
const ERR_TOO_MANY_RESOLVERS: int   = 454;   // V7-16: resolver set is bounded
const ERR_IMPORT_TERM_PAST: int     = 455;   // V7-17b: import fully lapsed (distinct from 453 'too long')
const ERR_EMOJI_COUNT_MISMATCH: int = 456;   // V7-28: attested tier != the tier the bytes segment to
const ERR_NAME_NOT_UTF8: int        = 457;   // V7-28: rawName is not well-formed UTF-8
const ERR_BAD_SIGNER_KEY: int       = 458;   // V7-30: rotation to the zero key
const ERR_NO_PENDING_SIGNER: int    = 459;   // V7-30: nothing staged to apply/cancel
// R24-4. A fresh number continuing the SYSTEM-WIDE sequence: the item took 480
// (R23-9 ERR_RECORD_TOO_SMALL) and that is the highest code any of the four
// contracts holds, so 481 is the next free one. Same rule as R21-3 and R23-9 —
// never reuse a low gap.
const ERR_NO_PENDING_COLLECTION: int = 481;  // R24-4: ConfirmNftCollection with nothing staged
const ERR_STATE_BUDGET: int         = 482;   // R24-5: account-state cell budget exhausted
const ERR_AUCTION_NOT_STALE: int    = 483;   // R24-6: unbid lot reclaimed before its window
const ERR_BAD_CONTENT: int          = 460;   // V7-31: content is not a URI-safe suffix
// R7-17 named this for the partner, but it is the GENERIC "this payout
// destination must be basechain" code and now has three consumers: SetPartner
// (R7-17), PlaceBid's bidder (R16V-1) and AddResolver (R16-3). The referrer
// (F-11) is the fourth member of the family but does not use it — a masterchain
// referrer is silently ignored rather than refused, because refusing would fail
// a sale the buyer got right. Kept under the old name so the constant, the
// integrator docs and every prior round's write-up keep agreeing.
const ERR_BAD_PARTNER_WC: int       = 461;   // basechain-only payout destination
const ERR_NOT_EMOJI_CODEPOINT: int  = 462;   // R9-2: a codepoint outside the emoji namespace
const ERR_BARE_KEYCAP_BASE: int     = 463;   // R9-2: ASCII base not followed by the keycap mark
const ERR_NO_NFT_COLLECTION: int    = 464;   // R13X-1: PushTerm with cfg.nftCollection unset
const ERR_UNKNOWN_OP: int           = 465;   // R13X-6: body this contract cannot interpret
const ERR_BAD_POLICY_HASH: int      = 466;   // R14B1-11: cannot freeze the "not yet published" sentinel
// R18. Nine new codes, all in this contract's own 4xx namespace. 403, 436 and 437
// were the only gaps below 467 and are left alone — R17-39 records that 401 already
// means four different things across the four contracts, and reusing a gap to save
// three digits is how that happened. The item's 423 and the shared 465 are the only
// numbers this file coordinates with; nothing here collides with either.
const ERR_SELF_REFERENCE: int       = 467;   // R17-9/R17-20: a config address pointing at this contract or a sibling
const ERR_BAD_BODY: int             = 468;   // R17-7: body length does not match the op's struct
const ERR_ABORT_REFUND_SHORT: int   = 469;   // R17-13: cannot abandon a lot without paying the winner in full
const ERR_BAD_DNS_LENGTH: int       = 470;   // R17-E1: RESERVED, not thrown. See assertCanonicalName —
                                             // the DNS-hostile length rule lives off chain by design.
                                             // Held so the number is never reused for another meaning.
const ERR_BAD_VARIATION_SELECTOR: int = 471; // R17-29: VS-16 stacked on VS-16, or opening the name
const ERR_CONTENT_NOT_BOUND: int    = 472;   // R17-4: metadata URI does not encode the name being issued
const ERR_EXPIRY_OVERFLOW: int      = 473;   // R15-9: the term would pass the uint32 expiry horizon (2106)
const ERR_BAD_SYNC_NONCE: int       = 474;   // R15-1: imported nonce with no room left to increment
const ERR_PRICE_BELOW_RENEWAL: int  = 475;   // R15-8: first-year price under the tier's immutable renewal
const ERR_WRONG_FEE_DESTINATION: int = 476;  // R17-37: WithdrawFees.to disagrees with cfg.feeDestination
// R21-1. 477 is NOT free — the item took it for ERR_RENEW_AT_REGISTRAR (R20-4) —
// so this continues at 478, and the collection's R21-3 code takes 479. Numbering
// stays monotonic across the whole system for the reason R17-39 gives.
//
// A SEPARATE CODE FROM 468, DELIBERATELY. `ERR_BAD_BODY` says "the body length does
// not match the op's struct", and on this failure the body length is exactly right —
// 704 bits, 4 refs. Answering 468 would send a front end to re-count its envelope,
// which is the one part it got correct. 478 says: the envelope is fine, a REFERENCED
// cell is not.
const ERR_BAD_BODY_REF: int         = 478;   // R21-1: a ref this op dereferences is not the
                                             // shape its struct declares (Reveal.parties,
                                             // Reveal.signature)

// ---------- storage ----------

// A live English auction for one name (singles drops).
struct Auction {
    // R24-6. WHEN THIS LOT WAS LISTED, so an unbid lot has a permissionless way
    // out. `endsAt` cannot serve — it is deliberately 0 until the first bid
    // (F-4), which is exactly the state that had no exit. 32 bits on a struct
    // that already measures 2 cells, on a population bounded by `liveLots`.
    listedAt: uint32
    highBidder: address?      // null until the first bid
    highBid: coins            // current high bid (or the start bid floor)
    startBid: coins
    duration: uint32          // F-4: competitive window length
    endsAt: uint32            // 0 until the FIRST BID starts the clock
    numYears: uint16          // term the hammer price includes
    emojiCount: uint16        // A-1: carried so settle records the TRUE tier
                              // (hardcoding 1 mispriced non-single lots forever)
    // R24-7. `policyHash` LIVED HERE UNTIL R24-2 ORPHANED IT, AND REMOVING IT IS
    // WHAT PAYS FOR `listedAt`.
    //
    // R14-5 snapshotted the listing policy so `SettleAuction` could refuse to
    // mint under a ruleset the project had since disowned. R24-2 deleted that
    // comparison — it was only ever reachable with a bidder's money custodied,
    // which made it an admin primitive for voiding a won auction — so the field
    // became write-only state: 256 bits nothing read.
    //
    // That mattered immediately, because this struct is a DICT VALUE and the leaf
    // must hold the key label plus the whole struct in ONE 1023-bit cell. Measured
    // before this change, with R24-6's `listedAt` added:
    //
    //     leaf = 918 + coinsBits(startBid) + coinsBits(highBid)
    //     unbid lot                        741 bits   ok
    //     bid at the 150 GRAM floor      1,006 bits   ok, 17 bits spare
    //     the audit suite's own 800M GRAM case
    //                                    1,054 bits   EXIT 8
    //
    // Pre-R24-6 that last case sat at 1,022 of 1,023 — one bit under. `listedAt`
    // spent 32 of the 49 free bits and broke it, and `PlaceBid` throws AFTER
    // accepting the value, so a bounce-stripping bidder lost the entire bid
    // (measured: 144,115,188 GRAM in, 0 returned).
    //
    // Dropping the orphan takes the worst case to 910 bits — safe for ANY `coins`
    // value including 2^120-1, with 113 bits spare — so the struct is now bounded
    // by construction rather than by one bit of luck. The `auctionPolicyHash`
    // getter goes with it; its docstring described the abort R24-2 removed and was
    // the one an operator would have acted on.
    //
    // `content` and `label` below are REF fields, so they cost the leaf 1 bit
    // each, not their payload — which is why the budget above is dominated by the
    // two `coins` and the optional address, and why removing a 256-bit inline
    // field is what buys the room.
    content: cell
    // R20-7. THE NAME, SNAPSHOTTED FOR THE SAME REASON `policyHash` IS.
    //
    // `SettleAuction` is PERMISSIONLESS and carries no attestation, so it has no
    // rawName of its own and cannot be given one — a caller-supplied name on a
    // permissionless op is exactly what R14-5 spent this struct's other field
    // preventing. `StartAuction` has already run `assertCanonicalName`, so the
    // bytes stored here are bound to `nameHash` at listing time and the hammer
    // mints the same name that was listed.
    label: cell
}

// SIMPLIFIED (July 23): no `isReserved` flag. Singles are unregistrable by the
// public in the first place, so an un-issued single is already reserved by
// construction — a flag added storage, four ops and audit surface for nothing.
// Which singles the foundation holds is now pure admin discretion via AdminMint.
struct NameRecord {
    owner: address
    expiresAt: uint32
    emojiCount: uint16
    // Authoritative "never expires" marker. Guards every expiry-dependent path;
    // a permanent name can never lapse, be renewed, or be re-registered.
    isPermanent: bool
    // F-12: bumped on every OWNER write, carried out through the mint and back
    // through OwnerSynced. A sync echoing an old nonce is provably a stale view
    // of ownership — discarded, not applied.
    syncNonce: uint32
}

// admin-adjustable first-year prices (bounded)
// NOTE: there is no p1. Singles are never publicly registered (auction or
// AdminMint only), so a single first-year price would be unreachable code.
// RENEW_1 remains live — auction winners renew singles at the flat rate.
// One ecosystem partner's standing revenue share.
struct PartnerEntry {
    addr: address
    bps: uint16
}

struct PriceConfig {
    // Also carries the §5.1 normalization commitment: Config already spends all
    // four of its cell refs (prices, note, referrerRates, resolvers), so the
    // policy hash rides in this cell rather than earning its own.
    //
    // The chain cannot run full emoji SEGMENTATION (grapheme clustering, counting),
    // so this hash publishes — and can permanently FREEZE — which ruleset the
    // signer is authorised to apply, converting a private trust assumption into an
    // auditable, irreversible commitment.
    //
    // NOTE: the skin-tone rule specifically is no longer trust-based. Pattern-
    // matching a fixed 4-byte sequence is NOT segmentation, so `assertCanonicalName`
    // proves the raw bytes against nameHash (SHA256U) and rejects skin tones in TVM
    // on every issuance path. A compromised signer cannot mint one.
    normalizationPolicyHash: uint256
    policyLocked: bool                // one-way
    // Ecosystem-partner revenue share lives here rather than in Config, which is
    // at its 1023-bit ceiling. null address = no partner deal active.
    partners: map<uint256, PartnerEntry>   // accountHash -> { address, bps }
    permanentPrice: uint64
    // ONE-WAY. Once true, no first-year tier price and no permanent price can
    // ever change again. Nothing anywhere clears it. Referral and partner rates
    // are deliberately NOT covered — those are revenue-share configuration, not
    // a price a user pays, and freezing them would break future partner deals.
    pricesLocked: bool
    // ONE-WAY. Closes AdminImport forever. Migration is a bounded event, not a
    // standing power: pull this once the last name is imported and the ability
    // to write an arbitrary expiry is gone for good. Nothing clears it.
    importsLocked: bool
    p2: uint64      // Legendary
    p3: uint64      // Epic
    p4: uint64      // Rare
    p5: uint64      // Uncommon  (exactly 5)
    p67: uint64     // Common    (6 and 7)
}

// Admin-settable configuration, kept in a referenced cell so the root Storage
// stays comfortably under 1023 bits.
struct Config {
    feeDestination: address
    signerPublicKey: uint256
    nftCollection: address?
    prices: Cell<PriceConfig>
    commitMinDelay: uint32
    commitMaxAge: uint32
    referralBps: uint16          // public affiliate share (basis points)
    referrerRates: map<uint256, uint16> // KOL overrides: referrerHash -> custom bps
    resolvers: map<uint256, address>    // account-hash -> resolver address (moved
                                        // here in v4: root hit TON's 4-ref limit)
}

// Commitments for commit-reveal. Confusable protection needs NO storage: the
// survivor of each class is named up front, so the rule is a stateless
// comparison (see assertNoConfusableVariant).
struct Aux {
    commitments: map<uint256, uint32>   // commitmentHash -> commit timestamp
    // V7-30. Signer rotation is STAGED, not instant. The project's threat model
    // treats a compromised admin key and a compromised signer key as separate
    // events; an instant UpdateSigner collapsed them into one, because an admin
    // could install a key it controlled and mint with it in the same block.
    // Rotation now serves the same adminTimelock as an admin handover, and the
    // staged key is public for that whole window.
    pendingSigner: uint256              // 0 = nothing staged
    pendingSignerAt: uint32             // 0 = nothing staged
    // R24-4. THE COLLECTION POINTER IS STAGED AND MUST BE ACKNOWLEDGED BY THE
    // COLLECTION ITSELF BEFORE IT GOES LIVE.
    //
    // Lives in Aux rather than Config for two reasons: Config is already ~873
    // bits of 1023 and a second optional address (268) would not fit, and this is
    // staged state, which is exactly what Aux already holds (pendingSigner).
    // null = nothing staged.
    pendingNftCollection: address?
    // R24-5. HOW MANY COMMITMENTS ARE CURRENTLY OCCUPYING CELLS.
    //
    // `commitments` is the second unbounded map in this contract's account, and
    // the only one an unprivileged party can grow. Counting it is what lets the
    // cell-budget guard below be O(1) instead of walking a dict on the hot path.
    // Maintained at exactly three sites — Commit (+1, only on a genuinely NEW
    // key), Reveal (-1) and SweepCommitment (-1) — which are the only three
    // places the map is mutated.
    liveCommitments: uint32
}

struct Storage {
    admin: address
    pendingAdmin: address?            // nominated successor (null = no transfer pending)
    pendingAdminAt: uint32            // timestamp the transfer was initiated
    adminTimelock: uint32             // required delay before accept (admin-set, bounded)
    // V7-19b: a DECREASE of adminTimelock is itself delayed by the timelock in
    // force when it was requested. Without this, a stolen key just reorders the
    // messages — lower the timelock BEFORE nominating — and the cancel window is
    // zero again. 0 = nothing staged.
    pendingTimelock: uint32           // the lower value waiting to take effect
    pendingTimelockAt: uint32         // when it becomes effective (0 = none staged)
    config: Cell<Config>
    auctions: map<uint256, Auction>   // nameHash -> live auction
    aux: Cell<Aux>                    // commit-reveal commitments
    totalNames: uint32
    totalRevenue: uint128             // cumulative license fees collected (provable traction)
    totalRegistrations: uint32        // lifetime successful registrations
    totalRenewals: uint32             // lifetime successful renewals
    // R17-6 (MEDIUM). THE ONE UNBOUNDED LOOP, AND THE THREE THINGS IT SWITCHED OFF.
    //
    // `escrowAndCount` walked every lot in `auctions` at 1,168 gas each, and three
    // consumers inherited the walk. The consequences were not academic:
    //
    //   SweepCommitment  calls freeBalanceOf for its bounty clamp, so R14-2's
    //                    "cleanup is a market" answer to commitment bloat went
    //                    LOSS-MAKING at 30 live lots and hard-failed (-14, stake
    //                    lost AND the commitment not freed) at ~37.
    //   WithdrawFees     hard-failed at 853 lots with an uncatchable -14 — all fee
    //                    revenue frozen until the lot count dropped back under it,
    //                    and more message value cannot cure an out-of-gas.
    //   the getters      freeBalance() / totalEscrowedBids() crossed the 1M gas
    //                    read limit at ~857 / ~890 lots.
    //
    // The lot count is MONOTONE under admin inventory — nothing removes a lot but
    // settle or cancel — so this was a ratchet, not a transient.
    //
    // These two fields are the walk's result, maintained incrementally by the four
    // ops that can move it (StartAuction, PlaceBid, SettleAuction, CancelAuction)
    // and by nothing else. The invariant they must satisfy is exact and testable:
    //
    //     escrowedTotal == SUM(a.highBid) over lots with a.highBidder != null
    //     liveLots      == COUNT(lots)
    //
    // pinned step-by-step against a freshly-walked total in
    // audit/round18/registrar/A_escrow_counters.spec.ts.
    //
    // WIDTHS, not `coins`. `coins` is a var-uint16 whose serialized length grows
    // with the value (up to 124 bits), and the c4 root is a fixed-size budget: at
    // 623/1023 bits empty and 888 with a pending admin nominated, a variable field
    // could make `toCell()` throw on a large escrow at exactly the wrong moment.
    // uint64 is fixed, and 2^64-1 nanoton is ~18.4e9 GRAM — more than three times
    // the entire TON supply, which is itself the hard ceiling on what this contract
    // can be holding in escrow. New occupancy: 719 empty / 984 with a pending admin.
    escrowedTotal: uint64             // R17-6: SUM of live high bids, incrementally maintained
    liveLots: uint32                  // R17-6: COUNT of entries in `auctions`
    names: map<uint256, NameRecord>
}

fun loadStorage(): Storage {
    return Storage.fromCell(contract.getData());
}

fun saveStorage(st: Storage) {
    contract.setData(st.toCell());
}

fun Storage.auxData(self): Aux {
    return self.aux.load();
}

fun Storage.cfg(self): Config {
    return self.config.load();
}

// ---------- pricing ----------

fun firstYearPrice(prices: PriceConfig, emojiCount: int): int {
    if (emojiCount == 2) { return prices.p2; }
    if (emojiCount == 3) { return prices.p3; }
    if (emojiCount == 4) { return prices.p4; }
    if (emojiCount == 5) { return prices.p5; }
    return prices.p67;                       // 6 and 7
}

fun renewYearPrice(emojiCount: int): int {
    if (emojiCount == 1) { return RENEW_1; }
    if (emojiCount == 2) { return RENEW_2; }
    if (emojiCount == 3) { return RENEW_3; }
    if (emojiCount == 4) { return RENEW_4; }
    if (emojiCount == 5) { return RENEW_5; }
    return RENEW_6_7;                        // 6 and 7
}

fun registerCost(prices: PriceConfig, emojiCount: int, numYears: int): int {
    return firstYearPrice(prices, emojiCount) + (numYears - 1) * renewYearPrice(emojiCount);
}

fun renewCost(emojiCount: int, numYears: int): int {
    return numYears * renewYearPrice(emojiCount);
}

fun priceBounds(emojiCount: int): (int, int) {
    if (emojiCount == 2) { return (FLOOR_2, CEIL_2); }
    if (emojiCount == 3) { return (FLOOR_3, CEIL_3); }
    if (emojiCount == 4) { return (FLOOR_4, CEIL_4); }
    if (emojiCount == 5) { return (FLOOR_5, CEIL_5); }
    return (FLOOR_67, CEIL_67);
}

/** Everything `SetFirstYearPrice` would accept for one tier: band, and R15-8. */
fun tierPriceAcceptable(price: int, tier: int): bool {
    val (lo, hi) = priceBounds(tier);
    return price >= lo && price <= hi && price >= renewYearPrice(tier);
}

// R17-26 / R17-12. A ONE-WAY LOCK MUST NOT BE ABLE TO FREEZE A CONFIG ITS OWN
// SETTERS REFUSE.
//
// R17-12 measured a genesis `p2` of 1 nanoton deploying happily — `priceRegister(2,1)`
// = 1 nanoton — and `LockPrices` then freezing it, permanently: every later
// `SetFirstYearPrice` answers 447 and there is no unlock op and no SETCODE. The
// same lever is available for the permanent price. `assertDeployableCollection`
// already states the governing premise for the sibling contract ("the constructor
// must not accept what the setter refuses"); this applies it at the only moment
// this contract can still act on it.
fun pricesAreLockable(p: PriceConfig): bool {
    return tierPriceAcceptable(p.p2 as int, 2)
        && tierPriceAcceptable(p.p3 as int, 3)
        && tierPriceAcceptable(p.p4 as int, 4)
        && tierPriceAcceptable(p.p5 as int, 5)
        && tierPriceAcceptable(p.p67 as int, 6)
        && (p.permanentPrice as int) >= PERMANENT_PRICE_FLOOR
        && (p.permanentPrice as int) <= PERMANENT_PRICE_CEIL;
}

// V7-29. The attestation is now DOMAIN-SEPARATED: it names the registrar it is
// for and the ruleset it was produced under, in a referenced cell (the payload
// no longer fits in 1023 bits).
//
//   registrar  An attestation used to be valid on ANY registrar that trusted the
//              same signer key — testnet, a staging deployment, a v5 successor,
//              a fork. One harvested signature registered the same name for free
//              on every one of them. This is the `subwallet_id` pattern that
//              telemint and every TON wallet use, applied to attestations.
//   policy     `normalizationPolicyHash` was published and one-way lockable, and
//              the comment on it says it "publishes — and can permanently FREEZE
//              — which ruleset the signer is authorised to apply". It did not:
//              nothing consumed it, so a signature produced under policy v1 kept
//              working after the admin published v2 AND locked it. Binding it
//              turns that declaration into an enforced gate — change the policy
//              and every attestation signed under the old one dies with it.
const ATTESTATION_DOMAIN: int = 0x454E5303;   // "ENS\x03" — R24-1 bumped from
                                              // 0x454E5301 when the spender binding
                                              // entered the domain cell. (0x454E5302
                                              // is ROTATION_DOMAIN.) The longer cell
                                              // already changes every hash; the bump
                                              // makes "which attestation version" a
                                              // legible field for a signer, a
                                              // dashboard, or anyone debugging a 402.

// R14-1 (HIGH, exploitable). THE ATTESTATION DID NOT NAME THE DOOR IT OPENS.
//
// V7-29 bound the attestation to a registrar and a policy. It did not bind it to
// an ISSUANCE PATH, and all four paths verified the identical preimage:
//
//     Reveal        public, permissionless, costs the list price
//     StartAuction  admin, lists a curated lot
//     AdminMint     admin, free promotional issuance
//     AdminImport   admin, migration, arbitrary expiry
//
// so ONE signature was simultaneously valid at all four. Measured: an attestation
// minted for AdminImport, replayed verbatim in a public Reveal — accepted, exit 0,
// name issued to the replayer.
//
// That needs no key leak and no admin mistake to matter, because of WHERE
// AdminImport attestations come from. They are generated in BULK, for the whole
// registry at once, and handed to an operator's migration script (see
// docs/MIGRATION_RUNBOOK.md phase C). Anybody who sees one — in a log line, a job
// queue, a CI artifact, a repo — can spend it in a public Reveal and take the
// migrant's name out from under them, paying only the list price for a name the
// migrant already owns. The reverse direction is worse in kind if not in
// likelihood: a harvested Reveal attestation is a valid AdminImport preimage, so
// the moment an admin key is compromised the attacker can write an arbitrary
// expiry for any name the signer has ever attested.
//
// One byte in the domain cell makes each signature structurally invalid on the
// other three doors. It is the same subwallet_id idiom V7-29 applied to the
// registrar address, applied one level finer.
//
// These constants are part of the SIGNER's contract, not just this file's: the
// off-chain signer must fold the same byte in, chosen by which op it is signing
// for. See ATT_PURPOSE in wrappers/EmojiRegistrarV4.ts, which mirrors them.
// R14B1-16 (HIGH). AN ATTESTATION WAS A 73-YEAR BEARER CREDENTIAL.
//
// `sigValidUntil` was bounded BELOW (S-1: `nowTime > sigValidUntil` is expired)
// and not at all above. Nothing on any of the four signature-verifying paths
// looked at how far in the FUTURE the window reached, and the wrapper's default —
// the one every integration example and every test used — was 4102444800: the
// year 2100. Signing that is not a mistake anyone would notice, because the
// signature works.
//
// The attestation preimage is (nameHash, emojiCount, contentHash, sigValidUntil,
// policyHash, purpose, registrar). It does NOT contain the buyer, the commitment,
// the price, or a nonce — deliberately, because the SAME name may legitimately be
// re-registered by anyone after it lapses. So the signature is a bearer token for
// "this exact name at this exact tier with this exact URI", and its ONLY expiry is
// this field.
//
// Measured: a signature harvested from a SUCCESSFUL reveal (it is in the message
// body, on chain, public) was replayed by a stranger to re-register the same name
// after it lapsed a year later. The signer was never contacted, the off-chain
// policy was never re-run, and the name had by then been re-priced and could have
// been re-classified. Every name ever sold shipped with a coupon for its own
// re-registration, valid until 2100.
//
// One hour is far more than a purchase needs — a commit-reveal is bounded by
// `commitMaxAge` and a human buys in seconds — and it is short enough that a
// harvested signature is worthless before anyone could act on it. The signer is
// expected to issue much shorter windows (~30 min in the wrapper default); this is
// the CEILING the chain enforces on whatever the signer chose.
//
// Enforced on all four paths. `Reveal` refunds (R8-12: a throw confiscates when
// the wallet stripped the bounce flag); the three admin paths keep `assert ...
// throw ERR_SIG_EXPIRED`, because there the admin's own tooling produced the
// over-long window and there is no third party to refund.
const MAX_SIG_WINDOW: int = 3600;   // 1 hour, the widest window the chain accepts

const ATT_PURPOSE_REVEAL: int       = 1;
const ATT_PURPOSE_START_AUCTION: int = 2;
const ATT_PURPOSE_ADMIN_MINT: int   = 3;
const ATT_PURPOSE_ADMIN_IMPORT: int = 4;

// V7-30. Domain-separated preimage the INCOMING signer key must sign to prove
// possession. Bound to this registrar for the same reason attestations are.
const ROTATION_DOMAIN: int = 0x454E5302;   // "ENS\x02"

fun signerRotationHash(newKey: uint256): uint256 {
    return beginCell()
        .storeUint(ROTATION_DOMAIN, 32)
        .storeAddress(contract.getAddress())
        .storeUint(newKey, 256)
        .endCell()
        .hash();
}

/// R24-1 (HIGH). THE ATTESTATION NAMED A NAME, A DOOR AND A RULESET — BUT NOT A
/// SPENDER. IT WAS A BEARER CREDENTIAL.
///
/// ===========================================================================
/// THE ATTACK, MEASURED
/// ===========================================================================
/// A failed `Reveal` publishes `rawName`, `nameHash`, `content` and the full
/// 512-bit signature on chain in the clear, and roughly fifteen refund paths
/// reach that state WITHOUT consuming the signature (406 mis-quoted ops budget,
/// 414, 415, 405, 428, 434 …). Nothing bound the credential to who could spend
/// it, so anyone watching could.
///
///   attacker pre-commits a desirable name — 0.05 GRAM, renewable every
///     `commitMaxAge`, reserves nothing, invisible as an attack
///   victim commits, waits, reveals with slightly too little value -> 406,
///     refunded, signature now public
///   attacker submits their OWN Reveal, one block later, with the harvested
///     signature under their aged commitment -> exit 0, attacker owns the name
///
/// Commit-reveal did not stop it: the attacker holds their own valid commitment.
/// The commitment proves "this sender reserved this name"; it never proved "the
/// signer approved this name FOR this sender". Those are orthogonal statements
/// and only the second one was missing.
///
/// ===========================================================================
/// THE FIX, AND WHY IT COSTS NOTHING
/// ===========================================================================
/// Bind the PAYER into the preimage — telemint's `force_sender_address`
/// (TelegramMessenger/telemint, `TelemintRestrictions`, checked as
/// `throw_unless(err::invalid_sender_address, equal_slices(...))`), made
/// MANDATORY rather than telemint's `Maybe`, because an optional binding means
/// an unset field silently means no protection.
///
/// THE PAYER, NOT THE RECIPIENT, and the difference is load-bearing:
///
///   * `StartAuction` attests a lot whose eventual owner is `auc.highBidder` —
///     a stranger who bids up to AUCTION_MAX_DURATION later and is issued the
///     name by a PERMISSIONLESS settle. The recipient is unknowable at
///     attestation time on that path. A recipient-binding is not implementable
///     uniformly across the four doors; a sender-binding is.
///   * `parties.newOwner` stays UNSIGNED, so gifting still works — pay from A,
///     deliver to B. Telemint needs a second field (`rewrite_sender_address`)
///     for this only because there `sender_address` IS the beneficiary. Our wire
///     format already separates payer from recipient, so we get it for free.
///   * The payer is the only principal in a Reveal the spender cannot choose at
///     spend time: `newOwner` is a free field in the body, so binding it stops
///     nothing that binding the payer does not already stop.
///
/// IN THE DOMAIN CELL, NOT THE BODY. The binding is hashed, never transmitted —
/// the contract already knows the sender. So `BODY_REVEAL` (704 bits),
/// `BODY_REVEAL_REFS`, every R17-7 / R21-1 / R21-2 envelope guard, every wrapper
/// builder and every integrator's serialiser are untouched. The domain cell goes
/// 563 -> 830 bits of 1023; the top cell stays 592. No new cell, no measurable
/// gas, no wire-format change.
///
/// NO NEW CHECK AND NO NEW ERROR CODE. The binding lives inside the hash, so a
/// wrong sender simply fails the existing `isSignatureValid` and returns the
/// existing ERR_BAD_SIGNATURE — refunded on `Reveal`, thrown on the three admin
/// doors. Carrying `boundSender` in the body and comparing it explicitly would
/// be more diagnosable and would cost every body-length guard in the contract;
/// diagnosability belongs off chain, in the wrapper's `verifyAttestation`.
///
/// ENCODING. `storeAddress` writes `addr_std$10 anycast:nothing workchain:int8
/// address:bits256` — 267 bits, byte-identical for raw `0:…`, `EQ…`, `UQ…` and
/// test-only forms, because the bounceable flag lives only in the base64 wrapper
/// and never in `MsgAddressInt`. It also binds the WORKCHAIN, which a bare
/// 256-bit account hash would not. Note the deliberate asymmetry with
/// `commitmentHash`, which DROPS the workchain: a masterchain twin satisfies the
/// commitment and fails the attestation. That fails closed, which is the correct
/// direction.
///
/// WHAT THIS DOES NOT CLOSE, stated plainly: one `StartAuction` attestation can
/// still be re-spent after `CancelAuction` to re-list the same name at a
/// different `startBid`/`duration`/`numYears` for the rest of its window. The
/// sender is the same admin both times, so no sender-binding can separate them.
/// Admin-only, and arguably as designed.
fun attestationHash(nameHash: uint256, emojiCount: int, contentHash: uint256, sigValidUntil: int,
                    policyHash: uint256, purpose: int, boundSender: address): uint256 {
    val domain = beginCell()
        .storeUint(ATTESTATION_DOMAIN, 32)
        .storeAddress(contract.getAddress())
        .storeUint(policyHash, 256)
        // R14-1: the issuance path. Folded into the DOMAIN cell rather than the
        // payload, alongside the registrar address, because it answers the same
        // question — "which door is this signature for" — at a different scale.
        .storeUint(purpose, 8)
        // R24-1: the spender. Same cell, same reasoning — "who may spend this"
        // is a scoping question, not a payload one.
        .storeAddress(boundSender)
        .endCell();
    return beginCell()
        .storeUint(nameHash, 256)
        .storeUint(emojiCount, 16)
        .storeUint(contentHash, 256)
        .storeUint(sigValidUntil, 64)   // S-1: request-scoped validity (replay defense)
        .storeRef(domain)
        .endCell()
        .hash();
}

// Operational budget the registrar must retain from the incoming value to fund
// the mint + resolver syncs it sends (so it never drains its own balance).
fun opsBudgetRegister(resolverCount: int, hasCollection: bool): int {
    // + MAX_PARTNERS forwarding fees, so the budget never depends on how many
    // partners are configured at the moment of a sale
    //
    // R14B1-15: the flat compute term is 30,000,000, not 20,000,000. The 20M was
    // sized for "the fixed part of a registration" and the fixed part had grown:
    // the payout fan-out — up to four `payPartner` sends plus the referral send,
    // each with its own action-phase cost — measures ~12,400 gas (~0.005 GRAM) that
    // nothing in this expression ever budgeted, and R14-1/R14-4/R14-5 have since
    // added an attestation-purpose byte, a carried nonce and a policy hash to the
    // same message. See REGISTER_COMPUTE_PER_BYTE below for the per-byte half.
    var b = resolverCount * SYNC_VALUE + 30000000 + MAX_PARTNERS * 2000000;
    // R20-5b: every caller of this budget is an ISSUANCE (Reveal, AdminMint,
    // AdminImport, StartAuction), so it quotes `MINT_VALUE_FUNDED`. AdoptItem —
    // the one repair path — asserts its own floor directly and never reaches
    // here. R25-4: that floor is now `MINT_VALUE_FUNDED + PUSH_TERM_GAS` too, so
    // a repair and a purchase fund the item identically; the only difference
    // left is that a repair does not pay the resolver fan-out or the partner
    // splits, which is why it is still a separate expression.
    if (hasCollection) { b += MINT_VALUE_FUNDED; }
    return b;
}

// R13-1 (HIGH). THE COMPUTE ALLOWANCE WAS FLAT AND THE COMPUTE IS NOT.
//
// opsBudgetRegister's `20000000` is the ONLY gas money in a registration, and at
// mainnet's 400 nanoton/gas it buys 50,000 gas. `assertCanonicalName` alone walks
// the name at ~3,215 gas/byte, so a 111-byte name costs ~424,566 gas — 0.17 GRAM,
// eight times the allowance. The shortfall does not fail; it is quietly taken out
// of the registrar's own float.
//
// That is invisible on a 20 GRAM tier-2 name. It is not invisible at the bottom
// of the price surface, where the two revenue shares are already at their
// ceilings: with the tier-7 price at its hard floor (0.375 GRAM), four partners
// at the combined 30% cap and a KOL referrer at the 33% cap, 63% of the fee is
// promised out before any gas is paid. Measured at mainnet gas: the registration
// COMPLETES — buyer owns the name, the NFT mints, partners and referrer are paid
// in full — and the registrar ends the transaction POORER than it started.
//
// This is R10-2's lesson arriving from the other direction. There the fix was to
// budget admin compute honestly (ADMIN_COMPUTE_BUDGET, 0.3 GRAM flat, paid by the
// admin). Here the cost is genuinely proportional to the name, and it is the same
// kind of mechanical cost MINT_VALUE and SYNC_VALUE already are — so it is priced
// the same way: per byte, paid by the buyer, on top of the license fee.
//
// R14B1-15. THE MARGIN THE COMMENT CLAIMED WAS NOT THE MARGIN THAT EXISTED.
//
// The paragraph that used to sit here read: "0.0016 GRAM/byte is 4,000 gas/byte at
// the mainnet schedule, ~1.24x the measured 3,215. At the 111-byte worst case the
// total allowance is 0.1976 GRAM against a measured 0.1698 — 16% margin."
//
// Both numbers were derived from `assertCanonicalName` in isolation. The quantity
// that matters is the MARGINAL cost of one more name byte to the WHOLE Reveal
// transaction — the walk, plus the wider cells it drags through hashing, minting
// and the resolver fan-out. Measured by differencing real registrations at
// mainnet gas: 0.001594 GRAM/byte against a 0.001600 allowance. That is a 0.4%
// MARGIN, not 1.24x — six nanoton of headroom per byte, well inside the noise of
// a config change, a gas-price vote, or one more field on the mint message.
//
// Separately, the flat term never budgeted the PAYOUT FAN-OUT at all (~12,400 gas
// for four partner sends plus the referral send); see opsBudgetRegister above,
// where the flat term is now 30,000,000.
//
// 0.002 GRAM/byte restores a real margin: 1.25x the measured 0.001594 marginal, so
// the 111-byte worst case allows 0.222 GRAM against a measured ~0.177, and a
// typical 8-byte two-emoji name pays 0.016 GRAM. Unspent allowance stays with the
// registrar, so an over-estimate costs the buyer only the difference, and
// `registerOpsBudget` lets a front end quote it exactly.
//
// =============================================================================
// R23. 1.25x BECAME 0.84x WITHOUT ANYBODY TOUCHING THIS LINE. THIRD TIME.
// =============================================================================
//
// R23 re-measured every funding constant on both fee schedules (see
// tests/_chainfees.ts for why "both" is now a thing this repo can say precisely).
// Differencing real registrations at 8 / 32 / 56 / 84 / 111 name bytes, with and
// without the four-partner + KOL payout fan-out, on THIS build:
//
//   marginal cost of one name byte    pessimistic row   0.002376586 GRAM/byte
//                                     live row          0.000396098 GRAM/byte
//   allowance                                           0.002000000 GRAM/byte
//
// R14B1-15 measured 0.001594 and set 0.002 for "1.25x". The marginal has grown
// 49% since — R20-6 percent-encodes the URI suffix (a per-byte walk that did not
// exist), R20-7 stores the raw label, R21 added the body-shape guards — so the
// allowance is now 0.84x of what a byte costs on the pessimistic row. Measured
// end to end at that row, 4 partners at the 30% cap and a KOL at the 33% cap:
//
//   name bytes    gas half of ops    consumed     net       headroom
//     8            0.054              0.038954    +0.015046   1.386x
//    32            0.102              0.094935    +0.007065   1.074x
//    56            0.150              0.151626    -0.001626   0.989x   <- crosses here
//    84            0.206              0.217766    -0.011766   0.946x
//   111            0.260              0.283742    -0.023742   0.916x
//
// Past ~56 bytes the registrar completes the registration and pays for part of it
// out of its own float. That is R13-1's finding — "the registrar ends the
// transaction POORER than it started" — arriving for the second time, by the
// same door R22-1 found ITEM_FULL_RENT coming through: the CODE grew underneath a
// constant that had been set to a measured edge.
//
// THIS IS NOT WHAT THE 2026-04-29 FEE CUT DID. On the live row the same byte
// costs 0.000396 and the allowance is 5.05x. The cut made this constant look
// generous while it was in fact already under water on the row it was sized
// against, which is precisely why R23 measures both and sizes against the worse.
//
// 0.003 GRAM/byte:
//
//   pessimistic row   0.003 / 0.002376586 = 1.262x   (R14B1-15's stated target)
//   live row          0.003 / 0.000396098 = 7.574x
//
// and it absorbs a further 26% of per-byte code growth on the pessimistic row
// before it is at parity again — roughly what R20+R21 added put together.
//
// WHAT IT COSTS THE BUYER, STATED. +0.001 GRAM per name byte: +0.008 on the
// 8-byte two-emoji name that is the common case (0.5% of the 1.5 GRAM tier-6/7
// launch price, 2.1% of the immutable 0.375 floor), +0.111 at the 111-byte
// ceiling. `registerOpsBudget` quotes it exactly, so a front end shows the real
// number rather than an estimate.
const REGISTER_COMPUTE_PER_BYTE: int = 3000000;   // 0.003 GRAM/byte (R23; R14B1-15 had 0.002, R13-1 0.0016)

fun nameByteLen(rawName: cell): int {
    return rawName.beginParse().remainingBitsCount() / 8;
}

/**
 * V7-19b: a staged timelock DECREASE becomes effective only once the timelock
 * that was in force when it was requested has elapsed. Applied lazily wherever
 * the timelock is read, so no keeper is needed.
 */
fun applyPendingTimelock(mutate st: Storage, nowTime: int) {
    if (st.pendingTimelockAt != 0 && nowTime >= (st.pendingTimelockAt as int)) {
        st.adminTimelock = st.pendingTimelock;
        st.pendingTimelock = 0;
        st.pendingTimelockAt = 0;
    }
}

fun countResolvers(resolvers: map<uint256, address>): int {
    var n = 0;
    var e = resolvers.findFirst();
    while (e.isFound) { n += 1; e = resolvers.iterateNext(e); }
    return n;
}

/**
 * V7-1: what the contract must keep back so it can always follow its own NFTs.
 * Rent floor plus a burst of unfunded resolver fan-outs.
 *
 * R13-3: plus the outbid-refund float for every LIVE auction lot. See
 * AUCTION_OPS_RESERVE — a lot is an open-ended stream of PAY_FEES_SEPARATELY
 * refunds the contract funds from its own balance, and this was the one
 * obligation freeBalance() could see and did not reserve.
 */
// commitment = H(nameHash ‖ salt ‖ committerAddress-hash)
// effective referral rate for a given referrer: their KOL override if set,
// otherwise the public rate. Bounded by the KOL hard cap defensively.
fun effectiveReferralBps(rates: map<uint256, uint16>, publicBps: int, referrerHash: uint256): int {
    val found = rates.get(referrerHash);
    if (found.isFound) {
        val r = found.loadValue();
        return (r > REFERRAL_KOL_BPS_CEIL) ? REFERRAL_KOL_BPS_CEIL : r;
    }
    return publicBps;
}

fun commitmentHash(nameHash: uint256, salt: uint256, committer: address): uint256 {
    val (_wc, committerHash) = committer.getWorkchainAndHash();
    return beginCell()
        .storeUint(nameHash, 256)
        .storeUint(salt, 256)
        .storeUint(committerHash, 256)
        .endCell()
        .hash();
}

// A name may be auctioned / admin-minted only if it is not reserved, not
// currently active (incl. grace), and has no live auction.
// Proves `rawName` is genuinely the name behind `nameHash`, then rejects any
// name containing a skin-tone modifier. Called on EVERY issuance path.
//
// V7-28 — it now also BOUNDS THE ATTESTED TIER against those same bytes.
// Before this, `emojiCount` was pure signer testimony with no on-chain relation
// to the name, and the tier is not cosmetic: it selects the first-year price and
// the renewal annuity, it decides ERR_SINGLE_LOCKED (whether a name may be
// bought outright at all, or must clear a >=150 GRAM auction), and it gates
// MakePermanent. A signer that could be induced to attest emojiCount=2 for a
// ONE-emoji name handed an attacker the whole singles class at the tier-2 price.
// That contradicted the standing rule stated below, so the same scan closes it.
/// R9-2. THE FLOOR UNDER THE SIGNER — is this codepoint even in our namespace?
///
/// ===========================================================================
/// THE HOLE THIS CLOSES
/// ===========================================================================
/// `assertCanonicalName` validated UTF-8, refused skin tones, refused 38
/// confusables and segmented the tier. It never asked whether a codepoint was an
/// emoji at all. A codepoint below 0x80 decoded cleanly, opened a unit, and was
/// counted — so with a signature over it, THESE ALL MINTED AND RESOLVED:
///
///     "emoji"    exit 0, resolves   <- the literal zone label of this project
///     "paypal"   exit 0, resolves
///     "binance"  exit 0, resolves
///     "аррӏе"    exit 0, resolves   <- Cyrillic homograph of "apple"
///     "ΑΒΓ"      exit 0, resolves
///
/// (measured — scripts/_asciiname.ts). The off-chain normalizer refuses every one
/// of them with reason `not_emoji`, so nothing could mint them while the signer
/// behaved. That is exactly the dependency V7-4 and this function's own header
/// claim to have removed: *"A compromised signer can no more mint 🙁 than it can
/// mint 👍🏽."* True of those two, false of `paypal` — and a Latin-script phishing
/// name in an emoji namespace is a worse outcome than any confusable pair this
/// contract spent three rounds blocking.
///
/// ===========================================================================
/// THE RULE
/// ===========================================================================
/// A whitelist of 41 ranges, DERIVED not guessed: scripts/_cpranges.ts walks the
/// frozen table (wrappers/emoji-table.json — the same artifact policyHash()
/// commits to), collects every codepoint any legal name can contain (1384 of
/// them), and merges them across gaps of at most 24. Result: 2077 codepoints
/// admitted, 693 more than are strictly legal.
///
/// It is deliberately an OVER-approximation. RGI is a 2055-entry table and cannot
/// live in TVM; the off-chain normalizer remains the authority on *which*
/// sequences are names. This is the floor beneath it — coarse enough to fit,
/// tight enough that the 693 extras are all symbols and dingbats. Verified in
/// tests/R9NamespaceFloor.spec.ts to admit every one of the 2055 frozen units and
/// to reject Latin, Cyrillic, Greek, Hebrew, Arabic, Hiragana, Katakana, CJK,
/// Hangul, Devanagari, Thai, fullwidth forms, and every invisible control the
/// merge could have swept in — ZWSP, ZWNJ, word joiner, BOM, soft hyphen, the
/// LRM/RLM/LRO/RLO bidi overrides and the combining enclosing marks. The gap was
/// tightened from 128 to 24 specifically to keep the bidi block out.
fun isNamespaceCodepoint(cp: int): bool {
    // Ordered by expected frequency: real names are overwhelmingly in the
    // supplementary emoji planes, so those compare first.
    if (cp >= 0x1F000) {
        if (cp >= 0x1F300 && cp <= 0x1F550) { return true; }
        if (cp >= 0x1F56F && cp <= 0x1F64F) { return true; }
        if (cp >= 0x1F680 && cp <= 0x1F6FC) { return true; }
        if (cp >= 0x1F90C && cp <= 0x1F9FF) { return true; }
        if (cp >= 0x1FA70 && cp <= 0x1FAF8) { return true; }
        if (cp >= 0x1F1E6 && cp <= 0x1F251) { return true; }   // flags + enclosed
        if (cp >= 0x1F7E0 && cp <= 0x1F7F0) { return true; }
        if (cp >= 0x1F170 && cp <= 0x1F19A) { return true; }
        if (cp == 0x1F004 || cp == 0x1F0CF) { return true; }   // 🀄 🃏
        // TAG CHARACTERS — the ten letters RGI's three subdivision flags use
        // (gb-eng, gb-sct, gb-wls) plus the terminator, and nothing else. The
        // wider E0020..E007F block is invisible by construction, so admitting it
        // would allow unlimited invisible variants of the same rendered 🏴.
        if (cp >= 0xE0062 && cp <= 0xE0063) { return true; }   // b c
        if (cp == 0xE0065 || cp == 0xE0067) { return true; }   // e g
        if (cp == 0xE006C || cp == 0xE006E) { return true; }   // l n
        if (cp >= 0xE0073 && cp <= 0xE0074) { return true; }   // s t
        if (cp == 0xE0077 || cp == 0xE007F) { return true; }   // w, cancel-tag
        return false;
    }
    if (cp >= 0x2000) {
        if (cp >= 0x2600 && cp <= 0x2764) { return true; }     // misc symbols + hearts
        if (cp >= 0x2795 && cp <= 0x27BF) { return true; }     // dingbats
        if (cp >= 0x2194 && cp <= 0x21AA) { return true; }     // arrows
        if (cp >= 0x231A && cp <= 0x2328) { return true; }     // watch..keyboard
        if (cp >= 0x23E9 && cp <= 0x23FA) { return true; }     // media controls
        if (cp >= 0x25B6 && cp <= 0x25C0) { return true; }     // play / reverse
        if (cp >= 0x2B05 && cp <= 0x2B1C) { return true; }     // arrows + squares
        if (cp >= 0x2B50 && cp <= 0x2B55) { return true; }     // star, circle
        if (cp >= 0x2122 && cp <= 0x2139) { return true; }     // ™ ℹ
        if (cp >= 0x203C && cp <= 0x2049) { return true; }     // ‼ ⁉
        if (cp >= 0x3030 && cp <= 0x303D) { return true; }     // 〰 〽
        if (cp >= 0x3297 && cp <= 0x3299) { return true; }     // ㊗ ㊙
        if (cp == 0x200D) { return true; }                     // ZWJ
        if (cp == 0x20E3) { return true; }                     // combining keycap
        if (cp == 0x23CF) { return true; }                     // ⏏
        if (cp == 0x24C2) { return true; }                     // Ⓜ
        if (cp == 0x2934 || cp == 0x2935) { return true; }     // ⤴ ⤵
        if (cp == 0xFE0F) { return true; }                     // VS-16
        return false;
    }
    // Below U+2000 the namespace holds exactly five things, and three of them are
    // ASCII keycap BASES that are illegal on their own — see the companion rule
    // in assertCanonicalName. Everything else here is a writing system.
    if (cp >= 0x30 && cp <= 0x39) { return true; }             // 0-9, keycap bases
    if (cp == 0x23 || cp == 0x2A) { return true; }             // # *, keycap bases
    if (cp == 0xA9 || cp == 0xAE) { return true; }             // © ®
    return false;
}

fun checkCanonicalName(rawName: cell, nameHash: uint256, emojiCount: int): int {
    var s = rawName.beginParse();
    // R17-7 SIBLING. THE GETTER GOT THIS GUARD AND THE PAID PATH DID NOT.
    //
    // `bitsHash()` compiles to SHA256U, which throws cell-underflow on a slice
    // whose bit count is not a multiple of 8 — so a ragged `rawName` never reaches
    // any of the refusals below, and the throw happens one line into the most
    // expensive handler in the contract. R10-3 added exactly this line to the
    // `checkName` GETTER (see the assert near the bottom of this file) and not
    // here, which `Reveal` calls. Measured on the same cell: the getter answers
    // 457 correctly while the paid reveal is exit 9 and confiscates 120.13 GRAM
    // from a bounce-stripping wallet.
    //
    // Returning 457 rather than throwing is what lets `Reveal`'s existing
    // `refundAndStop` handle it — a ragged cell is not well-formed UTF-8 by
    // definition, which is precisely what 457 says.
    if (s.remainingBitsCount() % 8 != 0) { return ERR_NAME_NOT_UTF8; }
    // R23-1 (HIGH). THE NAME IS ITS BYTES. IT IS NOT ALLOWED TO CARRY A SUBTREE.
    //
    // ===========================================================================
    // WHAT WAS OPEN
    // ===========================================================================
    // Every bound in this function — this one, the hash binding below, the length
    // ceiling, the UTF-8 walk, `nameByteLen`, `checkContentBindsName` — reads
    // `remainingBitsCount()`, and `bitsHash()` is SHA256U over the ROOT CELL'S
    // DATA BITS ONLY. Not one of them looks at refs. `content` gets an explicit
    // `remainingRefsCount()` bound, `parties` and `signature` get one, and
    // `rawName` — added later, for the label the item stores — got none on any of
    // the four issuance paths.
    //
    // So a `rawName` carrying the correct 8 canonical bytes PLUS four arbitrary
    // ref subtrees hashed correctly, matched the signer's attestation, passed
    // every namespace rule, priced as an ordinary name, and was then handed
    // through `MintFwd` -> `InitOrReassign` -> `storage.label` verbatim, because
    // the collection passes it through and the item has no bound of its own.
    //
    // Measured end to end on the pre-fix build, ordinary retail commit/reveal, no
    // privilege of any kind:
    //
    //   rawName cells       1        1,365          5,461
    //   reveal exit         0        0              0            <- all accepted
    //   item account       44 cells  1,408 cells    5,504 cells
    //   rent/yr (pess.)    0.019     0.368          1.417 GRAM
    //   freeze horizon     31.5 y    1.59 y         0.388 y      <- term sold: 5 y
    //
    // Two distinct harms, and the second is the one that does not require the
    // attacker to hurt themselves:
    //
    //   RENT INSOLVENCY. `ITEM_FULL_RENT` is derived in emoji_nft_item.tolk
    //   against a label budgeted at "1 cell + 888 bits". The real ceiling was
    //   `max_msg_cells`. A buyer could be sold a 5-year term on an item that
    //   freezes inside a year, and a frozen item is the unrepairable divergence:
    //   `get_nft_data` throws, resolution stops, the registry still shows the name
    //   live, and no repair op reaches it.
    //
    //   DISPLAY SPOOFING. `get_domain()` returns `label.beginParse()` and
    //   `get_full_domain()` does `.storeSlice(...)`, and storeSlice COPIES REFS.
    //   A bits-only reader sees "🌈✨"; a standard snake-string decode — the normal
    //   way a `.ton`-family domain cell is read — sees 7,323 bytes ending in
    //   "— verified by paypal.com". The item's own advertised integrity check,
    //   `sha256(get_domain()) == index`, PASSES for the poisoned item under a
    //   bits-only hash, so the two readers disagree about which name the item is
    //   while the check that exists to prevent exactly that reports success. It
    //   resells normally: no getter exposes it, only an account cell count does.
    //
    // It is an ACCIDENT vector too, not only an attack one — any front end that
    // builds the name cell with a ref attached produces it silently.
    //
    // ===========================================================================
    // THE RULE
    // ===========================================================================
    // A name is a flat byte string. TEP-81's internal representation is a flat
    // byte string. There is no legitimate reason for `rawName` to have a child,
    // and refusing one costs a single instruction on the hottest path in the
    // contract. Placed ABOVE the hash binding deliberately: the hash cannot speak
    // for the subtree, so the subtree must be gone before the hash is trusted.
    //
    // 457 rather than a new code: a cell with children is not the well-formed
    // UTF-8 byte string this function exists to certify, which is what 457 says,
    // and `Reveal` already refunds on it rather than confiscating.
    if (s.remainingRefsCount() != 0) { return ERR_NAME_NOT_UTF8; }
    // sha256 over the data bits — binds these bytes to the hash the signer attested
    if (s.bitsHash() != nameHash) { return ERR_NAME_BYTES_MISMATCH; }
    // F-9: refuse anything that could not survive a TEP-81 resolution walk
    if (s.remainingBitsCount() > MAX_NAME_BYTES * 8) { return ERR_NAME_TOO_LONG; }

    // R17-E1. THE FOUR "DNS-HOSTILE" LENGTHS ARE DELIBERATELY *NOT* ENFORCED HERE.
    //
    // `opentonapi/pkg/api/dns_handlers.go:78-80` returns a hard HTTP 400 for any
    // domain whose UTF-8 byte length is exactly 48 or 52 (live-verified). With the
    // two suffixes this project publishes — `.emojiverse.ton` (+15) and `.emoji`
    // (+6) — that lands on name lengths 33, 37, 42 and 46, which mint and resolve
    // on chain but are invisible to the reference indexer.
    //
    // R18 briefly enforced that here and it was REVERTED, for three measured
    // reasons that are worth preserving so nobody re-adds it:
    //
    //   1. It is one vendor's input-validation quirk, not a property of TON,
    //      TEP-81 or this namespace. An immutable contract must not carry another
    //      party's bug: the day tonapi relaxes the check, four byte-lengths stay
    //      dead forever with no way to revive them.
    //   2. It cost 11.4% of the adversarial multi-unit names in this repo's own
    //      `R9SegmenterFuzz` / `R9NamespaceFloor` corpora — a large, permanent
    //      hole in the namespace bought for an external, temporary constraint.
    //   3. `wrappers/normalization.ts` did not mirror it, so the signer attested
    //      names the chain then refused. That is exactly the V7-32 class the
    //      mirror exists to prevent, and it is a worse defect than the one the
    //      rule was closing.
    //
    // The constraint is real and is enforced where it belongs — in the mutable
    // off-chain layer that can track tonapi's behaviour:
    // `integration/tonapi/emojiNames.ts` rejects both name forms client-side with
    // a typed error before any API call, and the signer applies the same rule.
    // See docs/TONAPI_INTEGRATION.md.

    // ONE rolling 4-byte window serves both permanent namespace rules.
    //
    //   1. SKIN TONES  — F0 9F 8F followed by BB..BF (U+1F3FB..1F3FF).
    //   2. CONFUSABLE VARIANTS — the 38 emoji whose look-alike class already has
    //      a designated survivor (wrappers/normalization.ts BLOCKED_GROUPS).
    //
    // Both are enforced HERE, in TVM, after the raw bytes have been proven
    // against nameHash — so neither depends on the off-chain signer. A
    // compromised signer can no more mint 🙁 than it can mint 👍🏽.
    //
    // The 38 blocked emoji collapse into 13 contiguous codepoint ranges, and
    // every range shares its leading UTF-8 bytes, so each costs one prefix
    // match plus a bound on the final byte. The survivor of each group differs
    // from its variants in that final byte and is therefore never matched
    // (😮 U+1F62E survives; 😯 U+1F62F, one codepoint away, does not).
    var b1 = 0;
    var b2 = 0;
    var b3 = 0;
    // V7-28 segmenter state — decodes UTF-8 alongside the byte window.
    var pending = 0;        // continuation bytes still owed by the current codepoint
    var cp = 0;             // codepoint under construction
    var cpMin = 0;          // R9-7: smallest codepoint the current form may legally encode
    var units = 0;          // emoji units counted so far
    var prevWasZwj = false; // the previous codepoint was U+200D
    var prevWasVs16 = false; // R17-29: the previous codepoint was U+FE0F
    var riOpen = false;     // an unpaired regional indicator is open
    var keycapOwed = false; // R9-2: an ASCII base is open and still owes U+20E3
    var tagOpen = false;    // R26-1: a U+1F3F4 tag base is open and may carry tag characters
    var tagLen = 0;         // R26-1b: tag letters consumed in the open run, terminator not yet seen
    var tagAcc = 0;         // R26-1b: those letters packed one byte each, to match against RGI
    while (s.remainingBitsCount() >= 8) {
        val b = s.loadUint(8);
        if (b1 == SKINTONE_B0 && b2 == SKINTONE_B1 && b3 == SKINTONE_B2
            && b >= SKINTONE_LO && b <= SKINTONE_HI) {
            return ERR_SKIN_TONE_BLOCKED;
        }
        // --- blocked confusable variants, 4-byte sequences (F0 9F xx yy) ---
        if (b1 == 0xF0 && b2 == 0x9F) {
            // clock faces U+1F551..1F567          survivor 🕐 U+1F550
            if (b3 == 0x95 && b >= 0x91 && b <= 0xA7) { return ERR_CONFUSABLE_VARIANT; }
            // MOON PHASES — repartitioned in V7-27.
            //
            // The old split blocked U+1F313..14 and U+1F316..17, keeping 🌒 and 🌘.
            // That was inverted against its own purpose: the moon family is three
            // MIRROR PAIRS by lit area — crescents 🌒/🌘, halves 🌓/🌗, gibbous
            // 🌔/🌖 — and the old partition kept BOTH members of the crescent pair
            // (the most confusable relationship in the set, pure reflection) while
            // removing four phases that are plainly distinguishable from each
            // other. Two independent audit passes reached this by different routes.
            //
            // Now: keep one moon per lit-area level (🌑 🌒 🌓 🌔 🌕) and block the
            // mirrored waning half (🌖 🌗 🌘 = U+1F316..18). Every blocked emoji is
            // the exact reflection of a surviving one, which is as close to
            // identical as this family gets — consistent with the project's rule
            // that only genuinely indistinguishable forms are blocked outright.
            //
            // Strictly better on all three axes: removes a real collision, blocks
            // one FEWER emoji (4 -> 3) and recovers 🌓 🌔 into the namespace, and
            // collapses two byte ranges into one.
            if (b3 == 0x8C && b >= 0x96 && b <= 0x98) { return ERR_CONFUSABLE_VARIANT; }
            // 🗸 U+1F5F8                           survivor ✔ U+2714
            if (b3 == 0x97 && b == 0xB8) { return ERR_CONFUSABLE_VARIANT; }
            // 😟 U+1F61F (keep 😕) · 😦😧 U+1F626..27, 😯 U+1F62F, 😲 U+1F632 (keep 😮)
            //
            // R8-3: 😗 U+1F617, 😙 U+1F619, 😚 U+1F61A joined this line — survivor
            // 😘 U+1F618, which is the 0x98 deliberately absent from the range.
            //
            // dns.ton.org/about.html gives the Foundation's whole stated reason
            // for not having emoji domains in one sentence, and it names this
            // pair: "a lot of them look the same — e.g., 😗 and 😙 — which
            // scammers would use to trick unsuspecting users easily."
            //
            // TEP-81 says a zone contract may impose its own name limits "to
            // avoid similar characters to protect against phishing". That
            // argument only carries weight if the example they published is one
            // this contract already refuses, in bytes, before anything is minted
            // — not one a front end warns about after the fact.
            //
            // R8-4 widened this line. A 16px render audit across four vendors'
            // real artwork measured every candidate pair; the rule applied was
            // "block under d=0.10, or under d=0.145 when a member is top-100 by
            // use and the difference is not hue, or when the difference is pure
            // size". Additions here, all in the U+1F6xx face block:
            //   😀 80 😃 83 😄 84   survivor 😆 86 (rank 21, the most used)
            //   😌 8C               survivor ☺ U+263A
            //   😐 90 😑 91 😶 B6   survivor 😕 U+1F615 — d(😕,😐)=0.044, TIGHTER
            //                       than ☹/🙁=0.054 which this contract already
            //                       refused. The old block had a hole closer to
            //                       its own survivor than its own members.
            //   😫 AB               survivor 😩 A9
            if (b3 == 0x98 && (b == 0x80 || b == 0x83 || b == 0x84 || b == 0x8C
                            || b == 0x90 || b == 0x91
                            || b == 0x97 || b == 0x99 || b == 0x9A
                            || b == 0x9F || (b >= 0xA6 && b <= 0xA7)
                            || b == 0xAB || b == 0xAF || b == 0xB2 || b == 0xB6)) {
                return ERR_CONFUSABLE_VARIANT;
            }
            // 👿 U+1F47F                          survivor 😈 U+1F608 (d=0.077)
            if (b3 == 0x91 && b == 0xBF) { return ERR_CONFUSABLE_VARIANT; }
            // 💞 U+1F49E                          survivor 💕 U+1F495 (d=0.137,
            // 💕 is rank 7 and hearts are the most-registered emoji class)
            if (b3 == 0x92 && b == 0x9E) { return ERR_CONFUSABLE_VARIANT; }
            // 📂 U+1F4C2 (keep 📁) · 📥 U+1F4E5 (keep 📤) — d=0.084 / 0.087
            if (b3 == 0x93 && (b == 0x82 || b == 0xA5)) { return ERR_CONFUSABLE_VARIANT; }
            // 🔂 U+1F502                          survivor 🔁 U+1F501 (d=0.080)
            if (b3 == 0x94 && b == 0x82) { return ERR_CONFUSABLE_VARIANT; }
            // 🖐 U+1F590 · 🖖 U+1F596             survivor ✋ U+270B (d=0.117-0.139;
            // the finger gaps that separate them are sub-pixel at 16px)
            if (b3 == 0x96 && (b == 0x90 || b == 0x96)) { return ERR_CONFUSABLE_VARIANT; }
            // 🫢 U+1FAE2 (keep 🤭) · 🫤 U+1FAE4 (keep 😕) — both Emoji 14, both
            // unranked: obscure enough that nobody knows they exist, close
            // enough to stand in for a popular name.
            if (b3 == 0xAB && (b == 0xA2 || b == 0xA4)) { return ERR_CONFUSABLE_VARIANT; }
            // 🙁 U+1F641                           survivor 😕 U+1F615
            if (b3 == 0x99 && b == 0x81) { return ERR_CONFUSABLE_VARIANT; }
            // 🩵 U+1FA75 (keep 💙) · 🩶 U+1FA76 (keep 🖤)
            if (b3 == 0xA9 && (b == 0xB5 || b == 0xB6)) { return ERR_CONFUSABLE_VARIANT; }
        }
        // --- 3-byte sequences: ♥ U+2665 (keep ❤) · ☹ U+2639 (keep 😕) ---
        // 0xE2 is a 3-byte lead byte and can never appear as a continuation
        // byte of a 4-byte sequence, so this cannot collide with the above.
        // R8-4 adds the SIZE DUPLICATES. ◻ U+25FB ◽ U+25FD ◼ U+25FC ◾ U+25FE
        // (0x97 BB..BE) and ▫ U+25AB ▪ U+25AA (0x96 AA..AB), survivors ⬜ U+2B1C
        // and ⬛ U+2B1B. Measured 0.039-0.092, and these have the LOWEST
        // cross-vendor divergence of anything in the set — the confusion is
        // identical on every platform, and vendors disagree about which of the
        // four is drawn larger. Blocking them costs nothing expressive: the
        // colour distinction survives untouched, only redundant sizes go.
        // ☺ U+263A (0x98 BA) is a SURVIVOR and deliberately absent below.
        if (b2 == 0xE2 && ((b3 == 0x99 && b == 0xA5) || (b3 == 0x98 && b == 0xB9)
                        || (b3 == 0x97 && b >= 0xBB && b <= 0xBE)
                        || (b3 == 0x96 && (b == 0xAA || b == 0xAB)))) {
            return ERR_CONFUSABLE_VARIANT;
        }
        b1 = b2;
        b2 = b3;
        b3 = b;

        // ---- V7-28: UTF-8 decode + emoji-cluster segmentation, same pass ----
        var complete = false;
        if (pending == 0) {
            // cpMin is the smallest codepoint each form is allowed to carry, so an
            // OVERLONG encoding (a codepoint spelled in more bytes than it needs) is
            // refused below. C0/C1 leads are overlong by definition and caught by
            // the 2-byte floor of 0x80.
            if (b < 0x80)      { cp = b; complete = true; cpMin = 0; }
            else if (b < 0xC0) { return ERR_NAME_NOT_UTF8; }        // stray continuation
            else if (b < 0xE0) { pending = 1; cp = b & 0x1F; cpMin = 0x80; }
            else if (b < 0xF0) { pending = 2; cp = b & 0x0F; cpMin = 0x800; }
            else if (b < 0xF8) { pending = 3; cp = b & 0x07; cpMin = 0x10000; }
            else               { return ERR_NAME_NOT_UTF8; }        // 5-byte form
        } else {
            if ((b & 0xC0) != 0x80) { return ERR_NAME_NOT_UTF8; }   // truncated sequence
            cp = (cp << 6) | (b & 0x3F);
            pending -= 1;
            complete = pending == 0;
        }

        // R9-7. CANONICAL UTF-8 ONLY (RFC 3629). Without this, an OVERLONG form —
        // e.g. `#` (U+0023) spelled C0 A3 instead of 23 — decodes to a codepoint the
        // namespace floor admits (0x23 is a keycap base) and MINTS AS A DISTINCT
        // NAME with a different nameHash that renders identically to the canonical
        // `#️⃣`. That is a byte-level homograph, and the whole point of R9-2 /
        // skin-tone / confusable enforcement in TVM is that it holds even against a
        // compromised signer (an honest signer never emits overlong bytes, but a
        // compromised one could sign sha256 over them). An overlong ZWJ (U+200D)
        // would be worse still — it would fabricate a joiner and change the tier.
        // Also refuse UTF-16 surrogate halves, which are not scalar values.
        //
        // R14B1-7. R9-7 CLOSED TWO OF THE THREE NON-SCALAR FAMILIES.
        //
        // `cpMin` catches overlongs and the surrogate bound catches D800..DFFF, but
        // nothing bounded the codepoint ABOVE. The `b < 0xF8` arm accepts lead bytes
        // F5, F6 and F7 — which RFC 3629 removed from UTF-8 entirely when Unicode
        // was capped at U+10FFFF — and accepts F4 followed by 90..BF, which decodes
        // to U+110000..U+13FFFF. All six probe forms are non-scalar: no encoder can
        // produce them, no decoder should accept them, and `beginCell().storeBuffer`
        // on the wrapper side cannot even build them from a JS string.
        //
        // Measured before this line: the identical decoder inside `emojiUnitsOf`
        // returned 1 emoji for every one of the six probes (F5/F6/F7 leads and
        // F4 90/F4 A0/F4 BF), while `checkName` refused them with 462 — the
        // NAMESPACE code, not the malformed-UTF-8 code, because the floor happened
        // to reject the out-of-range value for the wrong reason. Two get methods
        // that are documented as the same rule disagreed about what the input even
        // was. After this line both answer 457.
        if (complete) {
            if (cp < cpMin) { return ERR_NAME_NOT_UTF8; }
            if (cp >= 0xD800 && cp <= 0xDFFF) { return ERR_NAME_NOT_UTF8; }
            if (cp > 0x10FFFF) { return ERR_NAME_NOT_UTF8; }
        }

        if (complete) {
            // R9-2. THE FLOOR. Before this line the loop happily counted `p`,
            // `а` and `Α` as emoji units. See isNamespaceCodepoint above.
            if (!isNamespaceCodepoint(cp)) { return ERR_NOT_EMOJI_CODEPOINT; }

            // A codepoint CONTINUES the current unit when it is a joiner, a
            // modifier, or the codepoint a joiner reaches for. Everything else
            // opens a new unit. These six classes are the entire RGI grammar as
            // far as counting is concerned — see scripts/segment-reference.ts,
            // which is the same algorithm and is proven equivalent to the
            // off-chain normalizer over the whole namespace.
            val isZwj = cp == 0x200D;
            val isRi  = cp >= 0x1F1E6 && cp <= 0x1F1FF;
            // R30-1. A JOINER MUST JOIN SOMETHING, AND R26-2 CLOSED ONLY THE
            // END-OF-NAME HALF OF THAT.
            //
            // `prevWasZwj` is recomputed on every complete codepoint, so ANYTHING
            // at all after the ZWJ clears it and R26-2's trailing check never sees
            // it. Four of the five continuers happen to be refused for an unrelated
            // reason — a tag char needs `tagOpen` (R26-1b), U+20E3 needs
            // `keycapOwed` (R9-2), a skin tone dies in the byte scan, and a second
            // ZWJ re-arms `prevWasZwj` — but U+FE0F is the one continuer with no
            // companion rule of its own (R17-29 enforced only "no VS-16 on VS-16"
            // and "no VS-16 opening the name"), so this walked straight through:
            //
            //     1F680 1F319 200D FE0F   accepted at exit 0, emojiCount 2
            //
            // That is NOT the RGI residual R26 §4 accepted. R26 priced that residual
            // on one property — a join collapses two units into one, so an impostor
            // lands in the singles tier and costs MORE than the name it imitates.
            // These shapes collapse nothing. The unit count, and therefore the tier
            // and the price, are identical to the genuine name, so `🚀🌙 ZWJ VS16` is
            // a tier-2 impostor of 🚀🌙 at 🚀🌙's price. The fence R26 leaned on is
            // simply not present here.
            //
            // Two harms, both of which this file's own comments already name as the
            // reason the floor exists at all. First, `checkName` is the oracle
            // integrators are told to trust — a user pastes a poisoned 🚀🌙, is told
            // it is registrable, pays COMMIT_MIN_VALUE, and can never construct a
            // Reveal, because the normalizer answers `not_emoji`. Second, the TVM
            // floor is what makes "a compromised signer can no more mint 🙁 than it
            // can mint 👍🏽" true, and against this family it was not.
            //
            // Enumerated from the segmenter's continuer set rather than from the
            // witness codepoint — the acceptance criterion R26 should have used:
            // 0 of the 2,055 frozen units break (248 contain a ZWJ, none has one
            // followed by a continuer), and no RGI sequence can, because a modifier
            // must follow a modifier base, VS-16 applies to the character before it,
            // and tag runs and keycaps contain no ZWJ. Measured on the compiled
            // bytecode over 25,259 generated multi-unit names, the canonicalised
            // accept-set, and an exhaustive length-1..3 sweep: zero regressions.
            //
            // THREE OF THE FIVE CONTINUERS ARE OMITTED ON PURPOSE. A skin tone after
            // a ZWJ already dies in the byte scan one statement earlier (440), and a
            // tag character already needs `tagOpen`, which is reassigned on every
            // non-tag codepoint and so is always false after a ZWJ, leaving R26-1b to
            // return the same 462. Both clauses are dead, verified across three
            // builds and 38,646 inputs — narrow, eager-wide and short-circuit-wide
            // agree on every one, including the differential class exhaustively (all
            // 101 dropped codepoints in every reachable prevWasZwj state).
            //
            // Dead clauses in an immutable contract are not free. Measured marginal
            // cost on the ZWJ ladder: 754 gas per codepoint for the wide form against
            // 230 for this one. `checkName` has to answer under a 300,000-gas
            // liteserver ceiling (client_method_gas_limit, an enum in ton's
            // validator/impl/liteserver.hpp — not configurable), and of 1,744 legal
            // ZWJ-heavy names 545 were ALREADY over it before this round. The wide
            // form put 26 more over; this form puts 1 over (🏳️‍🌈 x5, 70 bytes, 674 gas
            // past the line) and brings the other 25 back under.
            //
            // WHAT THIS DOES NOT CLOSE, measured rather than assumed: the VS-16
            // family needs no ZWJ at all. `1F680 1F319 FE0F` is one codepoint
            // SHORTER than the witness, segments to the same 2 units, prices at the
            // same tier, and is still accepted. Across the namespace that is 4,918
            // chain-acceptable spellings for 2,055 names — 2,863 impostors, of which
            // this rule closes none — plus 518 flag spellings where the chain's tier
            // and the normalizer's disagree. Closing it needs the full
            // presentation-selector rule (~117 ranges), and it is NOT taken here,
            // deliberately: R9-2's own header says this floor is a codepoint-class
            // over-approximation and that SEQUENCE legality lives off chain with the
            // signer. 680 codepoints in the floor are not emoji at all. Spending
            // immutable code to close one family while that remains is whack-a-mole,
            // and the honest signer refuses every one of the 2,863 today.
            //
            // The consequence that IS real — `checkName` telling a paying user a
            // name is registrable when the signer will refuse it — is fixed where it
            // belongs, in the integrator kit: the frozen normalizer is the oracle,
            // not this get method. See integration/README.md.
            //
            // `emojiUnitsOf` deliberately does NOT get this rule: it is a counter,
            // not a validity oracle (its own docstring says so), and because this
            // check RETURNS rather than reclassifying the unit, the two loops still
            // agree on the count for every name `checkName` accepts — verified over
            // 800+ names on chain, and structurally guaranteed by the `return`.
            if (prevWasZwj && (isZwj || cp == 0xFE0F || cp == 0x20E3)) {
                return ERR_NOT_EMOJI_CODEPOINT;
            }
            var newUnit = true;
            if (prevWasZwj) {
                newUnit = false;                                    // ZWJ joins what follows
            } else if (isZwj
                    || cp == 0xFE0F                                 // VS-16
                    || cp == 0x20E3                                 // combining keycap
                    || (cp >= 0xE0020 && cp <= 0xE007F)             // tag characters
                    || (cp >= 0x1F3FB && cp <= 0x1F3FF)) {          // skin tones (already refused)
                newUnit = false;
            } else if (isRi && riOpen) {
                newUnit = false;                                    // closes a flag pair
            }
            // R9-2, second half. THE ASCII BASES ARE ONLY LEGAL UNDER A KEYCAP.
            //
            // `0-9 # *` have to be admitted above because RGI's keycaps are
            // built on them (1️⃣ = 0031 FE0F 20E3). Admitted bare, they hand back
            // most of what the whitelist just took away: "1234567" would be a
            // legal 7-unit name, and every numeric brand with it.
            //
            // So an ASCII base opens an OBLIGATION: the unit it starts must
            // contain U+20E3 before the unit closes. Anything else — a new unit
            // opening, or the name ending — is ERR_BARE_KEYCAP_BASE.
            //
            // This also closes V7-3 on chain rather than only in the normalizer.
            // V7-3 was `A⃣D⃣I⃣D⃣A⃣S⃣`: the keycap branch checked the combining mark
            // and never the base. The whitelist refuses the Latin bases outright,
            // and this refuses a base with no mark, so both halves are now
            // enforced in TVM.
            //
            // R14B1-6. THE RULE WAS ONE-DIRECTIONAL, AND THE OTHER DIRECTION MINTS.
            //
            // R9-2 asserted "an ASCII base must be FOLLOWED by U+20E3". It never
            // asserted the converse — "U+20E3 must FOLLOW an ASCII base" — so the
            // combining keycap mark was free to attach to ANYTHING. U+20E3 is in
            // the namespace whitelist (it has to be, keycaps are built on it) and
            // the segmenter treats it as a continuer, so it changes NO tier and
            // opens NO unit. It is a pure decoration that changes only the bytes,
            // and therefore only the nameHash.
            //
            // Measured accepted by the chain at 1 unit, each a keycap-decorated
            // impostor of a name that already exists or plausibly will:
            //
            //     1F680 20E3        🚀 with a keycap box drawn round it
            //     2764 FE0F 20E3    ❤️ likewise
            //     0030 20E3 20E3    0️⃣ with a SECOND mark stacked on it
            //
            // Every one hashes differently from the name it imitates, so it is a
            // distinct registration that renders as a near-duplicate — the exact
            // class of thing R8-4's 16px render audit and the 38 blocked
            // confusables exist to keep out, arriving through a codepoint that was
            // whitelisted for an unrelated reason.
            //
            // The fix is the mirror of the existing obligation: track whether a
            // keycap is OWED, and require that it is when one is seen. The frozen
            // table (wrappers/emoji-table.json, the artifact policyHash commits to)
            // contains U+20E3 in exactly 12 sequences and every one of them is
            // `[0-9#*] FE0F 20E3` — there is no bare U+20E3 unit and no non-ASCII
            // base carrying one — so this refuses nothing legitimate. Pinned in
            // tests/R9NamespaceFloor.spec.ts, which drives all 2055 frozen units
            // through `checkName`.
            if (newUnit && keycapOwed) { return ERR_BARE_KEYCAP_BASE; }
            if (cp == 0x20E3) {
                if (!keycapOwed) { return ERR_BARE_KEYCAP_BASE; }
                keycapOwed = false;
            }
            if (newUnit) { keycapOwed = cp < 0x80; }

            // R26-1. THE TAG CHARACTERS WERE THE THIRD CONTINUER WITH NO RULE AT
            // ALL — AND UNLIKE U+20E3 AND U+FE0F, EVERY ONE OF THEM IS INVISIBLE.
            //
            // The whitelist above narrows E0020..E007F to the ten letters RGI's
            // three subdivision flags need, and its own comment gives the reason:
            // "the wider E0020..E007F block is invisible by construction, so
            // admitting it would allow unlimited invisible variants of the same
            // rendered 🏴". Narrowing the WHITELIST does not deliver that — the ten
            // survivors were still free-floating continuers with no companion rule,
            // no cap and no position constraint. They open no unit and change no
            // tier, so they change only the bytes, and therefore only the nameHash.
            //
            // Measured accepted by the SHIPPED bytecode at exit 0, `emojiCount` 2,
            // every one of them a pixel-identical impostor of 🚀🌙 (all ten tag
            // characters work, in any position, and 25 of them fit under
            // MAX_NAME_BYTES — so the family is combinatorial, not a handful):
            //
            //     1F680 1F319 E007F      🚀🌙 with an invisible cancel-tag appended
            //     E007F 1F680 1F319      ... prepended
            //     1F680 E007F 1F319      ... between the two glyphs
            //     E0067 1F680 E0062 1F319   ... two tag letters woven through
            //
            // The off-chain normalizer refuses all four with `not_emoji`, which is
            // the worse half of the same bug: `checkName` is the oracle this
            // contract tells integrators to trust instead of reimplementing the
            // policy ("There is no cheaper honest oracle"), so a user who pastes a
            // poisoned 🚀🌙 is told the name is registrable, pays COMMIT_MIN_VALUE,
            // and can then never construct a Reveal. That is R14B1-8 exactly,
            // recurring on a codepoint class its sweep never covered.
            //
            // The fix is the R14B1-6 pattern, third application: a tag character is
            // legal only while a tag BASE is open, and U+1F3F4 is the only base RGI
            // has. The terminator closes the run, so a second U+E007F — or a tag
            // letter after one — is refused too.
            //
            // Over-fix control, measured against the frozen table
            // (wrappers/emoji-table.json, the artifact policyHash commits to):
            // 2,055 units, 3 contain tag characters, all 3 are opened by U+1F3F4
            // and terminated by U+E007F, 0 have a tag character anywhere else.
            // BREAKS 0 OF 2,055 — the same acceptance criterion R17-29 and R14B1-6
            // were held to. Bare 🏴 stays legal: the base opens the option, it does
            // not create an obligation, so unlike `keycapOwed` there is no
            // end-of-name check for an unclosed tag run.
            // R26-1b. THE FIRST CUT OF THIS RULE UNDER-FIXED, AND AN INDEPENDENT
            // REVIEW OF IT FOUND THE HOLE. Recorded because the shape of the miss
            // is the interesting part.
            //
            // The first version was `if (newUnit) { tagOpen = cp == 0x1F3F4; }` —
            // it only ever reassigned the flag when a NEW UNIT opened. But every
            // continuer (ZWJ, VS-16, a ZWJ-joined base) leaves `newUnit` false, so
            // the run stayed open across a whole cluster, and nothing constrained
            // its CONTENTS. Measured against that build, all at exit 0, count 1,
            // each pixel-identical to a real flag and hashing differently:
            //
            //     1f3f4 e0067                       🏴 + one tag letter, never terminated
            //     1f3f4 e007f                       🏴 + a bare terminator
            //     1f3f4 200d 2620 fe0f e0067        🏴‍☠️ + an invisible tag letter
            //     1f3f4 e0067 200d 2620 fe0f        ...woven in before the join
            //     1f3f4 + 26x e0067                 26 tag letters, 110 bytes, accepted
            //
            // Nine letters are whitelisted and 26 fit under MAX_NAME_BYTES, so that
            // is ~9^26 invisible impostors of one Mythic single-emoji name. Closing
            // "a tag character needs a base" without also closing "a run must be
            // WELL-FORMED and CLOSED" bought almost nothing.
            //
            // RGI has exactly THREE tag sequences and they are frozen: 🏴 gb-sct,
            // gb-eng, gb-wls. `wrappers/emoji-table.json` — the artifact policyHash
            // commits to, and after R26-N2 the accept-set the normalizer itself is
            // gated on — contains those three and no other tag-bearing unit. So the
            // exact match below is not a narrowing of the namespace; it is the
            // namespace, written down. Same move R14B1-6 made for keycaps.
            //
            // Every other codepoint CLOSES the run (the `else`), an unterminated
            // run is refused at the next codepoint and at end of name, a bare
            // terminator is refused, and the five letters must spell one of three
            // things. Over-fix control: breaks 0 of the 2,055 frozen units, and the
            // three subdivision flags and the bare 🏴 all still pass.
            if (cp >= 0xE0020 && cp <= 0xE007F) {
                if (!tagOpen) { return ERR_NOT_EMOJI_CODEPOINT; }
                if (cp == 0xE007F) {
                    // gbsct / gbeng / gbwls, one ASCII byte per letter
                    if (tagLen != 5) { return ERR_NOT_EMOJI_CODEPOINT; }
                    if (tagAcc != 0x6762736374 && tagAcc != 0x6762656E67
                     && tagAcc != 0x6762776C73) { return ERR_NOT_EMOJI_CODEPOINT; }
                    tagOpen = false;
                    tagLen = 0;
                    tagAcc = 0;
                } else {
                    tagLen += 1;
                    if (tagLen > 5) { return ERR_NOT_EMOJI_CODEPOINT; }
                    tagAcc = tagAcc * 256 + (cp - 0xE0000);
                }
            } else {
                // A run that has taken letters must be terminated before anything
                // else may follow. A bare 🏴 opens an OPTION, not a debt, so
                // `tagOpen` alone carries no obligation — only `tagLen` does.
                if (tagLen != 0) { return ERR_NOT_EMOJI_CODEPOINT; }
                tagOpen = cp == 0x1F3F4;
            }

            // R17-29. U+FE0F IS A PURE CONTINUER WITH NO OBLIGATION AND NO CAP —
            // THE CASE R14B1-6 CLOSED FOR U+20E3 AND LEFT OPEN HERE.
            //
            // The rule directly above makes U+20E3 illegal unless something owes
            // it. VS-16 had neither half: it opens no unit, changes no tier, and
            // attaches to anything or to nothing, so it changes only the bytes —
            // and therefore only the nameHash. Measured on this build:
            //
            //     30 20E3 20E3      0-with-a-SECOND-keycap        463  (closed)
            //     2764 FE0F FE0F    heart-with-a-SECOND-VS-16       0  (open)
            //     FE0F 2764         VS-16 OPENING the name          0  (open)
            //
            // Only the two SAFE clauses are enforced. The obvious third — "at most
            // one FE0F per unit" — was measured against the frozen table and
            // BREAKS 16 OF 2,055 LEGITIMATE NAMES (👁️‍🗨️ 🏋️‍♀️ 🕵️‍♂️ 🏳️‍⚧️ and 12 more,
            // all of the form `<base> FE0F 200D <base> FE0F`). Enforcing it would
            // put unmintable names inside the policy-hashed table the attestation
            // commits to, which is a worse failure than the homograph it prevents.
            // These two clauses shrink the ❤️🚀 insertion family from 7,770 to 4
            // and break 0 of 2,055 — verified over the whole corpus in
            // audit/round18/registrar/E_namespace.spec.ts.
            //
            // A COMPLETE rule needs Unicode's Emoji_Presentation table on chain
            // (212 must-take / 1,171 must-not / 117 contiguous ranges); that is a
            // namespace decision with a real gas cost, not a guard, and it is not
            // made here.
            if (cp == 0xFE0F) {
                // (b) nothing to modify: VS-16 before any unit has opened.
                if (units == 0) { return ERR_BAD_VARIATION_SELECTOR; }
                // (a) a variation selector cannot vary a variation selector.
                if (prevWasVs16) { return ERR_BAD_VARIATION_SELECTOR; }
            }

            if (newUnit) { units += 1; }
            prevWasZwj = isZwj;
            prevWasVs16 = cp == 0xFE0F;
            riOpen = isRi ? !riOpen : false;
        }
    }
    if (pending != 0) { return ERR_NAME_NOT_UTF8; }                   // truncated at the end
    if (keycapOwed) { return ERR_BARE_KEYCAP_BASE; }                 // R9-2: name ended mid-keycap

    // R26-2. A DANGLING ZWJ IS THE ONE ZWJ POSITION THE COUNTER CANNOT CATCH.
    //
    // U+200D sets `newUnit = false` for whatever FOLLOWS it, so a ZWJ in the
    // middle or at the front collapses two units into one and is caught by the
    // `units != emojiCount` equality below — leading and interior ZWJ both answer
    // 456 on the shipped build. A ZWJ at the END has nothing to join: the unit
    // count is untouched, the tier is untouched, the rendering is untouched
    // (U+200D is Default_Ignorable_Code_Point), and only the bytes move.
    //
    //     1F680 1F319 200D    accepted at exit 0, emojiCount 2, renders as 🚀🌙
    //
    // The normalizer refuses it with `not_emoji`, so this is the same
    // oracle-lies-to-a-paying-user failure as R26-1 above. No RGI sequence ends
    // in ZWJ — 0 of the 2,055 frozen units do — so this breaks nothing.
    if (prevWasZwj) { return ERR_NOT_EMOJI_CODEPOINT; }              // R26-2: name ended on a joiner
    if (tagLen != 0) { return ERR_NOT_EMOJI_CODEPOINT; }             // R26-1b: name ended mid tag run

    // ---- V7-28: the attested tier must equal the tier the bytes actually are ----
    //
    // Not a bound — an EQUALITY. The first cut of this fix only bracketed the
    // claim by codepoint count, and that was not enough: 🇺🇸 ❤️ 5️⃣ 👨‍👩‍👧‍👦 🏳️‍🌈 👩‍💻
    // are all single emoji spanning 2-7 codepoints, so every one of them still
    // walked past the singles lock when attested as "2 emoji". Segmenting
    // properly is the only thing that closes it, and it costs one extra branch
    // per byte on a loop that was already running.
    //
    // Soundness is not asserted, it is measured: scripts/segment-reference.ts is
    // this same algorithm in TypeScript, and tests/V7TierBinding.spec.ts proves
    // it returns exactly normalizeEmojiName().emojiCount for all 3520 accepted
    // units and for 14080 generated multi-unit names — zero disagreement. So no
    // legitimate name can be refused here, and no lie about a tier can survive.
    if (units != emojiCount) { return ERR_EMOJI_COUNT_MISMATCH; }
    return 0;
}

/**
 * R14B1-5. THE FLOOR CHARGED THE BUYER FOR ITS OWN CORRECTNESS.
 *
 * `assertCanonicalName` and `assertUriSuffix` are the last things a `Reveal`
 * runs before the funding check, and they THREW. R8-12's rule — a `throw`
 * returns value only when the SENDER set the bounce flag, and real wallets strip
 * it — therefore applied to them with the FULL PRICE already in the message.
 *
 * Measured with a bounce-stripped buyer on a tier-2 name whose signer had
 * attested a suffix the on-chain floor rejects: 30.10 GRAM in, 30.10 GRAM kept,
 * 0 returned. The reachable codes are 456 / 450 / 462 / 457 / 460 / 451 / 463,
 * and every one of them means THE SIGNER SIGNED SOMETHING THE CHAIN REFUSES —
 * which is precisely the event the on-chain floor exists to catch. The buyer did
 * nothing but follow their front end, and the design's answer to "what if the
 * signer is wrong or compromised" charged them the list price for finding out.
 *
 * So the bodies are unchanged and now merely REPORT: `checkCanonicalName` and
 * `checkUriSuffix` return 0 or the exact code the assert used to throw. These
 * two shims are the old contract, byte-for-byte, for the four callers that must
 * not change behaviour:
 *
 *   AdminMint / AdminImport / StartAuction — admin-only, funded by the admin,
 *     and a throw there is the correct signal (the admin's own tooling produced
 *     a bad name; there is no third party to refund).
 *   the `checkName` get method — its whole contract with integrators is "throws
 *     the SAME exit code the reveal would", published as CHECK_NAME_ERRORS.
 *
 * Only `Reveal` uses the `check*` form, paired with `refundAndStop`.
 */
fun assertCanonicalName(rawName: cell, nameHash: uint256, emojiCount: int) {
    val e = checkCanonicalName(rawName, nameHash, emojiCount);
    if (e != 0) { throw e; }
}

/**
 * V7-31. The attested `content` cell becomes the NFT's individual content, which
 * the collection concatenates onto the base URI inside `get_nft_content`. It is
 * therefore a URI FRAGMENT, and it is written into the item at mint time and
 * never editable afterwards.
 *
 * Two wrapper helpers were both exported as `snakeCell` — one prepends the
 * TEP-64 0x00 ContentData tag, one does not — and every issuance path was
 * passing the tagged one. Every name minted so far in the test fixture carries
 * a URI with a raw NUL byte in the middle of its path, which no marketplace can
 * fetch. A naming collision in TypeScript should not be able to permanently
 * corrupt on-chain metadata, so the chain checks it: printable ASCII only, one
 * cell, non-empty. That is a strictly larger set than any correct suffix and a
 * strictly smaller one than "whatever the signer sent".
 *
 * R17-4 (MEDIUM, found independently by three specialists). "A strictly larger
 * set than any correct suffix" was the whole problem: the filter is a BYTE filter
 * with no relation to the name being minted, and the attestation binds
 * `content.hash()` without ever binding `content` to `rawName`. Measured:
 *
 *     registered name 🐶🐱  ->  https://…/item/🚀🌙
 *     registered name 🦄🐸  ->  https://…/item/🚀🌙      identical URIs: true
 *
 * and `docs/VERCEL_NFT_PIPELINE.md` §3 derives `name`, `image` and `Tier` PURELY
 * from the URL path — `get_tier()` and `get_name_data()` are never consulted. So
 * the marketplace card is a pure function of a signer-chosen string, the
 * individual content is immutable at the item, and the anti-phishing layer (which
 * operates on name strings) cannot see it. That is the wallet-comment-display
 * spoofing class from the incident record, one layer up.
 *
 * `checkContentBindsName` below closes it. The suffix is already a DETERMINISTIC
 * function of `rawName` — `encodeUriSuffix` in wrappers/EmojiRegistrarV4.ts, and
 * every deploy script and the Vercel route agree — so the chain can simply
 * recompute it instead of measuring its length. Every issuance path applies it.
 */
/**
 * R20-6b. THE SHAPE, WITHOUT THE PER-BYTE WALK — SPLIT OUT BECAUSE THE PER-BYTE
 * WALK TURNED OUT TO COST A QUARTER OF THE BASECHAIN GAS LIMIT.
 *
 * Measured on this build, one paid `Reveal` of a 100-byte name:
 *
 *   whole reveal                         887,715 gas
 *   without checkUriSuffix's byte filter 624,571   -> the filter costs 263,144
 *   without checkContentBindsName        625,846   -> the binding costs 261,869
 *
 * Both walk the SAME bytes, and R20-6 tripled how many there are (a 100-byte
 * name encodes to 300). At the top of the namespace that was fatal rather than
 * wasteful: R13's A2 — a 111-byte name at the tier-7 floor with three resolvers
 * and four partners — hit `exit -14`, out of gas, against basechain's
 * 1,000,000 `gas_limit`. That is a HARD CEILING, not a budget: no amount of
 * value from the buyer buys past it, so those names simply could not be
 * registered in that configuration.
 *
 * The two passes are not both needed, and this is provable rather than
 * plausible. `checkContentBindsName` recomputes `encodeUriSuffix(rawName)` byte
 * for byte, so if it passes, every content byte is either `%`, an UPPERCASE HEX
 * DIGIT, or a byte of `rawName` that is < 0x80 and not `#`/`?`. Callers run
 * `checkCanonicalName` FIRST — which is what makes the binding mean anything —
 * and after R9-2 the only ASCII a canonical name can contain is `0-9`, `#` and
 * `*`. So the bound content is drawn from {`0-9`, `A-F`, `*`, `%`}: every byte
 * >= 0x21, < 0x80, not DEL, and none of `#`, `?`, `/`, `\`. THE FILTER IS
 * IMPLIED BY THE BINDING.
 *
 * So the bound paths (Reveal, AdminMint, AdminImport, StartAuction) run
 * shape + binding, and the one door with no `rawName` to bind against — the
 * COLLECTION's admin `Mint` — keeps the full byte filter, which is where it was
 * always doing real work and where ADMIN_COMPUTE_BUDGET pays for it.
 *
 * WHAT THIS COSTS, stated: a content cell that is well-formed in SHAPE but is
 * not this name's suffix now reports 472 ERR_CONTENT_NOT_BOUND rather than 460
 * ERR_BAD_CONTENT. R17-4's note preferred 460 there ("the published code an
 * integrator switches on"). 472 is the more accurate of the two for exactly
 * that input — it says "well-formed suffix, wrong name" — and 460 still covers
 * every SHAPE failure, which is the case that note was really about.
 */
fun checkUriShape(content: cell): int {
    var c = content.beginParse();
    var cells = 1;
    var totalBits = 0;
    var walking = true;
    while (walking) {
        val bits = c.remainingBitsCount();
        if (bits % 8 != 0) { return ERR_BAD_CONTENT; }
        if (c.remainingRefsCount() > 1) { return ERR_BAD_CONTENT; }
        totalBits += bits;
        if (c.remainingRefsCount() == 0) {
            walking = false;
        } else {
            if (bits != URI_CELL_BITS) { return ERR_BAD_CONTENT; }
            cells += 1;
            if (cells > URI_MAX_CELLS) { return ERR_BAD_CONTENT; }
            c = c.loadRef().beginParse();
        }
    }
    if (totalBits < 8) { return ERR_BAD_CONTENT; }
    return 0;
}

fun checkUriSuffix(content: cell): int {
    // R20-6. THE SUFFIX IS A SNAKE CHAIN NOW, SO THE FILTER WALKS ONE.
    //
    // Full percent-encoding (every byte >= 0x80, so the URI is ASCII as TEP-64
    // requires) triples the suffix, and the worst registrable name — three
    // tag-sequence flags, 84 raw bytes — reaches 252 encoded, past the 127 a
    // single cell holds. TEP-64's snake format is a ref chain and
    // `get_nft_content` already hands the individual content back as a ref, so
    // the chain decodes on every standard snake reader with no client change.
    //
    // The walk is bounded at URI_MAX_CELLS. That bound is not defensive
    // dressing: this function is reachable from `checkName`, a GET METHOD anyone
    // may call with a cell they built, and an unbounded ref walk there is a
    // liteserver-gas denial of service. Three cells is 381 bytes against the 333
    // that MAX_NAME_BYTES can produce, so no legitimate name is anywhere near it.
    //
    // Every cell in the chain must be byte-aligned, not merely the whole. A
    // ragged JOIN reads as a whole-byte string to a naive reader and as a parse
    // error to tongo ("text data is not multiple of 8 bits"), so alignment is
    // asserted per cell, where the reader parses it.
    var c = content.beginParse();
    var cells = 1;
    var totalBits = 0;
    var walking = true;
    while (walking) {
        val bits = c.remainingBitsCount();
        if (bits % 8 != 0) { return ERR_BAD_CONTENT; }
        if (c.remainingRefsCount() > 1) { return ERR_BAD_CONTENT; }
        totalBits += bits;
        while (c.remainingBitsCount() >= 8) {
            val b = c.loadUint(8);
        // Every byte must be >= 0x21 and not DEL. That rejects NUL (the actual
        // bug — a stray TEP-64 ContentData tag), every C0 control byte, and the
        // space, while leaving UTF-8 alone: continuation and lead bytes are all
        // >= 0x80, so the name stays readable in the URI. Percent-encoding is
        // the front end's job when it builds the fetch URL; a NUL is nobody's.
        if (b < 0x21 || b == 0x7F) { return ERR_BAD_CONTENT; }

        // R9-3. `#` AND `?` TRUNCATE THE URI AT THE SERVER — AND COLLIDE.
        //
        // The metadata URI is composed on chain as `<commonContent><this>`, so
        // these bytes land in a real URL. `#` opens a fragment and `?` opens a
        // query string; NEITHER is sent to the origin as part of the path.
        //
        // Measured, with commonContent = "https://api.emojiverse.xyz/item/":
        //
        //     name          composed URI                  origin actually sees
        //     #️⃣            …/item/#️⃣                      /item/          (empty)
        //     🚀#️⃣          …/item/🚀#️⃣                    /item/🚀        <-- ANOTHER NAME
        //
        // The second line is the reason this is an assert and not a lint. It is
        // not a 404 — it is a metadata COLLISION: the NFT for `🚀#️⃣` would serve
        // whatever `🚀` serves, forever, with no way to tell them apart from the
        // URI. Every name containing a keycap `#` aliases onto its own prefix.
        //
        // `#` is reachable because it is an RGI keycap base (`#️⃣` = 0023 FE0F
        // 20E3) and therefore in the R9-2 namespace whitelist. `?` cannot appear
        // in a name at all, but this filter runs before anything knows what the
        // name is, so both are refused here.
        //
        // R17-4 UPDATE: the old justification for refusing `?` was that "`content`
        // is signer-supplied and need not be a name — reserved lots carry a note".
        // That is no longer true anywhere: `checkContentBindsName` now requires the
        // suffix to BE the encoded name on all four issuance paths, so there are no
        // note-carrying lots and no signer-chosen strings. The byte filter stays as
        // the first, cheapest and most legible line of defence (460 rather than
        // 472), and because its codes are published in CHECK_NAME_ERRORS.
        //
        // The fix is not to ban the names: `wrappers/EmojiRegistrarV4.ts`
        // `uriSuffixCell()` percent-encodes both (`#` -> `%23`), which is 3 bytes
        // for 1 and always fits the cell. Encoding the WHOLE name is not an
        // option — 110 bytes percent-encoded is 2,640 bits against a 1,023-bit
        // ceiling. This assert makes the unencoded form unrepresentable, so a
        // front end cannot reintroduce it later.
        if (b == 0x23 || b == 0x3F) { return ERR_BAD_CONTENT; }

        // R9-4. PATH SEPARATORS — the same argument R9-3 made for `?`.
        //
        // R9-3 refused `?` because `content` reaches this filter before anything
        // has established what the name is. That applies verbatim to the bytes
        // that let the path reach a DIFFERENT ROUTE. Measured, on chain:
        //
        //     content            composed URI              origin receives
        //     "../../evil"       …/item/../../evil          /evil
        //     "..\\..\\evil"     …/item/..\..\evil          /evil
        //     "a/b"              …/item/a/b                 /item/a/b
        //
        // The WHATWG parser applies these CLIENT-SIDE, before the request is
        // sent, so no origin or CDN hardening can defend against them.
        //
        // Costs nothing: after R9-2 the only ASCII any name can contain is `0-9`,
        // `#` and `*`, so no registrable name carries `/` or `\`.
        //
        // `.` IS DELIBERATELY STILL ALLOWED, and the first draft of this rule got
        // it wrong twice. It banned `.` claiming that "also kills the `%2E%2E`
        // form, since `%` alone cannot rebuild a dot" — false: `%`, `2` and `E`
        // are all legal bytes, and `%2E%2E` normalises to `..` in the URL parser
        // regardless. The ban therefore bought nothing while refusing ordinary
        // suffixes like `rocket-moon.json` (which V7-31's own test mints).
        //
        // WHAT REMAINS OPEN, STATED PRECISELY. With `/` and `\` gone, the only
        // content that still escapes is one that is ENTIRELY a WHATWG dot
        // segment. That set is closed and small — single-dot `.` `%2e`, and
        // double-dot `..` `.%2e` `%2e.` `%2e%2e`, hex case-insensitive:
        //
        //     "."       -> /item/     (empty)
        //     ".."      -> /          (site root)
        //
        // Severity is materially lower than R9-3 and the difference is the reason
        // this is documented rather than asserted: R9-3 aliased a legitimate name
        // onto ANOTHER REAL NAME and was reachable by an honest signer minting a
        // legitimate `🚀#️⃣`. This is reachable only by a signer that is already
        // compromised or broken, damages only the single item it mints, and can
        // collide with nothing — no name is empty, so no name maps to `/item/`.
        // Pinned by tests/R9UriIntegrity.spec.ts so the residue stays known and
        // cannot silently widen.
        //
        // R17-4 CLOSES THE RESIDUE, from the other end. `.` and `..` are not
        // encodings of any name, so `checkContentBindsName` refuses them on every
        // issuance path — including the compromised-signer case this paragraph
        // was written for. The `.`-permitting rule stays exactly as it is: it is
        // the correct rule for a BYTE filter, and narrowing it here would only
        // move an already-closed case to a less informative error code.
        if (b == 0x2F || b == 0x5C) { return ERR_BAD_CONTENT; }

        // R20-6. AND NOW: ASCII. TEP-64 §"Off-chain content layout" — "the URI is
        // encoded as ASCII". R19/T2 measured 8 of a `🚀🌙` item's 40 URI bytes at
        // >= 0x80, and the suffix has NO edit op on any path for any principal,
        // so a name minted with a non-ASCII URI has broken metadata forever on
        // any strict reader. The wrapper's `encodeUriSuffix` now emits `%XX` for
        // every such byte; this makes the raw form unrepresentable, exactly as
        // the `#` clause above does for its own reason.
        if (b >= 0x80) { return ERR_BAD_CONTENT; }
        }
        if (c.remainingRefsCount() == 0) {
            walking = false;
        } else {
            // A continuation is only meaningful when the cell it hangs off is
            // FULL. A chain that breaks early carries the same bytes in a
            // different shape, and `checkContentBindsName` compares BYTES — so
            // without this one name could be minted under several distinct
            // content cells with identical decoded URIs and different hashes.
            if (bits != URI_CELL_BITS) { return ERR_BAD_CONTENT; }
            cells += 1;
            if (cells > URI_MAX_CELLS) { return ERR_BAD_CONTENT; }
            c = c.loadRef().beginParse();
        }
    }
    if (totalBits < 8) { return ERR_BAD_CONTENT; }
    return 0;
}

/**
 * R17-4. THE METADATA MUST BE THE NAME, NOT MERELY A LEGAL STRING.
 *
 * Recomputes `encodeUriSuffix(rawName)` byte by byte and demands `content` equal
 * it exactly. The encoder is two rules wide:
 *
 *     byte 0x23 ('#')  ->  0x25 0x32 0x33   ("%23")
 *     byte 0x3F ('?')  ->  0x25 0x33 0x46   ("%3F")
 *     anything else    ->  itself
 *
 * so this is one pass with no allocation and no second copy of the name. `?` is
 * unreachable in a name after R9-2 and is handled anyway, for the same reason
 * `checkName`'s length mirror handles it: the two implementations must not be
 * able to drift on the day the whitelist changes.
 *
 * Callers must run `checkCanonicalName` FIRST — that is what proves `rawName`
 * hashes to the attested `nameHash`. Without it this binds content to an
 * arbitrary cell rather than to the name.
 *
 * Over-fix control, and the acceptance criterion for shipping it: every unit in
 * the frozen table (wrappers/emoji-table.json, 2,055 units) and every generated
 * multi-unit name must still pass with the suffix the shipping wrapper produces.
 * Verified in audit/round18/registrar/E_namespace.spec.ts.
 */
fun checkContentBindsName(content: cell, rawName: cell): int {
    var n = rawName.beginParse();
    var c = content.beginParse();
    while (n.remainingBitsCount() >= 8) {
        val nb = n.loadUint(8);
        // R20-6: three rules now, and `#`/`?` fold into the general one because
        // `%23` and `%3F` ARE `%` + uppercase hex of the byte. One expansion, one
        // comparison, no third branch to keep in step with the wrapper.
        if (nb == 0x23 || nb == 0x3F || nb >= 0x80) {
            if (nextUriByte(mutate c) != 0x25) { return ERR_CONTENT_NOT_BOUND; }       // '%'
            if (nextUriByte(mutate c) != hexDigitUpper(nb >> 4)) { return ERR_CONTENT_NOT_BOUND; }
            if (nextUriByte(mutate c) != hexDigitUpper(nb & 0xF)) { return ERR_CONTENT_NOT_BOUND; }
        } else {
            if (nextUriByte(mutate c) != nb) { return ERR_CONTENT_NOT_BOUND; }
        }
    }
    // Nothing may TRAIL the name either — a suffix of `🚀🌙/../other` is refused by
    // the byte filter, but `🚀🌙x` would not be, and it is a different URI. With a
    // chain that means "no bits left AND no continuation left": a trailing empty
    // cell is still a different content cell for the same name, and
    // `checkUriSuffix`'s full-cell rule already refuses it, so this only has to
    // agree with that rule rather than restate it.
    if (c.remainingBitsCount() != 0 || c.remainingRefsCount() != 0) { return ERR_CONTENT_NOT_BOUND; }
    return 0;
}

/**
 * One byte off a snake chain, stepping to the continuation when a cell runs out.
 * Returns -1 when the chain is exhausted, which no comparison above can match —
 * so "content ran out early" fails through the same path as "content differs",
 * with the same error code, and there is no separate length check to get wrong.
 *
 * The chain has already been walked and bounded by `checkUriSuffix`, which every
 * caller runs first (`assertUriSuffix`, and Reveal's paired `check*` form), so
 * this cannot walk further than URI_MAX_CELLS.
 */
fun nextUriByte(mutate c: slice): int {
    if (c.remainingBitsCount() < 8) {
        if (c.remainingRefsCount() == 0) { return -1; }
        c = c.loadRef().beginParse();
        if (c.remainingBitsCount() < 8) { return -1; }
    }
    return c.loadUint(8);
}

/** 0..15 -> '0'..'9','A'..'F'. The wrapper's `.toString(16).toUpperCase()`. */
fun hexDigitUpper(v: int): int {
    return v < 10 ? (0x30 + v) : (0x41 + v - 10);
}

/** R14B1-5: the re-throwing shim. See the note above `assertCanonicalName`. */
fun assertUriSuffix(content: cell, rawName: cell) {
    // R20-6b: shape, then binding. The per-byte filter is implied by the binding
    // — see the note on `checkUriShape` for the proof and the 263,144-gas
    // measurement that made skipping it necessary rather than merely tidy.
    val e = checkUriShape(content);
    if (e != 0) { throw e; }
    val b = checkContentBindsName(content, rawName);
    if (b != 0) { throw b; }
}

fun assertAvailableForIssue(st: Storage, nameHash: uint256, nowTime: int) {
    assert(!st.auctions.get(nameHash).isFound) throw ERR_AUCTION_EXISTS;
    val ex = st.names.get(nameHash);
    if (ex.isFound) {
        val rec = ex.loadValue();
        assert(!rec.isPermanent) throw ERR_NAME_UNAVAILABLE;        // never re-issuable
        assert(nowTime >= (rec.expiresAt + GRACE)) throw ERR_NAME_UNAVAILABLE;
    }
}

// shared issuance path: write the record, mint the NFT, sync every resolver
//
// R14-4a (HIGH, migration correctness). `carryNonce` EXISTS SO A MIGRATION CAN
// PRESERVE A NAME'S SYNC HISTORY.
//
// This function used to hardcode nonce 1 for any name it had not seen. That is
// correct for a first issuance and WRONG for an import, because the nonce is not
// a counter of this contract's writes — it is the token the ITEM echoes back
// through OwnerSynced, and the F-12 guard drops any relay whose nonce does not
// equal the record's. The item survives a migration untouched (its address
// derives from (nameHash, collection), not from the registrar), so it keeps
// whatever nonce it was last minted with.
//
// Measured on a v4 -> v5 dress rehearsal, before this parameter existed: a name
// that had been transferred once (item nonce 2) imported into v5 as nonce 1. The
// holder then sold it. The item moved to the buyer and relayed nonce 2; v5 held
// nonce 1, so `OwnerSynced` dropped it on the floor. Registry owner: the SELLER.
// NFT owner: the buyer. FOREVER — every subsequent transfer relays the same
// mismatched nonce, `AdminImport` cannot overwrite, and there is no SETCODE.
// Every name that had ever changed hands migrated into that state.
//
// Carrying the nonce is what lets the runbook import BEFORE the minter cutover,
// which is the ordering that preserves holder records (a post-cutover import
// re-mints the item and `InitOrReassign` wipes records unconditionally).
//
// 0 means "no carried nonce, derive one" — 0 is not a value this function can
// ever produce (it starts at 1 and only increments), which is exactly why R13X-2
// could use it as the collection's admin-mint sentinel. It is honoured ONLY for a
// name this registry has never seen, so it can never rewrite a live record's
// nonce and step around the F-12 stale-sync guard.
fun issueName(mutate st: Storage, cfg: Config, nameHash: uint256, owner: address,
              emojiCount: int, expiresAt: int, isPermanent: bool, content: cell, queryId: uint64,
              carryNonce: int, isReserved: bool, label: cell?) {
    // R15-9: the other four issuance paths converge here, so the horizon is
    // checked once rather than four times. `PERMANENT_EXPIRY` is the deliberate
    // exception — it IS 0xFFFFFFFF, and it means "never", not "in 2106".
    //
    // A throw is right for these callers where a refund was right for RenewName:
    // AdminMint and AdminImport are admin messages, and `SettleAuction` reaches
    // here only after the winner's money is already escrowed and the lot deleted,
    // where a rollback (lot and escrow survive, re-settle later) is the outcome
    // that protects the bidder — the same reasoning as R17-13 above.
    assert(expiresAt <= EXPIRY_HORIZON || expiresAt == PERMANENT_EXPIRY) throw ERR_EXPIRY_OVERFLOW;
    val prior = st.names.get(nameHash);
    var nonce = 1;
    if (prior.isFound) {
        nonce = (prior.loadValue().syncNonce as int) + 1;
    } else {
        st.totalNames += 1;
        if (carryNonce != 0) { nonce = carryNonce; }
    }
    st.names.set(nameHash, {
        owner: owner,
        expiresAt: expiresAt as uint32,
        emojiCount: emojiCount as uint16,
        isPermanent: isPermanent,
        syncNonce: nonce as uint32,
    });
    if (cfg.nftCollection != null) {
        sendMint(cfg.nftCollection!, queryId, nameHash, owner, expiresAt,
                 emojiCount, nonce, content, isReserved, false, label);
    }
    syncAllResolvers(cfg.resolvers, queryId, nameHash, owner, expiresAt);
}

// Partner share of a fee. Computed on the GROSS fee (independent of any referral)
// so a partner's cut is predictable and does not shrink when a referrer is
// involved. Rounds DOWN, so the contract never over-pays.
/** Combined partner share of a fee. Each cut floors, so the contract never overpays. */
fun partnerCutOf(cfg: Config, fee: int): int {
    val pp = cfg.prices.load();
    var total = 0;
    var e = pp.partners.findFirst();
    while (e.isFound) {
        total += fee * (e.loadValue().bps as int) / BPS_DENOM;
        e = pp.partners.iterateNext(e);
    }
    return total;
}

// R17-6: `totalEscrowed` (the F-5 walk) and `escrowAndCount` (R11-2/R13-3's
// one-pass version of it) both lived here and both are gone. The number they
// computed is now `st.escrowedTotal` / `st.liveLots`, maintained by the four ops
// that can move it. See the field comments in `Storage` for why, and
// audit/round18/registrar/A_escrow_counters.spec.ts for the differential proof
// that the incremental value equals the walk after every step of a randomised
// start/bid/settle/cancel lifecycle.

// R13-3. EVERY BID COSTS THE CONTRACT MONEY, AND NOTHING RESERVED FOR IT.
//
// PlaceBid escrows the FULL incoming value (`val bid = in.valueCoins`) and then
// refunds the outbid leader with PAY_FEES_SEPARATELY — F-3, so being outbid does
// not cost that bidder the forwarding fee. Correct for them, but it means the
// compute gas AND the forward fee come out of the registrar's own float, while
// escrow accounting records the whole incoming value as owed. Per bid the
// solvency delta is exactly -(gas + fwd): small, one-directional, and unbounded
// in the number of bids.
//
// Measured on one lot with the float first stripped by WithdrawFees, at mainnet
// gas: balance minus escrow crosses zero at bid #22. Refunds stayed whole through
// bid #39 only because F-1's `spare` clamp is computed against a balance that
// still holds the incoming bid — past that the clamp starts under-refunding an
// outbid leader, which is the F-3 promise breaking.
//
// The precondition is a stripped float, so this is the same class V7-1 fixed for
// the resolver fan-out: `freeBalance()` was reserving the obligations it could
// see and not this one. A live lot is an open-ended stream of outbid refunds, so
// it gets its own reserve, and the admin can no longer withdraw the money that
// funds it. 0.5 GRAM buys ~100 outbid cycles per lot at mainnet gas; lots are
// admin-created, so the total reserve is bounded by inventory, not by attacker
// action. Bid semantics are deliberately NOT changed — what you send is what you
// bid and what you get back — because the singles lots start at 150 GRAM and a
// silent net-of-fees bid is the wrong surprise on that path.
const AUCTION_OPS_RESERVE: int = 500000000;   // 0.5 GRAM per LIVE lot

// R14B1-14 (HIGH, R11-3 QUANTIFIED). THE RENT RESERVE DID NOT SCALE WITH THE
// THING THAT PAYS THE RENT.
//
// R11-3 recommended this and it was deferred "because it moves freeBalance()
// semantics and belongs in one considered change". This is that change, with the
// crossing re-measured.
//
// `MIN_STORAGE` is a FLAT 0.05 GRAM. Every other term above it is zero in the
// SHIPPING config — zero resolvers, zero live lots — so on the day this launches
// the entire rent reserve is 0.05 GRAM. Storage rent, meanwhile, is charged per
// cell per second on a `names` map that grows with every sale. R11-3 published a
// "~1,700 name" crossing; measured against the real reserve rather than the
// 0.242 GRAM three-resolver figure, the crossing is at 253 NAMES.
//
// What that costs, following MIGRATION_RUNBOOK step 4 as written ("withdraw only
// `freeBalance()`") and then going quiet — which is the normal, correct operating
// procedure, not a mistake:
//
//     10,000 names   balance exhausted day 28   ACCOUNT FROZEN day 56
//     32,000 names                              ACCOUNT FROZEN day 21
//
// And frozen is not a state you top up out of. Measured: a 50 GRAM transfer to
// the frozen account did NOT revive it — the state stays frozen, every get method
// throws, and every name in the registry is unresolvable and unrenewable. The one
// obligation the contract has that is guaranteed to grow was the one obligation
// `freeBalance()` did not reserve for, and `freeBalance()` is the number an
// operator is instructed to withdraw.
//
// R17-10 RE-SIZED THIS AGAINST THE OTHER PARAM-18 ROW.
//
// The 0.0016 figure was derived from the CURRENT config row (bit 0 / cell 135),
// under which 10,000 names cost 1.3163 GRAM/yr and 16 GRAM funds a decade. Param
// 18 ships both rows and has moved once already; on the pessimistic row
// (bit 1 / cell 500) the same 10,000 names cost 7.70 GRAM/yr — 0.00077 GRAM per
// name per year — so 0.0016 buys 2.08 YEARS against a term this contract will
// sell for TEN (MAX_TOTAL_TERM). The reserve was one row's worth of a two-row
// parameter.
//
// 0.008 = 10 x 0.00077 with margin: a full 10-year term funded on the WORSE row,
// which is the only sizing that matches what the contract promises a buyer. At
// the 32,000-name soft cap it reserves 256 GRAM of the contract's own balance —
// a number the operator sees in `freeBalance()` rather than discovers as a frozen
// account 756 days after a runbook-compliant withdrawal.
//
// Standing caveat, unchanged: @ton/sandbox never charges storage rent, so every
// figure here is real measured account state x a price table read out of the live
// config dictionary, not observed decay.
//
// `st.totalNames` is ALREADY IN STORAGE — this costs one field read, no layout
// change, and (crucially, given R11-2) no additional map walk.
//
// R22-4. 0.008 WAS "10 x 0.00077" EXACTLY — A TEN-YEAR TERM WITH NO MARGIN AT
// ALL — AND THE PIN THAT GUARDED IT COMPARED TWO CONSTANTS.
//
// R22-1 found `ITEM_FULL_RENT` stale for the second time because it had been set
// to a measured edge. This is the same shape one contract over: `10 * 0.00077`
// funds a ten-year term and not one day more, on a footprint that four rounds of
// registrar changes have grown since it was measured. And the pin
// (audit/round18/registrar/D_limits.spec.ts D2) asserted
// `RENT_RESERVE_PER_NAME >= 10n * 770_000n` — a constant against a LITERAL, so it
// could not fail for the reason it exists.
//
// Re-measured on this build by differencing real registrations, pessimistic row:
//
//   2-emoji names (8 raw bytes)      1.958 cells / 294.8 bits   0.000613 GRAM/yr
//   LONGEST names (111 raw bytes)    1.958 cells / 611.0 bits   0.000765 GRAM/yr
//   one insertion at n=20, longest   2 cells / 613 bits         0.000776 GRAM/yr
//
// The registry is permissionless, so the reserve has to hold for a registry of
// nothing but the longest names: 0.008 / 0.000776 = 10.31 YEARS against a
// ten-year MAX_TOTAL_TERM. A 3.1% margin, on the one failure in this system that
// cannot be recovered from — "frozen is not a state you top up out of", measured
// two paragraphs above.
//
// 0.010 buys 12.88 y on that worst case (28.8%) and 16.3 y on a 2-emoji registry.
// It costs the OPERATOR, not the buyer: it is a withdrawal reserve, so the only
// effect is that `freeBalance()` reports 64 GRAM less at the 32,000-name soft cap
// (320 instead of 256) — money that stays in the contract's own balance to pay
// the contract's own rent. Against an unrecoverable freeze that is not a close
// call. D2 now DIFFERENCES the per-name footprint off real registrations of the
// LONGEST legal name and asserts a 10% margin over the term, so the next round
// that grows a `names` entry goes red on purpose.
const RENT_RESERVE_PER_NAME: int = 10000000;  // 0.010 GRAM/name (R22-4; R17-10 had 0.008, was 0.0016)

/**
 * The R13-3 reserve, given a count already in hand. See AUCTION_OPS_RESERVE, and
 * RENT_RESERVE_PER_NAME for the R14B1-14 term.
 *
 * V7-1's rule binds every caller: `WithdrawFees` and the `freeBalance()` getter
 * must compute the IDENTICAL number, to the nanoton. A getter that over-reports
 * is worse than no getter, because ops read it and withdraw it.
 */
fun opsReserveWithCount(resolvers: map<uint256, address>, liveAuctions: int, totalNames: int): int {
    return MIN_STORAGE + countResolvers(resolvers) * SYNC_VALUE * SYNC_RESERVE_TRANSFERS
         + liveAuctions * AUCTION_OPS_RESERVE
         + totalNames * RENT_RESERVE_PER_NAME;
}

/**
 * THE free-balance expression. One definition, three callers: `WithdrawFees`,
 * `SweepCommitment`'s bounty clamp, and the `freeBalance()` getter.
 *
 * R15 cleanup: this arithmetic used to be written out three times, under a
 * comment instructing the reader to keep the copies "identical to the nanoton
 * (V7-1)". That is now structural rather than aspirational — a term added here
 * reaches all three sites, and the tests that pin them to +/-1 nanoton
 * (tests/R14Batch1Fixes.spec.ts) can no longer be satisfied by three copies
 * that are identically wrong.
 *
 * `inboundValue` is the value of the message currently being processed, which
 * is already in `getOriginalBalance()` but is not the contract's to spend. The
 * getter passes 0 because a get-method has no inbound message.
 *
 * R17-6: both auction terms are now O(1) field reads. This function used to be
 * the only unbounded loop reachable from a message, and it is called from the op
 * that pays for commitment cleanup — so its cost was the ceiling on the whole
 * anti-bloat market. Constant now, at any lot count.
 */
fun freeBalanceOf(st: Storage, inboundValue: int): int {
    return (contract.getOriginalBalance() as int) - inboundValue - (st.escrowedTotal as int)
         - opsReserveWithCount(st.cfg().resolvers, st.liveLots as int, st.totalNames as int);
}

/** Pay every partner their own share of `fee`, computed the same way. */
fun payPartner(cfg: Config, fee: int) {
    if (fee <= 0) { return; }
    val pp = cfg.prices.load();
    var e = pp.partners.findFirst();
    while (e.isFound) {
        val entry = e.loadValue();
        val cut = fee * (entry.bps as int) / BPS_DENOM;
        if (cut > 0) {
            createMessage({
                bounce: BounceMode.NoBounce,
                value: cut as coins,
                dest: entry.addr,
            }).send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_IGNORE_ERRORS);
        }
        e = pp.partners.iterateNext(e);
    }
}

/// R8-12. Give the whole inbound payment back and stop, WITHOUT throwing.
/// Only safe to call BEFORE any state write — every call site below is.
fun refundAndStop(to: address, queryId: uint64, reason: int) {
    // R17-36. DO NOT ANSWER OURSELVES.
    //
    // Five opcodes this contract EMITS — RejectedRefund (0x7e3a11c5),
    // OutbidNotification, SweepBounty, MintFwd and SyncNameOwnerFwd — have no
    // ingress arm, so R13X-6's `else` arm answers them with a RejectedRefund of
    // its own. When the peer in the sender slot is this contract, that is a loop:
    // 4 / 16 / 64 / 317 transactions for 0.01 / 0.05 / 0.2 / 1 GRAM, terminating
    // only when the forward fees have eaten the value.
    //
    // The guard belongs here rather than in a per-opcode arm for two reasons: it
    // covers all 46 refusal sites and every future one, and it does not turn the
    // five opcodes into silently-accepted top-ups — a STRANGER who sends one of
    // them by mistake still gets their money back, which is the whole point of
    // R13X-6. One address comparison, on a path that is already refusing.
    //
    // Self-addressed messages are reachable through any config field that can
    // point at this contract. R17-9 and R17-20 close two of them; this closes the
    // consequence for all of them at once.
    if (to == contract.getAddress()) { return; }
    createMessage({
        bounce: BounceMode.NoBounce,
        value: 0 as coins,
        dest: to,
        body: RejectedRefund { queryId: queryId, reason: reason as uint32 },
    }).send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS);
}

fun refundExcess(to: address, paid: int, cost: int) {
    val excess = paid - cost;
    if (excess >= REFUND_DUST) {
        createMessage({
            bounce: BounceMode.NoBounce,
            value: excess as coins,
            dest: to,
        }).send(SEND_MODE_IGNORE_ERRORS);
    }
}

// ---------- NFT + resolver sync helpers ----------

// mint/reassign the NFT item for a name via the collection
//
// R14-4b (HIGH, migration correctness). `isReserved` WAS HARDCODED `false` HERE.
//
// The flag makes an item permanently non-transferable (AskTransfer 403) and is
// pinned write-once ON at first init (R7-5/R8-11), so a mint that omits it does
// not just mis-set a bit — it decides the item's transferability for good. The
// only path that carries a meaningful value for it is a MIGRATION: a reserved
// foundation single re-issued into a v5 registrar. Measured on the dress
// rehearsal: a reserved single imported `isReserved true -> false`, the item
// deployed transferable, and the foundation's hold on it was gone with no op
// able to restore it (R7-5 forbids the mid-life flip ON, deliberately).
//
// Every other issuance path passes `false` explicitly, which is what they always
// meant; only AdminImport passes the migrant's real flag.
fun sendMint(collection: address, queryId: uint64, nameHash: uint256, owner: address,
             expiresAt: int, emojiCount: int, syncNonce: int, content: cell,
             isReserved: bool, adopt: bool, label: cell?) {
    createMessage({
        bounce: BounceMode.NoBounce,
        // R20-5b sent an ISSUANCE the item's whole prepaid record allowance and a
        // REPAIR the bare deploy floor, on the grounds that AdoptItem is
        // permissionless and its caller is not the beneficiary.
        //
        // R25-4 DELETED THAT BRANCH. The repaired item carries the SAME registry
        // term as a purchased one — up to MAX_TOTAL_TERM — so it needs the same
        // rent, and 0.08 bought it 9.41 years of a ten-year term. `adopt` still
        // distinguishes the two everywhere it should (the item's re-stamp
        // semantics); it has no business distinguishing how much rent the item
        // is left holding. One value, one derivation, one pin.
        value: MINT_VALUE_FUNDED as coins,
        dest: collection,
        body: MintFwd {
            queryId: queryId,
            nameHash: nameHash,
            owner: owner,
            expiresAt: expiresAt as uint32,
            emojiCount: emojiCount as uint8,
            syncNonce: syncNonce as uint32,
            isReserved: isReserved,
            adopt: adopt,               // R14-3: repair re-stamp, never a re-issue
            individualContent: content,
            label: label,               // R20-7: the verified name, for get_domain
        }
    // R17-35. `+16` WAS USED ZERO TIMES IN ALL SEVEN CONTRACTS, WHILE 46 COMMENTS
    // ASSUMED IT.
    //
    // Measured side by side: a COMPUTE throw bounces (sender net -0.0037 GRAM); an
    // ACTION-phase failure is `exit 0, aborted=true, NO BOUNCE`, and the caller's
    // value is absorbed REGARDLESS of the bounce flag they set. Every
    // `refundAndStop` call site in this file carries a comment asserting the
    // opposite about the paths around it.
    //
    // This is the send that can fail in the action phase on a well-formed, fully
    // paid registration: MINT_VALUE against a float the buyer does not control. The
    // compute phase has already written `names` — so without `+16` the buyer's
    // whole payment is absorbed, the name is recorded, and no item exists (R17-9's
    // wc-5 measurement is this shape). `+16` makes the same failure return the
    // payment and leave nothing behind. Free on the happy path; it changes nothing
    // unless the action phase already failed. No-op on any `+2` site, which is why
    // the IGNORE_ERRORS sends elsewhere are deliberately left alone.
    }).send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
}

// push a name-owner bind + record wipe to EVERY registered resolver (decision #4)
//
// V7-1 (CRITICAL). SEND_MODE_IGNORE_ERRORS is load-bearing here, not defensive
// dressing. This fan-out is called from THREE places, and one of them is not
// funded by anything the contract can assert:
//
//   Reveal / issueName  — funded, opsBudgetRegister asserted against the payer.
//   OwnerSynced         — funded ONLY by the NFT item's NOTIFY_VALUE, a
//                         COMPILE-TIME CONSTANT (0.1 GRAM) in a different
//                         contract that cannot know how many resolvers are
//                         registered here.
//
// With enough resolvers the fan-out costs more than OwnerSynced received, so
// the difference comes out of this contract's balance. Without IGNORE_ERRORS an
// underfunded send aborts the ACTION phase, which rolls back the COMPUTE phase
// — including the `st.names.set(...)` that recorded the new owner. Measured
// before the fix: the NFT moved to the buyer while the registry and every
// resolver stayed on the seller, so the name kept directing funds at the seller,
// silently, with no user-side remedy (see docs/V7_FINDINGS.md V7-1).
//
// Skipping ONE resolver push is recoverable — the permissionless ResyncOwner
// re-drives it. Losing the registry write is not. Fail soft, never revert.
fun syncAllResolvers(resolvers: map<uint256, address>, queryId: uint64, labelHash: uint256,
                     newOwner: address, expiresAt: int) {
    var entry = resolvers.findFirst();
    while (entry.isFound) {
        val resolverAddr = entry.loadValue();
        createMessage({
            bounce: BounceMode.NoBounce,
            value: SYNC_VALUE as coins,
            dest: resolverAddr,
            body: SyncNameOwnerFwd {
                queryId: queryId,
                labelHash: labelHash,
                newOwner: newOwner,
                expiresAt: expiresAt as uint32,
            }
        }).send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_IGNORE_ERRORS);
        entry = resolvers.iterateNext(entry);
    }
}
// R9-6: pushExpiryToResolvers (a term-only UpdateNameExpiry fan-out) was REMOVED.
// Its only caller, MakePermanent, now uses the authoritative syncAllResolvers like
// every other live-state change — a term-only push that arrives past expiresAt+GRACE
// hits the resolver's R8-2 drop and DELETES the entry (see the note in MakePermanent).
// Deleting the helper keeps the footgun from being reintroduced. RenewName always
// used syncAllResolvers (R8-7); nothing else needs a term-only resolver push.

// ---------- message bodies (incoming) ----------

// Step 1: commit (reveals nothing about the name)
struct (0x00000010) Commit {
    queryId: uint64
    commitment: uint256         // H(nameHash ‖ salt ‖ committer)
}

// Step 2: reveal + register. Recomputes the commitment from the SENDER, checks
// timing, then runs the registration. Direct one-step register is not available.
struct RevealParties {
    newOwner: address
    referrer: address?          // optional affiliate; paid a bounded share of the fee
}

struct (0x00000011) Reveal {
    queryId: uint64
    nameHash: uint256
    salt: uint256
    emojiCount: uint16
    numYears: uint16
    sigValidUntil: uint64       // S-1: attestation expiry (signed by the signer)
    parties: Cell<RevealParties>
    rawName: cell               // raw UTF-8 bytes; proven against nameHash
    content: cell               // TEP-64 individual content (attested)
    signature: Cell<SignatureCell>
}

struct SignatureCell {
    sig: bits512
}

struct (0x00000002) RenewName {
    queryId: uint64
    nameHash: uint256
    numYears: uint16
}

struct (0x00000004) WithdrawFees {
    queryId: uint64
    amount: coins
    to: address
}

struct (0x00000005) UpdateSigner {
    queryId: uint64
    newSignerPublicKey: uint256
    // V7-30: the new key must sign H(ROTATION_DOMAIN | registrar | newKey).
    // Rotation is the one operation that can permanently disable issuance — a
    // key nobody holds means no attestation can ever be produced again, on any
    // path, with no way back. Proof-of-possession makes that unreachable by
    // accident, and it costs one signature check on an admin-only message.
    proof: Cell<SignatureCell>
}

// V7-30: promote a staged signer once its timelock has run. Permissionless on
// purpose — the rotation was already authorised when it was staged, and leaving
// promotion to the admin alone would let a lost admin key strand a good signer.
struct (0x00000006) ApplySigner {
    queryId: uint64
}

// V7-30: abort a staged rotation. Adds no power an admin does not already have
// (only the admin can stage one) and gives a mis-entered key an exit.
struct (0x00000007) CancelSigner {
    queryId: uint64
}



// --- v2 admin ops ---
struct (0x0000000a) SetNftCollection {
    queryId: uint64
    collection: address
}

// R24-4: the collection acknowledging that it is the staged pointer. Sent by the
// collection's own `AnnounceMinter` op, which addresses it to whatever it holds
// as its minter — so both ends verify the other independently.
struct (0x0000002a) ConfirmNftCollection {
    queryId: uint64
}

// R24-4b: retract a staged collection pointer. Admin-only — unlike the promote,
// which is authorised by the staging and must be sendable by the target.
struct (0x0000002b) CancelNftCollection {
    queryId: uint64
}

struct (0x0000000b) AddResolver {
    queryId: uint64
    resolver: address
}

struct (0x0000000c) RemoveResolver {
    queryId: uint64
    resolver: address
}

struct (0x0000000d) SetFirstYearPrice {
    queryId: uint64
    emojiTier: uint16           // V7-34: 2..7. Tier 1 is REJECTED — singles never
                                // carry a first-year price. (Was "1,2,3,4,5", pre-V5.)
    price: uint64
}

struct (0x0000000e) SetFeeDestination {
    queryId: uint64
    feeDestination: address
}

struct (0x0000000f) SetCommitTiming {
    queryId: uint64
    minDelay: uint32
    maxAge: uint32
}

// --- two-step admin transfer (ownership handover / project sale) ---
struct (0x00000020) InitiateAdminTransfer {
    queryId: uint64
    newAdmin: address
}

struct (0x00000021) AcceptAdminTransfer {
    queryId: uint64
}

struct (0x00000022) CancelAdminTransfer {
    queryId: uint64
}

struct (0x00000023) SetAdminTimelock {
    queryId: uint64
    timelock: uint32
}

struct (0x00000024) SetReferralBps {
    queryId: uint64
    referralBps: uint16
}

// Configure (or clear) the ecosystem-partner revenue share.
// partnerBps = 0 or partnerAddress = null disables it.
// Upgrade a single-emoji name to permanent. Owner-only, singles-only, one-way.
struct (0x0000004b) MakePermanent {
    queryId: uint64
    nameHash: uint256
}

// ONE-WAY: freeze every buy-side price forever. There is no unlock op and no
// code path that clears the flag. After this the project cannot raise OR lower
// what a name costs — which is the point, and also the risk: it forfeits any
// response to GRAM volatility. Pull it once GRAM has settled, not at launch.
struct (0x0000004e) LockPrices {
    queryId: uint64
}

struct (0x0000004c) SetPermanentPrice {
    queryId: uint64
    price: uint64
}

// Add or update one ecosystem partner's standing share. Bounded by MAX_PARTNERS
// and by the COMBINED 30% ceiling, both immutable.
struct (0x0000004a) SetPartner {
    queryId: uint64
    partner: address
    bps: uint16
}

struct (0x0000004d) RemovePartner {
    queryId: uint64
    partner: address
}

// per-address KOL override: set a custom referral rate (up to 33%) for one referrer
struct (0x00000025) SetReferrerRate {
    queryId: uint64
    referrer: address
    bps: uint16
}

// drop a KOL override -> that referrer falls back to the public rate
struct (0x00000026) RemoveReferrerRate {
    queryId: uint64
    referrer: address
}

// --- singles auction (admin runs curated drops) ---
struct (0x00000040) StartAuction {
    queryId: uint64
    nameHash: uint256
    emojiCount: uint16
    numYears: uint16          // term the hammer price includes
    startBid: coins
    duration: uint32
    sigValidUntil: uint64
    rawName: cell
    content: cell
    signature: Cell<SignatureCell>
}

// F-2: sent to the outbid leader with their refund
struct (0x557cea20) OutbidNotification {
    queryId: uint64
}

// R14-2: carries the sweep bounty back to the sweeper. Opcode-tagged for the same
// reason OutbidNotification and RejectedRefund are — an indexer, and the
// sweeper's own bot, must be able to tell a paid sweep from a bare refund without
// re-deriving it from the transaction graph.
struct (0x5be3a077) SweepBounty {
    queryId: uint64
}

// R8-12. THE BOUNCE FLAG IS THE SENDER'S, NOT OURS.
//
// Every guard in the paid handlers was `assert … throw`. On TON that refunds the
// payment ONLY if the sender marked the message bounceable. Verified on a live
// local network on 2026-07-31: OpenMask — the wallet this project forked for its
// own demo — was handed the EQ (bounceable) form of an address and sent the
// message NON-bounceable anyway. 0.05 TON to an uninitialised address stayed
// there instead of bouncing.
//
// So a buyer who reveals one second early lost the whole registration payment
// (20-110 GRAM), and an outbid-by-a-race bidder lost their bid (150+ GRAM), on
// the most likely failure in the system.
//
// "Require bounceable" cannot fix this: the throw that would enforce it is
// itself defeated by the same bit. The only fix is to NOT THROW — refund the
// inbound value and return. This carries the exit code that WOULD have been
// thrown, so the client still learns why, and an indexer can tell a rejection
// apart from a top-up.
struct (0x7e3a11c5) RejectedRefund {
    queryId: uint64
    reason: uint32
}

// R25-6b. The same opcode as a plain constant, because the `else` arm has to
// recognise it on the WIRE — it is emit-only, so it is deliberately absent from
// `AllowedMessage` and never gets parsed into this struct on ingress. Kept
// adjacent so the two can never drift.
const OP_REJECTED_REFUND: int = 0x7e3a11c5;

struct (0x00000041) PlaceBid {
    queryId: uint64
    nameHash: uint256
}

// permissionless once the auction has ended
struct (0x00000042) SettleAuction {
    queryId: uint64
    nameHash: uint256
}

// admin may cancel only while there are NO bids
struct (0x00000043) CancelAuction {
    queryId: uint64
    nameHash: uint256
}



// Publish the hash of the canonical normalization spec (§5.1).
struct (0x00000048) SetNormalizationPolicy {
    queryId: uint64
    policyHash: uint256
}

// ONE-WAY: freeze the normalization policy forever. After this the project has
// publicly and irrevocably committed to one canonical answer for "what is 👍".
struct (0x00000049) LockNormalizationPolicy {
    queryId: uint64
}


// --- free promotional / partnership mint (any tier) ---
struct (0x00000044) AdminMint {
    queryId: uint64
    nameHash: uint256
    emojiCount: uint16
    numYears: uint16          // 0 = permanent
    sigValidUntil: uint64
    owner: address
    rawName: cell
    content: cell
    signature: Cell<SignatureCell>
}

// MIGRATION DOOR. Re-issues a name that already exists on a PREDECESSOR
// registrar, preserving its true remaining term and permanence flag.
//
// Why this exists: these contracts carry no SETCODE and are immutable by
// design — that is what makes "renewals can never rise" and "the cap is one
// number, forever" true rather than aspirational. If an audit or a defect ever
// forces a v5 registrar, the NFT collection and resolver can simply be
// re-pointed (SetMinter / SetRegistrar) and the item addresses survive, because
// they derive from (nameHash, collection). The only thing AdminMint could NOT
// carry across is the exact expiry: it computes now + numYears*YEAR, so every
// holder would be rounded to a whole year, some gaining and some losing time
// they paid for. This op closes that gap and nothing else.
//
// It grants no authority AdminMint does not already have. Deliberately it
// CANNOT overwrite: any name already present is refused outright, which is
// stricter than assertAvailableForIssue (no post-grace reclaim, no exceptions).
struct (0x00000045) AdminImport {
    queryId: uint64
    nameHash: uint256
    emojiCount: uint16
    expiresAt: uint32         // the TRUE expiry carried over, not a fresh term
    isPermanent: bool
    // R14-4b: the migrant's real reserved flag. `sendMint` used to hardcode
    // false, which silently RELEASED every reserved foundation single into the
    // market on import, irreversibly (R7-5 forbids flipping it back ON).
    isReserved: bool
    // R14-4a: the nonce the ITEM still carries. The item survives a registrar
    // migration untouched, so an import that does not carry its nonce leaves the
    // two permanently unable to agree about ownership. 0 = "no history, derive
    // one", which is the correct value for a name that never had an item.
    syncNonce: uint32
    sigValidUntil: uint64
    owner: address
    rawName: cell
    content: cell
    signature: Cell<SignatureCell>
}

// ONE-WAY: end the migration window forever.
struct (0x0000004f) LockImports {
    queryId: uint64
}

// S-2: permissionless cleanup of an abandoned (expired) commitment — anyone can
// reclaim storage rent for a commitment past commitMaxAge.
struct (0x00000027) SweepCommitment {
    queryId: uint64
    commitment: uint256
}

// R13X-1: PERMISSIONLESS TERM HEAL — the missing mirror of the item's ResyncOwner.
//
// The two writes this contract makes into the NFT layer — sendMint and the
// UpdateExpiryReqFwd that follows a renewal or MakePermanent — are BounceMode.
// NoBounce and unacknowledged. `names` is written first; if the hop then refuses
// (ERR_NOT_MINTER after a minter rotation) or the item does not exist yet
// (registered before SetNftCollection was wired), this contract never learns.
//
// ResyncOwner already re-drives the OWNER upwards, item -> collection -> here.
// Nothing re-drove the TERM downwards, and `issueName` is gated behind
// assertAvailableForIssue, so a name that is live in `names` can never be
// re-minted to repair itself. Measured consequence: a holder who paid to renew
// (or paid ~1000 GRAM for MakePermanent) ends up with a name that the registry
// says is theirs and current, while the item still believes the old term. Past
// the item's stale grace the name resolves nowhere (dnsresolve bits 0), cannot be
// transferred (410), cannot be written to (406), and cannot be bought by anyone
// else (405). Every repair the registrar offers is then closed: RenewName 442,
// MakePermanent 442.
//
// This carries NO new information — it re-asserts the term `names` already holds,
// which is the same reason ResyncOwner is safe to leave open. It is
// minter-originated, so it arrives at the item `authoritative` and does not wipe
// records (R12-1-FIX), and the item's extend-only guard (414) makes a replay a
// no-op. The caller pays; there is nothing to grief.
struct (0x00000028) PushTerm {
    queryId: uint64
    nameHash: uint256
}

// R14-3: THE OTHER HALF OF THE HEAL — PushTerm moves the TERM down, ResyncOwner
// moves the OWNER up, and NOTHING moved the IDENTITY of the issuance itself.
//
// Two divergences were reachable with no op anywhere able to repair them, and
// both are cases where the item is not merely stale but is not from the current
// issuance at all:
//
//   (a) A mint that never landed. `sendMint` is NoBounce and unacknowledged, so
//       a name registered before `SetNftCollection` was wired — or across a
//       minter rotation — leaves `names` holding nonce N while the item holds
//       nonce M != N (or does not exist). Measured in R11Operability K1: the
//       holder's NFT can never be created, every renewal strands EXPIRY_VALUE at
//       an uninitialised address, the name is non-transferable for its whole
//       term, and the ONLY repair was to let the name lapse past grace and
//       AdminMint it — which costs the holder the name they paid for.
//
//   (b) R13X-2 made an ADMIN-originated collection Mint stamp syncNonce 0. That
//       closed a seizure path and had to; but 0 can never equal a live record's
//       nonce, so the F-12 guard drops that item's relays forever. The repair
//       R13X-2 left behind — an admin mint — is now the thing that breaks it, and
//       `LockImports` closes the last escape (AdminImport into a fresh registrar).
//
// WHY IT GRANTS NO AUTHORITY. Every field on the wire comes from `names`: owner,
// expiresAt, emojiCount, isReserved and the record's OWN nonce, unchanged. The
// caller supplies a nameHash and the gas. It is the exact mirror of PushTerm,
// which re-asserts the term this contract already holds.
//
// WHY IT CANNOT SEIZE A LIVE NAME. This is the part that needed care, because
// pushing an OWNER downwards inverts the direction of truth: ownership is the
// ITEM's (transfer -> collection -> OwnerSynced), the term is the registrar's.
// A holder who bought the NFT on a marketplace after a dropped relay is the true
// owner while `names` still shows the seller — and blindly re-minting from
// `names` would hand the NFT back to the seller for the price of one message.
//
// The nonce is what tells the two cases apart, and the check has to live on the
// ITEM because no contract can read another's storage on TON:
//
//   item nonce == record nonce  the item IS from the current issuance, so any
//                               owner difference is a legitimate transfer this
//                               registry has not heard about. The repair is
//                               ResyncOwner (upwards). Adopt is REFUSED (item 421).
//   item nonce != record nonce  the item is not from the current issuance, so its
//                               owner field is not evidence of anything. Adopt.
//
// So adopt and ResyncOwner partition the divergence space and neither can do the
// other's job. And because the carried nonce is the record's own, a successful
// adopt is idempotent: a replay finds the nonces equal and is refused.
//
// PERMISSIONLESS, like PushTerm and like the item's ResyncOwner. The failure it
// repairs strands a PAYING holder, so it must not depend on the admin key still
// existing — that is the same reasoning that makes ApplySigner and ApplyMinter
// permissionless. The worst an attacker achieves by paying for one is that the
// item agrees with the registry, which is the state the system wants. It cannot
// wipe a holder's records either: the item keeps them when the owner does not
// change (see the item's adopt branch), so there is no free grief in it.
struct (0x00000029) AdoptItem {
    queryId: uint64
    nameHash: uint256
}

// --- from collection: an NFT item changed owner ---
struct (0x5ea3cc24) OwnerSynced {
    queryId: uint64
    nameHash: uint256
    newOwner: address
    syncNonce: uint32       // F-12: the nonce the ITEM was last minted with
}

// ---------- message bodies (outgoing) ----------

// to collection (matches emoji_nft_collection Mint 0x1f04537a)
struct (0x1f04537a) MintFwd {
    queryId: uint64
    nameHash: uint256
    owner: address
    expiresAt: uint32
    isReserved: bool
    emojiCount: uint8       // tier, stored on the item for marketplaces
    syncNonce: uint32       // F-12
    // R14-3: this write is a REPAIR of an item that is provably out of step with
    // the registry, not a (re)issuance. The item refuses it unless its own nonce
    // differs from the one carried here, and keeps the holder's records when the
    // owner does not change. See the AdoptItem note.
    adopt: bool
    individualContent: cell
    // R20-7: the raw UTF-8 name bytes, so the item can serve `get_domain`.
    // `assertCanonicalName` has already proved sha256(this) == nameHash on every
    // path that sets it, which is what makes it a fact rather than a claim by
    // the time the item stores it. Null on the AdoptItem repair, which has no
    // name: the registry stores only the hash.
    label: cell?
}

// to collection (matches UpdateExpiryReq 0x3c81aa02)
//
// R16-2: `syncNonce` is the ISSUANCE this term belongs to. R12-1-FIX exempts
// minter-originated extensions from the item's record wipe on the stated ground
// that "the registrar refuses to originate an extension on a lapsed name, so an
// authoritative extension is never a resurrection." That reasoning silently
// assumes the registry and the item agree about WHICH issuance is live. When
// they have diverged — the registrar re-issued the name to a new owner but the
// mint never landed, the R13X-1 / R14-3 state — the assumption fails: an
// authoritative extension writes the NEW owner's expiry onto the OLD owner's
// item, flips isWithinGrace() back to true, and un-masks the previous holder's
// wallet record on a name somebody else paid for. Carrying the nonce lets the
// item tell "stale term, same holder" (exempt, R12-1-FIX's case) from "not this
// issuance at all" (must wipe). AdoptItem already carries exactly this nonce for
// exactly this reason.
struct (0x3c81aa02) UpdateExpiryReqFwd {
    queryId: uint64
    nameHash: uint256
    newExpiresAt: uint32
    syncNonce: uint32           // R16-2: the issuance the registry currently records
}

// to resolver (matches resolver v2 SyncNameOwner 0xb2033a58)
struct (0xb2033a58) SyncNameOwnerFwd {
    queryId: uint64
    labelHash: uint256
    newOwner: address
    expiresAt: uint32           // F-6
}

// R17-7 (MEDIUM). A SHORT BODY ON A *KNOWN* OPCODE DEFEATED SIX ROUNDS OF REFUND
// WORK. It is a language-level defect, which is why logic review never caught it.
//
// Tolk emits ONE EAGER, CONTIGUOUS LOAD BLOCK at the point of the first field
// access, not a lazy field-by-field read. On every paid handler here that point
// is inside the first guard's own condition, so a body one bit short of the last
// field throws cell-underflow (exit 9) BEFORE `refundAndStop` is reachable.
// Verbatim from the disassembly of the `Reveal` arm:
//
//     x{00000011} SDBEGINSQ IFJMP:<{ ... // if (msg.emojiCount < 1)
//       64 LDU 256 LDU 256 LDU 16 LDU 16 LDU 64 LDU LDREF LDREF LDREF PLDREF
//       s6 PUSH 1 LESSINT IFJMP:<{ ... refundAndStop ... }>
//
// Measured against a bounce-stripping wallet: a `Reveal` carrying 703 of 704 bits
// is exit 9 and the registrar KEEPS 29.999870462 of 30 GRAM. Bare 32-bit bodies on
// Commit / PlaceBid / SettleAuction / MakePermanent / SweepCommitment are all
// confiscated the same way — while `unknown op 0xdeadbeef` refunds correctly,
// because R13X-6's `else` arm never reads a field.
//
// REACHABILITY IS VERSION SKEW, AND IT HAPPENED IN THIS REPO ONE ROUND AGO. R16-2
// appended `syncNonce: uint32` to `UpdateExpiryReq` and AUDIT_R16 line 450 records
// four hand-built bodies having to grow the trailing field. A front end built
// against a pre-R16 struct emits a body 32 bits short — of a KNOWN opcode.
//
// The project already recognised the class and closed it in exactly ONE of 79
// match arms (emoji_nft_item.tolk SetRecord, R12-3-GAP, `== 353`). These are the
// same guard for the arms where money is at stake, using `refundAndStop` because
// the sender's wallet may have stripped the bounce flag (R8-12).
//
// The counts are DERIVED from the struct definitions above, not guessed; refs are
// not counted in `remainingBitsCount`, so a struct whose tail is refs needs both
// numbers (only `Reveal` does).
// R23-4. op32 + queryId64, the whole body of a bare keeper op.
const BODY_OP_QUERYID: int      = 96;
const BODY_OP_QUERYID_HASH: int = 352;   // op32 + queryId64 + one 256-bit key.
                                         // Commit(commitment), MakePermanent(nameHash),
                                         // PlaceBid(nameHash), SettleAuction(nameHash),
                                         // SweepCommitment(commitment)
const BODY_RENEW_NAME: int      = 368;   // BODY_OP_QUERYID_HASH + numYears16
const BODY_REVEAL: int          = 704;   // op32 + queryId64 + nameHash256 + salt256
                                         //  + emojiCount16 + numYears16 + sigValidUntil64
const BODY_REVEAL_REFS: int     = 4;     // parties, rawName, content, signature — all four
                                         // required, and 704 bits with three of them is the
                                         // same exit 9 by a different door

// R21-1 (MEDIUM, TSA round 21). THE GUARD ABOVE VALIDATES THE ENVELOPE, NOT THE
// REFS — AND `Reveal` IS THE ONLY GUARDED ARM THAT CARRIES ANY.
//
// R17-7's harm survived on the one arm R18 was written to harden. TSA's witnesses
// were bodies of EXACTLY 704 bits with EXACTLY 4 refs — perfectly conformant
// envelopes, so the guard above passes them — whose ref 0 carried 266 / 533 / 534 /
// 704 bits instead of a `RevealParties`. `msg.parties.load()` then deserialises it,
// and exit 9 aborts the compute phase before `refundAndStop` can run. Measured, from
// a bounce-stripping wallet at 30 GRAM (audit/round21/tsa/tests/R21TsaReveal.spec.ts):
//
//     parties ref = 0 / 266 / 533 / 534 / 704 bits -> exit 9, registrar KEPT
//                                                    29.999750 of 30 GRAM, all five
//     703-bit envelope (R18's own case)            -> exit 0, 0 GRAM kept
//
// A BIT COUNT ALONE IS NOT THE PREDICATE HERE, which is why this is a walker rather
// than a third `BODY_*` constant. 534 bits IS the well-formed length of two internal
// addresses, and the 534-bit witness still threw: `LDSTDADDR` / `LDOPTSTDADDR` refuse
// anything that is not `addr_std$10` (or `addr_none$00` for the optional referrer),
// so the TAGS have to be checked too. The three offsets TSA reported — 384 / 400 /
// 416 — are exactly those two loads and the closing `ENDS`, so the walker below
// mirrors all three: tag, length, and "nothing left over".
//
// ALL FOUR REFS WERE AUDITED, NOT JUST THE ONE TSA WITNESSED. `Reveal` dereferences
// two of them through a TYPED load that can underflow, and both are covered here:
//
//   parties    Cell<RevealParties>   TSA's finding.
//   signature  Cell<SignatureCell>   THE SAME DEFECT, one door further down. Found
//                                    by auditing the other three refs after fixing
//                                    this one. `msg.signature.load().sig` sits below
//                                    four refunds and above ERR_BAD_SIGNATURE, so a
//                                    reveal that clears the commit-timing checks
//                                    reaches it. Measured on this build, same
//                                    bounce-stripping 30 GRAM reveal:
//                                      sig ref 0 / 511 / 513 bits, or 512 + a ref
//                                        -> exit 9, registrar KEPT 29.999428 of 30
//
// The other two are plain `cell`, handed to helpers that walk them defensively and
// RETURN a code rather than throwing, so they are already covered and are left
// alone: a ragged `rawName` is `checkCanonicalName`'s 457 (the R17-7 sibling
// documented on that function), and `content` is reached only behind a valid
// attestation over its hash and is then walked by `checkUriShape`, which also
// returns. Measured: a malformed content cell answers 402, refunded.
const ADDR_STD_TAG: int   = 0b100;  // addr_std$10 + anycast_none$0 — what Tolk's `address` is
const ADDR_NONE_TAG: int  = 0b00;   // addr_none$00 — what a null `address?` serialises to
const ADDR_STD_BITS: int  = 267;    // '10' + '0' + workchain:int8 + hash:uint256
const PARTIES_BITS_NO_REFERRER: int = 269;   // newOwner(267) + referrer = addr_none(2)
const PARTIES_BITS_REFERRER: int    = 534;   // newOwner(267) + referrer = addr_std(267)
const SIG_CELL_BITS: int            = 512;   // SignatureCell { sig: bits512 }, no refs

/// R21-1. True iff the two refs `Reveal` deserialises with a typed load —
/// `msg.parties.load()` and `msg.signature.load()` — are guaranteed not to throw.
/// Derived from the struct definitions, field by field, in the order each eager load
/// walks them; both loads close with `ENDS`, so refs and trailing bits count.
///
/// Anycast (`addr_std$10 anycast$1`) is refused with everything else: no wallet, no
/// `@ton/core` builder and no Tolk `storeAddress` can produce one, and the referrer
/// payout and NFT mint below both need a plain workchain+hash destination.
fun revealRefsAreWellFormed(parties: Cell<RevealParties>, signature: Cell<SignatureCell>): bool {
    var g = signature.beginParse();
    if (g.remainingBitsCount() != SIG_CELL_BITS || g.remainingRefsCount() != 0) { return false; }
    var s = parties.beginParse();
    if (s.remainingRefsCount() != 0) { return false; }   // the `ENDS` at offset 416
    val bits = s.remainingBitsCount();
    if (bits != PARTIES_BITS_NO_REFERRER && bits != PARTIES_BITS_REFERRER) { return false; }
    if (s.preloadUint(3) != ADDR_STD_TAG) { return false; }   // newOwner: LDSTDADDR
    s.skipBits(ADDR_STD_BITS);
    return bits == PARTIES_BITS_NO_REFERRER                   // referrer: LDOPTSTDADDR
        ? s.preloadUint(2) == ADDR_NONE_TAG
        : s.preloadUint(3) == ADDR_STD_TAG;
}

type IncomingMessage =
    | Commit | Reveal | RenewName | WithdrawFees | UpdateSigner | ApplySigner | CancelSigner
    | SetNftCollection | ConfirmNftCollection | CancelNftCollection | AddResolver | RemoveResolver | SetFirstYearPrice | SetFeeDestination
    | SetCommitTiming | InitiateAdminTransfer | AcceptAdminTransfer | CancelAdminTransfer
    | SetAdminTimelock | SetReferralBps | SetPartner | RemovePartner | SetReferrerRate | RemoveReferrerRate
    | MakePermanent | SetPermanentPrice | LockPrices
    | SweepCommitment | StartAuction | PlaceBid | SettleAuction | CancelAuction
    | AdminMint
    | AdminImport | LockImports
    | SetNormalizationPolicy | LockNormalizationPolicy | OwnerSynced | PushTerm | AdoptItem;

// ---------- entry point ----------

fun onInternalMessage(in: InMessage) {
    if (in.body.remainingBitsCount() < 32) {
        return;
    }

    var st = loadStorage();
    val msg = lazy IncomingMessage.fromSlice(in.body);
    val nowTime = blockchain.now();

    match (msg) {
        Commit => {
            // R17-7: shape first, before any field is touched. `msg.queryId` cannot
            // be quoted back here — reading it IS the eager load that throws — so
            // the refund carries queryId 0, exactly as the unknown-op arm does.
            if (in.body.remainingBitsCount() != BODY_OP_QUERYID_HASH) {
                refundAndStop(in.senderAddress, 0, ERR_BAD_BODY);
                return;
            }
            // R14B1-1. THE FIRST MESSAGE A USER EVER SENDS, AND IT CONFISCATED.
            //
            // R8-12 / R10-1 / R13-2 converted every paid handler to
            // `refundAndStop(...) + return` for one reason: on TVM a `throw`
            // returns the value ONLY when the SENDER set the bounce flag, and real
            // wallets strip it (OpenMask was verified live sending non-bounceable
            // to an EQ address). Those three rounds swept Reveal, RenewName,
            // PlaceBid, MakePermanent and SettleAuction and never came back to
            // `Commit` — the cheapest op, and therefore the one nobody costed.
            //
            // It is also the only op in the contract a user can trigger TWICE BY
            // ACCIDENT. Measured on a double-tapped Commit at 0.15 GRAM with the
            // bounce flag stripped: exit 417, 0 of 0.15 GRAM returned, the
            // registrar kept 0.018772 after fees and burned the rest. No attacker
            // is required — a slow block and an impatient second click is the
            // whole reproduction, and the user's second click costs them their
            // deposit while their FIRST commitment is still perfectly good.
            //
            // The funding guard below is the same story on the other side: a front
            // end quoting the pre-R14-2 0.02 floor sends 0.02 against the current
            // 0.05 and the user pays 0.02 for nothing.
            //
            // Both guards sit before `saveStorage`, and `auxC` is a local until it
            // is written back, so an early return leaves state untouched.
            //
            // V7-11: a commitment is a permanent map entry this contract pays
            // rent on until someone sweeps it, and Commit is permissionless.
            // FRONTEND_TOUCHPOINTS documented 0.1 GRAM; nothing enforced it, so
            // dust-funded commits were accepted without limit.
            if (in.valueCoins < COMMIT_MIN_VALUE) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_INSUFFICIENT_PAYMENT);
                return;
            }
            // R17-5: refuse at the soft cap rather than let the action phase fail
            // with code 50 and no refund. Unconditional here, unlike the three
            // issuance arms: a commitment is a HASH, so this handler cannot tell a
            // new name from the re-registration of a lapsed one. The cost of that
            // is honest and narrow — at the cap, a lapsed name can only be re-issued
            // through `AdminMint`, which does make the distinction. Refusing the
            // commit is what keeps the last ~1,254 cells free so the ops that still
            // work (renew, transfer, settle, sweep) keep working.
            if ((st.totalNames as int) >= NAMES_SOFT_CAP) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_NAME_UNAVAILABLE);
                return;
            }
            // R24-5: ...and the bound that actually tracks the account's cells.
            // A commitment is the one entry an unprivileged party can add, so
            // this is the arm where the budget guard matters most: it stops a
            // commitment surge from eating the margin the names depend on, and
            // it refuses with the deposit returned rather than letting the write
            // fail in the action phase with code 50.
            if (!hasStateHeadroom(st)) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_STATE_BUDGET);
                return;
            }
            // Step 1: store the commitment with its timestamp. Anyone may commit;
            // the commitment binds to whichever address the eventual reveal uses.
            // Duplicate active commitment is rejected (prevents timestamp reset grief).
            var auxC = st.auxData();
            val existing = auxC.commitments.get(msg.commitment);
            if (existing.isFound) {
                val prior = existing.loadValue();
                val cfgC = st.cfg();
                // allow overwrite only if the prior one already expired
                if (nowTime <= (prior + cfgC.commitMaxAge)) {
                    refundAndStop(in.senderAddress, msg.queryId, ERR_COMMIT_EXISTS);
                    return;
                }
            }
            // R24-5: only a NEW key grows the state. Re-stamping an expired
            // commitment reuses its cell, so the counter must not move — the same
            // discipline the resolver's `recordCount` uses for categories.
            if (!existing.isFound) {
                auxC.liveCommitments = ((auxC.liveCommitments as int) + 1) as uint32;
            }
            auxC.commitments.set(msg.commitment, nowTime as uint32);
            st.aux = auxC.toCell();
            saveStorage(st);
        }

        Reveal => {
            // R17-7: the handler this finding was measured on — 703 of 704 bits from
            // a bounce-stripping wallet kept 29.9998 of 30 GRAM. Both numbers are
            // checked: the four refs carry the owner, the name, the content and the
            // signature, and a 704-bit body missing one of them underflows in the
            // same load block. This precedes R14B1-4's parameter guards below,
            // because those are what triggers the load.
            if (in.body.remainingBitsCount() != BODY_REVEAL
                || in.body.remainingRefsCount() != BODY_REVEAL_REFS) {
                refundAndStop(in.senderAddress, 0, ERR_BAD_BODY);
                return;
            }
            // R21-1: ...and the guard above stopped at the envelope. `parties` and
            // `signature` are the two refs this arm DEREFERENCES with a typed load, so
            // they are the two that can underflow before any refusal is reachable;
            // `rawName` and `content` go to helpers that return a code instead of
            // throwing. See `revealRefsAreWellFormed` for the shapes and for the
            // measured 29.999750 / 29.999428 of 30 GRAM this returns.
            //
            // The queryId IS quoted here, unlike the envelope guard's `0`: the envelope
            // check has already passed, so the eager load cannot underflow and reading
            // the field is safe. A caller whose refs are malformed still gets their own
            // query correlated back.
            if (!revealRefsAreWellFormed(msg.parties, msg.signature)) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_BAD_BODY_REF);
                return;
            }
            // R14B1-4. THE FIRST FOUR LINES OF THE MOST EXPENSIVE HANDLER STILL THREW.
            //
            // R8-12 / R10-1 / R13-2 worked backwards through `Reveal` — the commit
            // timing, the signature, the availability guards, the funding check —
            // and stopped before reaching the four cheap parameter checks at the
            // top. Those run BEFORE anything else, so they are the guards a
            // mis-configured front end hits FIRST, and they carried the whole
            // payment when they fired.
            //
            // Measured on a NON-BOUNCEABLE reveal of a single-emoji name funded at
            // 82,200,000 nanoton: exit 427, and the registrar kept 82,054,799 of it.
            // The tier-1 quote is not 0.08 GRAM — a single is auction-only at a 150
            // GRAM floor, and a front end that offers one for sale by mistake sends
            // the tier price it computed. At a 100 GRAM quote the same path keeps
            // over 99 GRAM. 427 in particular is a POLICY refusal, not a user error:
            // the name is real, the signature is valid, and the contract simply does
            // not sell singles that way.
            //
            // All four precede every state write — `st` is a local and `saveStorage`
            // is ~200 lines below — so the conversion is the same mechanical one
            // R10-1 documents on `MakePermanent`.
            if (msg.emojiCount < 1) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_BAD_EMOJI_COUNT);
                return;
            }
            // R17-5: the cap binds only NEW names. Re-registering a lapsed one
            // rewrites an existing `names` entry and adds no cells, so refusing it
            // would cost the namespace something for nothing. The map read is
            // short-circuited behind a field compare, so it costs zero gas until
            // the registry is actually full.
            if ((st.totalNames as int) >= NAMES_SOFT_CAP
                && !st.names.get(msg.nameHash).isFound) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_NAME_UNAVAILABLE);
                return;
            }
            // R24-5b. NO HEADROOM GUARD HERE, DELIBERATELY — AND THE FIRST DRAFT
            // OF R24-5 HAD ONE, WHICH WAS A BUG.
            //
            // A reveal is CELL-NEUTRAL: it deletes one commitment (-2 cells) and
            // writes one name (+2). Measured with the `stateBudget()` getter,
            // `used` is 1,026 before and 1,026 after. So a guard here could never
            // prevent growth — it could only refuse a purchase that was already
            // safe, and the refused op is precisely the one that would have
            // RELEASED a commitment cell.
            //
            // The cost of getting that wrong scaled badly: at the ceiling every
            // in-flight buyer holding a paid, valid, correctly-aged commitment
            // would be refused 482, and at 30,000 names an attacker needed only
            // ~208 concurrent commitments (~10 GRAM/day) to freeze the entire
            // public purchase path. Guarding the op that SHRINKS the account is
            // how a capacity check turns into a denial-of-service primitive.
            //
            // `Commit` carries the guard instead, because it is the only
            // permissionless op that actually grows the account.
            // SINGLES ARE LOCKED (July 23 policy): never publicly registrable —
            // not at launch, not after a lapse. Auction drops and AdminMint are
            // the only doors. The attestation binds the true count, so a single
            // cannot be smuggled in by claiming a higher tier.
            if (msg.emojiCount < 2) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_SINGLE_LOCKED);
                return;
            }
            // namespace length cap. V7-34: MAX_EMOJI_COUNT is an immutable code
            // constant of 7 — there is no setter and no lock op. The previous
            // comment said "launch 5, admin-widenable to 8, lockable": three wrong
            // facts in the sentence most likely to be quoted into marketing.
            if (msg.emojiCount > MAX_EMOJI_COUNT) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_TOO_MANY_EMOJI);
                return;
            }
            if (msg.numYears < 1 || msg.numYears > MAX_YEARS) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_BAD_YEARS);
                return;
            }

            val cfg = st.cfg();

            // --- commit-reveal validation (front-run defense) ---
            val parties = msg.parties.load();
            val cmt = commitmentHash(msg.nameHash, msg.salt, in.senderAddress);
            var auxR = st.auxData();
            // R8-12. These four are ~every realistic user failure and they all
            // happen BEFORE any state write, so refunding and returning is safe.
            // They no longer throw: see the RejectedRefund note above.
            val found = auxR.commitments.get(cmt);
            if (!found.isFound) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_NO_COMMITMENT);
                return;
            }
            val committedAt = found.loadValue();
            if (nowTime < (committedAt + cfg.commitMinDelay)) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_COMMIT_TOO_NEW);
                return;
            }
            if (nowTime > (committedAt + cfg.commitMaxAge)) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_COMMIT_EXPIRED);
                return;
            }
            // content-bound attestation (decision #2) + S-1 request-scoped validity
            if (nowTime > msg.sigValidUntil) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_SIG_EXPIRED);
                return;
            }
            // R14B1-16: ...and bounded ABOVE. See MAX_SIG_WINDOW — an unbounded
            // window made every reveal's signature a reusable coupon for the same
            // name's next registration, harvestable from the public message body.
            if (msg.sigValidUntil > nowTime + MAX_SIG_WINDOW) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_SIG_EXPIRED);
                return;
            }
            val contentHash = msg.content.hash();
            val h = attestationHash(msg.nameHash, msg.emojiCount, contentHash, msg.sigValidUntil,
                                    cfg.prices.load().normalizationPolicyHash, ATT_PURPOSE_REVEAL,
                                    in.senderAddress);   // R24-1: bind the payer
            val sigSlice = msg.signature.load().sig as slice;
            // R13-2. THE LAST THROWING GUARD ON THE MOST EXPENSIVE PAID PATH.
            //
            // R8-12 and R10-1 converted the paid handlers to refundAndStop because
            // a `throw` only returns value when the SENDER set the bounce flag, and
            // real wallets strip it (OpenMask does). ERR_SIG_EXPIRED, one line
            // above, was converted. This one was not — and it is reachable without
            // the buyer doing anything wrong.
            //
            // `ApplySigner` is permissionless: once the timelock matures, ANYONE
            // may fire it. A buyer who obtained a signature seconds before the
            // rotation lands has a correctly-formed, honestly-obtained attestation
            // against the OLD key. Their reveal arrives after the rotation and
            // fails here. Measured with a bounce-stripped reveal on a tier-2 name:
            // the registrar kept 29.99 of 30 GRAM. Nothing about the flow is the
            // buyer's fault, and the rotation is not even the admin's act.
            //
            // Nothing is persisted at this point — `st` is a local and saveStorage
            // has not run — so an early return leaves state untouched.
            if (!isSignatureValid(h, sigSlice, cfg.signerPublicKey)) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_BAD_SIGNATURE);
                return;
            }

            // PERMANENT policy: no skin-toned name may ever be minted.
            //
            // R14B1-5. THE EXPENSIVE HALF, AND THE ONE THAT CARRIED THE FULL PRICE.
            //
            // These two ran BEFORE the `paid < cost + ops` check below, so a reveal
            // refused here arrived with the entire license fee on board. Measured
            // with a bounce-stripped buyer: 30.10 of 30.10 GRAM kept, on a name the
            // SIGNER had signed and the on-chain floor rejected — exactly the event
            // the floor exists for, billed to the party who could not have known.
            //
            // 439 (rawName does not hash to nameHash) is in the same family and is
            // the first line of `checkCanonicalName`, so it is covered here too.
            //
            // The `check*` twins return the code instead of throwing; see the note
            // on `assertCanonicalName`. The three admin issuance paths and the
            // `checkName` get method keep the throwing shims deliberately.
            val nameErr = checkCanonicalName(msg.rawName, msg.nameHash, msg.emojiCount);
            if (nameErr != 0) {
                refundAndStop(in.senderAddress, msg.queryId, nameErr);
                return;
            }
            // R20-6b: SHAPE, not the byte filter. The filter walked the same 300
            // bytes the binding below walks and cost 263,144 gas on a 100-byte
            // name — a quarter of basechain's 1,000,000 ceiling, which the
            // top-of-namespace case then blew (exit -14). It is implied by the
            // binding; `checkUriShape` carries the proof.
            val uriErr = checkUriShape(msg.content);
            if (uriErr != 0) {
                refundAndStop(in.senderAddress, msg.queryId, uriErr);
                return;
            }
            // R17-4: and it must be THIS name's suffix. `checkCanonicalName`
            // above has already proven `rawName` against the attested
            // `nameHash`, which is what makes this a binding rather than a
            // comparison of two unknowns — and, since R20-6b, what makes it a
            // strictly stronger statement than the byte filter it replaced.
            val bindErr = checkContentBindsName(msg.content, msg.rawName);
            if (bindErr != 0) {
                refundAndStop(in.senderAddress, msg.queryId, bindErr);
                return;
            }

            // F-1: a name with a live auction lot is NOT publicly registrable.
            // Without this, a drop lot and a list-price registration can both
            // claim the same nameHash and whichever writes last wins.
            //
            // R10-1: these three are REFUNDS, not throws. ERR_NAME_TAKEN in
            // particular is the launch-day race — two buyers commit the same name,
            // the loser's reveal lands second — and it is the single most likely
            // rejection in the whole system. R8-12 covered the commit-timing and
            // signature guards above and left the availability guards throwing, so
            // the loser of a race forfeited the entire fee (measured: 20.14 GRAM in,
            // 0 back) whenever their wallet stripped the bounce flag.
            //
            // Nothing below is persisted: `st` is a local and `saveStorage` has not
            // run, so an early return leaves state untouched even after the
            // in-memory `st.totalNames += 1`.
            if (st.auctions.get(msg.nameHash).isFound) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_AUCTION_EXISTS);
                return;
            }

            // availability + reserved check
            val existing = st.names.get(msg.nameHash);
            if (existing.isFound) {
                val rec = existing.loadValue();
                // never reclaimable, or still inside its term/grace
                if (rec.isPermanent || nowTime < (rec.expiresAt + GRACE)) {
                    refundAndStop(in.senderAddress, msg.queryId, ERR_NAME_TAKEN);
                    return;
                }
            } else {
                st.totalNames += 1;
            }

            val prices = cfg.prices.load();
            val cost = registerCost(prices, msg.emojiCount, msg.numYears);
            // R13-1: the per-byte compute term. assertCanonicalName has already run
            // above, so rawName is known byte-aligned and within MAX_NAME_BYTES.
            val ops = opsBudgetRegister(countResolvers(cfg.resolvers), cfg.nftCollection != null)
                    + nameByteLen(msg.rawName) * REGISTER_COMPUTE_PER_BYTE;
            val paid = in.valueCoins as int;

            // referral: a bounded share of the license fee, paid from the fee (not
            // added on top). referrer must be a real address and not the buyer.
            var referralCut = 0;
            if (parties.referrer != null) {
                val (refWc, referrerHash) = parties.referrer!.getWorkchainAndHash();
                val (_bwc, buyerHash) = parties.newOwner.getWorkchainAndHash();
                // R7-13. THE PAYER COUNTS TOO.
                //
                // This checked `newOwner` alone. But `newOwner` is a free field in
                // the reveal — the commitment binds `in.senderAddress`:
                //
                //     val cmt = commitmentHash(msg.nameHash, msg.salt, in.senderAddress);
                //
                // so payer and recipient are independent, and checking only the
                // second let one person hold two wallets, pay from A, deliver to
                // B and name A as the referrer. Two distinct addresses, guard
                // satisfied, cut paid — straight back to the wallet that just
                // spent it, since refundExcess also targets the sender.
                //
                // Not a griefing cost: a standing discount on the list price for
                // anyone who wants it, on every registration, forever. 5% at the
                // default rate and 33% at the KOL ceiling, with the traction
                // counters under-reporting revenue by the same amount.
                //
                // The payer is the one identity in a reveal that cannot be chosen
                // freely at reveal time, which is exactly what makes it the right
                // thing to check. A genuine gift — three distinct parties — still
                // pays out.
                val (_pwc, payerHash) = in.senderAddress.getWorkchainAndHash();
                // F-11: the referrer is BUYER-supplied and is paid with
                // PAY_FEES_SEPARATELY, so the contract covers the forward fee.
                // A masterchain destination costs ~25x a basechain one, which a
                // buyer could set deliberately to bleed the contract on every
                // cheap registration. Referrals are basechain-only; an off-chain
                // referrer simply earns nothing.
                if (refWc == BASECHAIN && referrerHash != 0
                    && referrerHash != buyerHash && referrerHash != payerHash) {
                    val rate = effectiveReferralBps(cfg.referrerRates, cfg.referralBps, referrerHash);
                    if (rate > 0) {
                        referralCut = cost * rate / BPS_DENOM;
                    }
                }
            }
            // caller must cover fee + ops (referral comes OUT of the fee, so no extra)
            // R10-1: refund rather than throw — an underpayment (e.g. the front end
            // read a price the admin has since moved) must not cost the buyer the
            // whole payment. Still before saveStorage, so no state is committed.
            if (paid < cost + ops) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_INSUFFICIENT_PAYMENT);
                return;
            }

            // consume the commitment (single-use)
            auxR.commitments.delete(cmt);
            // R24-5: the cell is released here. Guarded so the counter can never
            // underflow even if a future path reaches this line twice.
            if ((auxR.liveCommitments as int) > 0) {
                auxR.liveCommitments = ((auxR.liveCommitments as int) - 1) as uint32;
            }
            st.aux = auxR.toCell();

            val newExpiry = nowTime + msg.numYears * YEAR;
            // R23-8. THE FIFTH ISSUANCE PATH, WHICH THE "CHECKED ONCE" NOTE MISSED.
            //
            // `issueName` opens with `assert(expiresAt <= EXPIRY_HORIZON || ...)`
            // under a comment reading "the other four issuance paths converge here,
            // so the horizon is checked once rather than four times". There are
            // FIVE. `Reveal` — the primary public purchase path — does not call
            // `issueName`; it inlines an equivalent body, and it inherited neither
            // the horizon check nor `RenewName`'s (which has both).
            //
            // Two consequences, both on a FULLY PAID transaction, long past every
            // `refundAndStop`:
            //   * once `nowTime > 0xFFFFFFFF - numYears*YEAR`, `newExpiry as uint32`
            //     is a raw TVM range check — exit 5, aborted, uncatalogued. Measured
            //     at bc.now = 4137287416 (~2101-01-17) with numYears = 5: exit 5,
            //     name not registered, and against a bounce-stripping wallet the
            //     registrar kept 60.157 of 60.162 GRAM with nothing issued.
            //   * at the single second where `newExpiry == 0xFFFFFFFF` exactly, the
            //     record is written with the PERMANENT sentinel while `isPermanent`
            //     is false — the precise ambiguity EXPIRY_HORIZON = 0xFFFFFFFE was
            //     introduced to make unreachable. The sentinel is shared with the
            //     NFT item, so the item would treat the name as never-expiring while
            //     this contract lets it lapse and be re-registered.
            //
            // Refund rather than throw, matching every other refusal in this
            // handler: the buyer asked for a term this contract cannot represent,
            // which is their front end's error, and they should get their money back
            // rather than fund it. Not reachable before 2101 — fixed here anyway
            // because there is no SETCODE on this contract and 2101 arrives once.
            if (newExpiry > EXPIRY_HORIZON) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_EXPIRY_OVERFLOW);
                return;
            }
            // F-12: same nonce discipline as issueName — every owner write bumps it
            val priorR = st.names.get(msg.nameHash);
            var nonceR = 1;
            if (priorR.isFound) { nonceR = (priorR.loadValue().syncNonce as int) + 1; }
            st.names.set(msg.nameHash, {
                owner: parties.newOwner,
                expiresAt: newExpiry as uint32,
                emojiCount: msg.emojiCount as uint16,
                isPermanent: false,
                syncNonce: nonceR as uint32,
            });
            // partner share (ecosystem integration deal) — on the gross fee
            val partnerCut = partnerCutOf(cfg, cost);
            // traction counters record what the project actually keeps
            st.totalRevenue = (st.totalRevenue + (cost - referralCut - partnerCut)) as uint128;
            st.totalRegistrations += 1;
            saveStorage(st);

            if (cfg.nftCollection != null) {
                sendMint(cfg.nftCollection!, msg.queryId, msg.nameHash, parties.newOwner,
                         newExpiry, msg.emojiCount, nonceR, msg.content, false, false, msg.rawName);
            }
            syncAllResolvers(cfg.resolvers, msg.queryId, msg.nameHash, parties.newOwner, newExpiry);

            payPartner(cfg, cost);

            // pay the referrer their share (funded from the fee portion)
            if (referralCut > 0) {
                // PAY_FEES_SEPARATELY: the referrer receives their EXACT share.
                // Without it the forward fee (~0.001 GRAM) came out of the payout,
                // silently underpaying every referrer on every sale. Same fix as
                // the auction outbid refund (F-3).
                createMessage({
                    bounce: BounceMode.NoBounce,
                    value: referralCut as coins,
                    dest: parties.referrer!,
                }).send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_IGNORE_ERRORS);
            }

            // refund true excess; retain (cost - referralCut) as net fee, ops spent on sends
            refundExcess(in.senderAddress, paid - ops - referralCut - partnerCut,
                         cost - referralCut - partnerCut);
        }

        RenewName => {
            // R17-7: renewals are the op most likely to be sent by an old automation
            // — a bot written against a prior struct is exactly the version skew that
            // makes this reachable. Shape before fields.
            if (in.body.remainingBitsCount() != BODY_RENEW_NAME) {
                refundAndStop(in.senderAddress, 0, ERR_BAD_BODY);
                return;
            }
            // R10-1: renewal is permissionless and routinely automated, so a
            // mistimed one (name already lapsed past grace, or a typo'd hash) is a
            // realistic user failure. Same R8-12 rule as Reveal: refund, never throw,
            // because a non-bounceable wallet turns a throw into a confiscation.
            // All four guards precede every state write.
            if (msg.numYears < 1 || msg.numYears > MAX_YEARS) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_BAD_YEARS);
                return;
            }
            val found = st.names.get(msg.nameHash);
            if (!found.isFound) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_NAME_NOT_FOUND);
                return;
            }
            val rec = found.loadValue();
            if (rec.isPermanent) {   // nothing to renew
                refundAndStop(in.senderAddress, msg.queryId, ERR_ALREADY_PERMANENT);
                return;
            }
            if (nowTime >= (rec.expiresAt + GRACE)) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_NAME_EXPIRED);
                return;
            }

            val cost = renewCost(rec.emojiCount, msg.numYears);
            val cfgRenew = st.cfg();
            // F-7: reserve partner forwarding fees here too, exactly as
            // opsBudgetRegister does, so a renewal is never balance-negative.
            // F-6: a renewal now also pushes the new term to every resolver.
            var opsR = 20000000 + MAX_PARTNERS * 2000000
                     + countResolvers(cfgRenew.resolvers) * SYNC_VALUE;
            if (cfgRenew.nftCollection != null) { opsR += EXPIRY_VALUE; }
            val paid = in.valueCoins as int;
            if (paid < cost + opsR) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_INSUFFICIENT_PAYMENT);
                return;
            }

            val newExpiry = rec.expiresAt + msg.numYears * YEAR;   // extend from current expiry (ENS)
            // F-2: bound the TOTAL horizon, not just this call's length. Also
            // replaces the raw TVM range-check (exit 5) that used to fire at the
            // uint32 ceiling with a domain error.
            // R10-1: still before any write, so refund rather than throw.
            if (newExpiry > nowTime + MAX_TOTAL_TERM) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_TERM_TOO_LONG);
                return;
            }
            // R15-9: and the ABSOLUTE horizon, which the bound above does not
            // imply. This is the path the finding was measured on — a paid renewal
            // near 2106 — so it refunds rather than throws, like every other guard
            // in this handler. See EXPIRY_HORIZON.
            if (newExpiry > EXPIRY_HORIZON) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_EXPIRY_OVERFLOW);
                return;
            }
            st.names.set(msg.nameHash, {
                owner: rec.owner,
                expiresAt: newExpiry as uint32,
                emojiCount: rec.emojiCount,
                isPermanent: rec.isPermanent,   // preserved (renew rejects permanent anyway)
                syncNonce: rec.syncNonce,       // renewal is not a re-issue
            });
            val partnerCutR = partnerCutOf(cfgRenew, cost);
            st.totalRevenue = (st.totalRevenue + (cost - partnerCutR)) as uint128;
            st.totalRenewals += 1;
            saveStorage(st);

            // push new expiry to the NFT item (term lives with the name)
            if (cfgRenew.nftCollection != null) {
                createMessage({
                    bounce: BounceMode.NoBounce,
                    value: EXPIRY_VALUE as coins,
                    dest: cfgRenew.nftCollection!,
                    body: UpdateExpiryReqFwd {
                        queryId: msg.queryId,
                        nameHash: msg.nameHash,
                        newExpiresAt: newExpiry as uint32,
                        syncNonce: rec.syncNonce,           // R16-2
                    }
                // R17-35: see sendMint. A renewal that pays, extends `names` and
                // then cannot afford this hop leaves the registry and the item
                // disagreeing about the term — the R13X-1 divergence — with the
                // renewal fee absorbed. `+16` returns the fee instead.
                }).send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
            }

            // F-6: keep every resolver's term in step, WITHOUT wiping records
            // R8-7. A renewal accepted in the last seconds of grace used to push
            // ONLY the term. The resolver's R8-2 drop then fires on arrival --
            // the registrar cleared the grace check at T, the message lands at
            // T+delta past expiresAt+GRACE, the entry is dead, and it is deleted.
            // The holder has paid and the name stops resolving.
            //
            // Pushing the OWNER as well makes the message authoritative rather
            // than incremental, so the resolver can re-establish the binding
            // instead of dropping it. Records survive when the owner is
            // unchanged, which is exactly the renewal case.
            syncAllResolvers(cfgRenew.resolvers, msg.queryId, msg.nameHash,
                             rec.owner, newExpiry);

            payPartner(cfgRenew, cost);
            refundExcess(in.senderAddress, paid - opsR - partnerCutR, cost - partnerCutR);
        }

        // NFT-authoritative ownership: item transfer -> collection -> here.
        // Update the registry owner and re-sync all resolvers (wipe records).
        OwnerSynced => {
            val cfgO = st.cfg();
            assert(cfgO.nftCollection != null && in.senderAddress == cfgO.nftCollection!) throw ERR_NOT_COLLECTION;
            val found = st.names.get(msg.nameHash);
            if (found.isFound) {
                val rec = found.loadValue();
                // F-12 STALE-SYNC GUARD.
                //
                // ResyncOwner on the item is permissionless by design (it heals
                // desyncs). That also means a lapsed holder can fire one at the
                // exact moment a new registrant's mint is still in flight: the
                // item still holds the OLD owner, so the relay would arrive here
                // and overwrite the new registrant — reverting the registry and
                // wiping the buyer's resolver binding, while the NFT ends up with
                // the buyer. Registry and NFT then disagree.
                //
                // Every owner write bumps syncNonce, and the mint carries it to
                // the item. A relay echoing an older nonce is provably describing
                // ownership from before the latest issuance, so it is dropped.
                // Legitimate transfers echo the current nonce and pass.
                //
                // R13X-2, belt to the collection's braces. Nonce 0 is not a value
                // issueName can ever produce — it starts at 1 and only increments —
                // so it is the sentinel the collection now stamps on an ADMIN-
                // originated Mint. That was the relay by which a collection admin
                // could take a registered name whose item had not been deployed
                // yet: the item's reassign guard does not run on an uninitialised
                // item, and every input the F-12 check needs is a public getter.
                // Rejecting 0 here means the property does not rest on the
                // collection alone being correct.
                if ((msg.syncNonce as int) == 0) {
                    return;
                }
                if ((msg.syncNonce as int) != (rec.syncNonce as int)) {
                    return;
                }
                st.names.set(msg.nameHash, {
                    owner: msg.newOwner,
                    expiresAt: rec.expiresAt,      // term unchanged by transfer (ENS)
                    emojiCount: rec.emojiCount,
                    isPermanent: rec.isPermanent,  // permanence conveys with the NFT
                    syncNonce: rec.syncNonce,      // transfer does not re-issue
                });
                saveStorage(st);
                syncAllResolvers(cfgO.resolvers, msg.queryId, msg.nameHash, msg.newOwner, rec.expiresAt);
            }
        }

        PushTerm => {
            // R21-2 (LOW, TSA round 21). R18 guarded the seven arms carrying
            // 20–1,000 GRAM and left the two ~0.1 GRAM repair arms open on the
            // grounds of proportion. The pattern is now established and costs one
            // predicate, so they are closed too. Measured before, from a
            // bounce-stripping wallet (audit/round21/tsa/tests/R21TsaShortBody.spec.ts):
            //
            //     PushTerm 32-bit body, bounce=false -> exit 9, kept 0.099807 of 0.10
            //     PushTerm 96-bit body, bounce=false -> exit 9, kept 0.099804 of 0.10
            //     ...the same bodies with bounce=true -> exit 9, kept 0.000000
            //
            // Bits only, and no ref count: `PushTerm { queryId, nameHash }` has no
            // refs to dereference, so a stray one is ignored by the lazy union parse
            // exactly as it is on Commit / PlaceBid / SettleAuction. queryId 0 for
            // the same reason those arms use it — reading the field IS the eager
            // load that throws.
            if (in.body.remainingBitsCount() != BODY_OP_QUERYID_HASH) {
                refundAndStop(in.senderAddress, 0, ERR_BAD_BODY);
                return;
            }
            // R13X-1. See the struct for why this exists. Permissionless and
            // read-only against `names`: it re-asserts the term this contract
            // already holds, so the worst an attacker can do is pay to make the
            // item agree with the registry.
            val cfgT = st.cfg();
            if (cfgT.nftCollection == null) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_NO_NFT_COLLECTION);
                return;
            }
            val foundT = st.names.get(msg.nameHash);
            if (!foundT.isFound) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_NAME_NOT_FOUND);
                return;
            }
            // R10-1: refund rather than throw, so a bounce-stripping wallet
            // (OpenMask) does not silently forfeit the caller's value.
            if ((in.valueCoins as int) < EXPIRY_VALUE + PUSH_TERM_GAS) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_INSUFFICIENT_PAYMENT);
                return;
            }
            // No state write. The item's UpdateExpiry is extend-only, so a replay
            // — or a race against a renewal already in flight — is a no-op (414),
            // not a corruption.
            createMessage({
                bounce: BounceMode.NoBounce,
                value: EXPIRY_VALUE as coins,
                dest: cfgT.nftCollection!,
                body: UpdateExpiryReqFwd {
                    queryId: msg.queryId,
                    nameHash: msg.nameHash,
                    newExpiresAt: foundT.loadValue().expiresAt,
                    syncNonce: foundT.loadValue().syncNonce,    // R16-2
                }
            // R17-35: the fourth site of the same shape, added for the same reason
            // as the three the finding names. PushTerm writes no state and its ONLY
            // effect is this hop, so an absorbed action failure means the caller
            // paid 0.07 GRAM for a heal that did not happen and got no signal.
            }).send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
        }

        AdoptItem => {
            // R21-2: the other half of the pair, same shape and same reason as
            // PushTerm above. `AdoptItem { queryId, nameHash }` is also 352 bits.
            // Measured before, from a bounce-stripping wallet:
            //
            //     AdoptItem 32-bit body, bounce=false -> exit 9, kept 0.249803 of 0.25
            //     AdoptItem 96-bit body, bounce=false -> exit 9, kept 0.249801 of 0.25
            //     ...the same bodies with bounce=true -> exit 9, kept 0.000000
            if (in.body.remainingBitsCount() != BODY_OP_QUERYID_HASH) {
                refundAndStop(in.senderAddress, 0, ERR_BAD_BODY);
                return;
            }
            // R14-3. See the struct for the two divergences this repairs and for
            // why re-minting from `names` cannot seize a live name.
            //
            // Same shape as PushTerm: no state write here at all, so a replay, a
            // race against a renewal, or a race against another adopter is a
            // no-op rather than a corruption. The whole guard that makes this safe
            // is the item's nonce comparison, which is the one fact this contract
            // cannot observe.
            val cfgAd = st.cfg();
            if (cfgAd.nftCollection == null) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_NO_NFT_COLLECTION);
                return;
            }
            val foundAd = st.names.get(msg.nameHash);
            if (!foundAd.isFound) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_NAME_NOT_FOUND);
                return;
            }
            // R10-2 / R10-1: fund first, refund rather than throw. The mint value
            // is forwarded PAY_FEES_SEPARATELY, so the caller must also cover
            // this handler's compute and the forward fee — the same arithmetic
            // PUSH_TERM_GAS does for PushTerm.
            //
            // R25-4: the forwarded value is `MINT_VALUE_FUNDED`, not the deleted
            // 0.08 `MINT_VALUE`, so this floor is 0.52 and NOT 0.1. It is a
            // refusal-with-refund rather than a throw, so an under-funded healer
            // gets their money back and a legible ERR_INSUFFICIENT_PAYMENT — the
            // 5.2x price rise cannot silently eat anybody's value.
            if ((in.valueCoins as int) < MINT_VALUE_FUNDED + PUSH_TERM_GAS) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_INSUFFICIENT_PAYMENT);
                return;
            }
            val recAd = foundAd.loadValue();
            // The record's OWN nonce, not a fresh one. Bumping it here would
            // invalidate an honest in-flight OwnerSynced and would make a replay
            // meaningful; carrying it makes the operation idempotent and leaves
            // the F-12 anchor exactly where it was.
            // `content` and `isReserved` are DELIBERATELY not carried. This
            // registry holds neither — the TEP-64 suffix lives on the item and
            // `isReserved` was dropped from NameRecord by the July-23
            // simplification — and a permissionless op must never let its CALLER
            // supply them, which is the only other way they could get here. The
            // item's adopt branch therefore leaves both fields untouched; the
            // empty cell below is a placeholder the item never reads.
            // R20-7: `label` joins `content` and `isReserved` in the list of
            // things this op DELIBERATELY does not carry. The registry stores the
            // hash, not the name, and a permissionless op must not let its caller
            // supply the string a marketplace renders. The item's adopt branch
            // leaves the field untouched; null here is the placeholder it never
            // reads. (The self-verifying alternative — a caller-supplied rawName
            // checked against nameHash — is assessed in the item's adopt branch.)
            sendMint(cfgAd.nftCollection!, msg.queryId, msg.nameHash, recAd.owner,
                     recAd.expiresAt as int, recAd.emojiCount as int,
                     recAd.syncNonce as int, beginCell().endCell(),
                     false, true, null);
        }

        WithdrawFees => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            // R17-37. THE FIELD WAS DECLARED, THE WRAPPER MADE IT REQUIRED, AND THE
            // CONTRACT NEVER LOADED IT.
            //
            // The compiled Fift read `64 LDU / NIP / LDGRAMS / DROP` — `to` skipped
            // entirely. So on the ONE op that moves money, the trailing address was
            // structurally optional: a 140-bit body worked, and so did 1,023 bits of
            // garbage, while every operator, script and doc wrote an explicit
            // destination and believed it was being honoured. An operator who types
            // "withdraw to the multisig" got it wherever `feeDestination` happened
            // to point — which, after a `SetFeeDestination` nobody remembered, is
            // the whole point of the field.
            //
            // Kept and ENFORCED rather than deleted. Deleting it would silence the
            // wrapper's argument without answering the operator's question; as a
            // cross-check it does real work — a stale `feeDestination` is now a loud
            // 476 with the funds still in the contract, instead of a payment to the
            // old treasury. It also makes a short body fail: `to` is the last field,
            // so reading it forces Tolk's load block to require every bit of the
            // struct (R17-7's mechanism, used here in our favour).
            //
            // Admin-only, so `throw` is correct — R8-12's refund conversion is for
            // paths a stranger's wallet can reach.
            val cfgW = st.cfg();
            assert(msg.to == cfgW.feeDestination) throw ERR_WRONG_FEE_DESTINATION;
            // F-5: never pay out bidder escrow or the rent buffer. getOriginalBalance
            // includes this message's own value, so net it out first.
            // V7-1: reserve the resolver fan-out obligation, not just rent.
            // R17-6: both auction terms are now O(1) field reads — this used to be
            // the gas-heaviest read in the contract and hard-failed (-14) at 853
            // live lots, freezing all fee revenue. This expression, the
            // `freeBalance()` getter and R14-2's sweep-bounty clamp must all stay
            // identical to the nanoton (V7-1); they share one definition.
            // R14B1-14: the reserve also scales with `st.totalNames`.
            val freeBal = freeBalanceOf(st, in.valueCoins as int);
            assert((msg.amount as int) <= freeBal) throw ERR_WITHDRAW_EXCEEDS_FREE;
            createMessage({
                bounce: BounceMode.NoBounce,
                value: msg.amount,
                dest: cfgW.feeDestination,   // decision #6: admin-set payout target
            }).send(SEND_MODE_IGNORE_ERRORS);
        }

        // ---- V7-30: signer rotation, staged behind the admin timelock ----
        UpdateSigner => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            assert(msg.newSignerPublicKey != 0) throw ERR_BAD_SIGNER_KEY;
            // proof-of-possession: only the holder of the new key can produce this
            assert(isSignatureValid(signerRotationHash(msg.newSignerPublicKey),
                                    msg.proof.load().sig as slice,
                                    msg.newSignerPublicKey)) throw ERR_BAD_SIGNATURE;
            // R14B1-10. AN OP THAT IS NOT ABOUT THE TIMELOCK WAS COMMITTING ONE.
            //
            // This line used to be `applyPendingTimelock(mutate st, nowTime)`, which
            // does not merely READ the effective timelock — it WRITES it:
            // `st.adminTimelock = st.pendingTimelock`, staged slot cleared, and this
            // handler then calls `saveStorage`. V7-19 refuses `SetAdminTimelock`
            // while a handover is pending, precisely so a staged decrease cannot be
            // committed under a successor's nose; `UpdateSigner` is not covered by
            // that guard and does not need to be, because it has no business
            // touching the timelock at all.
            //
            // Measured: with a decrease to 0 matured and a handover pending,
            // `SetAdminTimelock` correctly returned 420, and `UpdateSigner` was
            // accepted — moving `pendingTimelockAt 1800172800 -> 0` and
            // `adminTimelock -> 0` as a SIDE EFFECT. Combined with R14B1-9 above
            // (which reads the landed value at accept time) that side effect was
            // the whole exploit: one unrelated admin op, and the successor inherits
            // a 0-second anti-theft window.
            //
            // The shape used here is `AcceptAdminTransfer`'s: compute the effective
            // timelock — a matured decrease DOES count, so nobody is made to wait
            // longer than they agreed to — and do not persist it. The only writer
            // of `adminTimelock` is now `SetAdminTimelock` (V7-19b's staged path)
            // plus the reset in `AcceptAdminTransfer`.
            val effLockU = effectiveTimelock(st, nowTime);
            var auxU = st.auxData();
            auxU.pendingSigner = msg.newSignerPublicKey;
            auxU.pendingSignerAt = (nowTime + effLockU) as uint32;
            st.aux = auxU.toCell();
            saveStorage(st);
        }

        ApplySigner => {
            // R23-4 (found by TSA symbolic analysis, fresh round). THE ONE
            // PERMISSIONLESS OP WITHOUT A BODY-SHAPE GUARD.
            //
            // Nine arms in this handler carry `remainingBitsCount() != BODY_…`
            // before touching a field, because Tolk's `lazy` load fires at first
            // field access and a truncated body underflows there (exit 9,
            // uncatalogued, and — since real wallets strip the bounce flag — the
            // sender's value is absorbed with no refund and no diagnostic). R17-7
            // and R21-2 closed this class systematically; this arm was missed.
            //
            // It is the arm where it matters most: `ApplySigner` is permissionless
            // BY DESIGN, so its callers are competing keeper bots rather than a
            // known operator, and a keeper with a malformed body loses its funding
            // silently and repeatedly. Measured pre-fix: 32-bit body, exit 9,
            // sender net cost 0.100307 of 0.1 GRAM sent, nothing returned.
            if (in.body.remainingBitsCount() != BODY_OP_QUERYID) {
                refundAndStop(in.senderAddress, 0, ERR_BAD_BODY);
                return;
            }
            var auxA = st.auxData();
            // R14B1-3. THE ONE PERMISSIONLESS ADMIN OP, AND IT KEPT THE LOSER'S GAS.
            //
            // ApplySigner is permissionless BY DESIGN — the struct's own header
            // says so: "leaving promotion to the admin alone would let a lost admin
            // key strand a good signer". Permissionless means competing keeper bots
            // are the EXPECTED operating mode, not an attack, and exactly one of
            // them wins. Every loser arrives at a cleared `pendingSignerAt` and hit
            // this throw.
            //
            // Measured with a bounce-stripped second ApplySigner one block after
            // the first: exit 459 and 0.998943 of 1.0 GRAM kept by the registrar.
            // A keeper funds generously precisely because it must not run out of
            // gas mid-rotation, so the amount confiscated scales with how carefully
            // the operator provisioned their bot.
            //
            // The struct already carries `queryId`, so the refund is correlatable.
            // Nothing is written before this point.
            //
            // NOTE — the ERR_TIMELOCK_ACTIVE guard immediately below is left
            // THROWING, deliberately and out of scope here. It is the same class of
            // confiscation, but firing it means the caller mis-read the maturity
            // time rather than lost a race, and converting it changes what a
            // still-locked rotation looks like on the wire for the monitoring in
            // docs/V7_INCIDENT_RUNBOOK. If it is ever converted it belongs with a
            // measurement of its own.
            if (auxA.pendingSignerAt == 0) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_NO_PENDING_SIGNER);
                return;
            }
            assert(nowTime >= (auxA.pendingSignerAt as int)) throw ERR_TIMELOCK_ACTIVE;
            var cA = st.cfg();
            cA.signerPublicKey = auxA.pendingSigner;
            st.config = cA.toCell();
            auxA.pendingSigner = 0;
            auxA.pendingSignerAt = 0;
            st.aux = auxA.toCell();
            saveStorage(st);
        }

        CancelSigner => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            var auxX = st.auxData();
            assert(auxX.pendingSignerAt != 0) throw ERR_NO_PENDING_SIGNER;
            auxX.pendingSigner = 0;
            auxX.pendingSignerAt = 0;
            st.aux = auxX.toCell();
            saveStorage(st);
        }


        SetNftCollection => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            // V7-18 (HIGH, admin). This was the single most powerful admin
            // capability in the system and nothing bounded it. OwnerSynced trusts
            // whatever address sits in cfg.nftCollection, so an admin could point
            // it at a wallet they control, send one hand-crafted OwnerSynced, and
            // take ANY name — including a PERMANENT one that the contract
            // otherwise guarantees is "never re-issuable" by any path. It
            // defeated every other guard at once: no attestation, no payment, no
            // availability check, no commit-reveal.
            //
            // The collection is deploy-time wiring, not an operating lever: its
            // address is vanity-mined and must be settled before the first mint
            // because every item address derives from it. Allowing changes while
            // the registry is EMPTY keeps deploy-time flexibility (a fat-fingered
            // address is still recoverable) and closes the steal-any-name path
            // the moment there is anything to steal.
            //
            // Note this does NOT constrain the documented v5 migration: that
            // re-points the COLLECTION's minter (SetMinter), not this field.
            // V7-18b: block REPOINTING a live collection, but always allow the
            // FIRST wiring. Gating on totalNames alone made a deploy-ordering
            // slip permanent: register one name before SetNftCollection lands and
            // the NFT layer could never be attached, with no heal path (the only
            // heal, ResyncOwner, needs an item that can never exist).
            assert(st.cfg().nftCollection == null || st.totalNames == 0) throw ERR_NAME_TAKEN;
            // R17-9 (MEDIUM). THE ONE FIELD V7-18b PROTECTS, AND NOTHING CHECKED
            // WHAT IT WAS BEING SET TO.
            //
            // Zero hash, workchain 5 and the registrar's OWN address all deployed
            // `exit 0`; only `addr_none` was refused, and that by serialization
            // rather than by a check. Each of the three is unrecoverable, because
            // the gate directly above closes behind the first registration:
            //
            //   self  — a Reveal produces 29 transactions, 26 of them a
            //           registrar->registrar MintFwd/RejectedRefund loop. The
            //           registrar keeps 20.128 of the buyer's 20.24 GRAM, no item
            //           exists, and `totalNames` still reaches 1 — so the repair
            //           `SetNftCollection(real)` then answers 405 FOREVER.
            //           `st.totalNames` is only ever `+= 1`; the gate never reopens.
            //   wc 5  — every Reveal is `aborted=true, actionCode 36`, NO bounce,
            //           the buyer's whole 23.19 GRAM absorbed, and `registered=false`
            //           so `totalNames` never moves and the next buyer loses too.
            //   mc    — the mint succeeds at +0.0188 GRAM each and deploys items
            //           where storage costs 1000x basechain, against an
            //           ITEM_MIN_STORAGE of 0.05 that was sized for basechain.
            //
            // Likelihood is low — deploy-localnet.ts derives the address and dies
            // if it disagrees, and preflight C-1 is FAIL severity — but the guard
            // is three comparisons against an outcome with no repair op.
            val (colWc, colHash) = msg.collection.getWorkchainAndHash();
            assert(colHash != 0) throw ERR_ZERO_ADDRESS;
            assert(msg.collection != contract.getAddress()) throw ERR_SELF_REFERENCE;
            assert(colWc == BASECHAIN) throw ERR_BAD_PARTNER_WC;
            // R24-4 (the fix for the finding the three guards above could not
            // reach). THE POINTER IS STAGED. THE COLLECTION ITSELF PROMOTES IT.
            //
            // ===============================================================
            // WHAT THE THREE GUARDS ABOVE DO NOT COVER
            // ===============================================================
            // They reject a zero hash, this contract's own address and a
            // non-basechain workchain. They cannot reject the case that actually
            // happens: a WRONG BUT LIVE address — a wallet, a stale collection
            // from a previous deploy, a typo that lands on an existing account.
            // Such an address silently ACCEPTS a `MintFwd` (0.5 GRAM of the
            // buyer's ops budget, gone), the mint is `NoBounce` so nothing comes
            // back, and the reveal returns exit 0 with `totalNames = 1`. The gate
            // above then closes on `totalNames != 0` and `SetNftCollection(real)`
            // answers 405 FOREVER. Measured end to end: no item ever created, 0.5
            // GRAM lost per registration for the life of the contract, `AdoptItem`
            // re-sending the mint to the same wrong address, and no SETCODE.
            //
            // ===============================================================
            // THE ECOSYSTEM'S ANSWER: THE TARGET ACKNOWLEDGES
            // ===============================================================
            // TON does not use time-delayed timelocks for this; it uses two-phase
            // claim plus a state precondition, and the second phase is performed
            // BY THE TARGET:
            //
            //   ton-blockchain/stablecoin-contract: `change_admin` writes
            //     `next_admin_address`; `claim_admin` requires
            //     `equal_slices_bits(sender_address, next_admin_address)` and
            //     clears the slot. The baseline token-contract has a single
            //     unconfirmed write; the confirmation is the deliberate hardening.
            //
            //   getgems nft auction v4r1 `op::set_jetton_wallet`: the write is
            //     refused unless it arrives FROM the target
            //     (`throw_unless(403, equal_slices(sender_addr, jetton_wallet))`),
            //     and the contract sits in `is_broken_state` — refusing money —
            //     until it lands.
            //
            // So `SetNftCollection` no longer writes the live pointer at all. It
            // stages it, and `ConfirmNftCollection` promotes it only when the
            // message arrives FROM the staged address. A wrong address cannot
            // acknowledge, so it never becomes live, so `totalNames` never closes
            // the gate on it, so it stays re-stageable — an unrecoverable brick
            // becomes an ordinary retry.
            //
            // WHAT THIS DOES AND DOES NOT DEFEND. It defends against a fat-finger
            // or a stale address, which is the finding. It does NOT defend against
            // a HOSTILE admin, who can point at a contract they control and have
            // it acknowledge — which is why V7-18b's `totalNames == 0` gate above
            // stays exactly as it was. Two different threats, two guards, neither
            // replacing the other.
            //
            // RE-STAGING IS FREE while unconfirmed: nothing is live, so a second
            // `SetNftCollection` simply overwrites the staged value. That is the
            // operability win — the deploy step became retryable.
            var auxSC = st.auxData();
            auxSC.pendingNftCollection = msg.collection;
            st.aux = auxSC.toCell();
            saveStorage(st);
        }

        // R24-4b. EVERY STAGED FIELD GETS AN EXIT.
        //
        // `pendingSigner` has `CancelSigner`; `pendingAdmin` has
        // `CancelAdminTransfer`; `pendingNftCollection` shipped with nothing. That
        // is not merely an inconsistency — without it, a pointer staged and then
        // superseded by a registration is frozen non-null FOREVER (promotion needs
        // `totalNames == 0`, and so does re-staging), so `pendingNftCollection()`
        // permanently advertises an address that can never land. Inert, but this
        // contract's own R7-11 / V7-30 doctrine is that staged state must be
        // both readable and retractable.
        CancelNftCollection => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            var auxXC = st.auxData();
            assert(auxXC.pendingNftCollection != null) throw ERR_NO_PENDING_COLLECTION;
            auxXC.pendingNftCollection = null;
            st.aux = auxXC.toCell();
            saveStorage(st);
        }

        // R24-4. The collection promoting itself. See SetNftCollection above.
        //
        // No admin check by design, and that is safe: the ONLY sender this
        // handler accepts is the address the admin already staged, so the
        // authorisation happened at staging time. Making it permissionless-
        // to-relay is deliberate — it matches this contract's own house rule that
        // a staged change must not be strandable by a lost admin key (the same
        // reasoning as `ApplySigner`), and here the "relayer" is necessarily the
        // collection itself, which cannot be anyone else.
        //
        // R25-6 (LOW). THE HANDLER R24-6b's REFUND SWEEP MISSED, ONE SIBLING OVER.
        //
        // R24-6b re-applied the six-round rule — "every permissionless paid
        // handler refuses rather than confiscates" (R8-12, R10-1, R13-2, R14-2,
        // R14B1-1, R23-4) — to `CancelAuction`, which R24-6 had just made
        // permissionless. This handler was made permissionless in the SAME round,
        // by R24-4, and was not swept. Its R17-7 body-shape guard already refunds;
        // the two asserts underneath it did not.
        //
        // Measured, all non-bounceable (which is what real wallets send), all
        // returning 0 to the sender:
        //   nothing staged -> exit 481, registrar kept 0.9998 of 1 GRAM
        //   wrong sender   -> exit 411, registrar kept 0.9998 of 1 GRAM
        //
        // `ApplySigner`'s `ERR_NO_PENDING_SIGNER` is the direct precedent, and
        // R14B1-3 converted it for exactly this reason: a permissionless promotion
        // op is driven by keepers and by hand — `wrappers/EmojiNft.ts` documents
        // driving this very handshake manually — so a stale or mis-aimed relay is
        // the EXPECTED failure, not an attack, and the operator should not pay the
        // registrar for making it.
        //
        // `refundAndStop`'s precondition is met: NOTHING IS WRITTEN ABOVE EITHER
        // ARM. `st.auxData()` and `st.cfg()` are reads; `st.config`, `st.aux` and
        // `saveStorage` are all below the last assert, so an early return leaves
        // the staged pointer exactly as it was and the op stays retryable.
        //
        // NOTE — the `ERR_NAME_TAKEN` (V7-18b) arm below is left THROWING,
        // deliberately, on the same reasoning R14B1-3 gave for leaving
        // `ERR_TIMELOCK_ACTIVE` alone: by the time it can fire the sender has
        // already been proven to be the staged collection, so it is not a stranger
        // losing a race — it is the operator being told the registry went live
        // under a different pointer, which is a state the monitoring in
        // docs/V7_INCIDENT_RUNBOOK reads off the exit code.
        //
        // ===================================================================
        // THE COST OF THIS CONVERSION, MEASURED — AND CLOSED BY R25-6b.
        // ===================================================================
        // Refunding here starts the R17-36 RejectedRefund ping-pong with the NFT
        // collection, because the collection is the ONE sender that reaches these
        // arms as a CONTRACT rather than a wallet — `AnnounceMinter` relays
        // `ConfirmNftCollection` from the collection's own address. The collection
        // has an unknown-op refund arm of its own, so it answers our refund with
        // one of its own, and the `else` arm at the bottom of this file answered
        // that. Measured on the build that shipped R25-6 without its close,
        // `stage -> cancel -> announce`:
        //
        //   announce funded 0.05 ->  99 transactions    0.2 -> 389 transactions
        //   announce funded 0.10 -> 195 transactions    0.5 -> 969 transactions
        //
        // terminating at exit -14 once the fees had eaten the value, with the
        // operator's whole attached value consumed. THE 411 ARM LOOPED TOO and the
        // original costing missed it: with a decoy staged and the real collection
        // announcing, the sender is by definition NOT the staged pointer, measured
        // 388 transactions at 0.2 GRAM. The address-shaped guard is structurally
        // unable to cover this handler — on the 481 arm there is no pointer to
        // match, and the 411 arm only fires when the match has already failed.
        //
        // R25-6b takes the close in the `else` arm: an incoming `RejectedRefund`
        // (0x7e3a11c5) is itself the peer-loop predicate. Re-measured on this
        // build, same scenarios:
        //
        //   0.05 -> 5 txs   0.2 -> 5 txs   0.5 -> 5 txs   411 arm -> 5 txs
        //
        // and the value is no longer burned: it lands in THIS contract's free
        // balance (registrar +0.0485 / +0.1985 / +0.4985 respectively) where
        // `WithdrawFees` can recover it. That is strictly better than the `throw`
        // this conversion replaced, which bounced the value into the COLLECTION —
        // a contract with no withdrawal op of any kind, so the operator's retry
        // money was stranded there permanently.
        //
        // Pinned by audit/round25/R25_6_confirm_refunds.spec.ts, which asserts the
        // transaction count on BOTH arms so the exchange cannot grow unnoticed.
        ConfirmNftCollection => {
            if (in.body.remainingBitsCount() != BODY_OP_QUERYID) {
                refundAndStop(in.senderAddress, 0, ERR_BAD_BODY);
                return;
            }
            var auxCC = st.auxData();
            if (auxCC.pendingNftCollection == null) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_NO_PENDING_COLLECTION);
                return;
            }
            if (in.senderAddress != auxCC.pendingNftCollection!) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_NOT_COLLECTION);
                return;
            }
            // The V7-18b gate is re-checked HERE, not only at staging: staging is
            // now cheap and repeatable, so the moment that actually matters — the
            // one that closes the door on a live registry — is promotion.
            assert(st.cfg().nftCollection == null || st.totalNames == 0) throw ERR_NAME_TAKEN;
            var cCC = st.cfg();
            cCC.nftCollection = auxCC.pendingNftCollection;
            st.config = cCC.toCell();
            auxCC.pendingNftCollection = null;
            st.aux = auxCC.toCell();
            saveStorage(st);
        }

        AddResolver => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            val (rWc, accHash) = msg.resolver.getWorkchainAndHash();
            // R16-3. The fourth member of the basechain-payout family, and the one
            // that was missing. `syncAllResolvers` fans out with
            // PAY_FEES_SEPARATELY | IGNORE_ERRORS on the identical events as the
            // referrer payout (F-11) and payPartner (R7-17), both of which are
            // guarded for exactly this reason. A masterchain resolver's ~10-25x
            // forward fee comes out of the registrar's own float on every
            // registration, renewal, permanent upgrade, auction settlement and
            // OwnerSynced relay, while opsBudgetRegister reserves a flat
            // SYNC_VALUE per resolver from the buyer regardless.
            //
            // Admin-only, so this throws rather than refunds — same shape, same
            // error and same reasoning as SetPartner below. LAUNCH_READINESS says
            // AddResolver — NEVER, and preflight D-1 is a FAIL-severity check that
            // resolverCount() stayed 0; this is the guard for the day somebody
            // stops believing the runbook.
            assert(rWc == BASECHAIN) throw ERR_BAD_PARTNER_WC;
            // R17-21: the workchain of this exact argument was checked and its hash
            // was not. A zero-hash resolver is a live entry in the fan-out set that
            // burns SYNC_VALUE on every registration, renewal, permanent upgrade,
            // settlement and OwnerSynced relay into an account that can never
            // acknowledge any of it — and it counts against MAX_RESOLVERS. The hash
            // is already in hand from the line above, so the guard is free.
            assert(accHash != 0) throw ERR_ZERO_ADDRESS;
            var cAdd = st.cfg();
            // V7-16: bound the set. Re-adding an existing resolver is a no-op
            // update and must stay allowed, so only count it when it is new.
            if (!cAdd.resolvers.get(accHash).isFound) {
                assert(countResolvers(cAdd.resolvers) < MAX_RESOLVERS) throw ERR_TOO_MANY_RESOLVERS;
            }
            cAdd.resolvers.set(accHash, msg.resolver);
            st.config = cAdd.toCell();
            saveStorage(st);
        }

        RemoveResolver => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            val (_wc2, accHash2) = msg.resolver.getWorkchainAndHash();
            var cRem = st.cfg();
            cRem.resolvers.delete(accHash2);
            st.config = cRem.toCell();
            saveStorage(st);
        }

        SetFirstYearPrice => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            var c = st.cfg();
            var p = c.prices.load();
            // V7-20. Order matters for the error a caller sees. The lock and the
            // tier bound were both checked AFTER the price-bounds assert, which
            // itself used the unvalidated tier via priceBounds(). A locked
            // contract therefore reported 410 (price out of bounds) instead of
            // 447 (prices locked), and an out-of-range tier silently fell through
            // priceBounds() to the Common band. Validate the cheapest and most
            // specific conditions first.
            assert(!p.pricesLocked) throw ERR_PRICES_LOCKED;
            // tier 1 removed: singles never carry a first-year price.
            // 6 and 7 share the Common tier — either value writes p67.
            assert(msg.emojiTier >= 2 && msg.emojiTier <= MAX_EMOJI_COUNT) throw ERR_BAD_EMOJI_COUNT;
            val (floorP, ceilP) = priceBounds(msg.emojiTier);
            assert(msg.price >= floorP && msg.price <= ceilP) throw ERR_BAD_PRICE_BOUND;
            // (kept as its own assert so the two refusals stay distinguishable —
            // `tierPriceAcceptable` folds both for LockPrices, which only needs a
            // yes/no.)
            // R15-8. THE FIRST YEAR COULD BE PRICED BELOW THE RENEWAL IT PRECEDES.
            //
            // The [floor, ceiling] band and the RENEW_* table are independent, and
            // the bands reach below their tier's renewal price: tier 2's floor is
            // 5 GRAM against an IMMUTABLE 10 GRAM renewal, so `registerCost` for a
            // 1-year tier-2 name becomes 5 while renewing that same name for the
            // second year costs 10. Measured `invert(1y)=true`.
            //
            // That is not merely odd pricing — it inverts the product. A one-year
            // registration is cheaper than the renewal, so the rational holder lets
            // every name lapse and re-registers it, which turns the annuity the
            // whole revenue model rests on into a churn tax, and hands every
            // re-registration a front-running window. RENEW_* has no setter and
            // never will, so the tier's renewal price is the honest floor for its
            // first year.
            assert(msg.price >= renewYearPrice(msg.emojiTier)) throw ERR_PRICE_BELOW_RENEWAL;
            if (msg.emojiTier == 2) { p.p2 = msg.price; }
            else if (msg.emojiTier == 3) { p.p3 = msg.price; }
            else if (msg.emojiTier == 4) { p.p4 = msg.price; }
            else if (msg.emojiTier == 5) { p.p5 = msg.price; }
            else { p.p67 = msg.price; }
            c.prices = p.toCell();
            st.config = c.toCell();
            saveStorage(st);
        }

        SetFeeDestination => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            // R17-20. THE LAST UNGUARDED MEMBER OF THE BASECHAIN-PAYOUT FAMILY.
            //
            // F-11 (referrer), R7-17 (partner), R16-3 (resolver), R16V-1 (bidder)
            // and R9-5 (item newOwner) are all guarded; the one that receives ALL
            // the revenue was not. `WithdrawFees` sends here with NoBounce and
            // IGNORE_ERRORS, so every failure mode is silent by construction:
            //
            //   zero hash  — treasury paid to an unspendable account, forever.
            //   wc 5       — `exit 0, skipped=1, paid 0`. A scripted withdrawal
            //                reports success on every run while nothing moves;
            //                `freeBalance()` drops by the "withdrawn" amount
            //                only because it never left.
            //   a sibling  — 35.16 GRAM measured stranded in the collection, which
            //                has no op to send its own balance anywhere.
            //
            // `addr_none` was already refused (exit 9, serialization). These three
            // close the rest. The sibling check is deliberately narrow — this
            // contract and the collection it is wired to — because those are the
            // two addresses an operator has in front of them while copying values
            // between deploy configs, and neither can spend an incoming balance.
            val (fdWc, fdHash) = msg.feeDestination.getWorkchainAndHash();
            assert(fdHash != 0) throw ERR_ZERO_ADDRESS;
            assert(fdWc == BASECHAIN) throw ERR_BAD_PARTNER_WC;
            assert(msg.feeDestination != contract.getAddress()) throw ERR_SELF_REFERENCE;
            val cFd = st.cfg();
            if (cFd.nftCollection != null) {
                assert(msg.feeDestination != cFd.nftCollection!) throw ERR_SELF_REFERENCE;
            }
            var c = st.cfg();
            c.feeDestination = msg.feeDestination;
            st.config = c.toCell();
            saveStorage(st);
        }

        SetCommitTiming => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            assert(msg.minDelay >= COMMIT_MIN_DELAY_FLOOR && msg.minDelay <= COMMIT_MIN_DELAY_CEIL) throw ERR_BAD_COMMIT_TIMING;
            assert(msg.maxAge >= COMMIT_MAX_AGE_FLOOR && msg.maxAge <= COMMIT_MAX_AGE_CEIL) throw ERR_BAD_COMMIT_TIMING;
            assert(msg.maxAge > msg.minDelay) throw ERR_BAD_COMMIT_TIMING;
            // R17-25. EACH FIELD WAS BOUNDED; THE WINDOW THEY DERIVE WAS NOT.
            //
            // `maxAge > minDelay` admits (3599, 3600): both ends are inclusive on
            // chain, so every commitment then gets a TWO-SECOND reveal window and
            // registration becomes impossible for everyone, instantly and without
            // a timelock. The genesis config has the same shape (R17-12 measured
            // `minDelay=86400 > maxAge=3600` deploying happily).
            //
            // 900 seconds refuses nothing legitimate: the shipping config is
            // (60, 3600) for a 3,540-second window, and the tightest sensible
            // anti-front-running setting — the 3600-second minDelay ceiling — still
            // leaves a 3-hour window inside the 604,800-second maxAge ceiling.
            assert(msg.maxAge - msg.minDelay >= COMMIT_WINDOW_MIN) throw ERR_BAD_COMMIT_TIMING;
            var c = st.cfg();
            c.commitMinDelay = msg.minDelay;
            c.commitMaxAge = msg.maxAge;
            st.config = c.toCell();
            saveStorage(st);
        }

        // Step 1 of ownership handover: current admin NOMINATES a successor.
        // Nothing changes yet — control only moves when the successor accepts.
        // A wrong/dead address here is harmless: it can never accept.
        InitiateAdminTransfer => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            // refuse an addr_none (0,0) to avoid a nonsensical pending state
            val (naWc, naHash) = msg.newAdmin.getWorkchainAndHash();
            assert(naHash != 0) throw ERR_ZERO_ADDRESS;
            // R17-21: this handler was the mirror image of the rest of the family —
            // the hash was checked and the workchain was not. The harm is milder
            // than the payout cases (nothing pays the admin, and the successor must
            // ACTIVELY accept, so a wrong workchain fails safe as a nomination that
            // never completes rather than as lost money). It is here for the same
            // reason the others are: one convention, no exceptions to remember.
            // Genesis admin is deliberately still unconstrained — an operator who
            // wants a masterchain admin can deploy with one; they just cannot hand
            // the contract to an address it could never hear back from.
            assert(naWc == BASECHAIN) throw ERR_BAD_PARTNER_WC;
            st.pendingAdmin = msg.newAdmin;
            st.pendingAdminAt = nowTime as uint32;
            saveStorage(st);
        }

        // Step 2: the SUCCESSOR accepts from their own address after the timelock.
        // Two-step + timelock: a wrong address can't be transferred to (must
        // actively accept), and a stolen key can't instantly seize control
        // (timelock gives a cancel window).
        AcceptAdminTransfer => {
            assert(st.pendingAdmin != null) throw ERR_NO_PENDING_ADMIN;
            assert(in.senderAddress == st.pendingAdmin!) throw ERR_NOT_PENDING_ADMIN;
            // Gate on the timelock actually in force — a matured decrease counts,
            // exactly as applyPendingTimelock computed before — but do NOT persist
            // that decrease onto the successor (see R9-6 below). NOT applyPendingTimelock,
            // whose mutation must not land here — effectiveTimelock is the pure reader.
            // R15 cleanup: this and UpdateSigner above both open-coded that reader.
            val effLock = effectiveTimelock(st, nowTime);
            assert(nowTime >= (st.pendingAdminAt as int) + effLock) throw ERR_TIMELOCK_ACTIVE;
            st.admin = st.pendingAdmin!;
            st.pendingAdmin = null;
            st.pendingAdminAt = 0;
            // R9-6: THE SUCCESSOR INHERITS NOTHING UNAPPROVED — the registrar's own
            // half of the R7-12 / R8-6 / R9-5 pattern, which the collection and
            // resolver already run on THEIR AcceptAdmin but which was never
            // back-fitted to the contract that originated it.
            //
            // Two staged slots outlived this handover:
            //   pendingSigner  — a departing admin stages UpdateSigner(theirKey),
            //     transfers admin, and the permissionless ApplySigner (fireable by
            //     ANYONE the instant it matures — which is arranged to be the accept
            //     moment) installs their signer key under the new admin. That breaks
            //     all issuance and hands the departed party the attestation key —
            //     precisely the admin/signer-compromise coupling V7-30 exists to
            //     prevent. (HIGH.)
            //   pendingTimelock — a staged decrease to 0 matures at the accept and,
            //     via the old applyPendingTimelock at the top, silently gave the
            //     successor a 0-second anti-theft window they never chose. (MEDIUM.)
            //
            // Clearing both here makes the rule the same one line the siblings
            // state: only the sitting admin's own staged changes can complete. A
            // genuinely coordinated handover just re-stages after accepting.
            st.pendingTimelock = 0;
            st.pendingTimelockAt = 0;
            // R14B1-9. R9-6 CLEARED THE STAGED DECREASE AND COULD NOT SEE A LANDED ONE.
            //
            // The two lines above are R9-6's fix and they are correct as far as
            // they reach: a decrease still sitting in `pendingTimelock` dies with
            // the handover. But a decrease that has ALREADY MATURED is no longer
            // staged — it is `st.adminTimelock` itself, and R9-6 has nothing to
            // look at. `ADMIN_TIMELOCK_FLOOR` is 0, so the value it can have landed
            // on is 0.
            //
            // Measured, end to end, with the predecessor persisting
            // `adminTimelock = 0` and the successor accepting in the SAME second:
            // the successor inherited 0. And at 0 the entire staged layer
            // evaporates — this is V7-30's collapse from the other side:
            //
            //     UpdateSigner(attackerKey)  ->  pendingSignerAt = now + 0
            //     ApplySigner                ->  matured already; permissionless
            //
            // both landing in ONE BLOCK, so a stolen successor key takes the
            // attestation key in two messages with zero elapsed time and no window
            // for anyone to notice. The `AcceptAdminTransfer` timelock itself is
            // equally gone: nominate and accept in the same second.
            //
            // The successor never agreed to a 0-second anti-theft window; they
            // agreed to become admin. R9-6's own sentence — "the successor
            // inherits nothing unapproved" — has to cover the value as well as the
            // staging slot, so the accept RESETS rather than inherits. Raising is
            // immediate (`SetAdminTimelock`), so a successor who genuinely wants a
            // longer window has it in one message, and one who genuinely wants an
            // expedited sale takes the documented 48h wait to lower it — which is
            // exactly the protection they are giving up.
            //
            // After this line the seizure attempt above returns 420.
            st.adminTimelock = DEFAULT_ADMIN_TIMELOCK;
            var auxAcc = st.auxData();
            auxAcc.pendingSigner = 0;
            auxAcc.pendingSignerAt = 0;
            st.aux = auxAcc.toCell();
            saveStorage(st);
        }

        // Current admin aborts a pending transfer (e.g. spotted a stolen-key
        // takeover attempt, or the sale fell through).
        CancelAdminTransfer => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            st.pendingAdmin = null;
            st.pendingAdminAt = 0;
            saveStorage(st);
        }

        // Adjust the anti-theft timelock within bounds. Lower it for a planned
        // live sale; keep it high for normal operation.
        SetAdminTimelock => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            assert(msg.timelock >= ADMIN_TIMELOCK_FLOOR && msg.timelock <= ADMIN_TIMELOCK_CEIL) throw ERR_BAD_ADMIN_TIMELOCK;
            // R17-11 (MEDIUM). THE TOB-MSIG-1 SHAPE: BOUNDED SETTER, UNBOUNDED
            // CONSTRUCTOR — AND THE REPAIR OP DIED INSIDE ITS OWN ARITHMETIC.
            //
            // The line above bounds what an admin may WRITE. Nothing bounded what
            // genesis could INSTALL, and this handler then READS the stored value
            // twice: once to decide raise-vs-lower, and once in
            // `nowTime + st.adminTimelock`, which is stored into a uint32.
            //
            //     genesis 4,000,000,000 -> SetAdminTimelock(48h) is exit 5,
            //                              changed=false, admin rotation bricked
            //     genesis 2,000,000,000 -> the decrease lands in 63.4 years
            //
            // Exit 5 is uncatalogued and tells the operator nothing. Refusing here
            // turns it into 421 with the offending value still readable through
            // `adminTimelock()`, and the deploy wrapper now refuses to write one
            // (see registrarV2StorageCell) — so this is the second line of defence
            // for a contract deployed by something other than the shipped wrapper.
            // It refuses nothing a compliant deployment can produce.
            assert((st.adminTimelock as int) <= ADMIN_TIMELOCK_CEIL) throw ERR_BAD_ADMIN_TIMELOCK;
            // V7-19  refused a change while a transfer was pending. V7-19b: that
            // closed only ONE ordering. A stolen key simply does it the other way
            // round — SetAdminTimelock(0) first, while nothing is pending so the
            // guard never fires, THEN nominate, THEN accept — and the cancel
            // window is zero again. Proven empirically at 0 elapsed seconds.
            //
            // The durable fix is that RAISING the timelock is safe and immediate,
            // but LOWERING it is itself subject to the timelock currently in
            // force. A thief can still lower it — they just cannot benefit for
            // `adminTimelock` seconds, which is exactly the window the honest
            // operator needs to notice and cancel.
            applyPendingTimelock(mutate st, nowTime);
            assert(st.pendingAdmin == null) throw ERR_TIMELOCK_ACTIVE;
            if (msg.timelock >= (st.adminTimelock as int)) {
                st.adminTimelock = msg.timelock;          // raising: immediate
                st.pendingTimelock = 0;
                st.pendingTimelockAt = 0;
            } else {
                st.pendingTimelock = msg.timelock;        // lowering: staged
                st.pendingTimelockAt = (nowTime + (st.adminTimelock as int)) as uint32;
            }
            saveStorage(st);
        }

        SetReferralBps => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            assert(msg.referralBps <= REFERRAL_BPS_CEIL) throw ERR_BAD_REFERRAL_BPS;
            var c = st.cfg();
            c.referralBps = msg.referralBps;
            st.config = c.toCell();
            saveStorage(st);
        }

        // ONE-WAY upgrade. Only the owner, only a single-emoji name, only once.
        // Restricted to singles deliberately: the 2-5 emoji tiers carry the
        // recurring-revenue annuity and are not for sale in perpetuity.
        MakePermanent => {
            // R17-7: R10-1 converted every guard below to a refund because this op
            // carries ~1,000 GRAM. A body one bit short reached none of them.
            if (in.body.remainingBitsCount() != BODY_OP_QUERYID_HASH) {
                refundAndStop(in.senderAddress, 0, ERR_BAD_BODY);
                return;
            }
            // R10-1. THE LARGEST SINGLE PAYMENT IN THE CONTRACT, WITH NO REFUND PATH.
            //
            // R8-12 established the rule: on TON a `throw` refunds ONLY if the sender
            // marked the message bounceable, and OpenMask was verified live sending
            // non-bounceable to an EQ address. R8-12 applied refundAndStop to Reveal
            // and PlaceBid and stopped there — so all SIX guards here still threw,
            // on the one op that carries ~1,000 GRAM. Measured: 1000.1136 GRAM kept
            // by the contract, 0 returned, on every one of them.
            //
            // Every guard below is BEFORE any state write, which is exactly the
            // precondition refundAndStop documents, so the conversion is mechanical.
            val found = st.names.get(msg.nameHash);
            if (!found.isFound) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_NAME_NOT_FOUND);
                return;
            }
            var rec = found.loadValue();
            if (in.senderAddress != rec.owner) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_NOT_NAME_OWNER);
                return;
            }
            if (rec.emojiCount != 1) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_PERMANENT_SINGLES_ONLY);
                return;
            }
            if (rec.isPermanent) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_ALREADY_PERMANENT);
                return;
            }
            // a lapsed name cannot be bought into permanence
            if (nowTime >= (rec.expiresAt + GRACE)) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_NAME_EXPIRED);
                return;
            }

            val cfgP = st.cfg();
            val price = cfgP.prices.load().permanentPrice as int;
            // V7-10: MakePermanent calls payPartner, so it must reserve the
            // partner forwarding fees exactly as opsBudgetRegister and RenewName
            // do. F-7 fixed this for renewals and missed the identical omission
            // here, leaving the shortfall to come out of contract balance.
            var opsP = 20000000 + MAX_PARTNERS * 2000000
                     + countResolvers(cfgP.resolvers) * SYNC_VALUE;   // F-6
            if (cfgP.nftCollection != null) { opsP += EXPIRY_VALUE; }
            val paid = in.valueCoins as int;
            if (paid < price + opsP) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_INSUFFICIENT_PAYMENT);
                return;
            }

            // partner shares this like any other revenue; there is no referrer
            // on an upgrade — the name was already sold.
            val partnerCutP = partnerCutOf(cfgP, price);

            rec.isPermanent = true;
            rec.expiresAt = PERMANENT_EXPIRY as uint32;
            st.names.set(msg.nameHash, rec);
            st.totalRevenue = (st.totalRevenue + (price - partnerCutP)) as uint128;
            saveStorage(st);

            // push the far-future expiry to the item. PERMANENT_EXPIRY is uint32
            // max, so this always satisfies the item's extend-only guard.
            if (cfgP.nftCollection != null) {
                createMessage({
                    bounce: BounceMode.NoBounce,
                    value: EXPIRY_VALUE as coins,
                    dest: cfgP.nftCollection!,
                    body: UpdateExpiryReqFwd {
                        queryId: msg.queryId,
                        nameHash: msg.nameHash,
                        newExpiresAt: PERMANENT_EXPIRY as uint32,
                        syncNonce: rec.syncNonce,           // R16-2
                    }
                // R17-35: see sendMint. This is the ~1,000 GRAM op; an absorbed
                // action failure here is the largest single silent loss available.
                }).send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
            }

            // F-6: a permanent name must never lapse at the resolver either.
            // R9-6: use the AUTHORITATIVE owner+term sync, not the term-only push —
            // the exact R8-7 fix RenewName already carries. A term-only
            // UpdateNameExpiry arriving a hop later, past expiresAt+GRACE (an owner
            // may MakePermanent in the final second of grace), hits the resolver's
            // R8-2 drop and DELETES the entry — and because the name is now
            // permanent it can never be re-registered, so the auto-heal never fires
            // and the owner is locked out of SetRecord (404) until a manual
            // ResyncOwner. syncAllResolvers re-establishes the binding instead, and
            // preserves the holder's records because the owner is unchanged (V7-14).
            // It also backfills any resolver added after registration.
            syncAllResolvers(cfgP.resolvers, msg.queryId, msg.nameHash, rec.owner, PERMANENT_EXPIRY);

            payPartner(cfgP, price);
            refundExcess(in.senderAddress, paid - opsP - partnerCutP, price - partnerCutP);
        }

        LockPrices => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            var cLP = st.cfg();
            var pLP = cLP.prices.load();
            // R17-26's sibling: refuse to freeze prices a setter would refuse to
            // write. See `pricesAreLockable`. This is the last moment the contract
            // can act on a nonsense genesis price table; after this line there is
            // no op, and no SETCODE, that can ever change one again.
            assert(pricesAreLockable(pLP)) throw ERR_BAD_PRICE_BOUND;
            pLP.pricesLocked = true;      // nothing anywhere sets this false
            cLP.prices = pLP.toCell();
            st.config = cLP.toCell();
            saveStorage(st);
        }

        SetPermanentPrice => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            assert(msg.price >= PERMANENT_PRICE_FLOOR && msg.price <= PERMANENT_PRICE_CEIL)
                throw ERR_BAD_PERMANENT_PRICE;
            var cSP = st.cfg();
            var pSP = cSP.prices.load();
            assert(!pSP.pricesLocked) throw ERR_PRICES_LOCKED;
            pSP.permanentPrice = msg.price;
            cSP.prices = pSP.toCell();
            st.config = cSP.toCell();
            saveStorage(st);
        }
        SetPartner => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            var cPa = st.cfg();
            var ppa = cPa.prices.load();
            val (pWc, pHash) = msg.partner.getWorkchainAndHash();
            // R7-17. THE F-11 RULE, APPLIED TO THE OTHER PAYOUT.
            //
            // F-11 blocks a non-basechain REFERRER because payouts use
            // PAY_FEES_SEPARATELY — the contract covers the forward fee — and a
            // masterchain destination costs roughly 25x a basechain one.
            //
            // `payPartner` has the identical send mode, fires on the identical
            // events, and had no such check. The budget reserves
            // MAX_PARTNERS * 0.002 GRAM per sale (opsBudgetRegister); a single
            // masterchain forward alone exceeds that, so four of them overdraw
            // the reserve on EVERY registration, renewal, permanent upgrade and
            // auction settlement — paid out of contract balance, silently,
            // because the send is also IGNORE_ERRORS.
            //
            // A partner address is admin-set rather than attacker-supplied, which
            // makes this a footgun rather than an exploit. It is still worth
            // refusing: the failure mode is a slow bleed that shows up as an
            // unexplained balance drift, not as an error anyone would notice.
            //
            // R17-20 UPDATE: `feeDestination` used to be the deliberate exception
            // here, on the argument that WithdrawFees sends with IGNORE_ERRORS
            // only, so the forward fee is the admin's own cost. That reasoning
            // held for the FEE and missed the DELIVERY: measured at workchain 5
            // the withdrawal is `exit 0, skipped=1, paid 0` — a scripted payout
            // that reports success forever while nothing moves. It is guarded now;
            // see SetFeeDestination.
            assert(pWc == BASECHAIN) throw ERR_BAD_PARTNER_WC;
            // R17-21: measured `SetPartner(0:0…0, 30%)` — the buyer is charged the
            // cut, `actionOk true skipped 0`, and the payout lands on an
            // unspendable account. A zero partner also consumes one of the four
            // MAX_PARTNERS slots and 30 of the 30 combined bps. `bps == 0` removes
            // a partner, but nothing legitimate can ever have been stored under the
            // zero hash, so refusing outright is simpler than special-casing it.
            assert(pHash != 0) throw ERR_ZERO_ADDRESS;

            // combined ceiling, counting this entry's replacement not its addition
            var others = 0;
            var n = 0;
            var e = ppa.partners.findFirst();
            while (e.isFound) {
                if (e.getKey() != pHash) { others += e.loadValue().bps as int; n += 1; }
                e = ppa.partners.iterateNext(e);
            }
            assert(others + msg.bps <= PARTNER_BPS_CEIL) throw ERR_BAD_PARTNER_BPS;
            assert(n < MAX_PARTNERS) throw ERR_TOO_MANY_PARTNERS;

            if (msg.bps == 0) {
                ppa.partners.delete(pHash);          // 0 bps removes
            } else {
                ppa.partners.set(pHash, { addr: msg.partner, bps: msg.bps });
            }
            cPa.prices = ppa.toCell();
            st.config = cPa.toCell();
            saveStorage(st);
        }

        RemovePartner => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            var cRp = st.cfg();
            var prp = cRp.prices.load();
            val (_wc2, rHash) = msg.partner.getWorkchainAndHash();
            assert(prp.partners.get(rHash).isFound) throw ERR_PARTNER_NOT_FOUND;
            prp.partners.delete(rHash);
            cRp.prices = prp.toCell();
            st.config = cRp.toCell();
            saveStorage(st);
        }

        SetReferrerRate => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            assert(msg.bps <= REFERRAL_KOL_BPS_CEIL) throw ERR_BAD_KOL_BPS;
            val (_wc, refHash) = msg.referrer.getWorkchainAndHash();
            // R17-21: a KOL override keyed on the zero hash pays up to 33% of every
            // fee to an unspendable account, and the referrer hash is what a buyer
            // supplies in the reveal — so it is the one member of this family a
            // NON-admin can aim at. F-11 already ignores a masterchain referrer at
            // read time; the zero hash was neither ignored nor refused.
            assert(refHash != 0) throw ERR_ZERO_ADDRESS;
            var c = st.cfg();
            c.referrerRates.set(refHash, msg.bps);
            st.config = c.toCell();
            saveStorage(st);
        }

        RemoveReferrerRate => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            val (_wc, refHash) = msg.referrer.getWorkchainAndHash();
            var c = st.cfg();
            c.referrerRates.delete(refHash);
            st.config = c.toCell();
            saveStorage(st);
        }

        // ---- AUCTION: start a curated drop lot (admin) ----
        StartAuction => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            // R25-7 (LOW). THE THIRD ADMIN ISSUANCE DOOR, AND THE ONE R10-2 MISSED.
            //
            // R10-2 put `ops + ADMIN_COMPUTE_BUDGET` on `AdminMint` and
            // `AdminImport` because it MEASURED them dying at exit -14 inside
            // `assertCanonicalName` (~3,215 gas/byte) when the incoming value —
            // which is what buys the compute-phase gas ceiling on TON — was too
            // small to reach the guard meant to reject them. `StartAuction` runs
            // the identical walk on the identical bytes and shipped with no
            // `valueCoins` floor at all.
            //
            // Measured at the legacy (pre-2026-04-29, 400 nanoton/gas) row with
            // the longest legal 7-unit label:
            //   0.10 / 0.15 / 0.20 GRAM -> exit -14, VALUE BURNED, NO LOT CREATED
            //   0.25 GRAM               -> exit 0 at 608,740 gas
            // A scripted singles drop funded from the old habit therefore creates
            // ZERO listings and reports nothing an operator can act on, because
            // -14 is a phase failure with no error code and no refund message.
            //
            // PLACEMENT IS THE WHOLE FIX, exactly as R10-2 argues: this sits
            // immediately after the admin check and BEFORE the name walk. Nothing
            // between them touches the name, so it moves up freely, and an
            // under-funded listing becomes a cheap, legible 406 instead of a burn.
            //
            // `ADMIN_COMPUTE_BUDGET` alone, NOT `ops + ADMIN_COMPUTE_BUDGET`:
            // unlike the two mint doors this handler emits no mint, no resolver
            // sync and no partner payout — issuance happens later, in
            // `SettleAuction`, out of the winner's escrow. The floor covers the
            // one thing this op actually spends, its own compute: 0.3 GRAM buys
            // 750,000 gas at the legacy 400 nanoton/gas row.
            //
            // R25-7b. THE MARGIN THIS PARAGRAPH FIRST CLAIMED WAS MEASURED ON A
            // NAME THAT IS NOT THE WORST ONE — the same class of error R14B1-15
            // and R23 both had to correct on `REGISTER_COMPUTE_PER_BYTE`. It read
            // "608,841 at its worst name — a 1.23x margin", and 608,841 is the
            // 100-byte / 7-unit label the pin happens to use. `MAX_EMOJI_COUNT`
            // is 7 but `MAX_NAME_BYTES` is 110, and gas here is driven by BYTES,
            // not units: three tag-sequence flags plus one 4-person ZWJ family is
            // 109 bytes in 4 units and is the byte-heaviest label the normalizer
            // accepts. Re-measured on this build at the legacy row, with the full
            // 3-cell percent-encoded suffix that name forces:
            //
            //   100 B / 7 units   608,841 gas   1.232x
            //   109 B / 4 units   661,291 gas   1.134x   <- the real worst case
            //
            // ~5,830 gas per additional byte, so the unreachable 110th byte is
            // ~667,100 and the floor still holds. THE FLOOR IS SUFFICIENT; the
            // margin is 1.13x, not 1.23x, and 88,709 gas (0.0355 GRAM) of
            // headroom is what a future field added to this handler is spending.
            //
            // At the live 66.667 row the same 0.3 buys 4.5M, so value stops being
            // the binding constraint entirely and basechain's 1,000,000
            // `gas_limit` becomes it, which the worst name still fits inside.
            // Pinned by audit/round25/R25_7_startauction_floor.spec.ts, which also
            // asserts the refusal costs 4,987 gas rather than 661,291 — that
            // number IS the fix, because a floor behind the walk buys nothing.
            //
            // Admin-only, so this THROWS rather than refunds — the house rule that
            // `SetPartner` / `AddResolver` / the two mint doors already follow, and
            // the same rule that keeps `CancelAuction`'s admin arm throwing while
            // its permissionless arms refund.
            assert(in.valueCoins >= ADMIN_COMPUTE_BUDGET) throw ERR_INSUFFICIENT_PAYMENT;
            assert(msg.numYears >= 1 && msg.numYears <= MAX_YEARS) throw ERR_BAD_YEARS;
            // V7-8: AdminMint and AdminImport both assert this; StartAuction was
            // the only issuance path without a lower bound. A lot settled with
            // emojiCount 0 wrote tier 0 into the registry and onto the NFT —
            // renewable at the CHEAPEST tier (RENEW_6_7 falls through), rendered
            // as no tier at all by marketplaces, and permanently ineligible for
            // MakePermanent, which requires emojiCount == 1.
            assert(msg.emojiCount >= 1) throw ERR_BAD_EMOJI_COUNT;
            assert(msg.emojiCount <= MAX_EMOJI_COUNT) throw ERR_TOO_MANY_EMOJI;
            assert(msg.duration >= AUCTION_MIN_DURATION && msg.duration <= AUCTION_MAX_DURATION)
                throw ERR_BAD_AUCTION_DURATION;
            assert(msg.startBid >= MIN_AUCTION_START_BID) throw ERR_BID_TOO_LOW;

            val cfgA = st.cfg();
            assert(nowTime <= msg.sigValidUntil) throw ERR_SIG_EXPIRED;
            // R14B1-16: bounded ABOVE too — see MAX_SIG_WINDOW. Admin paths throw
            // rather than refund: the admin's own signer produced the window.
            assert(msg.sigValidUntil <= nowTime + MAX_SIG_WINDOW) throw ERR_SIG_EXPIRED;
            val hA = attestationHash(msg.nameHash, msg.emojiCount, msg.content.hash(), msg.sigValidUntil,
                                     cfgA.prices.load().normalizationPolicyHash, ATT_PURPOSE_START_AUCTION,
                                     in.senderAddress);  // R24-1: the admin, asserted above
            assert(isSignatureValid(hA, msg.signature.load().sig as slice, cfgA.signerPublicKey))
                throw ERR_BAD_SIGNATURE;
            assertCanonicalName(msg.rawName, msg.nameHash, msg.emojiCount);
            assertUriSuffix(msg.content, msg.rawName);

            assertAvailableForIssue(st, msg.nameHash, nowTime);
            st.auctions.set(msg.nameHash, {
                listedAt: nowTime as uint32,   // R24-6
                highBidder: null,
                highBid: msg.startBid,
                startBid: msg.startBid,
                duration: msg.duration,
                // F-4: the clock does NOT run yet. A lot with no interest never
                // silently expires; every lot gets a FULL competitive window
                // beginning at its first bid (TON DNS / Fragment convention).
                endsAt: 0,
                numYears: msg.numYears,
                emojiCount: msg.emojiCount,
                content: msg.content,
                // R20-7: `assertCanonicalName` two lines up has already bound
                // these bytes to `nameHash`, so the permissionless settle can
                // mint the name it was told about without being handed one.
                label: msg.rawName,
            });
            // R24-5c. STARTAUCTION IS ISSUANCE, SO IT TAKES THE BUDGET GUARD TOO.
            //
            // The cell guard deliberately does NOT bind `AdminMint` or
            // `AdminImport`: those are the recovery and migration doors, and a
            // capacity bound that can block repair is worse than the capacity
            // problem it prevents. `StartAuction` is neither — it is an issuance
            // path that adds a lot, so it belongs on the guarded side of that
            // line. Admin-only, so it throws rather than refunds, matching
            // `SetPartner` and `AddResolver`.
            //
            // R25-1 NOTE: a lot is SIX cells, not the two this sentence used to
            // say, and `hasStateHeadroom` asks for room for one more NAME (2) —
            // so at the very edge this admits a lot with only 2 cells of the
            // estimate's headroom left. Deliberately not tightened to
            // `CELLS_PER_LOT`: `STATE_CELL_CEILING` already refuses 4,096 cells
            // below config 43's wall, a 4-cell overshoot is 0.1% of that reserve,
            // and making the ADMIN's issuance door stricter than the public one
            // is the wrong direction for a bound whose whole doctrine is that it
            // must never block recovery. `SettleAuction` converts a lot into a
            // name and is NET -4 cells, so the population shrinks on its own.
            assert(hasStateHeadroom(st)) throw ERR_STATE_BUDGET;
            // R17-6: one of the four writers of `liveLots`. `assertAvailableForIssue`
            // one line above throws 428 if a lot already exists under this hash, so
            // this `set` is always an INSERT and the increment can never double-count.
            // A new lot carries no bid (`highBidder: null`), so `escrowedTotal` is
            // unchanged — the escrow ledger tracks money actually received, and the
            // start bid is a floor, not a payment.
            st.liveLots += 1;
            saveStorage(st);
        }

        // ---- AUCTION: bid (English, +5% min raise, 1h anti-snipe) ----
        PlaceBid => {
            // R17-7: a bid is the largest single payment in the system (>= 150 GRAM)
            // and this arm is reached by strangers' wallets. Shape first — even
            // before R16V-1's workchain guard, which reads `msg.queryId`.
            if (in.body.remainingBitsCount() != BODY_OP_QUERYID_HASH) {
                refundAndStop(in.senderAddress, 0, ERR_BAD_BODY);
                return;
            }
            // R16V-1. THE OUTBID REFUND IS A `PAY_FEES_SEPARATELY` PAYOUT TO AN
            // ADDRESS THE COUNTERPARTY CHOOSES, AND IT HAD NO WORKCHAIN GUARD.
            //
            // F-11 (referrer) and R7-17 (partner, the assert ~200 lines below)
            // established the rule: any payout the CONTRACT covers the forward fee
            // for must be basechain-only, because a masterchain destination costs
            // ~10-25x. Both auction escrow releases — the outbid refund in this
            // handler and the policy-abort refund in SettleAuction — send with
            // PAY_FEES_SEPARATELY to `auc.highBidder`, which is simply whoever
            // bid. Neither was guarded.
            //
            // Measured on a live node: 0.012059031 GRAM per outbid cycle to a
            // basechain leader vs 0.021059044 to a masterchain one. At mainnet
            // forward prices that ratio is ~3.0x, and AUCTION_OPS_RESERVE (0.5
            // GRAM/lot) was sized as "~100 outbid cycles" against the BASECHAIN
            // figure — masterchain buys ~35. The reserve is one shared pool across
            // lots, so a single masterchain participant in one lot drains the
            // headroom the others depend on.
            //
            // Guarding the BID, not the two sends, is both cheaper and stricter:
            // it keeps the invariant "an accepted bid is always refundable at
            // basechain cost", so R16-1's clamp never has to absorb this. Fixing
            // only the sends would break F-3, which exists so that being outbid
            // costs the bidder nothing.
            //
            // refundAndStop, not throw: PlaceBid is a permissionless PAID path and
            // a bid is the largest single payment in the system, so R8-12/R10-1
            // apply — the money goes back even from a bounce-stripping wallet.
            // First guard in the handler, so this costs a masterchain bidder one
            // dict read less than any other refusal (R10-2).
            val (bidWc, _bidHash) = in.senderAddress.getWorkchainAndHash();
            if (bidWc != BASECHAIN) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_BAD_PARTNER_WC);
                return;
            }
            // R8-12: a bid is the largest single payment in the system (>= 150
            // GRAM). Losing one to a race with another bidder, because the wallet
            // stripped the bounce flag, is the worst outcome in the contract.
            val found = st.auctions.get(msg.nameHash);
            if (!found.isFound) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_NO_AUCTION);
                return;
            }
            var auc = found.loadValue();
            // an unstarted lot (endsAt == 0) is always open; a started one must be live
            if (auc.endsAt != 0 && nowTime >= auc.endsAt) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_AUCTION_ENDED);
                return;
            }

            val bid = in.valueCoins as int;
            val prevHigh = auc.highBid as int;
            // first bid must meet the start bid; later bids must beat the high by +5%
            val required = (auc.highBidder == null)
                ? prevHigh
                : prevHigh + (prevHigh * MIN_RAISE_BPS / BPS_DENOM);
            if (bid < required) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_BID_TOO_LOW);
                return;
            }

            // Refund the outbid leader.
            // F-1: clamp to what we can actually pay while keeping a storage
            //      reserve, exactly as TON DNS does — never let a refund push the
            //      contract below its rent floor or fail outright.
            // F-2: carry an opcode so the bidder's wallet can label the payment.
            // F-3: PAY_FEES_SEPARATELY so the outbid bidder is made WHOLE — being
            //      outbid should not cost them the forwarding fee.
            if (auc.highBidder != null && prevHigh >= BID_REFUND_DUST) {
                val spare = (contract.getOriginalBalance() as int) - MIN_STORAGE;
                val refundAmount = (prevHigh > spare) ? spare : prevHigh;
                if (refundAmount > 0) {
                    createMessage({
                        bounce: BounceMode.NoBounce,
                        value: refundAmount as coins,
                        dest: auc.highBidder!,
                        body: OutbidNotification { queryId: msg.queryId },
                    }).send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_IGNORE_ERRORS);
                }
            }

            // R17-6: the escrow ledger moves by exactly what the deleted walk would
            // have seen one instruction later — the new leader's full bid replaces
            // the outbid leader's contribution, and a lot that had never been bid on
            // contributed nothing. Deliberately keyed on the OWED amount (`prevHigh`)
            // and not on what the refund above actually sent: F-1's clamp can pay the
            // outbid leader less than they are owed on a short float, and the walk
            // this replaces did not know about that either. Matching the walk to the
            // nanoton is the invariant; matching the payout is R17-13's problem.
            st.escrowedTotal = ((st.escrowedTotal as int) + bid
                                - ((auc.highBidder == null) ? 0 : prevHigh)) as uint64;

            auc.highBidder = in.senderAddress;
            auc.highBid = bid as coins;
            if (auc.endsAt == 0) {
                // F-4: FIRST BID starts the competitive window (36h standard)
                auc.endsAt = (nowTime + auc.duration) as uint32;
            }
            // SOFT CLOSE: every bid guarantees >= BID_EXTENSION more. Early bids
            // change nothing (the base window is already further out); any bid in
            // the final hour pushes the close to exactly one hour from now. The
            // lot ends only after a full quiet hour.
            val floor = nowTime + BID_EXTENSION;
            if (floor > (auc.endsAt as int)) {
                auc.endsAt = floor as uint32;
            }
            st.auctions.set(msg.nameHash, auc);
            saveStorage(st);
        }

        // ---- AUCTION: settle (permissionless once ended) ----
        SettleAuction => {
            // R17-7: settle is permissionless and is the op a bot drives, so a
            // stale-struct bot is the realistic sender of a short body here.
            if (in.body.remainingBitsCount() != BODY_OP_QUERYID_HASH) {
                refundAndStop(in.senderAddress, 0, ERR_BAD_BODY);
                return;
            }
            // R10-1: settle is PERMISSIONLESS, so racing settlers are expected —
            // the loser's message arrives after the lot is gone. Refund rather than
            // throw, same R8-12 rule. All guards precede every state write.
            val found = st.auctions.get(msg.nameHash);
            if (!found.isFound) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_NO_AUCTION);
                return;
            }
            val auc = found.loadValue();
            // F-4: a lot that never received a bid has no clock and cannot be
            // settled — it stays listed until admin cancels it.
            if (auc.endsAt == 0 || auc.highBidder == null || nowTime < auc.endsAt) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_AUCTION_LIVE);
                return;
            }

            // V7-16: the flat settle floor is preserved deliberately — it is a
            // documented public interface ("anyone can settle for 0.05 GRAM").
            // What made settle unreachable was not this floor but the UNBOUNDED
            // resolver set: at a few hundred resolvers the fan-out exceeded TVM's
            // action limit and the gas the settle value can buy, while
            // CancelAuction still refused any lot holding a bid — stranding the
            // winner's escrow with no op able to release it. MAX_RESOLVERS bounds
            // the fan-out at the source, so the flat floor stays sufficient.
            if (in.valueCoins < AUCTION_SETTLE_VALUE) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_INSUFFICIENT_PAYMENT);
                return;
            }

            val cfgS = st.cfg();
            st.auctions.delete(msg.nameHash);
            // R17-6: the lot leaves the map here on BOTH exits below — the F-1b/R14-5
            // abandonment and the successful hammer — so the counters move here too,
            // once, next to the delete they mirror. The guard above proves
            // `highBidder != null`, so this lot's escrow contribution was exactly
            // `auc.highBid`. Anything that throws after this line rolls the whole
            // compute phase back, counters included (see R17-13 below).
            st.liveLots -= 1;
            st.escrowedTotal = ((st.escrowedTotal as int) - (auc.highBid as int)) as uint64;

            // R14-5. SETTLE VERIFIED NOTHING, AND IT IS THE ONE PATH WHERE THAT
            // MATTERS MOST — IT IS PERMISSIONLESS AND IT FIRES LATE.
            //
            // What I did NOT do, and why. The obvious fix is to make settle carry
            // a fresh attestation. That would be strictly worse:
            //
            //   - it would end permissionless settlement. A settler would need a
            //     signer round-trip, so a signer that is down, rotated or simply
            //     unwilling could strand the winner's escrow — and `CancelAuction`
            //     refuses any lot holding a bid, by design, precisely so a bidder
            //     is never stranded. There would be NO op able to release it.
            //   - re-checking `sigValidUntil` has the same effect for free. The
            //     signer issues SHORT-lived attestations in production (minutes),
            //     the lot's own window is up to 30 days and does not start until
            //     the first bid, so every real auction would settle expired. The
            //     expiry is a replay defence on the LISTING MESSAGE, and
            //     StartAuction already consumed it.
            //
            // What the policy hash is actually for is different from what the
            // expiry is for: it says WHICH RULESET the signer was authorised to
            // apply. A lot listed under v1 and minted after v2 was published and
            // LOCKED is a name issued under a ruleset the project has publicly and
            // irrevocably disowned. So bind the ruleset, not the clock.
            //
            // The refusal reuses the F-1b escape below verbatim — refund the
            // winner in full, drop the lot — because that path is already the
            // contract's answer to "this lot can no longer be minted honestly",
            // and it is the only shape that cannot strand a bid. The admin can
            // re-list under the new policy; nobody loses money either way.
            // R24-2 (MEDIUM). R14-5's REMEDY WAS ITSELF AN ADMIN PRIMITIVE FOR
            // VOIDING A WON AUCTION.
            //
            // ===================================================================
            // WHAT THE COMPARE ACTUALLY BOUGHT, AND WHAT IT COST
            // ===================================================================
            // The reasoning above is sound about the RISK: a lot listed under
            // policy v1 and minted after v2 was published is a name issued under a
            // disowned ruleset. The remedy was not. Settle cannot even be reached
            // with `endsAt == 0`, and `endsAt` stays 0 until the FIRST BID — so
            // this branch is only ever reachable when a bidder's money is already
            // custodied and, past `endsAt`, when the winner is already determined.
            //
            // `SetNormalizationPolicy` is a plain admin op with no timelock and no
            // per-lot targeting. So one message voided EVERY live lot, including
            // lots whose clearing price was already public:
            //
            //   admin lists 🚀 at 150 GRAM -> Alice bids 150 -> window closes,
            //   Alice is the winner -> admin, unhappy with 150, sends
            //   SetNormalizationPolicy(anything) -> any settler triggers the abort
            //   -> Alice refunded, lot deleted, name free -> AdminMint takes it
            //   permanently. (Measured end to end.)
            //
            // That is a free option on every bid, exercisable AFTER the outcome is
            // known. And `CancelAuction` twenty lines below refuses any lot holding
            // a bid — "never strand a bidder" — so this was a second, unguarded
            // door to precisely the outcome the first door was written to forbid.
            //
            // ===================================================================
            // WHAT THE ECOSYSTEM DOES: A LOT WITH STAKES IS UNTOUCHABLE
            // ===================================================================
            // Both live references agree, and one of them is the strongest
            // authority that exists on TON:
            //
            //   telemint (Fragment): `auction_config` is SNAPSHOTTED into item
            //     state at start and nothing ever re-consults the global config;
            //     cancellation is refused once there are stakes
            //     (`throw_unless(err::already_has_stakes, cell_null?(last_bid))`).
            //
            //   ton-blockchain/dns-contract: `op::process_governance_decision` —
            //     VALIDATOR-VOTED seizure, the highest authority in the system —
            //     refuses outright while an auction is in flight
            //     (`throw_unless(413, cell_null?(auction))`).
            //
            // If validator consensus defers to a live auction, an admin key
            // certainly should. So the snapshot this lot already carries becomes
            // authoritative, and the global policy is not consulted at settle.
            //
            // THE DRIFT RISK IS NOT LEFT OPEN, IT IS MOVED EARLIER. `StartAuction`
            // verified the attestation under the policy in force at listing, and
            // `assertCanonicalName` ran then too, so the on-chain floor has already
            // passed. The lot snapshots `policyHash`, `emojiCount`, `label` and
            // `numYears` — a bidder commits real money against exactly that
            // package, and minting it under that package is the honest outcome. If
            // the admin needs a lot gone for policy reasons, `CancelAuction` is
            // available for the whole pre-bid window, which is unbounded (the clock
            // does not start until the first bid). After a bid, it is the bidder's.
            //
            // This is a DELETION, not a new mechanism: one fewer branch, one fewer
            // storage read, and the two doors that can destroy a lot now enforce
            // the same single predicate — a lot holding a bid cannot be destroyed
            // by anyone.

            // F-1b: defence in depth. If the name became unavailable while the lot
            // ran, refund the winner and abandon the lot. Throwing instead would
            // strand the bid forever (CancelAuction refuses a lot that has bids).
            val exS = st.names.get(msg.nameHash);
            var freeS = true;
            if (exS.isFound) {
                val recS = exS.loadValue();
                freeS = !recS.isPermanent && nowTime >= (recS.expiresAt + GRACE);
            }
            if (!freeS) {
                // R17-13 (MEDIUM). R16-1's CLAMP BOUNDED THE LOSS BY THE FLOAT
                // DEFICIT, NOT BY `MIN_STORAGE` — AND IT DELETED THE ALARM.
                //
                // R16-1 replaced a silently-skipped refund with a clamped one and
                // documented the result as "a total loss becomes a <= 0.05 GRAM
                // shortfall". That was false in both directions. `spareS` compares
                // ONE LOT'S BID against the WHOLE CONTRACT'S BALANCE, so the
                // shortfall is the float deficit and is unbounded above:
                //
                //     registrar 100.0 GRAM | winner owed 150.0 got 100.0  SHORT  50.0
                //     registrar  10.0 GRAM | winner owed 150.0 got  10.0  SHORT 140.0
                //
                // and it did it with `exit 0, skipped=0, actionPhase.success=true`,
                // byte-identical in the transaction record to a fully-paid winner.
                // Pre-R16-1 the same loss at least carried `skippedActions=1`, so
                // the fix removed the one signal an operator could alarm on.
                //
                // REFUSE TO UNDER-PAY INSTEAD OF QUIETLY PAYING PART. A compute
                // throw rolls the whole phase back: `st.auctions.delete()` and the
                // R17-6 counter moves above are undone, so the lot and the escrow
                // SURVIVE, the settler's (bounceable) message bounces, and anyone —
                // including the winner, who has 150+ GRAM of motive — can top the
                // contract up and re-settle. Nothing is stranded, because settle is
                // permissionless and the lot is still there to settle.
                //
                // That inverts the R8-12 rule deliberately, and it is the one place
                // in the contract where it should be inverted: the party at risk is
                // a settler staking AUCTION_SETTLE_VALUE (0.05 GRAM), and the
                // alternative is short-changing a winner by up to their whole bid.
                //
                // Measured on a patched build (22A10CE66F1145F6) before landing it
                // here; the healthy-settle over-fix control is in
                // audit/round18/registrar/C_refusals.spec.ts.
                val spareS = (contract.getOriginalBalance() as int) - MIN_STORAGE;
                assert(spareS >= (auc.highBid as int)) throw ERR_ABORT_REFUND_SHORT;
                // The clamp is gone, so the value is the whole bid, and `highBid` is
                // provably >= MIN_AUCTION_START_BID here (the guard at the top of
                // this handler proves `highBidder != null`, and every accepted bid
                // met the 150 GRAM floor) — there is no zero case left to test for.
                // IGNORE_ERRORS is gone with it: it existed to tolerate a value the
                // balance could not cover, which the assert above now makes
                // unreachable, and keeping it would leave the silent-skip shape in
                // place for any future arithmetic slip. F-3's PAY_FEES_SEPARATELY
                // stays — the winner is made whole.
                createMessage({
                    bounce: BounceMode.NoBounce,
                    value: auc.highBid,
                    dest: auc.highBidder!,
                    body: OutbidNotification { queryId: msg.queryId },
                }).send(SEND_MODE_PAY_FEES_SEPARATELY);
                saveStorage(st);
                return;
            }

            {
                val hammer = auc.highBid as int;
                // R17-24. THE TERM STARTED AT SETTLE, NOT AT THE HAMMER.
                //
                // `nowTime + numYears * YEAR` charges for a term that begins
                // whenever somebody gets round to settling. Measured: a lot settled
                // two years late gave `expiry - hammer = 7 years` for a 5-year
                // purchase — free term, minted out of nothing, at the tier where
                // names are most valuable.
                //
                // THE OBVIOUS FIX IS WRONG AND WAS MEASURED WRONG. Plain
                // `endsAt + numYears * YEAR` issues an ALREADY-LAPSED name the
                // moment the delay exceeds the term: the winner pays 150+ GRAM and
                // anyone can re-register it. `max()` is what makes both true at
                // once — the clock runs from the hammer, and a lot settled past its
                // own term still issues something the winner holds.
                //
                // The floor is `nowTime`, not `nowTime + something`: a name issued
                // at exactly its expiry is inside GRACE for 90 days, so `RenewName`
                // works, `isAvailable()` is false, and no stranger can take it —
                // the winner keeps the exclusive right to extend, which is the
                // minimum the hammer bought. Granting a fresh full term instead
                // would restore the free-term bug from the other direction.
                //
                // `endsAt` is provably non-zero and <= nowTime here: the guard at
                // the top of this handler refuses `endsAt == 0` and `nowTime <
                // endsAt`. The absolute uint32 horizon is enforced in `issueName`.
                val hammerTerm = (auc.endsAt as int) + auc.numYears * YEAR;
                val expiry = (hammerTerm > nowTime) ? hammerTerm : nowTime;
                // hammer price already sits in this contract's balance (held from
                // the winning bid); the mint/sync gas comes out of it.
                val partnerCutA = partnerCutOf(cfgS, hammer);
                payPartner(cfgS, hammer);
                // Revenue is booked GROSS OF GAS on every path, so traction()
                // means one thing. Earlier this line also subtracted `ops` — a
                // forward-looking BUDGET, not actual spend — which understated
                // auction income relative to registrations and renewals.
                st.totalRevenue = (st.totalRevenue + (hammer - partnerCutA)) as uint128;
                st.totalRegistrations += 1;
                // R14-4: a hammer is a FIRST issuance of the lot — derive the
                // nonce (0), never reserved (the winner must be able to sell).
                issueName(mutate st, cfgS, msg.nameHash, auc.highBidder!, auc.emojiCount,
                          expiry, false, auc.content, msg.queryId, 0, false, auc.label);
                saveStorage(st);
            }
        }

        // ---- AUCTION: cancel (admin, only while unbid) ----
        CancelAuction => {
            // R24-6b. THIS OP BECAME PERMISSIONLESS, SO IT INHERITS THE
            // PERMISSIONLESS-HANDLER RULE: REFUSE, DO NOT CONFISCATE.
            //
            // Six rounds (R8-12, R10-1, R13-2, R14-2, R14B1-1, R23-4) converted
            // every permissionless paid handler in this contract from `throw` to
            // `refundAndStop`, because real wallets strip the bounce flag and a
            // throw therefore keeps the sender's whole value. `CancelAuction` was
            // exempt from that sweep for one reason only — it was admin-only.
            // R24-6 removed that reason and the sweep was not re-applied.
            //
            // Measured on the first draft, all non-bounceable, all returning 0:
            //   truncated body (96 bits)      -> exit 9, whole 1 GRAM kept
            //   one second before the window  -> exit 483, whole 1 GRAM kept
            //   lost reclaim race to another bot -> exit 429, whole 0.3 GRAM kept
            //
            // The last one is the sharpest: R24-6 CREATES that race by making
            // reclaim a bounty-free public good, and R14-2 converted
            // `SweepCommitment`'s identical lost-race arm to a refund for exactly
            // this reason. A reclaim bot that loses one race in two would
            // otherwise be paying the registrar to keep the namespace tidy.
            //
            // The admin keeps `throw` semantics: an admin op is sent by a known
            // operator from a bounceable wallet, and this contract's house rule
            // (SetPartner, AddResolver) is that admin mistakes throw loudly rather
            // than refund quietly.
            // R30-2. THE SHAPE GUARD IS UNCONDITIONAL; ONLY THE SEMANTIC
            // REFUSALS BELOW SPLIT ON THE SENDER.
            //
            // R24-6b's own write-up names this exact shape as the defect it was
            // fixing — "truncated body (96 bits) -> exit 9, whole 1 GRAM kept" —
            // and then gated the fix on `!isAdminCancel`, so the one sender the
            // house rule says should get a LOUD refusal is the one sender who
            // still gets a bare cell-underflow. Measured: stranger with a 96-bit
            // body -> exit 0, reason 468, 0.199 of 0.2 returned; admin with the
            // IDENTICAL body, bounce stripped -> exit 9, 0 returned, registrar
            // +0.9996.
            //
            // The house rule is that admin MISTAKES throw and MALFORMED BODIES
            // refund, and a truncated body is the second kind. Exit 9 is in no
            // error table and no front end can translate it. The admin's semantic
            // refusals — ERR_NO_AUCTION (429) and ERR_AUCTION_LIVE (431) below —
            // keep throwing exactly as before; this moves one bit-count
            // comparison above the branch and costs the admin path nothing else.
            if (in.body.remainingBitsCount() != BODY_OP_QUERYID_HASH) {
                refundAndStop(in.senderAddress, 0, ERR_BAD_BODY);
                return;
            }
            val isAdminCancel = in.senderAddress == st.admin;
            val found = st.auctions.get(msg.nameHash);
            if (!found.isFound) {
                if (isAdminCancel) { throw ERR_NO_AUCTION; }
                refundAndStop(in.senderAddress, msg.queryId, ERR_NO_AUCTION);
                return;
            }
            val auc = found.loadValue();
            if (auc.highBidder != null) {                 // never strand a bidder
                if (isAdminCancel) { throw ERR_AUCTION_LIVE; }
                refundAndStop(in.senderAddress, msg.queryId, ERR_AUCTION_LIVE);
                return;
            }
            // R24-6 (MEDIUM, operability). AN UNBID LOT WAS AN ADMIN-KEY-SHAPED
            // HOLE IN THE NAMESPACE.
            //
            // `StartAuction` writes a lot with `endsAt = 0` and the clock does not
            // start until the first bid (F-4, deliberate). Permissionless
            // `SettleAuction` refuses `endsAt == 0`. `assertAvailableForIssue`
            // refuses any name holding a lot. So an unbid lot blocked its name
            // against EVERY issuance path and had exactly one exit — this op,
            // admin-only. If the key is lost or the multisig quorum is
            // unreachable at any point after a listing, that name is
            // unregisterable by anyone, forever, with no timeout.
            //
            // The ecosystem's answer to exactly this is permissionless-after-a-
            // timeout, and `.ton` states it in one line:
            // `op::dns_balance_release` is callable by ANYONE once
            // `now() - last_fill_up_time > one_year` and no auction is in flight
            // (`throw_unless(414, ...)`), with the caller paying a floor so the
            // op cannot be used to grief. telemint reaches the same place from
            // the other side: its settlement runs on `recv_external` so the
            // CONTRACT pays and no key is required to end an auction.
            //
            // Here the anti-grief property is free and needs no payment floor,
            // because the precondition already carries it: the assert above
            // proves the lot holds NO BID, so cancelling strands nobody and
            // returns nothing to anyone. The only effect is to free a name the
            // market demonstrably did not want at its floor price for a full
            // reclaim window. There is nothing to steal, so there is nothing to
            // pay for.
            //
            // The admin keeps its unconditional door — a bad listing should be
            // retractable immediately, not in a fortnight.
            if (!isAdminCancel && nowTime < (auc.listedAt as int) + UNBID_RECLAIM_WINDOW) {
                refundAndStop(in.senderAddress, msg.queryId, ERR_AUCTION_NOT_STALE);
                return;
            }
            st.auctions.delete(msg.nameHash);
            // R17-6: the assert one line above proves this lot held no bid, so it
            // contributed nothing to `escrowedTotal` and only the count moves. This
            // is the fourth and last writer of the two counters.
            st.liveLots -= 1;
            saveStorage(st);
        }

        // ---- ADMINMINT: free promotional / partnership issuance ----
        AdminMint => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            assert(msg.emojiCount >= 1) throw ERR_BAD_EMOJI_COUNT;
            // the cap binds admin too — otherwise the "locked at 5" commitment
            // would be worthless the moment admin wanted an exception
            assert(msg.emojiCount <= MAX_EMOJI_COUNT) throw ERR_TOO_MANY_EMOJI;
            assert(msg.numYears <= MAX_YEARS) throw ERR_BAD_YEARS;   // 0 = permanent
            // R17-5: same cap, same "new names only" rule as Reveal. This is also
            // the door an operator uses to re-issue a lapsed name once `Commit` is
            // closed at the cap.
            assert((st.totalNames as int) < NAMES_SOFT_CAP
                   || st.names.get(msg.nameHash).isFound) throw ERR_NAME_UNAVAILABLE;

            val cfgM = st.cfg();
            // R10-2: FUNDING IS CHECKED FIRST, BEFORE ANY EXPENSIVE WORK.
            // Ordering is the whole fix. `assertCanonicalName` walks the name at
            // ~3,215 gas/byte, and the gas ceiling is bought with the incoming
            // value — so with the check placed after the walk, an under-funded call
            // exhausted gas (exit -14) inside the walk and never reached the guard
            // meant to reject it. Nothing above depends on the name, so this moves
            // up freely and makes an under-funded call a cheap, legible refusal.
            val ops = opsBudgetRegister(countResolvers(cfgM.resolvers), cfgM.nftCollection != null);
            assert(in.valueCoins >= ops + ADMIN_COMPUTE_BUDGET) throw ERR_INSUFFICIENT_PAYMENT;
            // signer attestation still required (spec decision 3): every record in
            // the registry stays canonically normalized, promo mints included.
            assert(nowTime <= msg.sigValidUntil) throw ERR_SIG_EXPIRED;
            // R14B1-16: bounded ABOVE too — see MAX_SIG_WINDOW.
            assert(msg.sigValidUntil <= nowTime + MAX_SIG_WINDOW) throw ERR_SIG_EXPIRED;
            val hM = attestationHash(msg.nameHash, msg.emojiCount, msg.content.hash(), msg.sigValidUntil,
                                     cfgM.prices.load().normalizationPolicyHash, ATT_PURPOSE_ADMIN_MINT,
                                     in.senderAddress);  // R24-1: the admin, asserted above
            assert(isSignatureValid(hM, msg.signature.load().sig as slice, cfgM.signerPublicKey))
                throw ERR_BAD_SIGNATURE;
            // admin cannot bypass the policy either
            assertCanonicalName(msg.rawName, msg.nameHash, msg.emojiCount);
            assertUriSuffix(msg.content, msg.rawName);

            assertAvailableForIssue(st, msg.nameHash, nowTime);

            val expiry = (msg.numYears == 0) ? PERMANENT_EXPIRY : (nowTime + msg.numYears * YEAR);
            // R14-4: a promo mint is a FIRST issuance, so it derives its own nonce
            // (0) and never sets the reserved flag — only a migration carries a
            // history, and only the collection admin seeds foundation items.
            issueName(mutate st, cfgM, msg.nameHash, msg.owner, msg.emojiCount, expiry,
                      msg.numYears == 0, msg.content, msg.queryId, 0, false, msg.rawName);
            saveStorage(st);
        }

        AdminImport => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            val cfgI = st.cfg();
            var polI = cfgI.prices.load();
            assert(!polI.importsLocked) throw ERR_IMPORTS_LOCKED;

            assert(msg.emojiCount >= 1) throw ERR_BAD_EMOJI_COUNT;
            assert(msg.emojiCount <= MAX_EMOJI_COUNT) throw ERR_TOO_MANY_EMOJI;
            // R15-1. THE ONLY REACHABLE INTEGER OVERFLOW IN THE CODEBASE.
            //
            // `carryNonce` is written straight into `NameRecord.syncNonce`, and
            // every later OWNER write does `prior.syncNonce + 1` into a uint32.
            // Measured: `syncNonce = 0xFFFFFFFF` imports with exit 0, and then the
            // first re-issuance after the name lapses is `exit 5, aborted` — the
            // name is bricked, the buyer is out 0.064 GRAM, and no op can lower a
            // nonce. It survives R14-4a's purpose (preserve a migrant's history)
            // untouched: the nonce counts OWNER WRITES, so a real v4 name arrives
            // with a value in the low tens. A million transfers of one name is
            // four orders of magnitude past anything the chain could produce and
            // still leaves 4,293,967,296 increments of headroom.
            assert(msg.syncNonce <= MAX_IMPORT_SYNC_NONCE) throw ERR_BAD_SYNC_NONCE;
            // R17-5: unconditional here — this handler asserts below that the name
            // is NOT already present, so every accepted import is a new cell pair.
            // A migration that would overrun the wall has to be split across two
            // registrars, and finding that out at the cap beats finding it out at
            // 32,627 with an action-phase failure.
            assert((st.totalNames as int) < NAMES_SOFT_CAP) throw ERR_NAME_UNAVAILABLE;

            // R10-2: funding checked BEFORE the expensive byte-walk — see AdminMint.
            // MIGRATION_RUNBOOK phase C drives the whole registry through this op, so
            // an under-funded batch must fail legibly rather than exhaust gas.
            val opsI = opsBudgetRegister(countResolvers(cfgI.resolvers), cfgI.nftCollection != null);
            assert(in.valueCoins >= opsI + ADMIN_COMPUTE_BUDGET) throw ERR_INSUFFICIENT_PAYMENT;

            // same attestation as every other issuance path — a migrated name is
            // still canonically normalized
            assert(nowTime <= msg.sigValidUntil) throw ERR_SIG_EXPIRED;
            // R14B1-16: bounded ABOVE too — see MAX_SIG_WINDOW. A migration batch is
            // signed in bulk, so this is the path where a wide window is most
            // tempting and where the signatures are most likely to leak.
            assert(msg.sigValidUntil <= nowTime + MAX_SIG_WINDOW) throw ERR_SIG_EXPIRED;
            val hI = attestationHash(msg.nameHash, msg.emojiCount, msg.content.hash(), msg.sigValidUntil,
                                     polI.normalizationPolicyHash, ATT_PURPOSE_ADMIN_IMPORT,
                                     in.senderAddress);  // R24-1: the admin, asserted above
            assert(isSignatureValid(hI, msg.signature.load().sig as slice, cfgI.signerPublicKey))
                throw ERR_BAD_SIGNATURE;
            assertCanonicalName(msg.rawName, msg.nameHash, msg.emojiCount);
            assertUriSuffix(msg.content, msg.rawName);

            // STRICTER than assertAvailableForIssue: import may only ever CREATE.
            // A name already in this registry is untouchable, lapsed or not.
            assert(!st.names.get(msg.nameHash).isFound) throw ERR_NAME_TAKEN;
            assert(!st.auctions.get(msg.nameHash).isFound) throw ERR_AUCTION_EXISTS;

            // F-2 still binds: migration cannot be used to grant a term the
            // namespace would not otherwise allow.
            val impExpiry = msg.isPermanent ? PERMANENT_EXPIRY : (msg.expiresAt as int);
            if (!msg.isPermanent) {
                assert(impExpiry <= nowTime + MAX_TOTAL_TERM) throw ERR_BAD_IMPORT_TERM;
                // V7-17 (HIGH). The term was bounded ABOVE but not BELOW, and the
                // two contracts read expiresAt == 0 with OPPOSITE meanings:
                //   registrar — 0 is "long expired", so isAvailable() is true and
                //               the name is instantly re-registrable;
                //   NFT item  — 0 is the NEVER-EXPIRES sentinel, so isWithinGrace()
                //               is true forever and InitOrReassign refuses (411).
                // An import of 0 therefore created a registry record anyone could
                // take over an NFT that could never be reassigned to them. The two
                // are then divorced permanently: AdminMint hits the same 411, there
                // is no SETCODE, and AdminImport cannot overwrite. The name is
                // bricked for good.
                //
                // V7-17b: the sentinel collision only ever required `!= 0`.
                // Bounding at `> nowTime` over-shot by the whole 90-day grace and
                // refused the migration MIGRATION_RUNBOOK.md explicitly
                // prescribes — "import them with their real expiresAt even if it
                // is in the past ... Do not silently extend them". An in-grace
                // name is a live holding with a real owner and a real renewal
                // right; refusing it strands the holder and lets a stranger take
                // the name at v5. Admit anything still inside grace.
                assert(impExpiry + GRACE > nowTime) throw ERR_IMPORT_TERM_PAST;
            }

            // (funding was asserted at the top of this handler — R10-2)
            // R14-4: the two fields that make a migration LOSSLESS. See the notes
            // on `issueName`'s carryNonce and on `sendMint`'s isReserved for the
            // measured before-state of each.
            issueName(mutate st, cfgI, msg.nameHash, msg.owner, msg.emojiCount,
                      impExpiry, msg.isPermanent, msg.content, msg.queryId,
                      msg.syncNonce as int, msg.isReserved, msg.rawName);
            saveStorage(st);
        }

        LockImports => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            // R17-26. THE ONE-WAY LOCK WITH NO PRECONDITION, ON THE ONLY ESCAPE
            // HATCH THE SYSTEM HAS.
            //
            // Measured: `exit 0` on a COMPLETELY EMPTY registry, after which every
            // `AdminImport` answers 452, idempotently and unclearably. That matters
            // more here than for any other lock, because `AdminImport` is the
            // documented escape from an NFT-layer divergence (MIGRATION_RUNBOOK
            // phase C) and from R17-9 — the situations where the registrar and the
            // item disagree and re-issuing into a v5 is the only repair.
            //
            // `LockNormalizationPolicy` got exactly this guard in R14B1-11 (466 on
            // hash 0) for exactly this reason: a one-way lever pulled a step early
            // in a runbook that contains both steps. `LockImports` and `LockPrices`
            // did not. The precondition here is the same shape — "there is
            // something to lock" — and `totalNames > 0` is the honest reading of
            // that: a migration that has imported nothing is not finished.
            assert(st.totalNames > 0) throw ERR_NAME_NOT_FOUND;
            var cLI = st.cfg();
            var pLI = cLI.prices.load();
            pLI.importsLocked = true;      // nothing anywhere sets this false
            cLI.prices = pLI.toCell();
            st.config = cLI.toCell();
            saveStorage(st);
        }

        SetNormalizationPolicy => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            // R17-27. R14B1-11 REFUSED TO *LOCK* THE SENTINEL AND NOTHING REFUSED
            // TO *WRITE* IT.
            //
            // 0 is documented everywhere as "no policy published yet". Writing it
            // back un-publishes the ruleset: every attestation then binds
            // `policyHash = 0`, which binds nothing, and V7-29's whole guarantee —
            // change the policy and every signature issued under the old one dies —
            // silently stops applying. The lock guard below can no longer catch it
            // either, because the sentinel is now the current value and locking is
            // refused, so the deployment is left permanently unable to commit to a
            // ruleset without ever having said so.
            //
            // Same code (466) as the lock guard: it is the same sentinel and the
            // same refusal, one op earlier.
            assert(msg.policyHash != 0) throw ERR_BAD_POLICY_HASH;
            var cP = st.cfg();
            var polP = cP.prices.load();
            assert(!polP.policyLocked) throw ERR_POLICY_LOCKED;
            polP.normalizationPolicyHash = msg.policyHash;
            cP.prices = polP.toCell();
            st.config = cP.toCell();
            saveStorage(st);
        }

        LockNormalizationPolicy => {
            assert(in.senderAddress == st.admin) throw ERR_NOT_ADMIN;
            var cL = st.cfg();
            var polL = cL.prices.load();
            // R14B1-11. THE ONE-WAY LOCK COULD FREEZE THE "NOT PUBLISHED" SENTINEL.
            //
            // `normalizationPolicyHash` starts at 0, and 0 is DOCUMENTED as "no
            // policy published yet" — `normalizationPolicy()` returns it, the
            // attestation preimage carries it, and every reference in
            // docs/NORMALIZATION_SPEC treats 0 as the pre-publication state.
            // `policyLocked` is one-way: nothing in this contract, and no SETCODE,
            // ever clears it.
            //
            // So `LockNormalizationPolicy` sent before `SetNormalizationPolicy` —
            // one transposed step in a launch runbook that has both ops in it —
            // freezes the sentinel FOREVER. The ruleset the whole signer-trust
            // story rests on ("the signer cannot mint outside the frozen table,
            // and here is the hash of that table") can then never be published on
            // this deployment, on any path. Every attestation would forever commit
            // to `policyHash = 0`, which binds nothing, and the only remedy is
            // redeploying the registrar and migrating the registry.
            //
            // Costs an operator nothing: publishing the hash first is the order the
            // runbook already prescribes, and this makes the wrong order fail
            // loudly instead of succeeding silently.
            assert(polL.normalizationPolicyHash != 0) throw ERR_BAD_POLICY_HASH;
            polL.policyLocked = true;    // nothing anywhere clears this
            cL.prices = polL.toCell();
            st.config = cL.toCell();
            saveStorage(st);
        }

        SweepCommitment => {
            // R17-7: R14-2 turned sweeping into a market, so this arm is now driven
            // by third-party bots staking their own value on every attempt. A short
            // body cost them the stake with no refund; the two R14-2/R14B1-2 refund
            // arms below only ever saw well-formed ones.
            if (in.body.remainingBitsCount() != BODY_OP_QUERYID_HASH) {
                refundAndStop(in.senderAddress, 0, ERR_BAD_BODY);
                return;
            }
            // permissionless: only removable once provably past its usable window
            var auxS = st.auxData();
            val found = auxS.commitments.get(msg.commitment);
            if (found.isFound) {
                val committedAt = found.loadValue();
                // R14B1-2. THE OTHER HALF OF R14-2'S REFUND, LEFT THROWING.
                //
                // R14-2 gave SweepCommitment a bounty and, having made sweeping a
                // race, correctly converted the not-found arm to a refund so a
                // sweeper who lost the race got their message value back. This arm
                // is the SAME race one block earlier: the sweeper's bot saw a
                // commitment that was about to age out, the block landed a second
                // early, and the commitment is still inside `commitMaxAge`.
                //
                // Measured before this change: 0.02 GRAM in, 0 back — the whole
                // stake kept — on every too-early sweep. The bounty is 0.02, so a
                // bot that mis-times one sweep in two makes nothing and a bot that
                // mis-times more than that is paying the registrar to clean it.
                // That is precisely the incentive R14-2 exists to create, inverted.
                //
                // Nothing has been written yet — `auxS` is a local and `saveStorage`
                // is three lines below — so returning here leaves state untouched.
                if (blockchain.now() <= (committedAt + st.cfg().commitMaxAge)) {
                    refundAndStop(in.senderAddress, msg.queryId, ERR_COMMIT_NOT_EXPIRED);
                    return;
                }
                auxS.commitments.delete(msg.commitment);
                // R24-5: same release, same underflow guard.
                if ((auxS.liveCommitments as int) > 0) {
                    auxS.liveCommitments = ((auxS.liveCommitments as int) - 1) as uint32;
                }
                st.aux = auxS.toCell();
                saveStorage(st);
                // R14-2. THE OP EXISTED AND NOBODY RAN IT, BECAUSE IT PAID NOTHING.
                //
                // "Permissionless cleanup" is not a defence unless somebody is
                // paid to perform it. Before this, sweeping cost the sweeper a
                // message and returned them nothing, so the only party with an
                // incentive was the operator — and the operator has to notice
                // first. Meanwhile a filled registrar refuses every state write in
                // the ACTION phase with code 50, including the admin ops the
                // operator would use to respond.
                //
                // A bounty makes the cleanup a market rather than a chore, which
                // is what converts the bloat attack from a one-off purchase into a
                // rent the attacker must keep paying (see COMMIT_MIN_VALUE).
                //
                // FUNDED BY THE COMMITMENT IT REMOVES. `Commit` refused anything
                // under COMMIT_MIN_VALUE and that value is already in this
                // contract's balance; SWEEP_BOUNTY is a compile-time constant
                // strictly below it, so no arithmetic here can pay out more than
                // the swept commitment deposited.
                //
                // The reserve check is the same one WithdrawFees applies (F-5 /
                // V7-1): never pay a bounty out of bidder escrow, the resolver
                // fan-out obligation, or the rent floor. If the contract cannot
                // afford it the sweep still HAPPENS — the cells are freed either
                // way — and the sweeper simply gets their own value back. Freeing
                // state must never depend on being able to pay for it.
                //
                // CARRY_ALL_REMAINING_MESSAGE_VALUE returns the sweeper's own
                // message value on top of the bounty, so the profit is the bounty
                // minus gas rather than the bounty minus gas minus their stake.
                val freeSw = freeBalanceOf(st, in.valueCoins as int);
                val bounty = (freeSw >= SWEEP_BOUNTY) ? SWEEP_BOUNTY : 0;
                createMessage({
                    bounce: BounceMode.NoBounce,
                    value: bounty as coins,
                    dest: in.senderAddress,
                    body: SweepBounty { queryId: msg.queryId },
                }).send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS);
            } else {
                // R14-2. A LOST SWEEP RACE MUST NOT COST THE LOSER THEIR MESSAGE.
                //
                // This arm used to fall straight out of the handler, keeping the
                // sender's value — the same silent confiscation R8-12 removed from
                // the paid handlers and R13X-6 removed from the unknown-op arm,
                // surviving here only because nobody had a reason to send this op
                // speculatively. A bounty gives them one: sweeping is now a race,
                // and a race has losers by construction. Measured before: 0.02
                // GRAM in, 0 back, on every duplicate sweep.
                //
                // Reuses ERR_NO_COMMITMENT (413) — "no commitment under that
                // hash", which is exactly what happened — so a sweeper's bot can
                // tell a lost race from a mis-computed commitment hash without a
                // new code.
                refundAndStop(in.senderAddress, msg.queryId, ERR_NO_COMMITMENT);
            }
        }

        else => {
            // R13X-6. "Treat as top-up" was CONFISCATION, and this is the only
            // one of the four contracts that did it.
            //
            // A genuine top-up carries no opcode at all and never reaches here —
            // the `remainingBitsCount() < 32` guard at the entry point returns
            // first. So the only bodies this arm ever sees are ones the contract
            // cannot interpret: a mis-addressed message, a wrong-version front end,
            // a fat-fingered opcode. Measured at 1 GRAM each, across unknown-op and
            // text-comment bodies, bounceable and not: the registrar kept
            // 0.999616599 every time. The collection, the item and the resolver all
            // throw 0xffff, so a bounceable sender gets the whole value back.
            //
            // That is the same silent confiscation R8-12 removed from the paid
            // handlers, sitting on the one path a confused integrator is most
            // likely to hit. Op 0 is the wallet text-comment convention and stays
            // a top-up; everything else goes home.
            //
            // R17-36, the other half. `refundAndStop` already declines to answer
            // THIS contract; the remaining ping-pong partner is the NFT collection,
            // which has an identical unknown-op refund arm of its own
            // (emoji_nft_collection.tolk, and its comment names this exchange).
            // Two mis-versioned peers then trade RejectedRefunds until the fees
            // consume the value. The collection is funded out of this contract's
            // own mints, so declining to bounce its money back costs the system
            // nothing and stops the exchange on hop one. A stranger's wrong opcode
            // is still refunded in full — that property is R13X-6 and it is intact.
            // R25-6b (the one-line close R25-6 costed and did not take).
            //
            // THE GUARD BELOW IS EXPRESSED IN TERMS OF *WHO* THE PEER IS, AND THE
            // PING-PONG IS A PROPERTY OF *WHAT* THE MESSAGE IS. Both pointers are
            // null on the `ERR_NO_PENDING_COLLECTION` arm of `ConfirmNftCollection`
            // — that is what "no pending collection" MEANS — so `peerLoops`
            // evaluated false exactly when the collection was relaying, and
            // R25-6's refund there started the R17-36 exchange it was meant to be
            // protected from. Measured on the shipped build, `stage -> cancel ->
            // announce`, with the operator's whole attached value consumed:
            //
            //   0.05 GRAM ->  99 txs      0.2 GRAM -> 389 txs
            //   0.10 GRAM -> 195 txs      0.5 GRAM -> 969 txs
            //
            // and the SECOND arm loops too, which the costing missed: a decoy
            // staged while the real collection announces reaches `ERR_NOT_
            // COLLECTION` (411), where the sender is by definition NOT either
            // pointer — measured 388 txs at 0.2 GRAM. So the address predicate is
            // structurally unable to cover this handler: on one arm there is no
            // pointer to match, and on the other the arm only fires when the match
            // fails.
            //
            // ANSWERING A REFUSAL WITH A REFUSAL IS THE PING-PONG BY DEFINITION,
            // whoever sends it. `RejectedRefund` is this system's "I am declining
            // your money" message; four contracts emit it and none has an ingress
            // arm for it, so it can only ever arrive here as the other half of an
            // exchange this arm started. Declining to answer it terminates every
            // such exchange on the registrar's leg in ONE hop, for every peer —
            // including the RESOLVER, whose own `else` arm (emoji_resolver_v2.tolk)
            // has no peer guard at all and would otherwise trade refusals with this
            // contract on any `AddResolver` pointed at a mis-versioned target.
            //
            // WHAT IT COSTS, STATED PLAINLY. R13X-6's property — "a stranger's
            // wrong opcode is still refunded in full" — now has exactly one
            // exception, out of 2^32: a stranger who sends 0x7e3a11c5 WITH VALUE
            // keeps neither the value nor an answer. No wallet, front end or
            // indexer produces that body (it is not a TEP opcode and it is
            // emit-only in all four contracts), and a sender who does produce it is
            // by construction telling this contract it is refusing a payment, which
            // is not a payment to give back. Measured before this change: 3 txs,
            // stranger net -0.000998 of 1 GRAM, i.e. refunded. After: the value is
            // kept. That is the whole regression and it is priced against an
            // unbounded burn of an operator's value on the deploy-day handshake.
            //
            // The address predicate is KEPT as well as, not instead of: it still
            // covers a mis-versioned collection sending some OTHER unknown op.
            val opU = in.body.preloadUint(32);
            if (opU != 0 && opU != OP_REJECTED_REFUND) {
                val cfgU = st.cfg();
                // R24-4: ...and the pointer currently AWAITING acknowledgement.
                // `cfg.nftCollection` is null for the whole staging window, which
                // is precisely the window in which the collection is talking to
                // this contract — so R17-36's peer-loop guard was blind exactly
                // when the two contracts are exchanging their first messages.
                val auxU = st.auxData();
                val peerLoops = (cfgU.nftCollection != null
                              && in.senderAddress == cfgU.nftCollection!)
                             || (auxU.pendingNftCollection != null
                              && in.senderAddress == auxU.pendingNftCollection!);
                if (!peerLoops) {
                    refundAndStop(in.senderAddress, 0, ERR_UNKNOWN_OP);
                }
            }
            return;
        }
    }
}

fun onBouncedMessage(in: InMessageBounced) {
    // NFT/resolver syncs are re-drivable via the item's permissionless
    // ResyncOwner; a bounced fee refund is non-critical. No state change.
}

// ---------- get methods ----------

get fun isRegistered(nameHash: uint256): bool {
    return loadStorage().names.get(nameHash).isFound;
}

get fun expiryOf(nameHash: uint256): int {
    val r = loadStorage().names.get(nameHash);
    if (!r.isFound) { return 0; }
    return r.loadValue().expiresAt;
}

get fun emojiCountOf(nameHash: uint256): int {
    val r = loadStorage().names.get(nameHash);
    if (!r.isFound) { return 0; }
    return r.loadValue().emojiCount;
}

/**
 * V7-28. The tier the registrar will compute for these exact bytes.
 *
 * Exposed so the signer, the frontend and CI can ask the CONTRACT what tier a
 * name is instead of re-deriving it and hoping the two agree — an attestation
 * whose emojiCount differs from this value is guaranteed to be refused with
 * exit 456, and can be caught before a user ever pays for it. It is also what
 * the differential test drives to prove the TVM segmenter and
 * scripts/segment-reference.ts never disagree.
 *
 * Throws 457 on malformed UTF-8, exactly as issuance would.
 *
 * R9-2 NOTE: this is the SEGMENTER ONLY and deliberately does not apply the
 * namespace floor — it answers "how many units", not "is this registrable".
 * `checkName` below is the whole rule. Do not use this one as a validity oracle.
 */
get fun emojiUnitsOf(rawName: cell): int {
    var s = rawName.beginParse();
    var pending = 0;
    var cp = 0;
    var cpMin = 0;          // R9-7: reject overlong forms, same as assertCanonicalName
    var units = 0;
    var prevWasZwj = false;
    var riOpen = false;
    while (s.remainingBitsCount() >= 8) {
        val b = s.loadUint(8);
        var complete = false;
        if (pending == 0) {
            if (b < 0x80)      { cp = b; complete = true; cpMin = 0; }
            else if (b < 0xC0) { throw ERR_NAME_NOT_UTF8; }
            else if (b < 0xE0) { pending = 1; cp = b & 0x1F; cpMin = 0x80; }
            else if (b < 0xF0) { pending = 2; cp = b & 0x0F; cpMin = 0x800; }
            else if (b < 0xF8) { pending = 3; cp = b & 0x07; cpMin = 0x10000; }
            else               { throw ERR_NAME_NOT_UTF8; }
        } else {
            if ((b & 0xC0) != 0x80) { throw ERR_NAME_NOT_UTF8; }
            cp = (cp << 6) | (b & 0x3F);
            pending -= 1;
            complete = pending == 0;
        }
        if (complete) {
            // R9-7: canonical UTF-8 only — no overlong forms, no surrogate halves.
            assert(cp >= cpMin) throw ERR_NAME_NOT_UTF8;
            assert(cp < 0xD800 || cp > 0xDFFF) throw ERR_NAME_NOT_UTF8;
            // R14B1-7: ...and nothing above U+10FFFF. THIS DECODER IS WHERE THE GAP
            // WAS MEASURED: lead bytes F5/F6/F7 and `F4 90..BF` all decode past the
            // Unicode ceiling, and before this line every one of the six probe forms
            // was reported as ONE emoji unit by this get method while `checkName`
            // refused the same bytes with 462. A tier oracle that answers "1" for a
            // string no encoder can produce is worse than one that refuses to
            // answer. See the long note in `checkCanonicalName`.
            assert(cp <= 0x10FFFF) throw ERR_NAME_NOT_UTF8;
            val isZwj = cp == 0x200D;
            val isRi  = cp >= 0x1F1E6 && cp <= 0x1F1FF;
            var newUnit = true;
            if (prevWasZwj) {
                newUnit = false;
            } else if (isZwj
                    || cp == 0xFE0F
                    || cp == 0x20E3
                    || (cp >= 0xE0020 && cp <= 0xE007F)
                    || (cp >= 0x1F3FB && cp <= 0x1F3FF)) {
                newUnit = false;
            } else if (isRi && riOpen) {
                newUnit = false;
            }
            if (newUnit) { units += 1; }
            prevWasZwj = isZwj;
            riOpen = isRi ? !riOpen : false;
        }
    }
    assert(pending == 0) throw ERR_NAME_NOT_UTF8;
    return units;
}

/**
 * R9-2. THE WHOLE NAME RULE, AS A GET METHOD.
 *
 * Runs the exact `assertCanonicalName` an issuance runs — byte binding, length,
 * skin tones, the 38 confusables, the namespace floor, the keycap-companion rule
 * and the tier equality — and returns `units` if the name is registrable.
 * Otherwise it throws the SAME exit code the reveal would:
 *
 *     440 skin tone · 450 confusable variant · 451 too long · 456 tier mismatch
 *     457 malformed UTF-8 · 462 codepoint outside the namespace · 463 bare keycap base
 *
 * Two reasons this exists rather than a test-only harness:
 *
 *   1. It is the ONLY way to sweep the whole namespace against the real code
 *      path. tests/R9NamespaceFloor.spec.ts drives all 2055 frozen units and
 *      every generated multi-unit name through this, so "the floor rejects
 *      nothing legitimate" is measured against the shipped bytecode rather than
 *      argued from a TypeScript copy that could drift.
 *   2. An integrator or front end can ask the CHAIN whether a name is
 *      registrable before a user pays, instead of reimplementing the policy and
 *      getting a different answer. There is no cheaper honest oracle.
 *
 * `emojiCount` is an input because the tier equality is part of the rule. Pass
 * the count you intend to attest; pass the value from `emojiUnitsOf` to check
 * everything except the tier.
 */
get fun checkName(rawName: cell, emojiCount: int): int {
    // R10-3: `bitsHash()` (SHA256U) requires whole bytes, so a ragged cell threw a
    // bare TVM cell-underflow (exit 9) — a code absent from the published
    // CHECK_NAME_ERRORS map that integrators are told to switch on. Answer with the
    // documented malformed-input code instead.
    assert(rawName.beginParse().remainingBitsCount() % 8 == 0) throw ERR_NAME_NOT_UTF8;
    assertCanonicalName(rawName, rawName.beginParse().bitsHash(), emojiCount);

    // =======================================================================
    // R14B1-8. THE ORACLE LIED AT THE EDGES — AND THIS IS THE ONE ORACLE WE
    // TELL INTEGRATORS TO TRUST INSTEAD OF REIMPLEMENTING THE POLICY.
    // =======================================================================
    //
    // `assertCanonicalName` is the WALK. It is complete as a walk, and issuance is
    // correct because the three things below are all enforced somewhere else on the
    // issuance path — which is exactly why they were never noticed here:
    //
    //   * `emojiCount` bounds. `Reveal` asserts 2..7, `AdminMint` / `AdminImport` /
    //     `StartAuction` assert 1..7. The walk itself only asserts EQUALITY with
    //     the byte count, so it is perfectly happy with 0 and with 28. Measured:
    //     `checkName(emptyCell, 0)` returned 0, and so did any string made only of
    //     continuers (a lone U+FE0F) at count 0 — the oracle blessing a name that
    //     no path will issue and that has no tier and no price.
    //
    //   * the ENCODED URI SUFFIX (R11-4, re-measured). `#` is the one namespace
    //     byte `encodeUriSuffix` expands 1 -> 3 (`%23`), and keycaps chain through
    //     ZWJ, so RAW and ENCODED lengths decouple. R11-4 documented the largest
    //     accepted name as 135 bytes encoded; it is really 165:
    //
    //       00A9 + (200D 0023)x27      110 raw B,  1 unit, 164 encoded B -> was 0
    //       (0023 20E3)x27 + 2764      111 raw B, 28 units, 165 encoded B -> was 0
    //
    //     A cell holds 1023 bits, so both blow up in `beginCell().storeBuffer()`
    //     in the wrapper — AFTER the user has already paid for a `Commit` on a
    //     name whose reveal can never be constructed. That is the precise harm the
    //     oracle exists to prevent, and it happened at the top of the tier where
    //     names are most valuable.
    //
    // ORDER IS PART OF THE FIX. These run AFTER the walk, never before, because
    // R9-2's diagnosis property — "the FLOOR runs before the TIER", so
    // `checkName('tonkeeper', 9)` answers 462 (not an emoji) rather than 435 (too
    // many emoji) — is pinned by tests/R9NamespaceFloor.spec.ts and is the reason
    // an integrator's error message says something true about the name.
    //
    // No new error codes: 412 / 435 are what `Reveal` and `AdminMint` already
    // raise for a tier out of bounds, and 460 is what `checkUriSuffix` already
    // raises for content the chain will not carry. CHECK_NAME_ERRORS grows to
    // {412, 435, 440, 450, 451, 456, 457, 460, 462, 463}.
    assert(emojiCount >= 1) throw ERR_BAD_EMOJI_COUNT;
    assert(emojiCount <= MAX_EMOJI_COUNT) throw ERR_TOO_MANY_EMOJI;

    // Mirror of `encodeUriSuffix` in wrappers/EmojiRegistrarV4.ts: every byte is
    // itself except `#` (0x23), `?` (0x3F) and — R20-6 — every byte >= 0x80,
    // which become three (`%23`, `%3F`, `%F0` …). `?` is unreachable in a name
    // after R9-2 and is counted anyway so the two implementations cannot drift on
    // the day the whitelist changes.
    //
    // R20-6: the ceiling is the CHAIN's, not one cell's. It was `<= 1023`, which
    // under full encoding would refuse every name over 42 raw bytes — including
    // any two tag-sequence flags, which are perfectly ordinary names. The whole
    // point of this assert is unchanged: refuse a name whose suffix cannot be
    // BUILT before the user pays for a Commit on a reveal that can never be
    // constructed (R11-4). It just has three cells to build into now.
    var uriS = rawName.beginParse();
    var encodedBits = 0;
    while (uriS.remainingBitsCount() >= 8) {
        val ub = uriS.loadUint(8);
        encodedBits += (ub == 0x23 || ub == 0x3F || ub >= 0x80) ? 24 : 8;
    }
    assert(encodedBits <= URI_CELL_BITS * URI_MAX_CELLS) throw ERR_BAD_CONTENT;
    return emojiCount;
}

/// R23-6. A MISS IS AN ANSWER, NOT A FAILURE.
///
/// This was the ONE keyed getter in the contract that threw on an absent name.
/// Every sibling returns a miss cleanly — `expiryOf` 0, `emojiCountOf` 0,
/// `syncNonceOf` 0, `isPermanent` false, `auctionOf` nulls — and the NFT item
/// states the house rule outright: "a getter which throws on a legitimate state
/// is a getter that removes the whole contract from an indexer's view".
///
/// `ownerOf` is among the first calls any wallet, explorer or marketplace makes,
/// and an unregistered name is the most ordinary state a name can be in. A client
/// batching `ownerOf` across a name list got a hard exit 407 on the first
/// unregistered entry and lost the whole batch. Measured pre-fix: `ownerOf` of an
/// absent hash, of 0, of 2^256-1 and of -1 all exit 407.
///
/// Returns `addr_none` for a miss, matching the item's own `ownerOrNone`
/// convention. `isRegistered` already carries the presence signal for any caller
/// that wants to distinguish "unregistered" from "owned by nobody" — and nothing
/// can be owned by `addr_none`, since every issuance path writes a real address.
get fun ownerOf(nameHash: uint256): address? {
    val f = loadStorage().names.get(nameHash);
    if (!f.isFound) { return null; }
    return f.loadValue().owner;
}



/**
 * R14-AVAIL. THE GETTER MUST ANSWER THE QUESTION THE FRONT END IS ASKING.
 *
 * This read only `names`, never `auctions` — so a single with a LIVE lot, listed
 * and possibly already bid on, reported `isAvailable = true`. Found by the
 * invariant fuzzer in a single operation: `StartAuction` alone, with no
 * registration anywhere, flipped the exclusivity invariant on its first step.
 *
 * Nothing can be double-sold — `Reveal` independently refuses a name with a live
 * lot (ERR_AUCTION_EXISTS, and since R10-1 it refunds rather than throws, so the
 * buyer loses under 0.05 GRAM) — which is precisely why this survived nine rounds
 * of adversarial testing that all asked "can I steal a name". The damage is to
 * everyone who trusts the getter:
 *
 *   - `docs/FRONTEND_TOUCHPOINTS.md` tells integrators to gate the Buy button on
 *     it, so the UI offers a name that is mid-auction and the click always fails.
 *   - its §12 operator query — `isAvailable(h) && emojiCountOf(h) == 1` — is
 *     documented as "singles awaiting re-listing" and returns the singles that
 *     are ALREADY listed, i.e. exactly the wrong set.
 *
 * `hasAuction()` stays as it is: that getter reports a raw fact, this one reports
 * a policy, and the policy is "can the public register this right now".
 */
get fun isAvailable(nameHash: uint256): bool {
    val st = loadStorage();
    // F-1: a name with a live auction lot is NOT publicly registrable. Same rule
    // the Reveal handler enforces, and it must be readable before the user pays.
    if (st.auctions.get(nameHash).isFound) { return false; }
    val r = st.names.get(nameHash);
    // R17-5: at the soft cap a name this registry has never seen is not available
    // — `Reveal` will refuse it with 434 — and this getter said `true` anyway.
    // It is the number a front end quotes a price against, so it has to know. A
    // name that IS already here falls through to the term rules below: the cap
    // bounds new cells, not re-registration.
    if (!r.isFound) { return (st.totalNames as int) < NAMES_SOFT_CAP; }
    val rec = r.loadValue();
    if (rec.isPermanent) { return false; }
    return blockchain.now() >= (rec.expiresAt + GRACE);
}

get fun isPermanent(nameHash: uint256): bool {
    val r = loadStorage().names.get(nameHash);
    if (!r.isFound) { return false; }
    return r.loadValue().isPermanent;
}

// true = every buy-side price is frozen forever
get fun pricesLocked(): bool {
    return loadStorage().cfg().prices.load().pricesLocked;
}

get fun permanentPrice(): int {
    return loadStorage().cfg().prices.load().permanentPrice;
}

get fun inGracePeriod(nameHash: uint256): bool {
    val r = loadStorage().names.get(nameHash);
    if (!r.isFound) { return false; }
    val rec = r.loadValue();
    if (rec.isPermanent) { return false; }
    val nowTime = blockchain.now();
    return nowTime >= rec.expiresAt && nowTime < (rec.expiresAt + GRACE);
}

/**
 * V7-34. Returns 0 for a single rather than a price that does not exist.
 *
 * `firstYearPrice` falls through to the Common tier for anything outside 2..5,
 * so this getter used to answer 1.5 GRAM for a 1-emoji name — a name whose only
 * door is an auction with a 150 GRAM reserve. PRICING.md tells integrators
 * "never hardcode, call priceRegister()", so the getter was handing every
 * front end a buy button priced at half a percent of the floor.
 */
get fun priceRegister(emojiCount: int, numYears: int): int {
    if (emojiCount < 2 || emojiCount > MAX_EMOJI_COUNT) { return 0; }
    // R10-3: bound numYears too. Unvalidated, `priceRegister(2, -1000)` returned
    // -9,990 GRAM and a huge value threw exit 4 (integer overflow) instead of a
    // usable answer. Registration itself already bounds 1..MAX_YEARS, so a quote
    // outside that range is never actionable.
    if (numYears < 1 || numYears > MAX_YEARS) { return 0; }
    return registerCost(loadStorage().cfg().prices.load(), emojiCount, numYears);
}

/**
 * R13-1. The MECHANICAL cost of one registration, on top of `priceRegister`.
 *
 * A reveal must carry `priceRegister(...) + registerOpsBudget(nameBytes)` at
 * minimum; anything above that is refunded. This covers the mint value sent to
 * the collection, the resolver fan-out (zero resolvers in the shipping config),
 * the partner forwarding fees, and — the part that used to be missing — this
 * contract's own compute, which is proportional to the name's byte length.
 *
 * Quote it rather than hardcoding: it moves when a resolver is added, and the
 * per-byte term means a 3-codepoint ZWJ family costs more to process than a
 * two-emoji name. `nameBytes` is the UTF-8 length of the CANONICAL form — the
 * same bytes you put in `rawName`, not the length of what the user typed.
 */
get fun registerOpsBudget(nameBytes: int): int {
    if (nameBytes < 0 || nameBytes > MAX_NAME_BYTES) { return 0; }
    val cfgQ = loadStorage().cfg();
    return opsBudgetRegister(countResolvers(cfgQ.resolvers), cfgQ.nftCollection != null)
         + nameBytes * REGISTER_COMPUTE_PER_BYTE;
}

/**
 * R10-3. THE OTHER HALF OF V7-34.
 *
 * V7-34 fixed `priceRegister` to return 0 outside 2..MAX_EMOJI_COUNT, because
 * `firstYearPrice` falls through to the Common tier and "the getter was handing
 * every front end a buy button priced at half a percent of the floor". The
 * identical fall-through in `renewYearPrice` was left in this getter: tiers 0, 8,
 * 9 and -1 all answered 0.75 GRAM — the Common rate — for names that do not exist.
 * Negative `numYears` returned a NEGATIVE price. PRICING.md tells integrators
 * "never hardcode, call priceRenew()", so these are the numbers front ends show.
 *
 * Tier 1 IS valid here (auction winners renew singles at the flat RENEW_1), which
 * is the one place this getter's domain legitimately differs from priceRegister's.
 */
get fun priceRenew(emojiCount: int, numYears: int): int {
    if (emojiCount < 1 || emojiCount > MAX_EMOJI_COUNT) { return 0; }
    if (numYears < 1 || numYears > MAX_YEARS) { return 0; }
    return renewCost(emojiCount, numYears);
}

/// (p2, p3, p4, p5, p67) — Legendary, Epic, Rare, Uncommon, Common
get fun firstYearPrices(): (int, int, int, int, int) {
    val p = loadStorage().cfg().prices.load();
    return (p.p2, p.p3, p.p4, p.p5, p.p67);
}

get fun adminAddress(): address {
    return loadStorage().admin;
}

get fun feeDestination(): address {
    return loadStorage().cfg().feeDestination;
}

get fun signerKey(): int {
    return loadStorage().cfg().signerPublicKey;
}

get fun totalNames(): int {
    return loadStorage().totalNames;
}

get fun nftCollection(): address? {
    return loadStorage().cfg().nftCollection;
}

// hash of the canonical normalization spec the signer is authorised to apply
get fun normalizationPolicy(): (int, bool) {
    val pol = loadStorage().cfg().prices.load();
    return (pol.normalizationPolicyHash, pol.policyLocked);
}

get fun maxEmojiCount(): int {
    return MAX_EMOJI_COUNT;
}

/// F-9: byte budget a name must fit so it stays resolvable under TEP-81.
get fun maxNameBytes(): int {
    return MAX_NAME_BYTES;
}

/// true = the migration door is shut forever; AdminImport can never run again.
get fun importsLocked(): bool {
    return loadStorage().cfg().prices.load().importsLocked;
}

/// the maximum total term any name may hold, measured from now (F-2).
get fun maxTotalTerm(): int {
    return MAX_TOTAL_TERM;
}

// true = the namespace length can never change again

get fun version(): int {
    return CONTRACT_VERSION;
}

// Skin-tone policy, ENFORCED IN TVM and permanent (no setter exists).
// 1 = skin-toned names can never be minted; ZWJ sequences remain distinct.
get fun skinTonePolicy(): int {
    return NORMALIZATION_POLICY;
}

// one-call metadata for integrators/auditors: everything self-describing
get fun contractInfo(): (int, int, int, int, int, int, int) {
    val st = loadStorage();
    val c = st.cfg();
    return (
        CONTRACT_VERSION,
        st.totalNames,
        st.totalRegistrations,
        st.totalRenewals,
        c.referralBps,
        st.adminTimelock,
        MAX_EMOJI_COUNT
    );
}

// provable traction: cumulative net fees + lifetime counts
get fun traction(): (int, int, int, int) {
    val st = loadStorage();
    return (st.totalRevenue, st.totalNames, st.totalRegistrations, st.totalRenewals);
}

// (bps, address) — address null when no partner deal is active
/** combined partner share in bps, and how many partners hold it */
get fun partnerShare(): (int, int) {
    val pp = loadStorage().cfg().prices.load();
    var total = 0;
    var n = 0;
    var e = pp.partners.findFirst();
    while (e.isFound) { total += e.loadValue().bps as int; n += 1; e = pp.partners.iterateNext(e); }
    return (total, n);
}

/** one partner's share in bps (0 if not a partner) */
/// R23-7. `addr_none` IS A FIRST-CLASS ADDRESS AND MUST NOT UNDERFLOW.
///
/// `getWorkchainAndHash()` reads a workchain and a 256-bit hash, so it throws
/// cell-underflow (exit 9, uncatalogued) on `addr_none$00` — which is a legal
/// `MsgAddress` arm and is exactly what `pendingAdmin()` returns as its null. A
/// client that round-trips one of this contract's own getter outputs back into
/// another of its getters got exit 9. Measured pre-fix on both this and
/// `referrerRate`.
///
/// 0 is the correct answer on its merits: `addr_none` is not a registered partner
/// and never can be, so its share is zero.
/// Declared `any_address` on purpose: the parameter's DECLARED type does not
/// constrain what a caller actually pushes, so typing it `address` only hid the
/// arm that underflows. Accepting the wider type is what makes the guard
/// expressible at all, and it does not change the ABI a well-formed caller sees.
get fun partnerBpsOf(partner: any_address): int {
    if (!partner.isInternal()) { return 0; }
    val pp = loadStorage().cfg().prices.load();
    val (_wc, h) = partner.getWorkchainAndHash();
    val f = pp.partners.get(h);
    if (!f.isFound) { return 0; }
    return f.loadValue().bps;
}

/// R24-4: staged state must be readable, or the handshake buys no warning time —
/// the same rule R7-11 applied to every other staged field in this system. A
/// deploy script, a monitor or an operator can see exactly which pointer is
/// waiting for its acknowledgement, and `nftCollection()` still reports the live
/// one (null while unconfirmed).
get fun pendingNftCollection(): address? {
    return loadStorage().auxData().pendingNftCollection;
}

/// R24-5: the account's own cell budget, reported rather than merely enforced.
///
/// Follows the arc getgems took between auction v3r3 and v4r1 — v3r3 THREW at
/// tooling when its config was unsound, v4r1 REPORTS the same condition as a
/// getter field and throws only where money is at stake. A monitor can alarm on
/// `used` approaching `ceiling` weeks before any user sees a refusal, and the
/// three population counts make it obvious WHICH one is growing.
///
/// (used, ceiling, hardWall, names, commitments, lots)
get fun stateBudget(): (int, int, int, int, int, int) {
    val st = loadStorage();
    return (estimatedStateCells(st), STATE_CELL_CEILING, MAX_ACC_STATE_CELLS,
            st.totalNames, st.auxData().liveCommitments, st.liveLots);
}

get fun referralBps(): int {
    return loadStorage().cfg().referralBps;
}

// effective rate a given referrer would earn (their override, else public rate)
/// R23-7 sibling — see partnerBpsOf. An `addr_none` argument underflowed here too.
/// Answering with the PUBLIC rate rather than 0: an unknown referrer already falls
/// back to `cfg.referralBps` in `effectiveReferralBps`, and `addr_none` is simply
/// an unknown referrer, so this keeps the getter's contract ("what rate would this
/// address get") uniform instead of inventing a second meaning for one arm.
get fun referrerRate(referrer: any_address): int {
    val c = loadStorage().cfg();
    if (!referrer.isInternal()) { return c.referralBps; }
    val (_wc, refHash) = referrer.getWorkchainAndHash();
    return effectiveReferralBps(c.referrerRates, c.referralBps, refHash);
}


get fun pendingAdmin(): address? {
    return loadStorage().pendingAdmin;
}

/**
 * V7-33. These two must report the timelock that will ACTUALLY be in force, not
 * the one currently stored.
 *
 * V7-19b made a DECREASE of adminTimelock itself wait out the old timelock, so
 * between staging and maturity the stored value is the OLD one while the pending
 * value is what will apply. Both getters read the stored field, so a monitor
 * watching `adminTransferReadyAt()` after an admin had staged a decrease from
 * 48h to 1h was told the takeover completed 47 hours later than it does. The
 * mitigation is only worth what the alarm on it is worth.
 */
fun effectiveTimelock(st: Storage, nowTime: int): int {
    if (st.pendingTimelockAt != 0 && nowTime >= (st.pendingTimelockAt as int)) {
        return st.pendingTimelock;
    }
    return st.adminTimelock;
}

get fun adminTransferReadyAt(): int {
    val st = loadStorage();
    if (st.pendingAdmin == null) { return 0; }
    return st.pendingAdminAt + effectiveTimelock(st, blockchain.now());
}

get fun adminTimelock(): int {
    val st = loadStorage();
    return effectiveTimelock(st, blockchain.now());
}

/** V7-33: the staged value and when it lands. (0, 0) when nothing is staged. */
get fun pendingAdminTimelock(): (int, int) {
    val st = loadStorage();
    return (st.pendingTimelock, st.pendingTimelockAt);
}

/**
 * V7-33. The staged signer key and its maturity. V7-30's whole rationale is that
 * "the staged key is public for that whole window" — which is only true if it
 * can be read. (0, 0) when nothing is staged.
 */
get fun pendingSigner(): (int, int) {
    val aux = loadStorage().auxData();
    return (aux.pendingSigner, aux.pendingSignerAt);
}

/**
 * V7-33. F-12's stale-sync defence keys on this nonce, and nothing exposed it,
 * so neither an indexer nor a relay could tell a stale OwnerSynced from a live
 * one before sending it. Returns 0 for an unknown name.
 */
get fun syncNonceOf(nameHash: uint256): int {
    val r = loadStorage().names.get(nameHash);
    if (!r.isFound) { return 0; }
    return r.loadValue().syncNonce;
}

// live auction state: (highBidder, highBid, startBid, endsAt, numYears)
get fun auctionOf(nameHash: uint256): (address?, int, int, int, int) {
    val f = loadStorage().auctions.get(nameHash);
    if (!f.isFound) {
        return (null, 0, 0, 0, 0);
    }
    val a = f.loadValue();
    return (a.highBidder, a.highBid, a.startBid, a.endsAt, a.numYears);
}

// 0 = listed but no bid yet (clock not started)
get fun auctionEndsAt(nameHash: uint256): int {
    val f = loadStorage().auctions.get(nameHash);
    if (!f.isFound) { return 0; }
    return f.loadValue().endsAt;
}

get fun hasAuction(nameHash: uint256): bool {
    return loadStorage().auctions.get(nameHash).isFound;
}

// what the next bid must be (start bid if unbid, else high +5%)
get fun minNextBid(nameHash: uint256): int {
    val f = loadStorage().auctions.get(nameHash);
    if (!f.isFound) { return 0; }
    val a = f.loadValue();
    if (a.highBidder == null) { return a.highBid; }
    val h = a.highBid as int;
    return h + (h * MIN_RAISE_BPS / BPS_DENOM);
}

get fun commitTiming(): (int, int) {
    val c = loadStorage().cfg();
    return (c.commitMinDelay, c.commitMaxAge);
}

// timestamp of a commitment (0 if none) — lets clients check readiness
get fun commitmentAt(commitment: uint256): int {
    val f = loadStorage().auxData().commitments.get(commitment);
    if (!f.isFound) { return 0; }
    return f.loadValue();
}

// F-5: what admin may safely withdraw right now (balance minus live bidder
// escrow minus the rent floor). Read this before every WithdrawFees.
get fun freeBalance(): int {
    val st = loadStorage();
    // V7-1: must agree with the WithdrawFees check exactly, including the
    // resolver fan-out reserve. A getter that over-reports is worse than none:
    // ops read this number and withdraw it.
    //
    // R14B1-14: and including the per-name rent reserve. This getter IS the
    // finding — MIGRATION_RUNBOOK step 4 says "withdraw only `freeBalance()`", so
    // whatever this over-reports is exactly what leaves the account. Before the
    // per-name term, at 10,000 names it over-reported by ~16 GRAM and the account
    // froze on day 56; at 32,000, on day 21, unrecoverably (a later 50 GRAM
    // top-up did not thaw it). Agreement with WithdrawFees is pinned to +/-1
    // nanoton in tests/R14Batch1Fixes.spec.ts.
    return freeBalanceOf(st, 0);
}

// R17-6: a field read, not a walk. This getter used to cross TVM's 1M gas read
// limit at ~890 live lots and simply stop answering; an indexer polling solvency
// then sees an exception rather than a number, at exactly the inventory level
// where solvency is worth watching.
get fun totalEscrowedBids(): int {
    return loadStorage().escrowedTotal as int;
}

// R17-6: the companion count, published for the same reason — an operator
// checking why `freeBalance()` is low should be able to read the two reserve
// drivers (lots and names) directly rather than inferring them.
get fun liveAuctionCount(): int {
    return loadStorage().liveLots as int;
}

get fun resolverCount(): int {
    return countResolvers(loadStorage().cfg().resolvers);
}
