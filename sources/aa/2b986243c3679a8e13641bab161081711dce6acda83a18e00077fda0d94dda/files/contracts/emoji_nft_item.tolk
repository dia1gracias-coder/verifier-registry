// emoji_nft_item.tolk — TEP-62 NFT item for one emoji name
// Emoji Name Service · P1 NFT layer · Tolk 1.4.2
//
// Emojiverse · Emoji Name Service on TON
//   Website : https://emojiverse.xyz
//   X       : https://x.com/emojiverse_xyz
//   Zone    : emojiverse.ton   ·   Publisher: Hyperborea LLC
//
// The item IS the user-facing ownership object for a registered emoji name.
// index = nameHash (sha256 of the normalized emoji string) — deterministic
// address per name, .ton-domains style. One item per name, forever; a
// re-registration after grace REASSIGNS the same item instead of minting a
// new one.
//
// Rights & stipulations carried on-chain by the item:
//   - owner            — TEP-62 ownership; transfer conveys the name + remaining term
//   - expiresAt        — the rental term (0 = never expires; reserved singles)
//   - isReserved       — foundation-reserved single emojis: NON-transferable
//   - GRACE            — transfers allowed through expiry + 90d grace (renewal
//                        right conveys with the item, ENS-consistent)
//   - content          — TEP-64 individual content (emoji string suffix, or the
//                        reservation note for reserved singles)
//
// Trust model: the item trusts ONLY its collection. Mint/reassign and expiry
// updates arrive from the collection (which itself trusts the registrar as
// minter). On every successful transfer the item notifies the collection,
// which relays OwnerSynced to the registrar so the registry of record follows
// the NFT.

// ===========================================================================
// R12 — RECORDS LIVE HERE NOW (the .ton architecture)
// ===========================================================================
// Records used to live in ONE shared resolver contract keyed by labelHash, so
// that contract grew with the namespace — and TON caps an account's state at
// 65,536 cells. A hashmap with 256-bit keys is a Patricia trie: N leaves plus
// N-1 branch nodes, i.e. ~2 cells per entry REGARDLESS of value size (measured
// 1.998 cells/entry for an 8-bit value and for a 348-bit one, so shrinking the
// record could never have helped). A resolver entry carrying one wallet record
// measured 4 cells, putting a hard ceiling near 16,000 names on the product's
// core function. The failure mode was silent: past the ceiling a registration
// SUCCEEDED while dnsresolve answered NOT FOUND, because the abort happens in
// the ACTION phase, where there is nothing left to bounce and no compute error
// for refundAndStop to catch.
//
// `.ton` has no such ceiling because it keeps NO per-name state in any shared
// contract. Every domain is an NFT item at an address derived from its name, and
// that item holds its own records and answers `dnsresolve` for itself; the
// collection is a router that consumes the label and hands out the item address.
//
// This item now does the same. Per-name state moves from one shared account into
// one account PER NAME, so the namespace is bounded by the blockchain rather than
// by any single contract, and each holder pays rent on their own record.
//
// Scope note: the registrar's `names` map is a SEPARATE trie and still caps
// around 32.6k (AUDIT_R10_R11.md R11-1). This removes the LOWER of the two
// ceilings and is the prerequisite for ever removing the other.
//
// Two properties are preserved exactly, because they are the security model:
//   - a SOLD name never resolves to the seller  (records wiped on transfer)
//   - a LAPSED name stops resolving             (refused past expiry + grace)
// Both are now enforced locally by the contract that owns the data, which is
// strictly stronger than a cross-contract push that could be silently dropped.

tolk 1.4

import "@stdlib/tvm-dicts"

const GRACE_PERIOD = 7776000;        // 90 days, must match registrar

// ---- record bounds (mirrored from emoji_resolver_v2: same numbers, same reasons)
// V7-5: root-cell checks bound only the root, so the WHOLE tree is measured with
// CDATASIZE. V7-22: the NUMBER of categories is bounded too. These matter less
// here than in the shared resolver — a holder can now only bloat their OWN item,
// whose rent they pay — but they are kept so that no single name can grow its
// item toward the account ceiling.
const MAX_RECORD_BITS = 1023;
const MAX_RECORD_REFS = 4;
const MAX_RECORD_CELLS = 4;
const MAX_RECORD_TOTAL_BITS = 4092;   // 4 x 1023
// R23-9. THE RECORD BOUNDS WERE UPPER BOUNDS ONLY, AND THE SHAPE THIS FILE
// DOCUMENTS AS "MUST NEVER BE EMITTED" WAS ONE MESSAGE AWAY.
//
// Every DNSRecord arm in TEP-81 opens with a 16-bit constructor tag —
// `dns_smc_address#9fd3`, `dns_next_resolver#ba93`, `dns_adnl_address#ad01`,
// `dns_storage_address#7473`, `dns_text#1eda`. A value shorter than the tag
// cannot be any of them, so it cannot be a record at all.
//
// Nothing enforced a MINIMUM, so `beginCell().endCell()` — 1 cell, 0 bits —
// satisfied all five upper bounds and was stored. `dnsresolve` then returned it
// two ways: as `(bits, <empty cell>)` for the specific category, and as a leaf
// ref inside the category-0 record set. The invariant note further down this
// file argues that shape "is unrepresentable here" for two reasons — the
// `records == null` early return, and `uDictDelete` nulling the last entry. Both
// are about the dict ROOT. Neither constrains a record VALUE.
//
// The cost lands on readers, not on us: a strict `Hashmap 256 ^DNSRecord`
// unmarshal fails on the whole SET, so one 0-bit record poisons the name's
// `wallet` record too, and the reference indexer answers HTTP 500 rather than
// 404 for that name. One message makes a name's DNS endpoint error instead of
// resolve, and only the owner who wrote it can undo it.
//
// 16 bits is the tag width — the weakest bound that is still principled. It
// refuses nothing a real client writes, and deleting a record remains the
// supported way to clear one (`record: null`), which is what the empty cell was
// being mistaken for.
const MIN_RECORD_BITS = 16;
const MAX_CATEGORIES_PER_NAME = 8;
// V7-1: this funds the ENTIRE item -> collection -> registrar -> N resolvers
// chain, and it was a FIXED constant in a contract that cannot know how many
// resolvers the registrar has. Benched at 0.06 it covered exactly ONE resolver;
// at two the registrar subsidised every transfer from its own balance, and at
// four the transfer failed in the action phase and silently left the registry
// and every resolver pointing at the SELLER while the buyer held the NFT.
//
// A constant can never cover an unbounded N, so it is now a FLOOR, and the
// relay forwards whatever surplus the sender actually provided, up to a cap.
// The sender can therefore fund a large fan-out simply by sending more, while
// the cap stops a marketplace that routinely sends 1 GRAM from donating the
// difference to the protocol — the excess still returns via responseDestination.
//
// V7-1b: the FLOOR must fund the registrar's MAXIMUM fan-out, not one resolver.
// At 0.06 against MAX_RESOLVERS=8 a sale funded at the item's own asserted
// minimum synced 2 of 8 resolvers and left 6 answering with the SELLER — exit 0,
// no bounce, nothing recorded. IGNORE_ERRORS turned a loud failure into a quiet
// one, which is only an improvement if the funded path is actually funded.
// 0.16 covered MAX_RESOLVERS = 3 across all three hops with headroom.
//
// This is the belt. The braces are IGNORE_ERRORS on the registrar's resolver
// fan-out (so a shortfall skips one resolver instead of reverting the registry
// write) and the withdrawal reserve in freeBalance().
//
// R20-1 (LAUNCH BLOCKER). 0.16 + 0.05 IS A 0.21 GRAM TRANSFER FLOOR, AND NO
// WALLET IN THE ECOSYSTEM SENDS THAT MUCH.
//
// The value a holder's wallet attaches to an NFT transfer is a hardcoded
// constant with no user override and no per-collection hook. Read at source
// 2026-08-11:
//
//   tonkeeper-web  packages/core/src/service/ton-blockchain/encoder/nft-encoder.ts
//                  nftTransferBase = toNano('0.05')
//   mytonwallet    src/api/chains/ton/constants.ts
//                  NFT_TRANSFER_AMOUNT = 100_000_000n   (0.1)
//
// R19/T7 measured the practical minimum against the 0.16 + 0.05 floor at
// 0.21001 GRAM: Tonkeeper is 4.2x short and MyTonWallet 2.1x short, and BOTH
// get exit 412. A holder could not send their own name from either wallet, and
// a seller could not even list on GetGems (T8: the LISTING leg is sent by the
// seller's wallet at the wallet's amount; only the sale contract's own legs,
// at ~1 GRAM, cleared it). "Use our website to move your name" is the thing
// that stops a name being an asset, so the floor had to come to the wallets.
//
// WHAT 0.16 WAS BUYING, AND WHY IT IS NOT NEEDED. V7-1b sized it to fund
// MAX_RESOLVERS = 3 end-to-end. The shipping configuration has ZERO resolvers:
// `scripts/deployPlan.ts` ships `resolvers: []`, `README_BACKEND.md` says "Do
// not AddResolver", and preflight D-1 is a FAIL if `resolverCount() != 0` —
// because R12 moved records INTO this item and the shared resolver is legacy.
// So 4.2x of every holder's transfer floor was funding a fan-out the project
// has already decided never to switch on.
//
// 0.02 + 0.02 = a 0.04 floor, measured in audit/round20/wallets:
//   - the item -> collection -> registrar relay completes with 0 skipped
//     actions and the registry follows, at every wallet value including the
//     bare floor;
//   - the registrar is net non-negative on the OwnerSynced transaction at
//     resolverCount() == 0.
//
// AT resolverCount() == 3 THE FLOOR NO LONGER FUNDS THE FAN-OUT, and this is
// stated rather than hidden: the relay still delivers and all three resolvers
// still bind, because `syncAllResolvers` sends PAY_FEES_SEPARATELY and
// therefore draws the shortfall from the REGISTRAR'S OWN BALANCE rather than
// skipping — which is the subsidy V7-1's own note describes, bounded by the
// `SYNC_RESERVE_TRANSFERS` withdrawal reserve that exists for it. Nothing goes
// silently unsynced; the registrar simply pays. A deployment that genuinely
// wants resolvers must either raise this constant (new item code, new item
// addresses) or accept the measured per-transfer subsidy. Measured both ways
// in audit/round20/wallets/W3_relay_solvency.spec.ts.
const NOTIFY_VALUE = 20000000;       // 0.02 GRAM floor — item -> collection -> registrar
// R20-2 (TEP-62 §1.3). 0.4 GRAM IS EXACTLY basechain `max_tx_gas_price`, SO THE
// RELAY ATE THE WHOLE ALLOWANCE.
//
// §1.3 is the one MUST in TEP-62 whose satisfaction is arithmetic: the item
// "must send at least in_msg_value - forward_amount - max_tx_gas_price" to
// response_destination. ConfigParam 21 basechain gas_limit 1,000,000 at 400
// nanoton/gas is 0.4 GRAM, and NOTIFY_MAX was that number exactly — so a capped
// relay consumed the entire allowance and this item's own compute and forward
// fees spilled past it. R19/T1 measured the shortfall at 796,402 nanoton, at
// every value where the relay caps. The reference nft-item.fc has no relay and
// so never meets this edge.
//
// 0.39 leaves 0.01 GRAM of allowance for the compute and forward fees, which is
// 12.6x the measured overrun. It costs the relay 2.5% of a ceiling that is only
// reached when a sender attaches >= 0.41 GRAM, and the surplus goes home in the
// excesses instead of down the chain.
//
// =============================================================================
// R23 (HIGH, value). `max_tx_gas_price` IS NOT 0.4 GRAM. IT HAS BEEN 0.0667
// SINCE 2026-04-29, AND THIS CONSTANT WAS DEFINED AGAINST IT.
// =============================================================================
//
// The paragraph above sizes this constant as "one hundredth under basechain
// max_tx_gas_price", and max_tx_gas_price is not a number — it is
// `gas_limit x gas_price` out of ConfigParam 21. Basechain gas was cut exactly 6x
// on 2026-04-29, so:
//
//   schedule                       max_tx_gas_price = gas_limit 1,000,000 costs
//   pessimistic (pre-2026-04-29)   0.400000000   <- what R20-2 sized 0.39 against
//   LIVE (today)                   0.066666672
//
// TEP-62 §1.3 requires the item to send at least
// `in_msg_value - forward_amount - max_tx_gas_price` to response_destination, so
// a CHEAPER chain makes §1.3 STRICTER. This is the one constraint in the system
// that tightens when fees fall, which is why the fee cut broke it silently and
// why R23 measures every value flow on both rows rather than the worse one.
//
// Measured on this build, a wallet-shaped transfer with forward_amount 0:
//
//   in        relay      excesses      §1.3 floor    slack (LIVE row)
//   0.05      0.020000   0.036878      -0.016667     +0.053544
//   0.10      0.080000   0.036878      +0.033333     +0.003544   <- MyTonWallet, by a hair
//   0.20      0.180000   0.036878      +0.133333     -0.096456
//   1.00      0.390000   0.626875      +0.933333     -0.306458   <- GetGems' own sale leg
//
// The same rows at the pessimistic schedule are all positive (worst +0.011250),
// which is R20-2's result and is what T1/W3 have been asserting — against a
// hard-coded `maxTxGasPrice = 400000000n`, a mirror of a chain constant, which is
// the R23 bug class exactly.
//
// IT IS NOT ONLY A CONFORMANCE POINT. The value does not evaporate: it goes down
// the relay to the collection and on to the registrar, which at the shipping
// resolverCount() of 0 simply banks it. So on today's chain every transfer
// carrying more than ~0.09 GRAM quietly routes up to 0.373 GRAM of the SENDER's
// money into our own contract instead of returning it — and the sale contract
// GetGems uses sends 1 GRAM per leg.
//
// 0.05 IS DERIVED FROM THE LIVE ROW THE SAME WAY 0.39 WAS DERIVED FROM THE OLD ONE:
//
//   max_tx_gas_price (live)              0.066666672
//   the item's own compute + fwd fee     0.001022 measured live (0.005846 pessimistic)
//   allowance left by 0.05               0.016667  = 16.3x that overhead
//                                                    (R20-2's 0.39 left 12.6x)
//
// and the relay is BETTER funded in the only case that spends it. Measured at
// MAX_RESOLVERS = 3, the registrar's net position on the OwnerSynced transaction:
//
//   relay value   live row     pessimistic row
//   0.02 (floor)  -0.017682    -0.026091     (the documented V7-1 subsidy)
//   0.05 (new)    +0.012318    +0.003659     self-funding on BOTH rows
//   0.39 (old)    +0.352235    +0.343159     the sender overpaying by ~0.34
//
// All three resolvers bind at every one of those values — the fan-out was never
// short, only the registrar's reimbursement was — so lowering the ceiling costs
// no functionality and makes the 3-resolver configuration pay for itself.
//
// HEADROOM, STATED IN THE UNIT THAT MOVES IT. §1.3 binds again if
// max_tx_gas_price falls below relay + own gas = 0.051, i.e. after a FURTHER 1.31x
// cut to basechain gas. A revert to the pessimistic row moves max_tx_gas_price the
// other way (0.4) and is a non-event: 7.2x. If TON cuts gas again, this is the
// constant to re-derive, and audit/round23 is the file that will say so.
const NOTIFY_MAX   = 50000000;       // 0.05 GRAM ceiling (R23; was 0.39 against a 0.4 max_tx_gas_price)
const MIN_TRANSFER_GAS = 20000000;   // 0.02 GRAM headroom for transfer processing
// V7-15: the item's own rent floor. It must never fund a transfer out of this.
//
// R25-3 (MEDIUM) PROPOSED RAISING THIS TO 0.116, AND IT IS DELIBERATELY LEFT AT
// 0.05. The finding's arithmetic is CORRECT and its fix is REFUSED — read both
// halves before touching this line, because the reason is not in the finding.
//
// What R25-3 measured is true. Re-measured here on this build, on the
// pessimistic param-18 row (bit 1 / cell 500), with freeze_due_limit 0.1 read
// out of config 21 (audit/round25/R25A_rent_coupling.spec.ts,
// audit/round25/R25A_transfer_floor.spec.ts):
//
//   bare issued item            46 cells / 18,567 bits -> 0.020002 GRAM/yr
//   marginal maximal record     ~5.9 cells / ~4,357 bits -> 0.003510 GRAM/yr
//   8 maximal records           93 cells / 53,421 bits -> 0.048082 GRAM/yr
//
// so at this floor's OWN value the freeze horizon is (0.05 + 0.1) / 0.020002 =
// 7.50 y with no records, inside a term the registrar sells for 10. The comment
// this replaces implied otherwise. (`RECORD_RENT_RESERVE` 0.035 against a
// measured 0.03510 of ten-year marginal rent is 0.3% short — 11 days on one
// record, against a 0.1 GRAM freeze buffer. Also left alone, for the same
// reason as below plus its own irrelevance.)
//
// WHY THE RAISE IS REFUSED: THIS CONSTANT HAS TWO CONSUMERS AND THE FINDING
// PRICED ONE.
//
//   applyRecordWrite  assert getOriginalBalance() >= this + n * RECORD_RENT_RESERVE
//   AskTransfer       keep = clamp(held, this + keptRecords * RECORD_RENT_RESERVE,
//                                  ITEM_FULL_RENT), reserved EXACT_AMOUNT
//
// The second is a RAWRESERVE. Raising the floor above what an item HOLDS does
// not refuse the transfer — it fails the ACTION PHASE. And an item's balance
// falls on its own: `ITEM_FULL_RENT` is sized so a maximal item is nearly spent
// at the end of a ten-year term, which is R22-1's 11.687 y horizon working as
// designed. Measured consequence of raising this to 0.116:
//
//   a NORMAL item — front door, funded 0.48, holding 8 maximal records —
//   crosses 0.116 after 7.57 YEARS, inside its own paid term, and from that
//   point a sale carrying a wallet's standard 0.05 (and even 0.1) dies with
//   ACTION CODE 37, compute exit 0, aborted, OWNERSHIP UNCHANGED.
//
// Exit 0 with no ownership move is what a marketplace reads as success. That is
// a worse failure than the one R25-3 set out to fix — a freeze at year 9 that
// ANY stranger can cure with a plain-GRAM top-up — and it lands on the
// mainstream path rather than on a repair cohort.
//
// SO THE SHORTFALL WAS FIXED AT ITS SOURCE INSTEAD. Every cohort that could sit
// near this floor was funded properly rather than fenced off from it:
//   * registrar-issued items already arrive at ITEM_FULL_RENT (0.48) and
//     `AskTransfer`'s clamp carries that across every sale;
//   * R25-4 deleted the `AdoptItem` funding split, so a REPAIRED item now
//     arrives at ITEM_FULL_RENT too (was 0.078 / 9.41 y);
//   * what is left is an item minted thin through the COLLECTION's admin door,
//     where the value is the admin's own choice in their own message.
//
// The floor's job is not to buy ten years — `ITEM_FULL_RENT` buys those. Its job
// is to be the line a transfer must never sweep below, and it has to stay
// meetable by the thinnest item the system can produce or it stops being a floor
// and starts being a wall. DO NOT RAISE IT WITHOUT RE-DRIVING
// audit/round25/R25A_transfer_floor.spec.ts.
const ITEM_MIN_STORAGE = 50000000;   // 0.05 GRAM
// R17-10 (MEDIUM). A FIXED FLOOR IS A FLOOR FOR A FIXED AMOUNT OF STATE, AND THIS
// ITEM'S STATE IS WRITTEN BY ITS HOLDER.
//
// `ITEM_MIN_STORAGE` was sized against an item with NO records — the only shape
// scripts/rent-model.ts ever modelled. R12 then moved the records here, so the
// holder can grow the account by a factor of ~3 in cell weight while the reserve
// that keeps it alive stayed constant. Measured on the PESSIMISTIC param-18 row
// (bit_price_ps 1, cell_price_ps 500 — the row that shipped before utime
// 1777500000, and a revert is a 5.85x increase, not the ~2x the old comment
// assumed): an item holding its full 8-record allowance is 79 cells / 44,809
// bits and freezes at 3.70 YEARS, inside a term this contract will happily sell
// for 10. Frozen means get_nft_data throws and dnsresolve stops while the
// registrar still shows the name live — a divergence with no repair op.
//
// Storage weight on TON is `cells * cell_price_ps + bits * bit_price_ps`, and the
// yearly fee is `weight * 31,536,000 / 65,536` nanograms. Both measured rows,
// solved back to weight:
//
//   8 max records : 79*500 + 44,809 = 84,309 units  -> 0.040570 GRAM/yr
//   0 records     :                   27,934 units  -> 0.013441 GRAM/yr
//   per record    : (84,309 - 27,934) / 8 = 7,047 units
//                 = 7,047 * 31,536,000 / 65,536      = 0.003391 GRAM/yr
//   ten years     =                                    0.033910 GRAM
//
// 0.035 rounds that up, so one record carries its own rent for the full
// MAX_TOTAL_TERM. It is charged at SetRecord (the write that creates the
// obligation) and reserved at AskTransfer (the send that would otherwise sweep
// it away).
//
// Reproduced end to end in audit/round18/item on this exact build, against
// R17-10's own metric — the FREEZE horizon, (balance + freeze_due_limit) /
// rent_per_year, freeze_due_limit read from config 21:
//
//   8 distinct max records : 82 cells / 46,081 bits  (R17-10: 79 / 44,809)
//   rent, bit 1/cell 500   : 0.041903479 GRAM/yr
//   frozen at 0.05 flat    :  3.58 y     (R17-10 measured 3.70 y)
//   frozen at 0.05 + 8*0.035 = 0.33 : 10.26 y
//
// 10.26 against a 10-year MAX_TOTAL_TERM is thin — 2.6% — and deliberately so:
// it is the WORST case (eight maximum records) on the WORSE of the two published
// param-18 rows, and the row that is actually live buys 80.72 y. Raising it is a
// one-constant change if param 18 ever reverts.
const RECORD_RENT_RESERVE = 35000000;   // 0.035 GRAM — ten years of ONE maximum record
// R20-5. THE WHOLE RECORD BUDGET, PREPAID AT MINT.
//
// R18 charged RECORD_RENT_RESERVE at the WRITE. R19/T7 measured what that does
// to a stock wallet: a freshly transferred item sits at exactly ITEM_MIN_STORAGE,
// MyTonWallet's `TON_GAS.changeDns` is 0.015 and Tonkeeper's `nftLinkAmount` is
// 0.02, and neither is enough to lift the balance over `0.05 + 1 * 0.035`. So the
// first record a new owner writes — the `wallet` record, which is the entire
// point of owning the name — failed with 412 from both dominant wallets. Rent
// solvency and wallet compatibility were in genuine tension.
//
// They are only in tension at the WRITE. At the MINT the buyer is paying 1.5-20
// GRAM and the registrar chooses the value, so the item can simply be funded with
// its whole 8-record allowance up front:
//
//   ITEM_MIN_STORAGE + MAX_CATEGORIES_PER_NAME * RECORD_RENT_RESERVE
//   = 0.05 + 8 * 0.035 = 0.33 GRAM
//
// against a floor price of 1.5 GRAM (tier 6/7) — 22% of the cheapest name, 1.65%
// of the most expensive, and it is not a fee: it is the holder's own rent, sitting
// in the holder's own item, and it is what keeps the name resolvable for the full
// 10-year MAX_TOTAL_TERM. `SetRecord` then needs gas only, for all eight
// categories, from any wallet, at any value that pays for its own compute.
//
// TWO THINGS MUST HOLD FOR THIS TO BE A FIX RATHER THAN A MOVE:
//
//   1. The registrar must actually fund it.
//   2. A SALE MUST NOT SWEEP IT AWAY. AskTransfer's reserve used to be
//      `ITEM_MIN_STORAGE + keptRecords * RECORD_RENT_RESERVE`, which on a sale
//      (keptRecords = 0, records wiped) is the bare floor — so the first transfer
//      would have returned the entire budget to the seller and left the buyer
//      exactly where R19/T7 found them. The reserve now carries the STANDING
//      BALANCE across, capped here. See the reserve note in AskTransfer.
//
// R20-5b. (1) WAS WRITTEN AS THOUGH IT HAD BEEN DONE, AND IT HAD NOT BEEN.
//
// The paragraph above used to end "`MINT_VALUE` is raised to land the item on
// this number after both hops' gas — measured, not computed." `MINT_VALUE` was
// still 0.08. R19/T7 printed an item balance of 0.074904 and R20 re-measured
// 0.078143 on the shipping build: the charge had been moved off the write
// without ever being put anywhere else, so a floor-funded item took its FIRST
// record for free and its second at 412 — strictly worse than R18, because R18
// at least charged consistently. The registrar now sends `MINT_VALUE_FUNDED`,
// and audit/round20/item/M1_mint_funding_and_rent.spec.ts asserts the arriving
// balance on BOTH issuance doors rather than trusting this comment.
//
// R20-6/R20-7 also grew the item: the URI suffix is percent-encoded (up to 3
// cells instead of 1) and the raw label is stored (1 cell). Re-measured on the
// pessimistic param-18 row with the WORST name in the frozen table and eight
// maximum records, the freeze horizon at 0.33 no longer cleared MAX_TOTAL_TERM.
// 0.36 restores it. The margin is deliberately thin and deliberately stated:
// this is the worst case on the worse of the two published rows, and the row
// that is actually live buys ~80 years.
//
// =============================================================================
// R22-1. "THE MARGIN IS DELIBERATELY THIN" IS HOW THIS CONSTANT WENT STALE TWICE.
// =============================================================================
//
// 0.33 -> 0.36 (R20-5b) was measured against the R20 item. R21 then added three
// body-shape guards and `get_domain` / `get_full_domain`, which grew the item's
// CODE, which grows every item's storage footprint, which shortens the freeze
// horizon of every item in the registry. Measured on item F334498CD0B916BF the
// first time `audit/**` was executed by CI (R21-I10): 9.96 years against a
// 10-year MAX_TOTAL_TERM. A fully-populated name could freeze INSIDE A TERM
// SOMEBODY PAID FOR — R17-10's original defect, arriving for the third time by
// the third door.
//
// THE WORST CASE THE PREVIOUS TWO ROUNDS MEASURED WAS NOT THE WORST CASE.
// Re-derived from the bounds the contracts actually enforce, three inputs
// maximise the account state and R20 held only one of them at its maximum:
//
//   1. THE NAME. R20 used "the worst name in the frozen table" — three
//      tag-sequence flags, 84 raw bytes -> 252 encoded, TWO content cells. But
//      MAX_NAME_BYTES is 111 and every byte >= 0x80 percent-encodes 1 -> 3, so
//      the real ceiling is 333 encoded bytes = THREE content cells, and it is
//      reachable: 🏴󠁧󠁢󠁥󠁮󠁧󠁿🏴󠁧󠁢󠁳󠁣󠁴󠁿🏴󠁧󠁢󠁷󠁬󠁳󠁿👩‍❤️‍💋‍👨 is 111 raw bytes, 4 units, and
//      `checkName` returns 0 for it. The label cell maxes with it (888 bits).
//   2. THE RECORD SHAPE. R20's fixture record was 4 cells / 3,117 bits. The
//      bound ERR_RECORD_TOO_BIG enforces is 4 cells / 4,092 bits — 975 bits per
//      record, 7,800 bits over eight, unmeasured.
//   3. THE CATEGORY KEYS. `records` is a dict uint256 -> ref, so the key SPREAD
//      decides how much of each 256-bit key survives as an uncompressed label.
//      Eight sequential keys share a 245-bit prefix stored once; eight spread
//      keys (which is what sha256 category IDs are) cost 1,826 bits more.
//
// All three at their maximum, RE-MEASURED ON THIS BUILD BY R25:
//
//   worst item state       93 cells / 56,629 bits   (R20 measured 92 / 45,147)
//   pessimistic row        bit 1 / cell 500
//   rent                   (93*500 + 56,629) * 31,536,000 / 65,536
//                          = 103,129 units          = 0.049625795 GRAM/yr
//   freeze_due_limit       0.100000000              (config 21, read not assumed)
//   ten-year break-even    10 * 0.049625795 - 0.10  = 0.396257956
//
// R25 REFRESH, AND WHY IT IS HERE RATHER THAN A FOOTNOTE. This block shipped
// stating 55,637 bits / 0.049148444 / 11.80 y. Those were R22-1's numbers and
// they went 1.0% optimistic the moment R23 added four body-shape guards to this
// contract — 1,056 bits of code, which lands as +992 bits of worst-case item
// state at the same 93 cells, because code is part of what the account is
// charged rent on. That is the THIRD time this derivation has rotted by exactly
// the same mechanism (R20-5b's numbers rotted under R21; R21's under R23), and
// it is why the figure to keep an eye on is the CELLS-OF-GROWTH line below
// rather than the horizon itself.
//
// 0.36 is BELOW that break-even. So is 0.3621, the number the R21 finding
// computed from the shape it had measured — setting the constant to a measured
// edge is exactly what produced two stale rounds, and it would have produced a
// third here, because the edge itself was measured against the wrong worst case.
//
// 0.48 IS CHOSEN FOR ITS HEADROOM, AND THE HEADROOM IS THE POINT:
//
//   freeze horizon   (0.48 + 0.10) / 0.049625795 = 11.687 y
//   vs MAX_TOTAL_TERM (10 y)                     = +1.687 y, +16.9%
//
// In the unit that actually moves — cells of item code — one cell of this
// contract's growth has cost 475 bits on average across R20 and R21 (+12 cells /
// +5,706 bits), i.e. 0.000469 GRAM/yr of rent. 0.48 therefore absorbs
//
//   (0.58/10 - 0.049625795) / 0.000469 = 17.8 CELLS
//
// of future item growth before a ten-year term is threatened again — still
// ~1.5x everything R20 and R21 added put together, and R23's guards spent ~2 of
// the 18.9 this block used to claim. The pin that guards it
// (audit/round18/item/C_reserve_and_rent.spec.ts, and the true-worst-case
// version in audit/round20/item/M1_mint_funding_and_rent.spec.ts) does NOT
// assert the ten-year term: it asserts horizon >= 11 y, so CI goes red after
// 6.6 further cells of growth with ~11 still in hand, instead of at the edge
// with none. THE PIN GOING RED MEANS RE-MEASURE AND RAISE THIS CONSTANT. It does
// not mean relax the pin.
//
// WHAT IT COSTS THE BUYER, STATED. `MINT_VALUE_FUNDED` follows this constant, and
// `opsBudgetRegister` quotes `MINT_VALUE_FUNDED`, so a registration's ops budget
// rises by the same 0.12 GRAM. Together with R22-2's `MINT_HOP_GAS` correction
// (0.006 -> 0.02, the mainnet forward fee the old figure priced on the sandbox
// row) the budget goes 0.404 -> 0.538 with no resolvers wired. Against the
// tier-6/7 launch price of 1.5 GRAM that is +8.9% of the name's price, and the
// prepaid rent itself is 32% of it (2.4% of a 20 GRAM tier-2 name). Against the
// IMMUTABLE tier-6/7 floor price of 0.375 GRAM — where a future admin may take
// the license fee — the prepaid rent is 128% of the fee, so a floor-priced name
// costs ~0.91 GRAM all in. That is the honest number, and it is still not a fee:
// it is the holder's own rent, in the holder's own item, returned to the
// responseDestination by AskTransfer's cap the moment it is not needed.
//
// The literal does not feed back into the code size — measured across 0.36,
// 0.38, 0.40, 0.42, 0.44, 0.45, 0.48 and 0.50 the item code is 41 cells /
// 16,357 bits at every value — so raising it does not shorten its own horizon.
const ITEM_FULL_RENT = 480000000;       // 0.48 GRAM — worst-case item, 11.687 y vs a 10 y term (R25 re-measure)

// ---- exit codes ----
const ERR_NOT_INIT = 405;
const ERR_NOT_OWNER = 401;
const ERR_NOT_COLLECTION = 402;
const ERR_RESERVED = 403;
const ERR_EXPIRED = 410;
const ERR_STILL_VALID = 411;         // reassign attempted before grace elapsed
const ERR_INSUFFICIENT_VALUE = 412;
const ERR_EXPIRY_NOT_EXTEND = 414;   // UpdateExpiry may only extend, never shorten
// R9-5. 333 is the code the reference nft-item.fc uses for `force_chain`, so an
// integrator that already handles TEP-62 items sees the error it expects.
const ERR_BAD_WORKCHAIN = 333;       // transfer destination must be basechain
// R14B1-13. 708 is likewise the reference nft-item.fc's own code for a `transfer`
// body that stops before `forward_payload` (`throw_unless(708, slice_bits(...) >= 1)`).
const ERR_NO_FORWARD_PAYLOAD = 708;  // transfer body ends before the Either bit
// R12 record ops.
//
// R12-4: these were first pinned to the numbers emoji_resolver_v2 used, for client
// parity. That was wrong HERE: the resolver had no NOT_INIT or RESERVED to collide
// with, and this item does. 403 meant both "not your name" and "reserved,
// non-transferable", and 405 meant both "never minted" and "record too big" — a
// wallet could not tell them apart. Owner-failure now reuses this contract's OWN
// ERR_NOT_OWNER (401), which is the identical condition already raised by
// AskTransfer, and the remaining record errors take fresh, unused numbers.
const ERR_NAME_EXPIRED_REC = 406;    // write access must not outlive ownership (V7-6)
const ERR_TOO_MANY_RECORDS = 407;    // per-name category cap (V7-22)
// R23-4: op32 + queryId64 — the whole body of the two bare ops on this contract.
const BODY_OP_QUERYID = 96;
const ERR_RECORD_TOO_BIG = 416;      // record cell/tree exceeds the bound
// R23-9. A FRESH NUMBER, CONTINUING THE SYSTEM-WIDE SEQUENCE: the collection
// reached 479 (R21-3's ERR_BAD_ITEM_INDEX) and that is the highest code any of
// the four contracts holds, so 480 is the next free one. Reusing a low gap would
// recreate the R17-39 hazard the R18 rule was written against. The resolver
// enforces the identical predicate and is pinned to this same number, so a
// client can map the code to a message without knowing which contract answered.
const ERR_RECORD_TOO_SMALL = 480;    // R23-9: record too short to carry a TEP-81 tag
const ERR_BAD_CATEGORY = 417;        // R12-5: category 0 is the "whole dict" selector
const ERR_BAD_RECORD_BODY = 418;     // R12-3-GAP: SetRecord body is not exactly 353 bits
const ERR_BAD_SUBDOMAIN = 70;        // TEP-81: subdomain must be byte-aligned
const ERR_ALREADY_IN_SYNC = 421;     // R14-3: AdoptItem on an item that is NOT out of step
const ERR_NEXT_RESOLVER_CAT = 422;   // R14-6: a name cannot delegate to another resolver
const ERR_NOT_IN_SYNC = 423;         // R17-3: nonce 0 — this item is not from any issuance
// R17-34. The registrar (R13X-6, `ERR_UNKNOWN_OP = 465`) and the collection both
// carry this predicate under 465 already. R17-39's hazard is one NUMBER meaning
// two things across contracts; the cure is the same number for the same
// predicate, so an integrator's error map stays true whichever door was hit.
const ERR_UNKNOWN_OP = 465;          // R17-34: body this contract cannot interpret
// R20-4. 477 IS THE NEXT FREE NUMBER SYSTEM-WIDE, and it is a fresh number for a
// fresh predicate rather than a reuse of the 436/437 gap — the rule R18 wrote
// down after R17-39 found 401 meaning four different things across four
// contracts. See the `key == 0` arm of ChangeDnsRecord for the decision this
// code carries.
const ERR_RENEW_AT_REGISTRAR = 477;  // R20-4: change_dns_record key 0 — renewal is not an item op
// R21-2. THE SAME NUMBER FOR THE SAME PREDICATE, per the rule 465 above already
// follows. The registrar's `ERR_BAD_BODY = 468` means exactly "body shape does not
// match the op's struct" and it is what R18 answers on seven arms; a malformed
// `transfer` at the item is that predicate, at a different door. A fresh number
// here would only make an integrator's error map contract-dependent.
const ERR_BAD_BODY = 468;            // R21-2: body shape does not match the op's struct
                                     // (registrar: ERR_BAD_BODY, same meaning)
// R14-6: sha256("dns_next_resolver"), the TEP-81 delegation category.
const CATEGORY_DNS_NEXT_RESOLVER: int =
    0x19f02441ee588fdb26ee24b2568dd035c3c9206e11ab979be62e55558a1d17ff;

// R21-2: the TL-B widths `askTransferBodyIsWellFormed` walks. Derived from the
// struct definitions and from what LDSTDADDR / LDOPTSTDADDR / LDGRAMS accept, not
// guessed. The registrar carries the same three address constants under the same
// names for the same reason (R21-1).
const OP_QUERYID_BITS: int = 96;    // op:uint32 + queryId:uint64, the common prefix
const ADDR_STD_TAG: int    = 0b100; // addr_std$10 + anycast_none$0 — Tolk's `address`
const ADDR_NONE_TAG: int   = 0b00;  // addr_none$00 — a null `address?`
const ADDR_STD_BITS: int   = 267;   // '10' + '0' + workchain:int8 + hash:uint256
const COINS_LEN_BITS: int  = 4;     // VarUInteger 16 length prefix, then that many bytes

// ---- storage ----

struct ItemStorage {
    index: uint256          // nameHash
    collection: address
    owner: address?         // null until first InitOrReassign
    expiresAt: uint32       // 0 = never expires (reserved singles)
    isReserved: bool
    // TIER, on-chain. Marketplaces and indexers can read rarity straight off the
    // item without a second call to the registrar. 1=Mythic 2=Legendary 3=Epic
    // 4=Rare 5=Uncommon 6/7=Common.
    emojiCount: uint8
    // F-12 anti-stale-sync. Bumped by the registrar on every OWNER write and
    // carried through mint -> item -> SyncOwner -> registrar. A sync echoing an
    // old nonce is a stale view of ownership and must be discarded.
    syncNonce: uint32
    content: cell?          // TEP-64 individual content
    // R20-7. THE NAME ITSELF, IN RAW UTF-8, ONE CELL, NO TAG.
    //
    // `index` is sha256(name) and is one-way, so until now the item did not know
    // its own name — address -> name back-resolution went through the TEP-64
    // suffix and nothing else. Two things made that untenable:
    //
    //   * R20-6 percent-encodes the suffix, so recovering the name from it now
    //     means DECODING `%F0%9F%9A%80` on chain rather than reading bytes;
    //   * an `AdoptItem`-repaired orphan (R17-1) has 0 bits of content by
    //     construction, so for that item the suffix answer does not exist at all.
    //
    // See `get_domain` for what reads it and the measurement behind storing it.
    // Written ONLY by an issuance (`adopt == false`), never by a repair, for the
    // same reason `content` is: a repair carries no name to write.
    label: cell?            // R20-7: raw UTF-8 name bytes; null on a never-issued item
    // R12: how many categories this name holds, so the per-name record count can
    // be bounded without walking the dict on every write (V7-22's technique).
    recordCount: uint8
    // R12: TEP-81 records for THIS name. dict uint256 category -> ref record cell.
    // This is the state that used to live in the shared resolver.
    records: cell?
}

fun ItemStorage.load(): ItemStorage {
    return ItemStorage.fromCell(contract.getData());
}

fun ItemStorage.save(self) {
    contract.setData(self.toCell());
}

// ---- messages ----

// TEP-62 standard
struct (0x5fcc3d14) AskTransfer {
    queryId: uint64
    newOwner: address
    responseDestination: address?
    customPayload: cell?
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x05138d91) OwnershipAssigned {
    queryId: uint64
    prevOwner: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0xd53276db) Excesses {
    queryId: uint64
}

struct (0x2fcb26a2) AskStaticData {
    queryId: uint64
}

// R17-34. Outbound only — see the terminal arm of onInternalMessage. Same opcode
// and same layout as the registrar's and the collection's, so one decoder reads a
// rejection from any contract in the system. Deliberately NOT in AllowedMessage:
// this contract never answers one, and adding an ingress arm would only turn a
// refund into a silent absorption.
struct (0x7e3a11c5) RejectedRefund {
    queryId: uint64
    reason: uint32
}

// R31-2. The comment above used to end "this contract never answers one". It did:
// the terminal `else` arm answered ANY uninterpretable body, and 0x7e3a11c5 is
// uninterpretable here, so two of our own contracts trading rejections was a loop.
// The opcode is named here so the `else` arm can decline it, which is the guard
// R25-6b gave the registrar and did not give this file.
const OP_REJECTED_REFUND: int = 0x7e3a11c5;

struct (0x8b771735) ReportStaticData {
    queryId: uint64
    index: uint256
    collection: address
}

// custom (collection -> item)
struct (0x2b71c34f) InitOrReassign {
    queryId: uint64
    owner: address
    expiresAt: uint32
    isReserved: bool
    emojiCount: uint8       // tier, stored on-chain
    syncNonce: uint32       // F-12
    content: cell?
    // R20-7: the raw UTF-8 name. Carried alongside `content` and written under
    // exactly the same rule, so the pair can never disagree about which name this
    // item is. Optional because the repair path (`adopt`) has neither.
    label: cell?
    authoritative: bool     // R7-10: minter-originated, so the registrar has already ruled
    // R14-3: this is the registrar's AdoptItem REPAIR, not a (re)issuance. See
    // the adopt branch in the handler for the guard that makes it non-seizing.
    adopt: bool
}

// R12-1-FIX. `authoritative` here means exactly what it means on InitOrReassign
// (R7-10): the registrar — not the collection admin — originated this write, and
// the registrar has already ruled on the term. See the long note in the handler.
struct (0x3c81aa02) UpdateExpiry {
    queryId: uint64
    newExpiresAt: uint32
    authoritative: bool     // R12-1-FIX: minter-originated, so the registrar has already ruled
    syncNonce: uint32       // R16-2: the issuance the REGISTRY records for this name
}

// custom (item -> collection)
struct (0x4d92bb13) SyncOwner {
    queryId: uint64
    index: uint256
    newOwner: address
    syncNonce: uint32       // F-12: the nonce this item was last minted with
}

// Fix #1: permissionless heal — anyone can pay to re-push the current owner
// down the sync chain if a prior sync bounced/desynced. Reads item state, so
// it can only ever assert the TRUE current owner; it cannot forge ownership.
struct (0x7e5a9c01) ResyncOwner {
    queryId: uint64
}

// R12: holder -> item. Write or delete one TEP-81 record for this name.
//
// R12-3 (HIGH). THIS DELIBERATELY DOES **NOT** REUSE THE RESOLVER'S OPCODE.
//
// It first shipped as 0xd4255c7a — emoji_resolver_v2's SetRecord — on the same
// reasoning that lets the collection and the item share 0x3c81aa02 for
// UpdateExpiry: same operation, and the item's shape simply drops the key it
// already knows. That reasoning does not survive here, and the difference is who
// builds the message.
//
// UpdateExpiry is an INTERNAL message: only the collection ever sends it, and the
// collection builds it correctly. SetRecord is USER-FACING — a front end builds
// it. And the two shapes are prefix-compatible:
//
//     resolver: op | queryId | labelHash:256 | category:256 | record:Maybe
//     item:     op | queryId | category:256  | record:Maybe
//
// Tolk's `lazy` union parsing does not assert the body was fully consumed, so a
// front end that half-migrates — aims at the item address but keeps the old
// builder — is ACCEPTED: the item reads `labelHash` as the category and the top
// bit of the real category as the Maybe flag. Measured: exit 0, recordCount 1,
// the wallet category left EMPTY. The UI says "record set", the item reports a
// record and pays rent on it, the name never resolves, and each mis-write burns
// one of the eight category slots. No error anywhere.
//
// A distinct opcode makes that unrepresentable: the old body now falls through to
// `else => throw 0xffff` and fails loudly on the first attempt.
struct (0x7e5a9c02) SetRecord {
    queryId: uint64
    category: uint256
    record: cell?           // null = delete this category
}

// R20-3 (LAUNCH BLOCKER). THE TEP-81-ECOSYSTEM COMPATIBILITY ALIAS.
//
// `change_dns_record#4eb1f0f9` is NOT in TEP-81 — 0 hits across all 17 published
// TEPs. It is a constant in ton-blockchain/dns-contract/func/dns-utils.fc:11 that
// every wallet then hard-coded, so it is the de-facto write interface for a TON
// domain regardless of what the standard says. Without it, R19/T3 measured the
// user-visible result: a "link this domain to my wallet" from Tonkeeper or
// MyTonWallet is SILENTLY ACCEPTED and writes nothing (the body falls through to
// the unknown-op arm, which refunds at exit 0 — no error the wallet can show),
// MyTonWallet sets `isLinkable: false`, and no TEP-81-standard client can write a
// record at all.
//
// THE WIRE SHAPE IS **NOT** `value:(Maybe ^DNSRecord)`. Measured at source:
//   dns-contract/func/nft-item.fc:207   int has_value = in_msg_body.slice_refs() > 0;
//   tonweb  DnsItem.createChangeContentEntryBody     body.refs[0] = value  (no bit)
//   MyTonWallet DnsItem.buildChangeDnsWalletMessage  .storeRef(...)        (no bit)
//   Tonkeeper NFTEncoder.nftLinkBody                 .storeRef(...)        (no bit)
// The body is exactly op(32) + queryId(64) + key(256) = 352 data bits with the
// record in a REF whose PRESENCE is the discriminator. A Maybe bit here would
// reject every real client, which is the whole point of the alias.
struct (0x4eb1f0f9) ChangeDnsRecord {
    queryId: uint64
    key: uint256
    rest: RemainingBitsAndRefs      // 0 bits; 0 refs = delete, 1 ref = set
}

type AllowedMessage = AskTransfer | AskStaticData | InitOrReassign | UpdateExpiry
                    | ResyncOwner | SetRecord | ChangeDnsRecord;

// ---- helpers ----

// F-10: the boundary MUST match the registrar's exactly. The registrar frees a
// name at `now >= expiresAt + GRACE` (inclusive). If this used `<=`, then at the
// single second where now == expiresAt + GRACE the registrar would re-issue the
// name while this item refused to reassign (ERR_STILL_VALID) — leaving the
// registry and resolver on the new owner and the NFT on the old one. One
// character, one second per name lifecycle, and a desync that ResyncOwner would
// then propagate backwards. Strict `<` closes it.
fun ItemStorage.isWithinGrace(self): bool {
    if (self.expiresAt == 0) {
        return true;    // never expires
    }
    return blockchain.now() < (self.expiresAt as int) + GRACE_PERIOD;
}

// Fix #1/#2: single place that emits SyncOwner to the collection with a
// BOUNCEABLE message and adequate value, so a failed relay comes back to
// onBouncedMessage instead of vanishing.
/**
 * V7-1: how much to forward down the sync chain. The caller already had to
 * cover forwardTonAmount + NOTIFY_VALUE + MIN_TRANSFER_GAS, so `spare` is never
 * below the floor; anything they sent beyond that funds a wider resolver
 * fan-out, up to NOTIFY_MAX.
 */
fun relayValue(msgValue: int, forwardAmount: int): int {
    val spare = msgValue - forwardAmount - MIN_TRANSFER_GAS;
    if (spare < NOTIFY_VALUE) { return NOTIFY_VALUE; }
    if (spare > NOTIFY_MAX)   { return NOTIFY_MAX; }
    return spare;
}

// tonapi. NO OPTIONAL ADDRESS EVER LEAVES A GET-METHOD AS A TVM NULL.
//
// `address?` serialises to a NULL stack entry when it is null, and the Go readers
// the whole TON indexing layer is built on cannot take one. Verified against
// tonkeeper/tongo at source: `tlb.MsgAddress` is a STRUCT with an `addr_none$00`
// arm, so `addr_none` decodes cleanly — but `VmStack.Unmarshal` rejects
// `VmStkNull` outright ("can't unmarshal null"), and the generated
// `DecodeGetNftDataResult` (abi/get_methods.go:4802) refuses the stack BEFORE
// unmarshalling unless slot 3 is `VmStkSlice`. A null owner therefore does not
// produce a null owner in tonapi; it makes tonapi fail to recognise the account
// as an NFT AT ALL — no indexing, no NftItemTransfer action, no DomainRenew
// action, no `verified`, no Tonkeeper risk card, for every item of this
// collection an indexer happens to crawl while unminted.
//
// `addr_none` says the same thing in a form every reader already handles, and it
// is what TON DNS's own root collection ships in production. The `init` flag in
// slot 0 remains the authoritative "is there an owner" signal, exactly as TEP-62
// specifies.
fun ownerOrNone(owner: address?): any_address {
    return owner != null ? (owner! as any_address) : createAddressNone();
}

// R21-2 (LOW, TSA round 21). A TRUNCATED TEP-62 `transfer` THREW EXIT 9 AND KEPT
// THE VALUE — ON THE HANDLER A HOLDER'S OWN WALLET TALKS TO.
//
// R17-7's class, on the arm R18 explicitly left out: it guarded the registrar's
// seven paid arms (20–1,000 GRAM) and judged the item's ~0.1 GRAM transfer not
// worth a guard. It is worth one, because `0x5fcc3d14` is the op every wallet and
// marketplace sends and the item is the contract the HOLDER addresses directly —
// the same population R8-12 and R17-34 were written for. Measured before, on a
// deployed item from a bounce-stripping wallet
// (audit/round21/tsa/tests/R21TsaShortBody.spec.ts):
//
//     AskTransfer body 64 bits  -> exit 9, item kept 0.099836 of 0.10 GRAM
//     AskTransfer body 256 bits -> exit 9, item kept 0.099834
//     AskTransfer body 512 bits -> exit 9, item kept 0.099834
//     AskTransfer body 640 bits -> exit 9, item kept 0.099834
//
// WHY THIS IS A WALKER AND NOT A BIT COUNT. The registrar's seven arms are
// fixed-width structs, so R18 could compare one number. `AskTransfer` is not:
// `responseDestination` is 2 or 267 bits, `customPayload` is 1 bit or 1 bit + a
// ref, `forwardTonAmount` is a VarUInteger 16 (4-bit length + that many bytes),
// and `forwardPayload` takes whatever remains. A minimum-length guard would catch
// the four witnesses above and still leave, say, a 400-bit body whose
// `responseDestination` tag claims a 267-bit address underflowing exactly as
// before. So this walks the struct field by field, in the order the eager load
// walks it, and answers the only question that matters: can that load underflow.
//
// It deliberately does NOT re-implement the handler's semantic guards. Workchain
// (333), value (412) and the R14B1-13 empty-`forwardPayload` refusal (708) stay
// exactly where they are and keep their own codes; this says only "the bytes are
// parseable", so a legible failure is not relabelled as a format error.
fun askTransferBodyIsWellFormed(body: slice): bool {
    var s = body;
    if (s.remainingBitsCount() < OP_QUERYID_BITS) { return false; }
    s.skipBits(OP_QUERYID_BITS);
    // newOwner: address — LDSTDADDR takes addr_std$10 + anycast_none$0 and nothing
    // else. Anycast is refused here too; no wallet, no @ton/core builder and no
    // Tolk `storeAddress` emits one, and the basechain assert below wants a plain
    // workchain+hash destination anyway.
    if (s.remainingBitsCount() < ADDR_STD_BITS || s.preloadUint(3) != ADDR_STD_TAG) { return false; }
    s.skipBits(ADDR_STD_BITS);
    // responseDestination: address? — LDOPTSTDADDR takes addr_std$10 or addr_none$00.
    if (s.remainingBitsCount() < 2) { return false; }
    if (s.preloadUint(2) == ADDR_NONE_TAG) {
        s.skipBits(2);
    } else {
        if (s.remainingBitsCount() < ADDR_STD_BITS || s.preloadUint(3) != ADDR_STD_TAG) { return false; }
        s.skipBits(ADDR_STD_BITS);
    }
    // customPayload: cell? — Maybe ^Cell. The set bit without the ref is the same
    // exit 9 by a different door, so the ref is counted, not assumed.
    if (s.remainingBitsCount() < 1) { return false; }
    if (s.loadBool()) {
        if (s.remainingRefsCount() < 1) { return false; }
        s.loadRef();
    }
    // forwardTonAmount: coins — VarUInteger 16, i.e. len:uint4 followed by len bytes.
    if (s.remainingBitsCount() < COINS_LEN_BITS) { return false; }
    val nbytes = s.loadUint(COINS_LEN_BITS);
    return s.remainingBitsCount() >= nbytes * 8;
    // forwardPayload: RemainingBitsAndRefs — consumes the rest and cannot underflow.
}

// R21-2. The refund shape R17-34 already uses in the terminal arm, factored out so
// the two sites cannot drift. Value 0 + CARRY_ALL_REMAINING_MESSAGE_VALUE hands the
// sender's own value back and touches nothing of the item's balance, so it is safe
// at the rent floor; IGNORE_ERRORS keeps a failed refund from turning a refusal into
// a throw. Only safe BEFORE any state write — both call sites are.
fun rejectAndRefund(to: address, reason: int) {
    // R31-2. DO NOT ANSWER OURSELVES — the registrar's R17-36 guard, which this
    // file never got. A transfer naming this item's own address as
    // `response_destination` makes the item send itself an Excesses it has no
    // ingress arm for, which this function answers, which the `else` arm answers
    // again: 1,048 transactions measured on a 0.5 GRAM item. One address
    // comparison on a path that is already refusing.
    if (to == contract.getAddress()) { return; }
    createMessage({
        bounce: BounceMode.NoBounce,
        value: 0,
        dest: to,
        body: RejectedRefund { queryId: 0, reason: reason as uint32 },
    }).send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS);
}

fun ItemStorage.sendSyncOwner(self, queryId: uint64, value: coins) {
    val sync = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        value: value,
        dest: self.collection,
        body: SyncOwner {
            queryId: queryId,
            index: self.index,
            newOwner: self.owner!,
            syncNonce: self.syncNonce,
        }
    });
    // R17-35: +16, see the AskTransfer reserve note. ResyncOwner reaches this
    // helper too, and the same argument applies there — a heal that cannot pay
    // must hand the healer their money back, not keep it.
    sync.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
}

// R20-3. THE ONE RECORD-WRITE PATH, SHARED BY BOTH OPCODES.
//
// Lifted verbatim out of the `SetRecord` arm when the `change_dns_record` alias
// landed, so that the alias cannot drift from the native op: same owner check,
// same category-0 refusal, same dns_next_resolver ban, same grace gate, same
// 1023-bit/4-ref root bound, same 4-cell/4092-bit tree bound, same 8-category
// cap, same delete semantics. TWO OPCODES, ONE FUNCTION — the only thing the two
// arms do differently is decode the body, and every guard below is therefore
// reachable through either door by construction rather than by test coverage.
fun applyRecordWrite(mutate storage: ItemStorage, sender: address,
                     category: uint256, record: cell?) {
    assert (storage.owner != null) throw ERR_NOT_INIT;
    assert (sender == storage.owner!) throw ERR_NOT_OWNER;
    // R12-5: category 0 is TEP-81's "return the whole record dict" selector,
    // so `dnsresolve` intercepts it before any lookup and a record stored
    // under it can never be read back. Accepting the write consumed one of
    // the eight slots and charged rent for data that is unreachable by
    // construction. Refuse it instead of storing an invisible record.
    assert (category != 0) throw ERR_BAD_CATEGORY;
    // R14-6. A NAME CANNOT DELEGATE, SO IT MUST NOT BE ABLE TO CLAIM IT DOES.
    //
    // `sha256("dns_next_resolver")` is the slot a TEP-81 client reads to
    // continue resolution somewhere else. A holder could write it on their
    // own name and point at another name — or at their own — and a client
    // that follows the hop without bounding it walks in a circle. Measured
    // against our own contracts: item A's record pointing at item B and B's
    // back at A, walked with the hop cap removed, ran until the caller gave
    // up. Real clients bound their hops, but wrappers/tonDnsClient.ts is
    // the file we hand integrators and it must not be the thing that hangs.
    //
    // THE SAME ARGUMENT R12-5 MADE ABOUT CATEGORY 0: refuse a write that
    // can never be read back as its author intends, rather than store an
    // unreachable record, burn one of the eight slots and charge rent for
    // it. `dnsresolve` here returns `totalBits` for EVERY answer — the
    // whole query, always — because an item is one name and answers only
    // for itself; the branch above it returns (0, null) the moment any
    // label remains. So a next_resolver stored here can never be returned
    // as a PARTIAL resolution, which is the only form TEP-81 gives it
    // meaning in. It can only surface as a terminal answer for this
    // category, where it means nothing to a conforming client and means
    // "hop" to a naive one.
    //
    // IT BREAKS NO SUBDOMAIN DELEGATION, because there is none to break:
    // `sub.name.emoji` already resolves to (0, null) before the record dict
    // is consulted at all. `.ton`'s nft-item.fc does implement that shape —
    // return (8, next_resolver) for the residual label — and if a future
    // item version wants it, it ships as new item CODE, which moves every
    // item address anyway.
    //
    // The 0xba93 record TAG is deliberately NOT sniffed under other
    // categories. Records are opaque blobs by design, a tag check would be
    // incomplete (nest it one cell down and it disappears), and a
    // next_resolver-shaped cell filed under `wallet` is simply a malformed
    // wallet record, indistinguishable from any other garbage a holder is
    // free to store. The client-side hop bound and cycle detector are what
    // make the walk provably terminating; this closes the one slot that is
    // specifically an instruction to hop.
    assert (category != CATEGORY_DNS_NEXT_RESOLVER) throw ERR_NEXT_RESOLVER_CAT;
    // V7-6: write access must not outlive ownership. A lapsed holder wrote
    // freely to the shared resolver for as long as the entry survived;
    // here the same rule is enforced against this name's own term.
    assert (storage.isWithinGrace()) throw ERR_NAME_EXPIRED_REC;

    var records: dict = storage.records;
    if (record != null) {
        val rc = record!;
        val rs = rc.beginParse();
        // bound the ROOT cell...
        assert (rs.remainingBitsCount() <= MAX_RECORD_BITS
             && rs.remainingRefsCount() <= MAX_RECORD_REFS) throw ERR_RECORD_TOO_BIG;
        // R23-9: ...and a FLOOR. See MIN_RECORD_BITS — a value too short to carry
        // a TEP-81 constructor tag is not a record, and storing one makes the
        // whole record set unparseable for every reader of this name.
        assert (rs.remainingBitsCount() >= MIN_RECORD_BITS) throw ERR_RECORD_TOO_SMALL;
        // ...and then the WHOLE TREE (V7-5: the root check alone is not a
        // bound — a root at the limits can carry an arbitrary subtree).
        // calculateSize returns not-ok once traversal exceeds maxCells,
        // which is itself the rejection.
        val (rCells, rBits, _rRefs, sizeOk) = rc.calculateSize(MAX_RECORD_CELLS);
        assert (sizeOk) throw ERR_RECORD_TOO_BIG;
        assert (rCells! <= MAX_RECORD_CELLS && rBits! <= MAX_RECORD_TOTAL_BITS)
            throw ERR_RECORD_TOO_BIG;
        // V7-22: only a NEW category grows the state, so overwriting an
        // existing one is always allowed.
        val (_prev, existed) = records.uDictGetRef(256, category as int);
        if (!existed) {
            assert ((storage.recordCount as int) < MAX_CATEGORIES_PER_NAME)
                throw ERR_TOO_MANY_RECORDS;
            val newCount = (storage.recordCount as int) + 1;
            // R17-10 / R20-5. THE ITEM MUST BE ABLE TO PAY TEN YEARS OF RENT FOR
            // THE STATE IT HOLDS — BUT THE HOLDER'S WALLET MUST NOT HAVE TO
            // CARRY THAT MONEY IN A 0.015 GRAM MESSAGE.
            //
            // R17-10's own reasoning is unchanged and is quoted at
            // RECORD_RENT_RESERVE: an item at the bare storage floor holding its
            // full 8-record allowance freezes at 3.58 years inside a term this
            // contract sells for 10, and a frozen item is a name whose
            // get_nft_data throws while the registrar still shows it live, with
            // no repair op. What changed in R20 is WHO PAYS AND WHEN.
            //
            // R18 charged it at the write. R19/T7 then measured the consequence:
            // MyTonWallet's `TON_GAS.changeDns` is 15,000,000 nanoton and
            // Tonkeeper's `nftLinkAmount` is 0.02, both hardcoded, and a freshly
            // transferred item sits at exactly the storage floor — so the FIRST
            // record a new owner writes from a stock wallet hit this assert and
            // failed with 412. Rent solvency and wallet compatibility were in
            // direct tension, and the write is the wrong end to resolve it at:
            // the wallet has 0.015 GRAM of headroom by construction and no way
            // to be told otherwise.
            //
            // R20-5 moves the charge to the MINT, where the buyer is already
            // paying 1.5-20 GRAM and the registrar controls the value: the
            // registrar funds the item with ITEM_FULL_RENT (floor + the whole
            // 8-record allowance) and AskTransfer's reserve carries that budget
            // across every sale instead of sweeping it back to the floor. So a
            // correctly minted item satisfies this assert for all eight
            // categories before the holder sends anything, and `SetRecord` needs
            // gas only.
            //
            // THE ASSERT STAYS ANYWAY, and that is deliberate. It is the
            // invariant, not the payment mechanism — it still binds the two
            // shapes the mint cannot fund: an item repaired by AdoptItem from a
            // 0.06 GRAM stranger shell, and an item minted through the
            // collection's admin door with whatever value that admin attached.
            // Those keep exactly R18's behaviour: pay the increment or get 412.
            //
            // R25-4 removed the first of those two: `AdoptItem` now funds a
            // repaired item with `MINT_VALUE_FUNDED`, so it arrives at
            // ITEM_FULL_RENT like any purchase. The remaining shape is a thin
            // admin mint through the collection, where the value is the admin's
            // own choice in their own message.
            //
            // Asserted on the BALANCE, not on in.valueCoins, so it states the
            // same invariant AskTransfer reserves rather than a proxy for it.
            // getOriginalBalance() is the balance at the start of the compute
            // phase, so it already includes this message's value and does not
            // yet include this message's gas.
            //
            // WHICH MEANS THIS IS ALREADY `held + in.valueCoins >= floor`, and a
            // caller who attaches more value passes it. R25 read the balance
            // assert as "an under-funded item can NEVER write a record"; measured
            // on a variant build with the floor raised to 0.116, the same item
            // and the same message with enough value attached writes at exit 0.
            // The real cost of raising the floor is narrower and it is a UX cost:
            // a stock wallet's hardcoded 0.015/0.02 stops clearing it. That is
            // R19/T7's harm exactly, which is why `ITEM_MIN_STORAGE` was left
            // where it is — the reasoning is at that constant.
            assert ((contract.getOriginalBalance() as int)
                    >= ITEM_MIN_STORAGE + newCount * RECORD_RENT_RESERVE)
                throw ERR_INSUFFICIENT_VALUE;
            storage.recordCount = newCount as uint8;
        }
        records.uDictSetRef(256, category as int, rc);
    } else {
        val (_p2, had) = records.uDictGetRef(256, category as int);
        if (had && (storage.recordCount as int) > 0) {
            storage.recordCount = ((storage.recordCount as int) - 1) as uint8;
        }
        records.uDictDelete(256, category as int);
    }
    storage.records = records;
}

// ---- entrypoint ----

fun onInternalMessage(in: InMessage) {
    // V7-26 (found by TSA symbolic analysis). `isEmpty()` is SEMPTY — no bits AND
    // no refs — so a body carrying a stray reference but ZERO data bits passed
    // this guard and then underflowed reading the 32-bit opcode (exit 9,
    // uncatalogued, untranslatable by a front end). It also meant a legitimate
    // plain-GRAM top-up sent with a stray ref was REJECTED rather than accepted,
    // which matters most for an item sitting near its rent floor.
    // The registrar always used the stricter bit-count guard; these did not.
    if (in.body.remainingBitsCount() < 32) {
        return;     // no opcode -> plain GRAM transfer (storage top-up)
    }

    var storage = ItemStorage.load();
    val msg = lazy AllowedMessage.fromSlice(in.body);

    match (msg) {
        InitOrReassign => {
            assert (in.senderAddress == storage.collection) throw ERR_NOT_COLLECTION;
            // R14-3. THE ADOPT BRANCH: A REPAIR, NOT AN ISSUANCE.
            //
            // AdoptItem on the registrar re-asserts the record it already holds
            // so that an item which is NOT FROM THE CURRENT ISSUANCE can be put
            // back in step. Three ways to get there, all previously unrepairable
            // by any op in the system:
            //   - the mint never landed (name sold before SetNftCollection was
            //     wired, or across a minter rotation): item nonce M, record N;
            //   - the mint never landed AND NOTHING WAS EVER WRITTEN: the account
            //     is uninit, or a shell somebody deployed for 0.06 GRAM at the
            //     name's derived address, holding owner == null (R17-1);
            //   - R13X-2 stamps nonce 0 on an admin-originated Mint, which can
            //     never equal a live record's nonce, so that item's relays are
            //     dropped by the F-12 guard forever.
            //
            // THE ONE GUARD THAT MAKES THIS SAFE lives here rather than at the
            // registrar, because no contract can read another's storage on TON.
            // Pushing an owner DOWNWARDS inverts the system's direction of truth
            // — ownership belongs to this item (transfer -> collection ->
            // OwnerSynced), the term belongs to the registrar — so an unguarded
            // re-mint from `names` would be a seizure primitive: buy the NFT on a
            // marketplace, have the seller's relay dropped, and anyone can hand it
            // back to the seller for the price of one message.
            //
            // The nonce separates the two cases exactly. If it MATCHES, this item
            // is from the current issuance and any owner difference is a real
            // transfer the registry has not heard about — the repair for that is
            // the upward ResyncOwner, and adopt must refuse. If it DIFFERS, this
            // item's owner field is not evidence of anything the registry ever
            // sanctioned. Adopt and ResyncOwner therefore partition the divergence
            // space and neither can do the other's job.
            //
            // Idempotent by construction: the registrar carries the record's OWN
            // nonce, so a successful adopt makes the next one fail here.
            if (msg.adopt) {
                // `adopt` is stamped false by the collection unless the write came
                // from the minter, so this is the registrar and nobody else.
                //
                // R17-1 (HIGH). `assert (storage.owner != null) throw ERR_NOT_INIT`
                // STOOD HERE, AND IT MADE THE REPAIR FAIL ON THE ONE STATE IT IS
                // DOCUMENTED TO REPAIR.
                //
                // wrappers/EmojiRegistrarV4.ts:591-595 sells this op as handling
                // "the registry on nonce N and the item on nonce M (OR WITH NO ITEM
                // AT ALL)", and emoji_registrar_v4.tolk:2126-2131 repeats it. The
                // claim was false: with owner == null the branch answered 405, so a
                // buyer whose mint died at the collection (every registrar ->
                // collection message is NoBounce, so a minter/nftCollection
                // disagreement throws 402, keeps the value, and returns exit 0 to
                // the buyer) held a registry record they could never sell, never
                // set a record on, and never repair. Found by three independent
                // specialists this round. Measured: buyer -20.24 GRAM, registry
                // isRegistered = -1, item uninit, AdoptItem 405, PushTerm 405,
                // AskTransfer 405 — forever.
                //
                // THE NONCE GUARD IS VACUOUS WHEN THERE IS NOTHING TO SEIZE. It
                // exists because pushing an owner downwards inverts the direction
                // of truth, and it is the OWNER FIELD that makes that dangerous —
                // a null owner is not evidence of anything, cannot be a party to a
                // sale the registry has not heard about, and has no records, no
                // metadata and no market position to take. So owner == null is a
                // first init: write what the registry knows and stop.
                //
                // This is also what makes R17-3's ERR_NOT_IN_SYNC guard below safe
                // rather than a new trap. That guard freezes a nonce-0 item until
                // something re-stamps it, and the refuter's over-fix control found
                // that "something" did not exist for an orphan. It does now: adopt
                // reaches an item at any nonce, including one it just created.
                val prevOwner = storage.owner;
                if (prevOwner != null) {
                    assert (storage.syncNonce != msg.syncNonce) throw ERR_ALREADY_IN_SYNC;
                }
                // R17-1: a first init has no previous holder, so it can never be a
                // change OF one — which is the whole precondition of the wipe below.
                val ownerChanged = prevOwner != null && prevOwner! != msg.owner;
                storage.owner = msg.owner;
                // R23-10. WHY THIS WRITE IS DELIBERATELY *NOT* EXTEND-ONLY.
                //
                // A fresh audit round observed that `UpdateExpiry` one handler below
                // guards this same storage slot extend-only (Fix #5, closing the
                // "shorten -> wait -> reassign" theft path) while this branch writes
                // it unconditionally — and that `AdoptItem` is PERMISSIONLESS.
                // Measured: an item at now+1y, nonce 5, adopted with nonce 6 and
                // `expiresAt = now+100`, accepts at exit 0 and the term shortens.
                //
                // The asymmetry is real and it is CORRECT. The two writes answer
                // different questions:
                //
                //   UpdateExpiry is a term EDIT on the issuance this item already
                //   holds. Nothing legitimate shortens one, so extend-only is exactly
                //   right and shortening there is the theft primitive Fix #5 named.
                //
                //   adopt is RECONCILIATION with the registry after a divergence.
                //   It fires only when `storage.syncNonce != msg.syncNonce`, i.e.
                //   this item is holding a term from an issuance that is over. The
                //   registrar's record is the authority on the CURRENT issuance's
                //   term, and the whole point of the op is to make the item agree
                //   with it. An extend-only guard here would let a stale item keep a
                //   term the registry has already replaced — leaving the item live
                //   and transferable past the registry's own expiry, which is the
                //   R23-5 harm this round fixed one handler below, reintroduced from
                //   the other side.
                //
                // The value is also not attacker-chosen: it is read from the
                // registrar's `names` record, and `AdoptItem` refuses outright for a
                // nameHash the registry does not hold. A caller controls WHETHER a
                // reconciliation happens, never WHAT it writes.
                //
                // Left as-is on purpose. Flagged here rather than silently, so the
                // next round finds the reasoning instead of re-deriving the finding.
                storage.expiresAt = msg.expiresAt;
                storage.emojiCount = msg.emojiCount;
                storage.syncNonce = msg.syncNonce;
                // content and — R20-7 — label are NOT touched, on the first-init
                // path too. The registrar holds neither (the TEP-64 suffix and
                // the name bytes live here), so it has nothing truthful to say
                // about them — and AdoptItem is permissionless, so there is no
                // other honest source. Leaving them alone means adopt cannot
                // repoint a holder's metadata.
                //
                // R25-5 (MEDIUM). `isReserved` USED TO BE ON THAT LIST, AND
                // BEING ON IT BRICKED THE RIGHTFUL OWNER'S NAME.
                //
                // The reasoning above was "leaving them alone means adopt can
                // neither release a reserved foundation single into the market
                // nor repoint a holder's metadata". The first half is false, and
                // it is false in the direction that costs a buyer their asset.
                // Measured (audit/round25/R25B_reserved_adopt.spec.ts): a
                // foundation single seeded through the COLLECTION's admin door
                // (isReserved true, expiresAt 0, nonce 0 — the registrar knows
                // nothing about it) whose nameHash is then bought at the
                // registrar during the window before `SetNftCollection`, so the
                // issuance mint never lands. `AdoptItem` repairs it: owner
                // becomes Alice, `isReserved` stays TRUE, and `AskTransfer`
                // throws 403 on a reserved item — so Alice owns, pays for and
                // renews a name she can never move or sell, forever, and no op
                // in the system can release it.
                //
                // THE FLAG IS NOT A RESERVATION AND CLEARING IT GRANTS NOTHING
                // NEW. Measured, same file, control N4: the ORDINARY public
                // registration of a seeded reserved hash — collection wired, no
                // adopt anywhere — already runs the non-adopt branch below,
                // which already clears the flag and already delivers the item
                // transferable to the buyer. So `AdoptItem` is not a second door
                // to that outcome; it is the SAME door, on the path where the
                // first attempt failed to land. A repair that leaves the holder
                // worse off than a success is not a repair.
                //
                // GATED ON `ownerChanged`, WHICH IS NOT CALLER-CHOSEN. `msg.owner`
                // is read from the registrar's `names` record; the caller picks
                // only WHICH nameHash to reconcile. So to clear the flag on a
                // single the foundation still holds, an attacker would first have
                // to make `names[h].owner` somebody other than the foundation —
                // i.e. buy the name — and if they can do that they can already
                // clear it through the ordinary mint. Four negative controls, all
                // measured on this build:
                //
                //   foundation holds the registry record  -> ownerChanged false,
                //                                            flag preserved
                //   item and registry IN SYNC             -> 421 ERR_ALREADY_IN_SYNC,
                //                                            never reaches here
                //   nameHash not in `names`               -> 407 at the registrar
                //   squatter shell at the derived address -> genesis `isReserved`
                //                                            is FALSE and is hashed
                //                                            into the address, so it
                //                                            cannot be pre-set ON
                //
                // R8-11's rule is preserved exactly: write-once ON at first init,
                // always clearable OFF, monotonically decreasing thereafter. This
                // only ever clears, and only where the item is being handed to
                // somebody the registry says is its owner. The clear lives in the
                // `ownerChanged` block below, next to the record wipe, because it
                // is the same predicate answering the same question — "is this a
                // NEW holder" — and keeping them together means they can never
                // disagree about who this item now belongs to.
                //
                // R17-1's accepted residual: a repaired orphan therefore carries
                // NO individual content, because there was never a truthful place
                // to get it from. That is a metadata gap, not an ownership one —
                // the name is owned, transferable, renewable and resolvable, and
                // the collection's admin Mint can supply the suffix afterwards.
                // Inventing one here would let a permissionless op write the
                // string a marketplace renders, which is R17-4's hazard on purpose.
                //
                // R20-7 EXTENDS THE RESIDUAL RATHER THAN CLOSING IT, deliberately.
                // `get_domain` is empty on a repaired orphan for the same reason
                // its URI is. The tempting fix — let `AdoptItem`'s caller supply
                // `rawName`, since sha256(rawName) == nameHash makes it
                // SELF-VERIFYING and therefore unforgeable in a way `content`
                // never was — is a real option and is recorded here rather than
                // taken: it widens a permissionless op's wire format on the eve of
                // a mint to serve a state that exists only if the deploy runbook's
                // `SetNftCollection` step is skipped, and the collection's admin
                // `Mint` already repairs it with both fields at once. Revisit if
                // an orphan ever actually happens.
                //
                // R12's record wipe is CONDITIONAL here, and this is the reason
                // adopt can be permissionless. The wipe exists so that a name
                // issued to a NEW holder never resolves to the previous one; when
                // the owner is unchanged there is no new holder, exactly as
                // renewal (UpdateExpiry) and the resolver's same-owner
                // SyncNameOwner already reason (R8-7). Without this, any stranger
                // could erase a live holder's wallet binding for the price of one
                // message, on any name whose item happened to be out of step.
                if (ownerChanged) {
                    storage.records = null;
                    storage.recordCount = 0;
                    // R25-5: and the new holder must be able to MOVE what they
                    // now own. Reasoned in full above; clearing only, never
                    // setting, and only under the predicate that says this item
                    // has changed hands.
                    storage.isReserved = false;
                }
                storage.save();
                return;
            }
            // First init: owner == null. Reassign (post-grace re-registration or
            // foundation policy change on a reserved item) is allowed only when
            // the previous term is fully spent or the item is reserved — the
            // collection/registrar is trusted, this guard is defense-in-depth.
            // R7-2 (CRITICAL). `expiresAt == 0` is the never-expires sentinel, so
            // isWithinGrace() returns true for it FOREVER. An item carrying
            // (expiresAt == 0, isReserved == false) therefore failed this assert
            // on every future reassignment — permanently, by everyone, including
            // the registrar and the collection admin who wrote it. Measured:
            // exit 411 on every subsequent attempt, with any flag combination,
            // and still 411 after ten more years.
            //
            // That state is one boolean away from the DOCUMENTED foundation
            // seeding path, which is (expiresAt == 0, isReserved == true) and is
            // correctly recoverable. The same slip is also an attack: seize a
            // lapsed name's item this way and the registrar can never mint over
            // it, so the next buyer pays, the registry records them as owner,
            // and the NFT — the object marketplaces actually trade — stays with
            // whoever wrote it. Confirmed end to end in the sandbox.
            //
            // V7-9 already found and fixed the mirror of this bug one handler
            // below, in UpdateExpiry. The sentinel needs the same treatment
            // here: never-expires means "seeded, re-seedable", not "sealed".
            // R7-10: a mint that originated at the minter carries the
            // registrar's own availability ruling, and the registrar holds the
            // record while this contract holds only a replica of the term. Defer
            // to it. Admin-originated mints keep the clock check below, so the
            // conservative path is unchanged for everything except the one
            // sender that is definitionally the authority on issuance.
            if (storage.owner != null && !msg.authoritative) {
                assert (storage.isReserved
                     || storage.expiresAt == 0
                     || !storage.isWithinGrace()) throw ERR_STILL_VALID;
            }
            // V7-17 NOTE. expiresAt == 0 is the NEVER-EXPIRES sentinel HERE, but
            // it reads as "long expired" at the registrar — the same field with
            // opposite meanings. An AdminImport of 0 used to create a registry
            // record anyone could claim over an item that could never be
            // reassigned to them, divorcing the two permanently with no repair
            // op. That is now blocked at the source: AdminImport requires
            // expiresAt > now. It is deliberately NOT re-asserted here, because
            // the collection admin legitimately seeds foundation singles with
            // expiresAt == 0 and this guard would break that path.
            // R7-5. `isReserved` does two things at once: it makes the item
            // permanently NON-TRANSFERABLE (AskTransfer throws 403) and it acts
            // as an unconditional reassignment licence in the guard above. So
            // flipping it on an item somebody already owns takes their asset out
            // of the market AND hands the collection admin a standing right to
            // re-take it -- while the registrar still records them as the owner
            // and still charges them to renew it.
            //
            // The flag exists to seed foundation singles, which is a FIRST-mint
            // operation. Pinning it at first init preserves that entirely and
            // removes the mid-life flip, which had no legitimate use.
            //
            // R8-11. R7-5 pinned the flag at first init to kill the mid-life
            // flip. It closed a seizure primitive and opened a worse one by
            // omission: there was then NO path to clear the flag, so a reserved
            // single that the foundation later RELEASES — by AdminMint or by
            // winning it at auction — stayed non-transferable forever. Two
            // independent audit lenses reproduced it, one paying a 300.5 GRAM
            // hammer price for an asset the winner could never sell.
            //
            // The two directions are not symmetric and should never have been
            // treated as one rule:
            //   setting it ON mid-life  takes a live asset out of the market and
            //                           hands the admin a standing re-take right
            //   clearing it OFF         releases an asset INTO the market and
            //                           removes a right the admin held
            // So the flag is write-once ON and always clearable OFF —
            // monotonically decreasing after first mint. R7-5's property is
            // preserved exactly; only the escape hatch it forgot is added.
            if (storage.owner == null) {
                storage.isReserved = msg.isReserved;
            } else if (!msg.isReserved) {
                storage.isReserved = false;
            }
            storage.owner = msg.owner;
            storage.expiresAt = msg.expiresAt;
            storage.emojiCount = msg.emojiCount;
            storage.syncNonce = msg.syncNonce;
            // Fix #3: always overwrite content on (re)assign so a reassigned
            // name can never inherit the previous owner's content — including
            // a formerly-reserved single's "coming soon" note.
            storage.content = msg.content;
            // R20-7: the label moves with the content, always, for the same
            // reason and by the same rule. A reassigned item must not keep the
            // previous issuance's name any more than it keeps its URI — and
            // because both are written here in one statement pair, an item can
            // never end up reporting one name through `get_domain` and another
            // through its metadata.
            storage.label = msg.label;
            // R12: and WIPE THE RECORDS, for exactly the same reason. This is the
            // local equivalent of the resolver's SyncNameOwner wipe: a name issued
            // to a new holder after a lapse must never resolve to the previous
            // one's wallet. Unconditional here — an InitOrReassign is by
            // definition a (re)issuance, so there is no "same owner" case to
            // preserve records for (renewal uses UpdateExpiry, which does not
            // touch them).
            storage.records = null;
            storage.recordCount = 0;
            storage.save();
        }

        UpdateExpiry => {
            assert (in.senderAddress == storage.collection) throw ERR_NOT_COLLECTION;
            assert (storage.owner != null) throw ERR_NOT_INIT;
            // Fix #5: expiry may only be EXTENDED, never shortened. Closes the
            // admin "shorten -> wait -> reassign" ownership-theft path.
            //
            // V7-9: this guard was INVERTED relative to that comment. `assert(A
            // || B)` passes whenever A holds, so `storage.expiresAt == 0` — the
            // never-expires sentinel — made the assert unconditionally true and
            // a never-expires item accepted ANY new value, including a past one.
            // Confirmed: expiresAt 0 -> UpdateExpiry(1) -> exit 0, item now
            // outside grace and reassignable. That is precisely the theft path
            // Fix #5 was written to close, left open for exactly the items it
            // most needed to protect.
            assert (storage.expiresAt != 0 && msg.newExpiresAt >= storage.expiresAt)
                throw ERR_EXPIRY_NOT_EXTEND;
            // R12-1. AN EXTENSION MUST NOT RESURRECT A DEAD HOLDER'S RECORDS.
            //
            // This is R8-2's rule, which the shared resolver already enforced, moved
            // to where the data now lives. Past expiry + grace the name is nobody's:
            // dnsresolve MASKS the records (returns 0) but they are still sitting in
            // storage, still owned by whoever held the name last. Extending the term
            // un-masked them — the entry came back live with the FORMER holder's
            // owner and the FORMER holder's wallet record.
            //
            // Today the registrar refuses to renew or MakePermanent a lapsed name,
            // so nothing reaches this. That is exactly the objection: the guard lived
            // entirely in a DIFFERENT contract, which is the coupling R12 exists to
            // remove. A contract that owns the data should not depend on a caller it
            // cannot see to keep that data honest.
            //
            // R12-1-FIX (HIGH). THE FIRST CUT OF THIS GUARD DESTROYED A *PAYING*
            // HOLDER'S RECORDS.
            //
            // The two contracts rule on grace at different instants. The registrar
            // rules at ACCEPTANCE, against the record it owns. The item re-rules at
            // DELIVERY — two hops and several seconds later — against its own,
            // still-old `expiresAt`. A RenewName or MakePermanent submitted in the
            // last seconds of grace is therefore accepted and PAID FOR, and then
            // lands on an item that has meanwhile decided the name is dead. Exit 0
            // at every hop, term extended correctly on both sides, holder's records
            // silently gone. Measured: wiped in 11 of 24 timing configurations, and
            // MakePermanent (~1000 GRAM) sits in the same window.
            //
            // This is R7-10's problem exactly, one message type over: the item's
            // replica of the term is stale by construction, so it must not be the
            // authority on a question the registrar has already answered. Same
            // remedy — the minter's writes carry their authority with them, the
            // admin's do not and keep the conservative clock check.
            //
            // The R12-1 property survives intact. The resurrection path it closed is
            // an extension arriving on a name the REGISTRAR considers lapsed, and the
            // registrar refuses to originate one — so an authoritative extension is
            // never a resurrection. An admin-originated extension still wipes, and a
            // reassignment to a new holder still wipes unconditionally above.
            // R16-2 (MEDIUM). THE EXEMPTION ABOVE ASSUMED THE TWO CONTRACTS AGREE
            // ABOUT *WHICH ISSUANCE* IS LIVE, AND NOTHING ENFORCED THAT.
            //
            // "The registrar refuses to originate an extension on a lapsed name"
            // is true of the name — not of THIS ITEM. When the registry and the
            // item have diverged (the R13X-1 / R14-3 state: the registrar re-issued
            // the name to a new owner, the mint never landed because the minter was
            // rotated away), the registrar considers the name perfectly live and
            // will happily originate an authoritative extension — onto an item that
            // is past grace and still owned by the PREVIOUS holder. The exemption
            // then does exactly what R12-1 exists to prevent: isWithinGrace() flips
            // back to true and the dead holder's wallet record is un-masked, so the
            // name resolves to THEM while somebody else holds the registry record
            // and paid for it. Measured before this fix: a full walk from the real
            // config-#4 root returned the previous holder's address for a name the
            // new owner had just bought for 20.29 GRAM. It also restored the
            // previous holder's ability to sell the NFT (AskTransfer 410 -> 0).
            //
            // PushTerm is the cheapest door (permissionless, ~0.12 GRAM) but not
            // the only one — RenewName and MakePermanent emit the identical
            // authoritative message, so the new owner renewing their OWN name
            // triggers it with no attacker anywhere in the loop.
            //
            // The nonce is the only fact that separates the two cases, and it is
            // already the fact this system uses for exactly this question: F-12's
            // sentinel partitions the sync space by it, and AdoptItem carries it to
            // decide whether a repair is legitimate. An extension for the issuance
            // this item actually holds keeps R12-1-FIX's exemption in full; an
            // extension for a DIFFERENT issuance is not authoritative about this
            // item's records, because it is not about this item's holder at all.
            //
            // Pure tightening: in-step items are unaffected (same nonce), the
            // R12-1-FIX last-seconds-of-grace renewal is unaffected (same nonce),
            // and the admin path never had the exemption.
            val sameIssuance = msg.syncNonce == storage.syncNonce;
            if ((!msg.authoritative || !sameIssuance) && !storage.isWithinGrace()) {
                storage.records = null;
                storage.recordCount = 0;
            }
            // R23-5 (HIGH). WIPING THE RECORDS WAS ONLY HALF OF IT — THE TERM WRITE
            // IS WHAT BRINGS THE STALE HOLDER BACK.
            //
            // R16-2 introduced `sameIssuance` precisely because an authoritative
            // extension aimed at a DIFFERENT issuance is not about this item's
            // holder. It then gated only the record wipe. `storage.expiresAt` was
            // still written unconditionally — so the message still flipped
            // `isWithinGrace()` back to true on an item that belongs to the
            // PREVIOUS issuance and still holds the PREVIOUS owner in `owner`.
            //
            // R16-2's own note measures both halves of the harm and closed one:
            // records un-masked AND "restored the previous holder's ability to sell
            // the NFT (AskTransfer 410 -> 0)". `AskTransfer` checks owner,
            // `syncNonce != 0` and `isWithinGrace()` — every one of which passes on
            // a re-armed stale item, because the item has no way to read the
            // registry's nonce and cannot self-diagnose.
            //
            // Measured end to end: Alice registers, the collection's minter is
            // rotated away (a documented migration step), grace elapses, Bob
            // re-registers — registry {bob, nonce 2}, the mint is refused at the
            // collection (402, NoBounce), the item stays {alice, nonce 1}, inert.
            // Minter restored. Anyone then sends the PERMISSIONLESS `PushTerm` for
            // ~0.07 GRAM, or Bob simply renews his own name, and the item goes live
            // still owned by Alice. Alice sells: exit 0, NFT to Mallory, the
            // `SyncOwner(nonce 1)` relay dropped by the registrar's F-12 guard, the
            // registry still naming Bob. Mallory writes a wallet record and
            // `dnsresolve` returns MALLORY's address for the name BOB paid for.
            // Three losers, and nothing in `get_nft_data` / `get_name_record` /
            // `get_nft_content` distinguishes that item from a healthy one.
            //
            // THE RULE: a term is a fact about an ISSUANCE. An extension that names
            // an issuance this item is not holding has nothing true to say about
            // this item's clock, so it does not touch it. Records are wiped as
            // before (that arm is unchanged and still fires), but the item stays
            // lapsed, stays untransferable, and stays adoptable — which is the
            // correct end state, because `AdoptItem` is exactly the op that
            // reconciles it and it remains permissionless.
            //
            // Pure tightening: in-step items have the same nonce and are wholly
            // unaffected, which is every item in normal operation.
            if (sameIssuance) {
                storage.expiresAt = msg.newExpiresAt;
            }
            storage.save();
        }

        AskTransfer => {
            // R21-2: shape first, before any field is touched — the same ordering
            // R17-7 forced on the registrar, and for the same reason: Tolk emits ONE
            // eager load block at the first field access, so a body that cannot be
            // parsed throws exit 9 before ANY of the asserts below is reachable.
            //
            // A REFUND, NOT A THROW. Every other refusal in this handler is an
            // `assert ... throw`, and on a non-bounceable send a throw keeps the
            // value just as exit 9 did — so relabelling alone would have fixed
            // nothing. R17-34 already reached this conclusion for the item's unknown
            // -op arm ("`throw 0xffff` WAS CONFISCATION FOR HALF THE SENDERS") and a
            // body this contract cannot parse is the same event as a body it cannot
            // interpret. The semantic refusals keep throwing: those are answers about
            // a message that WAS understood.
            //
            // queryId 0, not the sender's: reading `msg.queryId` is the eager load
            // that throws, exactly as on the registrar's envelope guards.
            if (!askTransferBodyIsWellFormed(in.body)) {
                rejectAndRefund(in.senderAddress, ERR_BAD_BODY);
                return;
            }
            assert (storage.owner != null) throw ERR_NOT_INIT;
            val owner = storage.owner!;
            assert (in.senderAddress == owner) throw ERR_NOT_OWNER;
            assert (!storage.isReserved) throw ERR_RESERVED;
            // R17-3 (MEDIUM-HIGH). A NONCE-0 ITEM IS NOT FROM ANY ISSUANCE, SO IT
            // MUST NOT TRADE.
            //
            // R13X-2 stamps syncNonce 0 on a collection-admin Mint precisely so
            // that such an item can never be mistaken for the registry's record.
            // The unnoticed other side is that the item stayed TRANSFERABLE: this
            // handler checked owner, sender, isReserved, grace, workchain, value
            // and payload, and never the one field that says "the registry has
            // never sanctioned this". So the sale went through, its SyncOwner relay
            // was silently DROPPED by the F-12 guard at emoji_registrar_v4:2714,
            // the registry kept naming the SELLER — and AdoptItem, seeing nonce 0
            // != record nonce, correctly concluded "not this issuance" and pushed
            // the seller back onto the item. Measured: buyer paid, attacker spent
            // 0.252 GRAM, NFT returned to the seller, replay 421.
            //
            // The divergence is manufactured by letting the trade happen at all,
            // so it is closed here rather than at AdoptItem — an item out of step
            // with the registry has nothing to convey, and its holder is one
            // permissionless AdoptItem away from being in step and selling
            // normally. The refuter's over-fix control — an orphan for a nameHash
            // the registrar has no record of would be frozen with nothing able to
            // re-stamp it — is answered by R17-1 above, which is what makes this
            // guard a pause rather than a brick.
            assert (storage.syncNonce != 0) throw ERR_NOT_IN_SYNC;
            assert (storage.isWithinGrace()) throw ERR_EXPIRED;
            // R9-5. BASECHAIN ONLY, like the reference nft-item.fc `force_chain`.
            //
            // The reference TEP-62 item throws 333 on a non-basechain owner. Ours
            // accepted any workchain, and a transfer is IRREVERSIBLE: the item
            // rebinds `owner` and relays SyncOwner up to the registrar, so a
            // masterchain destination puts the name — and its resolution record —
            // behind an address no basechain contract in this system can be sent
            // to. There is no admin recovery; the item obeys its owner.
            //
            // This codebase already reached the same conclusion once, from the
            // other direction: F-11 / R7-17 made partner payouts basechain-only
            // (ERR_BAD_PARTNER_WC) for exactly this reason. A holder losing their
            // own name to a typo'd workchain is the worse case of the two.
            assert (msg.newOwner.getWorkchainAndHash().0 == 0) throw ERR_BAD_WORKCHAIN;
            assert (in.valueCoins >= msg.forwardTonAmount + NOTIFY_VALUE + MIN_TRANSFER_GAS)
                throw ERR_INSUFFICIENT_VALUE;
            // R14B1-13. A TRUNCATED TEP-62 `transfer` MOVED THE NAME AND EMITTED A
            // NOTIFICATION NOBODY CAN PARSE.
            //
            // TEP-62's transfer body ends `forward_amount:(VarUInteger 16)
            // forward_payload:(Either Cell ^Cell)`, so at least ONE bit must remain
            // after `forward_amount`. `RemainingBitsAndRefs` accepts zero of them
            // happily, and the reference nft-item.fc does not:
            //
            //     throw_unless(708, slice_bits(in_msg_body) >= 1);
            //
            // Measured, with a body ending immediately after `forward_amount`:
            // EXIT 0, ownership moved, and the emitted `ownership_assigned` carried
            // 0 BITS AND 0 REFS where `forward_payload` must begin.
            //
            // That combination is the harm, not the missing bit. A conformant
            // reader on the other end does `in_msg_body~load_int(1)` (or the
            // equivalent Either parse) and UNDERFLOWS — exit 9 — while the transfer
            // that produced it has already succeeded. `ownership_assigned` is sent
            // NON-BOUNCEABLE by construction (it carries `forwardTonAmount` to a
            // possibly-uninit address), so the failure never travels back: an
            // escrow or marketplace contract holding the name is left never having
            // learned it received it, with no message to retry and no way to
            // release it. A stranded name, from a body a sloppy client can produce
            // by accident.
            //
            // Placed after the value assert so an underfunded transfer still reads
            // as 412 (the more common and more actionable failure) rather than as a
            // format error.
            assert (msg.forwardPayload.remainingBitsCount() >= 1) throw ERR_NO_FORWARD_PAYLOAD;

            // R12-2: wipe only on a REAL change of owner. Wiping unconditionally
            // also cleared the records of a holder transferring to THEMSELVES —
            // which is not a hypothetical: it is the shape of every no-op or
            // book-keeping transfer a wallet might make. The security property is
            // about the name changing hands, so condition it on exactly that.
            // (An escrow round-trip through a marketplace is two GENUINE owner
            // changes and still wipes, which is the correct, conservative answer.)
            val ownerChanged = msg.newOwner != owner;

            // R17-23 (R16-4's stated fix, which had not landed) + R17-10.
            // THE RENT RESERVE IS AN ACTION, AND ACTIONS RUN IN THE ORDER QUEUED.
            //
            // This used to sit at the BOTTOM of the handler, inside the
            // responseDestination arm, queued THIRD — after both
            // PAY_FEES_SEPARATELY sends had already drawn their value and their
            // forward fees off this item's balance — and it used
            // RESERVE_MODE_AT_MOST, which CLAMPS to whatever is left instead of
            // guaranteeing anything. A reserve that clamps is not a floor; it is a
            // report of how little remains. Measured, by forward_payload size:
            // from 145 cells the TEP-62 `excesses` message was silently SKIPPED,
            // from 146 the 0.05 rent floor was breached, and only past 260 did
            // anything fail loudly. That band is the whole harm — ownership moved,
            // the sender got no excesses and no error, and the item drifted below
            // the floor that keeps the name alive.
            //
            // Queued FIRST it is taken off the top, so the sends spend only what is
            // genuinely surplus; EXACT means a shortfall cannot be absorbed by
            // quietly reserving less. Measured on a patched build (3D3E8E216A0EAB28):
            // the silent-starvation band becomes a loud actionCode 37 revert, and
            // "item >= floor whenever ownership moved" then holds at every payload
            // size.
            //
            // ACCEPTED TRADE-OFF: a >= ~150-cell forward_payload sent at the bare
            // asserted minimum now fails instead of half-succeeding. That is the
            // right side of the trade — a marketplace learns immediately and
            // retries with more value, where before it learned nothing and the item
            // lost its rent — and it is one `+16` away from costing the sender
            // nothing (below).
            //
            // R17-35 / R8-12: +16 ON EVERY ACTION IN THIS HANDLER, NOT JUST THE
            // RESERVE. An action-phase failure gives `exit 0, aborted=true, NO
            // bounce`, and absorbs the sender's value regardless of their own
            // bounce flag — the exact confiscation class R8-12, R13X-6 and R17-34
            // spent four rounds removing, and I would be re-introducing it on the
            // item's busiest handler in the same change that removes it from the
            // unknown-op arm.
            //
            // Measured while building this fix, which is why the flag is on the two
            // sends as well: at a 1,000-cell forward_payload the action that fails
            // is NOT the reserve (which succeeds — the balance covers the floor) but
            // the `ownership_assigned` send, whose PAY_FEES_SEPARATELY forward fee
            // no longer fits. With `+16` only on the reserve the holder lost the
            // whole 0.23 GRAM with no bounce and no transfer; with it on all three
            // the transaction bounces and they lose fees. Free on the happy path,
            // and a no-op wherever IGNORE_ERRORS (+2) is already set.
            //
            // R17-10: the amount scales with the records that SURVIVE this message.
            // An item at its full 8-record allowance freezes at 3.70 years inside a
            // 10-year term if a transfer sweeps it back to the bare 0.05 — see
            // RECORD_RENT_RESERVE above for the arithmetic and both rows. It is
            // read AFTER `ownerChanged` because a sale wipes the records in this
            // same transaction: the state that must be paid for is the state the
            // item is left holding, and the seller gets their now-unneeded record
            // deposits back in the excesses rather than having them locked in an
            // item that no longer stores anything.
            //
            // R20-5: AND THE RESERVE MUST CARRY THE PREPAID RECORD BUDGET ACROSS
            // A SALE, OR MOVING THE CHARGE TO THE MINT BUYS NOTHING.
            //
            // The old expression was `ITEM_MIN_STORAGE + keptRecords *
            // RECORD_RENT_RESERVE`, and on a genuine sale `keptRecords` is 0 by
            // construction — the records are wiped two lines below. So the FIRST
            // transfer of a mint-funded item would have swept the whole 0.28
            // budget back to the seller in the excesses and handed the buyer an
            // item at the bare floor: exactly the state R19/T7 measured a
            // 0.015 GRAM MyTonWallet record write failing on. Every property
            // R20-5 buys would have survived precisely one owner.
            //
            // The reserve is now "keep the standing balance, capped at the full
            // budget, never below the hard rent floor":
            //
            //   held  = balance at the start of compute MINUS this message's
            //           value — i.e. what the item already had, so a transfer
            //           sweeps only what the transfer itself brought;
            //   cap   = ITEM_FULL_RENT, so an item somebody dumped 5 GRAM into
            //           still returns the surplus to responseDestination rather
            //           than locking it in a sold NFT forever;
            //   floor = the R17-10 expression, unchanged and still EXACT, so a
            //           self-transfer of a full-record item cannot end below the
            //           rent for the records it keeps.
            //
            // The clamp is what stops this bricking the items the mint does not
            // fund. A RESERVE_MODE_EXACT_AMOUNT of a flat 0.33 fails the action
            // phase whenever the balance is short, and with +16 that means the
            // whole transfer bounces — so an AdoptItem-repaired orphan (R17-1's
            // 0.06 GRAM stranger shell) or a thinly funded admin Mint would have
            // become permanently untransferable.
            //
            // R25-3. THE SENTENCE THAT STOOD HERE — "`held` is by definition
            // available, so the reserve can never ask for money the item does not
            // have" — IS FALSE, AND IT IS THE WHOLE REASON `ITEM_MIN_STORAGE` WAS
            // NOT RAISED THIS ROUND. `keep` is clamped UP to `rentFloor` two lines
            // below, so whenever `held < rentFloor` the reserve asks for exactly
            // the money the item does not have, and the difference has to come out
            // of THIS MESSAGE'S value. Measured on a variant build with the floor
            // at 0.116: an ordinary 8-record item drained to 0.05 — which happens
            // after 7.65 years of its own paid term — fails at ACTION CODE 37,
            // compute exit 0, aborted, ownership unchanged, carrying 0.05 AND
            // carrying 0.1. audit/round25/R25A_transfer_floor.spec.ts.
            //
            // It is harmless at 0.05 only because 0.05 is under every shape the
            // system can currently produce (a purchase and — since R25-4 — a
            // repair both arrive at ITEM_FULL_RENT). That is a property of the
            // NUMBER, not of the expression, and the expression is one raise away
            // from bricking sales on the mainstream path. Whoever changes
            // `ITEM_MIN_STORAGE` owns that.
            val keptRecords = ownerChanged ? 0 : (storage.recordCount as int);
            val rentFloor = ITEM_MIN_STORAGE + keptRecords * RECORD_RENT_RESERVE;
            var keep = (contract.getOriginalBalance() as int) - (in.valueCoins as int);
            if (keep > ITEM_FULL_RENT) { keep = ITEM_FULL_RENT; }
            if (keep < rentFloor)      { keep = rentFloor; }
            reserveGramsOnBalance(keep as coins,
                RESERVE_MODE_EXACT_AMOUNT | RESERVE_MODE_BOUNCE_ON_ACTION_FAIL);

            storage.owner = msg.newOwner;
            // R12. A SOLD NAME MUST NEVER RESOLVE TO THE SELLER.
            //
            // This is the property emoji_resolver_v2's SyncNameOwner wipe existed
            // to guarantee, and it is now enforced in the same transaction that
            // moves ownership rather than three messages later. That closes the
            // window the old design had by construction: the wipe used to travel
            // item -> collection -> registrar -> resolver with IGNORE_ERRORS on the
            // last hop, so an underfunded fan-out could leave the buyer owning a
            // name that still paid the seller (V7-1). Here it cannot be dropped,
            // cannot be underfunded, and cannot arrive late.
            //
            // Stricter than ENS, deliberately, and unchanged from v2's semantics:
            // the buyer sets their own record.
            if (ownerChanged) {
                storage.records = null;
                storage.recordCount = 0;
            }
            storage.save();

            // keep the registry of record in sync: item -> collection -> registrar
            // (bounceable + funded; a failed relay returns to onBouncedMessage)
            // V7-1: forward the sender's surplus so a multi-resolver fan-out is
            // actually funded, instead of a fixed amount sized for one resolver.
            storage.sendSyncOwner(msg.queryId,
                relayValue(in.valueCoins as int, msg.forwardTonAmount as int) as coins);

            if (msg.forwardTonAmount > 0) {
                val notify = createMessage({
                    bounce: BounceMode.NoBounce,
                    value: msg.forwardTonAmount,
                    dest: msg.newOwner,
                    body: OwnershipAssigned {
                        queryId: msg.queryId,
                        prevOwner: owner,
                        forwardPayload: msg.forwardPayload,
                    }
                });
                // R17-35: +16 — this is the send that actually fails first at a large
                // forward_payload, measured at 1,000 cells.
                notify.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
            }

            if (msg.responseDestination != null) {
                // V7-15: the Excesses message carries the REMAINING INBOUND VALUE
                // (mode 64), but the two sends above used PAY_FEES_SEPARATELY, so
                // their forward fees came off this item's own balance. Measured
                // before the fix: one transfer with a responseDestination left the
                // item at 0.0359 GRAM — BELOW its 0.05 rent floor. Repeat that and
                // the item drifts toward frozen, taking the name with it.
                //
                // The reserve that answers that now stands at the TOP of this
                // handler (R17-23), so CARRY_ALL_BALANCE here sends exactly the
                // surplus above the floor and nothing else. TEP-62 still gets its
                // Excesses message — which mode 64 alone would have skipped once
                // the item was short — and the item keeps its storage at every
                // payload size, not just the small ones.
                val excess = createMessage({
                    bounce: BounceMode.NoBounce,
                    value: 0,
                    dest: msg.responseDestination!,
                    body: Excesses { queryId: msg.queryId }
                });
                excess.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
            }
        }

        ResyncOwner => {
            // R23-4 sibling — see AskStaticData. `msg.queryId` is reached inside
            // `sendSyncOwner` once the two asserts below pass, so a 32-bit body
            // underflows there. Measured pre-fix: exit 9, 0 out-messages,
            // 0.100307 of 0.1 GRAM absorbed. This arm is permissionless, so its
            // callers are healer bots rather than a known operator — the same
            // reason the registrar's `ApplySigner` gap mattered.
            //
            // Guard placed FIRST: a shape refusal must not depend on the item
            // being initialised or on the caller having funded the relay, or the
            // diagnostic the caller gets depends on which of three unrelated
            // things is wrong.
            if (in.body.remainingBitsCount() != BODY_OP_QUERYID) {
                rejectAndRefund(in.senderAddress, ERR_BAD_BODY);
                return;
            }
            // Fix #1: permissionless desync heal. Requires the name to be
            // initialized; re-pushes the item's CURRENT owner. Cannot forge
            // ownership (reads storage.owner). Caller must fund the relay.
            assert (storage.owner != null) throw ERR_NOT_INIT;
            assert (in.valueCoins >= NOTIFY_VALUE + MIN_TRANSFER_GAS) throw ERR_INSUFFICIENT_VALUE;
            // V7-1: a healer who pays more heals more resolvers. This is the
            // only recovery path when a fan-out was skipped, so it must be able
            // to fund the full set.
            storage.sendSyncOwner(msg.queryId, relayValue(in.valueCoins as int, 0) as coins);
        }

        // R12: the holder writes their own records, directly on their own name.
        SetRecord => {
            // R12-3-GAP. THE OPCODE CHANGE ALONE DID NOT CLOSE THE CLASS.
            //
            // R12-3 gave this handler its own opcode so that the resolver's
            // prefix-compatible body — which carries an extra leading labelHash:256
            // — would fail loudly instead of being silently misread. That closed
            // *old opcode + old shape*. It did not close *NEW opcode + old shape*:
            // a front end that updates the opcode constant (a one-line change, and
            // the obvious response to a rejected message) but keeps the old builder
            // is back to exit 0 with an empty wallet category.
            //
            // Tolk's `lazy` union parsing does not assert the body was fully
            // consumed, so shape confusion can only be ruled out by measuring. The
            // body is exactly op(32) + queryId(64) + category(256) + Maybe(1) = 353
            // bits, with the record itself in a ref. Anything else is a different
            // message wearing this opcode.
            // R31-1. REFUSE, DO NOT THROW — R26-3 FIXED THE REF SHAPE THREE LINES
            // BELOW AND LEFT THE BIT COUNT THROWING.
            //
            // This assert and R26-3's guard answer the SAME event with the SAME
            // code (418) and opposite value semantics: a body one bit off absorbs
            // the sender's whole attachment on a bounce-stripping wallet, while a
            // body with a missing ref hands it back. R8-12 is the reason this file
            // refunds at all, and these were the last two parse-class refusals in
            // any of the four contracts that still kept the money.
            if (in.body.remainingBitsCount() != 353) {
                rejectAndRefund(in.senderAddress, ERR_BAD_RECORD_BODY);
                return;
            }
            // R26-3. THE BIT COUNT WAS CHECKED AND THE REF WAS NOT — SO THE ONE
            // BODY THAT PASSES 353 AND STILL UNDERFLOWS IS AN UNCATALOGUED EXIT 9.
            //
            // `record: cell?` serialises as `Maybe ^Cell`. A body of exactly 353
            // bits with the Maybe bit SET and ZERO refs satisfies the assert above,
            // and then Tolk's eager load of `msg.record` on the next line reaches
            // for a ref that is not there. Measured on the shipped bytecode:
            //
            //     op|queryId|category:256|Maybe=1, 0 refs   ->  exit 9
            //
            // exit 9 is a bare cell-underflow: it is in no error table, no front
            // end can translate it, and it fires before any owner check, so any
            // sender reaches it. That is precisely the class R21-2 and R23-4 spent
            // two rounds removing from this file — and the R23-4 note below claims
            // it is already closed HERE by "the exact bit-count asserts (353 /
            // 352)". It was closed for `ChangeDnsRecord`, which checks its ref
            // count on the next line, and not for this arm.
            //
            // Any builder that sets the Maybe bit before deciding on the payload
            // produces it. Refuse it the way this file refuses every other
            // malformed shape: a legible RejectedRefund, not a naked TVM exit.
            var recProbe = in.body;
            recProbe.skipBits(352);
            if (recProbe.loadBool() && in.body.remainingRefsCount() < 1) {
                rejectAndRefund(in.senderAddress, ERR_BAD_RECORD_BODY);
                return;
            }
            applyRecordWrite(mutate storage, in.senderAddress, msg.category, msg.record);
            storage.save();
        }

        // R20-3. THE ALIAS. Identical semantics, the wire shape the ecosystem
        // actually builds. Both arms call ONE function, so the guards cannot
        // diverge and neither can the rent charge.
        ChangeDnsRecord => {
            // The body-length guard is the analogue of SetRecord's 353, and it
            // closes the same R12-3-GAP shape-confusion class: the RESOLVER's
            // prefix-compatible `op|queryId|labelHash:256|category:256|Maybe`
            // body carries 609 bits, so a front end that changed only the opcode
            // constant is refused rather than silently writing an empty record
            // under a garbage category. 352 data bits exactly, and at most one
            // ref, whose PRESENCE is the set/delete discriminator — see the
            // struct for the four client implementations that agree on this and
            // the one Maybe-bit reading that would have rejected all of them.
            // R31-1, second door. `change_dns_record` (0x4eb1f0f9) is the STANDARD
            // TEP-81 op — any wallet, explorer or dApp can build it, the gate sits
            // above the owner check so any sender reaches it, and three shapes a
            // real builder produces land here: value stored inline instead of as a
            // ref (368 bits), no queryId (288 bits), two refs. Each one absorbed
            // the whole attachment. Same event, same code, so the same refund
            // R26-3 and R26-4 already give two and eight lines below.
            if (in.body.remainingBitsCount() != 352) {
                rejectAndRefund(in.senderAddress, ERR_BAD_RECORD_BODY);
                return;
            }
            var restS = msg.rest;
            if (restS.remainingRefsCount() > 1) {
                rejectAndRefund(in.senderAddress, ERR_BAD_RECORD_BODY);
                return;
            }
            val value: cell? = restS.remainingRefsCount() > 0 ? restS.loadRef() : null;
            // R20-4. `key == 0` WITH NO REF IS TONKEEPER'S RENEW BUTTON, AND THIS
            // CONTRACT WILL NOT PRETEND TO HONOUR IT.
            //
            // Three things collide on this one message shape:
            //
            //   Tonkeeper  nft-encoder.ts sends exactly `op|queryId|0:256`, no
            //              ref, `nftRenewAmount = toNano('0.02')`, at the ITEM.
            //   tonapi     bath/dns.go:28 detects exactly key==0 + no ref +
            //              HasInterface(NftItem) and renders a "Domain Renew"
            //              action in every explorer and wallet history.
            //   .ton       prolongs on any owner-signed op, so there the button
            //              is honest and free.
            //
            // Ours is a REGISTRAR-PRICED rental: `RenewName` costs 0.75-50 GRAM
            // depending on tier, the term lives in the registrar's `names` map,
            // and this item cannot extend its own `expiresAt` — only
            // `UpdateExpiry` from the collection can, and the collection only
            // relays what the registrar ruled. Three options were on the table.
            //
            //   (b) ACCEPT IT AS A TOP-UP. Rejected. It costs one line and buys
            //       a lie: tonapi would render "Domain Renew" on a transaction
            //       that moved no term, in the one surface a holder checks to
            //       find out whether their name is safe. A holder who believes
            //       a name is renewed and lets it lapse loses it after grace to
            //       anyone who re-registers it. The whole reason this contract
            //       refuses category 0 (R12-5) and dns_next_resolver (R14-6) is
            //       that it will not store something that cannot be read back as
            //       its author intends; accepting a renewal that did not happen
            //       is the same defect with a user-visible label attached.
            //
            //   (c) RELAY A GENUINE RENEWAL ONWARD. Rejected on measurement, not
            //       on principle. The item knows only its collection, so this
            //       needs a new collection opcode and two extra hops to reach
            //       `RenewName` — and the value that arrives is the wallet's
            //       hardcoded 0.02 against a 0.75 GRAM floor, so 100% of real
            //       renew clicks would travel four hops to be refunded. The
            //       holder's outcome is identical to the refusal below; the
            //       difference is that the refusal is legible in one hop, and
            //       does not add an ingress door to the collection for a path
            //       that is unfunded by construction.
            //
            //   (a) REFUSE — shipped, with its OWN exit code rather than the
            //       417 the shipping build happened to give it. 417 means
            //       "category 0 is the whole-dict selector and a record filed
            //       there is unreadable", which is true of `key == 0` WITH a ref
            //       and stays 417 below. It is not what happened here. 477 says
            //       one thing only: this was a renewal attempt, renewal is not
            //       an item operation, send `RenewName` to the registrar. A
            //       front end can map it to that sentence; 417 it could only map
            //       to a sentence about categories.
            //
            // WHAT IS DELIBERATELY NOT DONE: `key == 0` with no ref is also the
            // shape that would most naturally mean "clear every record", by
            // symmetry with `dnsresolve(0)` returning the whole dict. That
            // reading is unavailable precisely because Tonkeeper aims its RENEW
            // button at it — a holder clicking Renew would silently wipe every
            // record they own. The button decides what this message may do, and
            // the only safe answer is nothing.
            // R26-4. REFUSE IT, BUT REFUND IT.
            //
            // R20-4 chose `throw` here on the grounds that the refusal is "legible
            // in one hop". It is — but a throw returns the attachment only if the
            // sender set the bounce bit, and R17-35's rule everywhere else in this
            // file is that a refusal to a WALLET-ORIGINATED message must be
            // `rejectAndRefund` for exactly that reason. This is the single most
            // predictable wallet-originated refusal the contract has: R20-4's own
            // analysis names the caller as Tonkeeper's Renew button, sending
            // `op|queryId|0:256` with no ref at `nftRenewAmount = 0.02`, and tonapi
            // renders it as "Domain Renew" in every explorer. Measured on the
            // shipped bytecode:
            //
            //     bounceable      exit 477, 0.019764 of 0.02 returned
            //     NON-bounceable  exit 477, 0.000000 returned   <- the whole attachment
            //
            // R8-12 measured OpenMask stripping the bounce bit live, so the second
            // row is a real population, and a confused holder can repeat it on
            // every tap. The semantics do not change — the message still does
            // nothing, for the reason given above — only the receipt does.
            //
            // Safe here because the guard sits before any state write, which is the
            // documented precondition for this helper.
            if (msg.key == 0 && value == null) {
                rejectAndRefund(in.senderAddress, ERR_RENEW_AT_REGISTRAR);
                return;
            }
            applyRecordWrite(mutate storage, in.senderAddress, msg.key, value);
            storage.save();
        }

        AskStaticData => {
            // R23-4 (confirmed independently by TSA and by manual review). THE
            // TEP-62 QUERY EVERY INDEXER SENDS, WITH NO BODY-SHAPE GUARD.
            //
            // Tolk's `lazy` load fires at first field access, so a body carrying
            // only the 32-bit opcode underflows on `msg.queryId` — exit 9,
            // uncatalogued, and because real wallets strip the bounce flag the
            // sender's value is absorbed with no refund and no diagnostic. R21-2
            // gave `AskTransfer` a full struct walker and a `RejectedRefund`, and
            // `SetRecord` / `ChangeDnsRecord` exact bit-count asserts (353 / 352
            // above); this arm and `ResyncOwner` were missed.
            //
            // `get_static_data` is not a low-traffic arm — it is the op every
            // marketplace and indexer sends on discovery, so a wrong-shaped
            // standard query silently costs the integrator its attached value
            // instead of erroring visibly. Measured pre-fix: 32-bit body, exit 9,
            // 0.100307 GRAM absorbed; 64-bit body (op + half a queryId) likewise.
            //
            // Refuse-and-refund rather than throw, matching the R17-34 policy the
            // unknown-op arm below already follows: everything else goes home.
            if (in.body.remainingBitsCount() != BODY_OP_QUERYID) {
                rejectAndRefund(in.senderAddress, ERR_BAD_BODY);
                return;
            }
            val report = createMessage({
                bounce: BounceMode.NoBounce,
                value: 0,
                dest: in.senderAddress,
                body: ReportStaticData {
                    queryId: msg.queryId,
                    index: storage.index,
                    collection: storage.collection,
                }
            });
            report.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS);
        }

        else => {
            // R17-34. `throw 0xffff` WAS CONFISCATION FOR HALF THE SENDERS.
            //
            // A throw refunds only if the sender set the bounce bit, and R8-12
            // recorded a wallet this project demoed with sending the non-bounceable
            // form at an EQ address anyway. R13X-6 converted the registrar and left
            // the other three; the collection followed. This one matters most of
            // the four: the item is the contract a HOLDER'S OWN WALLET talks to,
            // which is exactly the population R8-12 was written for, and the one
            // that pays a mis-versioned front end's opcode out of its own pocket.
            //
            // A genuine top-up never reaches here — the `remainingBitsCount() < 32`
            // guard at the entry point returns first — so the only bodies this arm
            // sees are ones this contract cannot interpret: the resolver's SetRecord
            // shape (R12-3's whole point), a mis-addressed collection op, a wallet
            // text comment with a non-zero tag. Op 0 is the wallet text-comment
            // convention and stays a top-up; everything else goes home, carrying the
            // reason so the sender learns why and an indexer can tell a rejection
            // from a transfer.
            //
            // R31-2. R17-36 WAS PRICED AS BOUNDED AND MIS-WIRING-ONLY. BOTH HALVES
            // OF THAT WERE WRONG, AND R25-6b ALREADY REACHED THE OPPOSITE
            // CONCLUSION — IN THE REGISTRAR ONLY.
            //
            // It does not need a mis-wiring. `AskTransfer` answers
            // `response_destination` with an Excesses (0xd53276db) at
            // CARRY_ALL_BALANCE. Name any peer with no ingress arm for that opcode
            // — the collection, the resolver, or ANY SIBLING ITEM — and the peer
            // answers RejectedRefund, which this arm does not know either. That is
            // one ordinary TEP-62 transfer from the item's own owner, and
            // scripts/r16-nft-checks.ts already documents a third-party
            // `response_destination` as a supported case.
            //
            // Nor is it bounded in any useful sense. What enters the loop is the
            // item's ENTIRE balance above `keep`, not the transfer's attachment,
            // and anyone may top an item up with a bodiless value message.
            // Measured, response_destination = the collection: 123 transactions
            // and 0.0357 GRAM burned at a 0.5 balance; 1,647 and 0.468 at 1.0;
            // 4,696 and 1.3325 at 2.0. The item always survives at exactly
            // ITEM_FULL_RENT — the difference is burned, not delivered, which is
            // also a TEP-62 §1.3 failure, since the remainder is owed to
            // `response_destination`.
            //
            // R25-6b's rule is the fix: an incoming 0x7e3a11c5 is itself the
            // peer-loop predicate, whoever sends it. A sender who produces that
            // body is by construction telling this contract it is refusing a
            // payment, which is not a payment to hand back. No wallet, front end
            // or indexer builds it; it is emit-only in all four contracts.
            //
            // R21-2 factored this send into `rejectAndRefund` so the malformed-body
            // guard on AskTransfer and this arm cannot drift apart: they are the same
            // event — a body this contract will not act on — answered the same way,
            // with only the reason code distinguishing "cannot interpret" (465) from
            // "cannot parse" (468).
            val opU = in.body.preloadUint(32);
            if (opU != 0 && opU != OP_REJECTED_REFUND) {
                rejectAndRefund(in.senderAddress, ERR_UNKNOWN_OP);
            }
            return;
        }
    }
}

// ---- bounce handler ----
//
// Fix #1: if a SyncOwner relay bounces (collection rejected / under-gas), the
// ownership change on THIS item is still legitimate — we do NOT revert it.
// The desync is recoverable by anyone calling ResyncOwner. We deliberately
// no-op here (ownership stays as set) rather than silently dropping the fact.
fun onBouncedMessage(in: InMessageBounced) {
    // Ownership on the item is authoritative and already committed. A bounced
    // SyncOwner means the registry lags; heal via the permissionless
    // ResyncOwner op. No state change here (reverting would strand the NFT).
    return;
}

// ---- get methods ----

// TEP-62 required
//
// tonapi (HIGH). THIS METHOD MUST NEVER PUT A TVM NULL ON THE STACK.
//
// It returned `address?` and `cell?`, both of which serialise to VmStkNull when
// empty — and an unminted-but-deployed item (R17-1's 0.06 GRAM shell, or an
// account somebody topped up at a name's derived address) has both. Verified
// against tonkeeper/tongo at source, this is not a degraded read, it is no read
// at all: `abi/get_methods.go:4802` checks the STACK SHAPE before decoding and
// requires slot 3 = VmStkSlice and slot 4 = VmStkCell, so `GetNftData` returns
// "can not decode outputs" and tonapi never classifies the account as an NFT.
// No indexing, no NftItemTransfer action, no DomainRenew action, no `verified`
// badge, no Tonkeeper risk card — for the whole collection, from one item state
// anyone can create. It is the same line GetGems mis-attributes `.ton` items on
// (`readAddress()` on owner_address), which is the shape R17-1 measured:
// "STRICT TEP-62 reader: stack decode threw: Not a cell: null".
//
// `addr_none` (b{00}) and an empty cell are the conformant answers. `addr_none`
// is a first-class arm of tlb.MsgAddress, it is what TON DNS's own root
// collection ships in production, and TEP-62's `init?` flag in slot 0 remains
// the authoritative "is there an owner" signal — no information is lost, it is
// merely encoded in a form every reader already has a case for.
get fun get_nft_data(): (bool, uint256, address, any_address, cell) {
    val storage = ItemStorage.load();
    val content = storage.content;
    return (
        storage.owner != null,
        storage.index,
        storage.collection,
        ownerOrNone(storage.owner),
        content != null ? content! : beginCell().endCell()
    );
}

/**
 * R20-7. ADDRESS -> NAME, THE WAY THE ECOSYSTEM ALREADY ASKS FOR IT.
 *
 * THE SHAPE IS NOT A CHOICE — it is transcribed from the implementation every
 * reader was written against, `ton-blockchain/dns-contract/func/nft-item.fc`,
 * read 2026-08-11:
 *
 *     ;; cell domain - e.g contains "alice" (without ending \0) for "alice.ton"
 *     slice get_domain() method_id {
 *         (…, cell domain, …) = load_data();
 *         return domain.begin_parse();
 *     }
 *
 * So: a BARE SLICE of the LABEL's raw UTF-8 bytes. No length prefix, no TEP-64
 * tag, no zone suffix, no trailing NUL. Three consumers, all agreeing:
 *   tongo   abi/schemas/dns.xml  <get_method name="get_domain">
 *                                  <slice name="domain">string</slice>
 *   tonweb  DnsItem.getDomain()  decodes the returned slice's bytes as UTF-8
 *   MyTonWallet  getDnsItemDomain() -> get_domain, in verifyTonDnsLinkedAddress
 *
 * WHY IT IS STORED AND NOT DERIVED. R19/T7 posed the choice as "store the label
 * (costs storage and a wire field) or derive it from the TEP-64 suffix (free)".
 * Both were measured; derive lost on three counts and the first is decisive:
 *
 *   1. R20-6 percent-encodes the suffix, so the suffix is no longer the name.
 *      Deriving now means a percent-DECODER in a get-method — ~111 iterations of
 *      hex parsing, on the read path, that can be made to throw by any content
 *      cell the admin `Mint` door accepts. "Free" stopped being true this round.
 *   2. It is EMPTY on an `AdoptItem`-repaired orphan (0 bits of content, R17-1)
 *      and on any admin `Mint` whose content is not an encoded name.
 *   3. Stored, the pair (label, index) is CHECKABLE: any reader can verify
 *      sha256(get_domain()) == index in one call and know the item is not lying
 *      about which name it is. Derived, that check is circular.
 *
 * MEASURED COST, on the pessimistic param-18 row (bit_price_ps 1, cell_price_ps
 * 500 — the row R17-10 sizes the rent floor against):
 *
 *     label cell, worst case  1 cell + 888 bits = 1,388 storage units
 *     rent                    1,388 * 31,536,000 / 65,536 = 0.000668 GRAM/yr
 *     over MAX_TOTAL_TERM     0.00668 GRAM
 *
 * against an `ITEM_FULL_RENT` of 0.36 — 1.9% of the item's own prepaid budget,
 * and it is inside the number, not on top of it. The wire field rides on
 * `InitOrReassign` and `MintFwd`, both of which already carry `content`.
 */
get fun get_domain(): slice {
    val label = ItemStorage.load().label;
    // An empty slice, never a throw: `get_domain` is called speculatively by
    // indexers on any account, and the R18 lesson from `get_nft_data` is that a
    // getter which throws on a legitimate state is a getter that removes the
    // whole contract from an indexer's view. An orphan answers "" — which is
    // true — rather than exit 11.
    return label != null ? label!.beginParse() : beginCell().endCell().beginParse();
}

/**
 * R20-7. The telemint shape, for the readers that ask for that one instead.
 *
 * `TelegramMessenger/telemint/func/nft-item.fc`, read 2026-08-11:
 *
 *     slice get_full_domain() method_id {
 *         …
 *         return begin_cell().store_slice(domain).store_slice(token_name)
 *                            .store_int(0, 8).end_cell().begin_parse();
 *     }
 *
 * where telemint's `domain` is the zone in TEP-81 INTERNAL representation, so a
 * `.t.me` item answers `"me\0t\0durov\0"`. Ours is the same construction over
 * `emojiverse.ton`: `"ton\0emojiverse\0" + label + "\0"`.
 *
 * THE ZONE IS ALREADY A CHAIN CONSTANT, so this hardcodes nothing new.
 * `MAX_NAME_BYTES` is literally derived from it in emoji_registrar_v4.tolk —
 * `127 - len("\0ton\0emojiverse\0") - 1 = 110` (R24-3 corrected this: the old
 * form omitted the leading self byte every root-walking client prepends, and was
 * one byte over) — which is also why the result of
 * this method fits one cell with a byte to spare at the longest legal name:
 * 15 + 110 + 1 = 126 bytes = 1008 bits, against a cell's 1023. R24-3 moved the
 * cap and this line kept quoting the pre-R24 111, i.e. it described a name the
 * registrar can no longer issue; the margin is 15 bits, not 7.
 *
 * AND IT DOES NOT COST R7-21'S ROOT-AGNOSTICISM. That invariant is about
 * RESOLUTION — "the answer must be a function of the LABEL ALONE, never of which
 * parent delegated to it" — and nothing here is on a resolution path.
 * `dnsresolve` is untouched and still reads only the label the parent hands
 * down, so the `.emoji` play is exactly as open as it was. This method reports
 * the zone the project publishes in `integration/tonapi/emojiNames.ts`
 * (`CANONICAL_ZONE`), and a reader that wants the parent-relative answer uses
 * `get_domain`, which is the one every `.ton`-family client actually calls.
 */
get fun get_full_domain(): slice {
    val label = ItemStorage.load().label;
    if (label == null) { return beginCell().endCell().beginParse(); }
    // "ton\0emojiverse\0" — 15 bytes, pinned byte-for-byte by the R20 item suite
    return beginCell()
        .storeUint(0x746F6E00656D6F6A69766572736500, 120)
        .storeSlice(label!.beginParse())
        .storeUint(0, 8)
        .endCell().beginParse();
}

// project-specific: the rights record
get fun get_name_record(): (uint32, bool, bool) {
    val storage = ItemStorage.load();
    return (storage.expiresAt, storage.isReserved, storage.isWithinGrace());
}


/// Tier as stored on-chain, for marketplaces and indexers.
/// 1 Mythic · 2 Legendary · 3 Epic · 4 Rare · 5 Uncommon · 6-7 Common
get fun get_tier(): (int, int) {
    val st = ItemStorage.load();
    return (st.emojiCount, st.syncNonce);
}

/// Everything an indexer needs in one call.
///
/// tonapi: `any_address` for the same reason get_nft_data uses it, applied as a
/// house rule rather than case by case. No optional address ever leaves a
/// get-method of this contract as a TVM null — a reader that hits one here is a
/// reader that has already succeeded on the TEP-62 method and then falls over on
/// the project-specific one, which is the worse of the two failures because
/// nobody is testing for it. Emptiness is still readable: addr_none, and
/// expiresAt == 0 with isReserved == false, is an item that has never been issued.
get fun get_name_data(): (int, any_address, int, int, bool) {
    val st = ItemStorage.load();
    return (st.index, ownerOrNone(st.owner), st.expiresAt, st.emojiCount, st.isReserved);
}

/**
 * R12. TEP-81 — THIS NAME ANSWERS FOR ITSELF.
 *
 * The shape `.ton`'s domain item uses, and the reason the whole namespace is no
 * longer bounded by one contract's state. The collection consumes the zone label
 * and this name's label, leaving the trailing separator, and points the client
 * here; this method then answers from its own storage.
 *
 *   root        "\0ton\0emojiverse\0<name>\0"  -> consumes "\0ton",        -> .ton collection
 *   .ton coll   "\0emojiverse\0<name>\0"       -> consumes "\0emojiverse", -> our zone
 *   our coll    "\0<name>\0"                   -> consumes "\0<name>",     -> THIS ITEM
 *   this item   "\0"                           -> resolved, returns records
 *
 * A leading \0 is the self-reference byte TEP-81 requires of every non-root
 * resolver; it is skipped if present, matching the reference nft-item.fc. Once it
 * is gone nothing must remain — this item is one name, not a zone, so a further
 * label is not something it can answer and it reports NOT FOUND rather than
 * guessing.
 *
 * F-6 / R8-2 PARITY: a name past expiry + grace is nobody's, so it must stop
 * resolving. That check lived in the resolver and is now local, which means it can
 * no longer be out of step with the term this contract actually holds.
 *
 * tonapi #3/#4. THE SHAPE OF EVERY ANSWER BELOW IS AUDITED, NOT ASSUMED, because
 * one of the two ways to get it wrong is an HTTP 500 rather than a 404. Read
 * against tonkeeper/tongo at source (`contract/dns/dns.go`, `tlb/dns.go`):
 *
 *   (0, null)            -> dns.go:89-91 matches VmStkTinyInt 0 + VmStkNull and
 *                           returns ErrNotResolved. A clean "not found".
 *   (bits, null)         -> dns.go:92-95, stack.Unmarshal cannot put a null into
 *                           `Result boc.Cell`, and the error IS wrapped in
 *                           ErrNotResolved. Also a clean "not found".
 *   (bits, EMPTY CELL)   -> dns.go:102-106 takes the full-match branch and
 *                           unmarshals tlb.DNSRecordSet, which fails "not enough
 *                           bits" — and THAT error is returned RAW, not wrapped.
 *                           tonapi answers 500. THIS SHAPE MUST NEVER BE EMITTED.
 *   (bits, dict root)    -> the good path. tlb.DNSRecordSet is
 *                           `Hashmap[Bits256, Ref[DNSRecord]]` — the ROOT form,
 *                           with no leading maybe bit — which is exactly what a
 *                           Tolk `dict` holds. Not a HashmapE, and not a bare
 *                           DNSRecord.
 *
 * R23-9 CORRECTION TO THE PARAGRAPH BELOW. The two reasons given were about the
 * dict ROOT and neither constrained a record VALUE, so `(bits, EMPTY CELL)` — the
 * shape this comment declares MUST NEVER BE EMITTED — was reachable by writing a
 * zero-bit cell as a record, and the category-0 form embedded it as a leaf, which
 * poisons the whole set rather than one category. `MIN_RECORD_BITS` now enforces
 * it at the WRITE, which is the only place it can be enforced: by the time
 * `dnsresolve` runs, a bad value is already in storage and a get method has no
 * way to signal a refusal. Both original reasons still hold and are retained.
 *
 * The empty-cell shape is unrepresentable here and stays that way for three
 * reasons: the `records == null` arm returns before the category-0 arm can hand
 * back an empty root; uDictDelete of the last entry nulls the dict rather than
 * leaving an empty one, so `records != null` implies at least one leaf; and no
 * value shorter than a 16-bit TEP-81 constructor tag can be stored in the first
 * place (R23-9).
 */
get fun dnsresolve(subdomain: slice, category: uint256): (int, cell?) {
    var s = subdomain;
    val totalBits = s.remainingBitsCount();
    // TEP-81: the internal representation is whole bytes. The reference root
    // resolver throws 70 rather than mis-parsing a ragged slice; match it.
    assert (totalBits % 8 == 0) throw ERR_BAD_SUBDOMAIN;
    // R23-2 (same rule as the collection's router). Every length test here is
    // `remainingBitsCount()`, which does not see refs — so the "nothing may
    // remain" gate below passed for a query whose ROOT CELL ends at the
    // separator but which CONTINUES in a reference, and this item answered with
    // its own records for a strictly deeper name. Answering for a name we did not
    // read in full is the one thing a resolver must never do. Refuse: 0 is NOT
    // FOUND, which is the honest report.
    if (s.remainingRefsCount() != 0) {
        return (0, null);
    }
    // tonapi #5. `resolved_bits` IS AN INDEX INTO THE CALLER'S OWN BUFFER, AND
    // THE CALLER DOES NOT BOUND IT.
    //
    // tongo/contract/dns/dns.go:127 continues a partial resolution with
    // `dom[result.ResolvedBits/8:]` and no length check, so a resolver that
    // reports MORE bits than it was handed does not produce an error in tonapi —
    // it produces a Go slice-out-of-range PANIC. Byte alignment (throw 70, one
    // line up) is the same class of hazard and is already pinned; this is its
    // upper half, and the two together are the complete contract the reader
    // assumes and never verifies.
    //
    // Stated honestly: today this holds by construction — `totalBits` is read
    // once, from the caller's own slice, and every return below reports either it
    // or 0. It is asserted anyway because "holds by construction" is precisely
    // what stops holding the day someone adds a partial-match path (`.ton`'s
    // nft-item.fc returns 8 for a residual label), and on the other end of the
    // wire there is no second line of defence.
    assert (totalBits <= subdomain.remainingBitsCount()) throw ERR_BAD_SUBDOMAIN;
    if (totalBits == 0) {
        return (0, null);       // 0 resolved bits means LOOKUP FAILED
    }
    val storage = ItemStorage.load();
    // an unissued name resolves to nothing (the item may exist but hold no owner)
    if (storage.owner == null) {
        return (0, null);
    }
    // F-6: past expiry + grace this name is nobody's — never point at a former
    // holder's wallet.
    if (!storage.isWithinGrace()) {
        return (0, null);
    }
    // skip the self-reference byte if present
    if (s.preloadUint(8) == 0) {
        s.skipBits(8);
    }
    // anything left is a sub-subdomain, which one name cannot serve
    if (s.remainingBitsCount() != 0) {
        return (0, null);
    }
    if (storage.records == null) {
        // issued, live, but the holder has set no records yet: RESOLVED, empty.
        // Distinct from (0, null) — the name exists, it simply points nowhere.
        //
        // tonapi #3: `null`, never `beginCell().endCell()`. Both read as "no
        // records" to a human; only one of them reads as a 404 to tongo. See the
        // shape table above.
        return (totalBits, null);
    }
    if (category == 0) {
        // tonapi #4: the RAW dict root, so tlb.DNSRecordSet's root-form
        // `Hashmap 256 -> ^DNSRecord` lands on exactly the bits it expects.
        // Reached only when at least one leaf exists, per the arm above.
        return (totalBits, storage.records);    // whole dict, per TEP-81
    }
    val records: dict = storage.records;
    val (recordCell, exists) = records.uDictGetRef(256, category as int);
    if (!exists) {
        return (totalBits, null);
    }
    return (totalBits, recordCell);
}

/// R12 observability: (recordCount, hasRecords). Lets an indexer see whether a
/// name carries records without decoding the dict.
get fun get_records(): (int, cell?) {
    val st = ItemStorage.load();
    return (st.recordCount, st.records);
}
