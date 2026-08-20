// emoji_nft_collection.tolk — TEP-62 NFT collection for emoji names
// Emoji Name Service · P1 NFT layer · Tolk 1.4.2
//
// Emojiverse · Emoji Name Service on TON
//   Website : https://emojiverse.xyz
//   X       : https://x.com/emojiverse_xyz
//   Zone    : emojiverse.ton   ·   Publisher: Hyperborea LLC
//
// Layering / trust model:
//   registrar (minter) --Mint/UpdateExpiry--> collection --> item
//   item --SyncOwner--> collection --OwnerSynced--> registrar (minter)
// The item trusts only the collection; the collection trusts the registrar
// (minter) and the admin. Item addresses are deterministic from
// (itemCode, index=nameHash, collection) so the collection can authenticate
// SyncOwner senders and anyone can compute get_nft_address_by_index.
//
// next_item_index is reported as -1 (non-sequential indexes, .ton-domains
// style): index = sha256(normalized emoji string).
//
// Content (TEP-64): collectionContent is the collection-level metadata cell;
// commonContent is the base-URI slice cell prepended to each item's
// individual content in get_nft_content (offchain concat pattern, the same
// one Getgems parses for .ton domains).
//
// Royalty (TEP-66): report_royalty_params + royalty_params get method, so
// secondary sales on Getgems pay the foundation.

tolk 1.4

// ---- exit codes ----
const ERR_NOT_ADMIN = 401;
const ERR_NOT_MINTER = 402;
const ERR_NOT_ITEM = 403;
const ERR_BAD_ROYALTY = 405;         // numerator > denominator
const ERR_LOW_RELAY_VALUE = 407;     // sync relay under-funded
const ERR_EXPIRY_OUT_OF_RANGE = 408; // R7-3/R7-4: expiry beyond the registrar's horizon
const ERR_BAD_CONTENT = 409;         // R7-7: commonContent would overflow get_nft_content
const ERR_ZERO_ADDRESS = 410;        // R7-8: zero admin / minter
const MAX_COMMON_CONTENT_BITS = 900; // R7-7: leaves room for the 0x01 tag and headroom
const ERR_TIMELOCK_ACTIVE = 411;     // R7-11: accept/apply before the delay elapsed
const ERR_NOTHING_PENDING = 412;     // R7-11: nothing staged
const ERR_NOT_SUCCESSOR = 413;       // R7-11: only the nominee may accept
// R31-3. Pinned to the registrar's number for the identical predicate (R17-9 /
// R17-20), per the standing rule that a client maps an exit code to a message
// without knowing which contract produced it. Reusing ERR_ZERO_ADDRESS here would
// have told an operator "zero address" about a perfectly good non-zero one.
const ERR_SELF_REFERENCE = 467;      // R31-3: a config address pointing at this contract
const HANDOVER_TIMELOCK = 172800;    // 48h, fixed. No setter — see the storage note.
// R20-1. MIRRORS THE ITEM'S `NOTIFY_VALUE`, WHICH IS THE ONLY THING THAT EVER
// PAYS IT. The item's relay floor came down 0.16 -> 0.02 so that a holder can
// move their own name from a stock wallet (Tonkeeper attaches 0.05, MyTonWallet
// 0.1, neither overridable). A 0.03 floor here would have turned that fix into a
// 407 one hop later: the transfer would still succeed on the item, the SyncOwner
// would bounce, and the registry would silently keep naming the SELLER — the
// exact V7-1 divergence class, re-opened from the other end.
//
// 0.015 is half the value the item guarantees, so the relay has 2x headroom over
// the floor, and it is still ~4x the measured cost of this hop (compute + the
// forward fee on to the registrar). Measured in audit/round20/wallets.
const MIN_RELAY_VALUE = 15000000;    // 0.015 GRAM floor for OwnerSynced relay (item NOTIFY_VALUE is 0.02)
const ERR_BAD_SUBDOMAIN = 70;        // TEP-81: subdomain must be byte-aligned
// The next three deliberately reuse the REGISTRAR's numbers, because they carry
// the registrar's exact meanings. R17-39's hazard is one number meaning two
// things across contracts; the cure is not a fresh number per contract but the
// same number for the same predicate, so an integrator's error map stays true
// whichever door a message hit.
const ERR_BAD_URI_SUFFIX = 460;      // R17-30: content is not a URI-safe suffix (registrar: ERR_BAD_CONTENT)
const ERR_BAD_PAYOUT_WC = 461;       // R17-28: basechain-only payout destination (registrar: ERR_BAD_PARTNER_WC)
const ERR_UNKNOWN_OP = 465;          // R17-34: body this contract cannot interpret
// R21-3. A FRESH NUMBER, CONTINUING THE SYSTEM-WIDE SEQUENCE: the registrar stops
// at 478 (R21-1's ERR_BAD_BODY_REF) and the item holds 477, so 479 is the next free
// one. Reusing a low gap would recreate exactly the R17-39 hazard R18 wrote the rule
// against. No other contract has this predicate, so there is nothing to align with.
const ERR_BAD_ITEM_INDEX = 479;      // R21-3: index outside [0, 2^256) — see
                                     // get_nft_address_by_index
// R23-4. Pinned to the number the registrar and the item already use for the
// identical predicate (468), so a client maps the code to a message without
// knowing which contract answered.
const ERR_BAD_BODY = 468;            // body shape does not match the op's struct
const BODY_OP_QUERYID = 96;          // op32 + queryId64 — a bare query's whole body
const DNS_NEXT_RESOLVER = 0xba93;    // TEP-81 record tag
// R9-1. Our own zone label, as the 56 bits a walking client actually sends:
// "\0" + "emoji" + "\0" = 00 65 6d 6f 6a 69 00. Pinned against
// integration/emojiZone.ts `suffixes` by tests/R9ZoneWalk.spec.ts, so the
// descriptor we hand integrators and the bytes the chain answers to cannot drift.
const ZONE_SELF_PREFIX = 0x00656d6f6a6900;
const ZONE_SELF_BITS = 56;           // the whole prefix, incl. both separators
const ZONE_LABEL_BITS = 48;          // what we CONSUME: "\0emoji", trailing \0 left
// R23-EMJ. THE SECOND ZONE LABEL, CO-EQUAL WITH THE FIRST.
//
// `.emj` is an ALIAS, not a second namespace: 🚀🌙.emj and 🚀🌙.emoji are the
// SAME name, the same NFT, the same owner and the same records. Nothing about
// storage changes — the item address is derived from sha256(<label>) and the
// zone label is consumed before the label is read, so both suffixes converge on
// one `index` and one item. There is no migration, no re-issue, and no second
// registration path: a name bought as `.emoji` answers as `.emj` from the block
// this code is live.
//
//     "\0" + "emj" + "\0"  =  00 65 6d 6a 00
//
// Consume "\0emj" (32 bits) and leave the trailing separator, exactly as the
// `.emoji` branch leaves it and exactly as mainnet's config-#4 root leaves it
// after eating "\0ton". The two prefixes cannot collide: they agree on the
// first three bytes (00 65 6d) and diverge on the fourth (0x6f 'o' vs 0x6a
// 'j'), so at most one branch can ever match a given query.
//
// Like `emoji`, `emj` is ASCII and therefore not a registrable label in an
// emoji-only namespace — see assertNotZoneLabel below, which now makes that
// structural rather than merely true-in-practice.
const ZONE_ALT_PREFIX = 0x00656d6a00;
const ZONE_ALT_BITS = 40;            // "\0emj\0", incl. both separators
const ZONE_ALT_LABEL_BITS = 32;      // what we CONSUME: "\0emj", trailing \0 left
// The bare labels, without separators, as a walking parent of the item-style
// shape delivers them: "emoji" (40 bits) and "emj" (24 bits).
const ZONE_LABEL_EMOJI = 0x656d6f6a69;
const ZONE_LABEL_EMOJI_BITS = 40;
const ZONE_LABEL_EMJ = 0x656d6a;
const ZONE_LABEL_EMJ_BITS = 24;

// R7-3. The registrar caps any term at 10 years from now and adds a 90-day
// grace; PERMANENT_EXPIRY is the one sentinel allowed past that. This collection
// forwards expiry writes to the item, and the item's UpdateExpiry is
// EXTEND-ONLY, so any value written here is permanent. Unbounded, one message
// wrote 0xFFFFFFFE and put an item a hair below the sentinel: never reassignable
// by anyone, not the registrar, not the admin who sent it, not ever — and unlike
// the real sentinel it is not even recognisably permanent to a reader.
//
// Mirrors the registrar's own bound rather than inventing a new one, so the two
// contracts cannot drift into disagreeing about what a legal term is.
const MAX_TOTAL_TERM = 315360000;    // 10 years, matches the registrar
const GRACE_PERIOD   = 7776000;      // 90 days, matches the registrar and the item
const PERMANENT_EXPIRY = 0xFFFFFFFF; // the ONE legitimate far-future value

struct RoyaltyParams {
    numerator: uint16
    denominator: uint16
    destination: address
}

// R8-1: THE ONE ADDRESS.
//
// Every third-party DNS zone the TON ecosystem recognises — `.ton`, `.t.me`,
// `.vipx.ton`, `.grm`, GetGems Domains — is ONE contract that is simultaneously
// the TEP-62 collection and the TEP-81 `dnsresolve` responder. Five out of five,
// no deployed counter-example. Six independent integrations take exactly one
// address per zone, and four of them compare it against `nft.collectionAddress`:
//
//   MyTonWallet   zone.resolver — used BOTH as the dnsresolve target AND as
//                 `zone.resolver === nft.collectionAddress`
//   tonapi        pkg/references/dns.go DomainSuffixes, keyed by collection
//   Tonkeeper     KnownNFTDnsCollections, a collection allowlist
//   toncenter     ton-index-worker Tokens.cpp, compile-time collection gate
//   toncenter     ton-index-go DetectInterface, probes for the dnsresolve id
//   tonscan       closed backend
//
// We keep records in a SEPARATE contract, which is better for security and worse
// for integration: publishing the resolver makes our names invisible as NFTs,
// publishing the collection makes them unresolvable. Neither address worked.
//
// So the collection answers `dnsresolve` with a delegating stub pointing at the
// record contract — exactly what `.ton`'s own collection does
// (dns-contract/func/nft-collection.fc:119). One address does both jobs, and the
// stub reads no records and holds no authority, so every property of the split
// survives. Free side effect: toncenter's DetectInterface starts reporting
// ["dns","nft_collection"] for us with no outreach at all.
//
// `resolver` is a POINTER, not a copy of anything. Repointing it moves every
// name in the collection to a new record contract in one message — which is the
// only sane way to ship a resolver v2 without touching 25,000 items. It is
// therefore as load-bearing as `minter`, and gets the identical R7-11 treatment:
// instant while bootstrapping, staged behind 48h forever after LockHandover.
// R12 NOTE — `resolver` IS NOW LEGACY, AND DELIBERATELY KEPT.
//
// `dnsresolve` no longer reads this field: it delegates to the NAME'S OWN ITEM,
// so no shared contract holds per-name records or grows with the namespace (see
// the header of emoji_nft_item.tolk for the ceiling this removed).
//
// The pointer and its staged-change machinery (SetResolver / ApplyResolver /
// CancelResolver / handover_dns) are retained rather than deleted for two
// reasons: an operator who has already published this address keeps a valid
// answer from `collection_resolver()`, and it remains the escape hatch for
// re-pointing the zone at a shared record contract if one is ever wanted again.
// Nothing in the resolution path depends on it.
struct DnsConfig {
    resolver: address                // LEGACY pointer; dnsresolve no longer reads it
    pendingResolver: address?        // staged replacement (null = none)
    pendingResolverAt: uint32        // when the staged change matures
}

/// R9-5. A staged `SetContent`, held for HANDOVER_TIMELOCK before it can land.
/// Present only while a change is pending; `ops.pendingContent == null` means
/// nothing is staged. Both halves travel together because `SetContent` writes
/// both, and letting them mature separately would be a third state to reason
/// about for no benefit.
struct PendingContent {
    collectionContent: cell
    commonContent: cell
    at: uint32                       // when the staged change matures
}

/// R14-7. A staged `SetRoyalty`, held for HANDOVER_TIMELOCK like every other
/// admin write on this contract. Same shape as PendingContent, deliberately.
///
/// `SetRoyalty` was the LAST instant setter here, and it had the same retroactive
/// reach that put `SetContent` behind the timelock in R9-5: `get_royalty_params`
/// is read AT SALE TIME by every TON marketplace, so one message re-prices the
/// secondary-market cut of every item the collection has ever minted, including
/// names sold years ago, taking effect on the next block. R7-6 bounded WHAT can
/// be written (the 100%-to-an-arbitrary-address case); it left WHEN untouched,
/// and `LockHandover` — the one-way commitment that says every future change is
/// visible for 48 hours — did not cover it either. A holder listing an NFT could
/// have the royalty moved under them between listing and sale with no warning.
struct PendingRoyalty {
    royalty: RoyaltyParams
    at: uint32                       // when the staged change matures
}

struct CollectionOps {
    royalty: RoyaltyParams
    // CollectionOps sits inline in a ref of CollectionStorage and was already
    // ~900 bits. Three more address-sized fields would overflow 1023, so the DNS
    // pointer lives one level down. CollectionOps carries no other ref, so this
    // claims the first of its four.
    dns: Cell<DnsConfig>
    // R9-5. THE SIXTH SLOT OF THE SAME PATTERN.
    //
    // `commonContent` is read by `get_nft_content` AT CALL TIME, so one message
    // repoints the metadata AND image origin of every NFT the collection has
    // ever minted — retroactively, including names sold years ago. That is a
    // larger blast radius than `minter` or `dns.resolver`, both of which stage
    // behind 48 hours, and it was the one admin power on this contract that
    // applied instantly.
    //
    // Its own docs called the destination "load-bearing forever". A power that
    // can silently repoint every holder's artwork at a host the admin controls
    // belongs behind the same warning window as everything else here, so a
    // holder or an indexer can see it coming for two days.
    //
    // Optional so "nothing staged" costs one bit, not two refs — bit pressure in
    // this struct is the reason `dns` is nested in the first place.
    pendingContent: Cell<PendingContent>?
    // R14-7. THE SEVENTH SLOT OF THE SAME PATTERN — and the last instant setter.
    // Optional for the same reason pendingContent is: "nothing staged" costs one
    // bit rather than a whole ref, and this struct is bit-pressured enough that
    // `dns` already had to nest.
    pendingRoyalty: Cell<PendingRoyalty>?
    // ONE-WAY. While false, ChangeAdmin/SetMinter apply IMMEDIATELY — that is
    // the deploy-time bootstrap, where the collection is stood up with the
    // deployer in both slots and then rotated to the real admin and the real
    // registrar. Making an operator wait 48 hours to finish wiring a contract
    // nobody is using yet is pure friction and buys no safety.
    //
    // Pull LockHandover once the wiring is verified and every future change is
    // staged behind the timelock, forever. Nothing clears it. Same idiom as the
    // registrar's LockPrices / LockImports / LockNormalizationPolicy.
    handoverLocked: bool
    //
    // Round 7 bounded what these admins can WRITE. It left untouched what they
    // can HAND OVER, which was one instant unbounded message on each of the two
    // most load-bearing slots in the system. `minter` in particular does two
    // jobs at once — it is the Mint sender allow-list AND the destination of the
    // item -> registrar ownership relay — so repointing it severs transfer sync
    // as well as minting, silently, in one block.
    //
    // The registrar has run a two-step timelocked handover since V7-19 and a
    // staged signer rotation since V7-30. This is the same idiom, deliberately:
    // one pattern to reason about across all four contracts.
    //
    // The timelock is a FIXED constant with no setter. The registrar's is
    // admin-adjustable and V7-19b was entirely about that being gameable; there
    // is no reason to repeat that here.
    pendingAdmin: address?           // nominated successor (null = none)
    pendingAdminAt: uint32           // when the nomination matures
    pendingMinter: address?          // staged minter (null = none)
    pendingMinterAt: uint32
}

struct CollectionStorage {
    // VANITY SALT. Functionally inert — it is never read by any handler. Its
    // only job is to change this contract's state-init hash, and therefore its
    // address, so the deployer can mine an address with a chosen suffix.
    //
    // Mine it with scripts/mine-vanity-address.ts AFTER the contract is final:
    // the address depends on the code hash, so any later code change invalidates
    // the result. Every NFT item address derives from the collection address, so
    // this must be settled before the first mint.
    vanitySalt: uint64
    admin: address
    minter: address                  // the registrar
    itemCode: cell
    collectionContent: cell          // TEP-64 collection metadata
    commonContent: cell              // base for per-item offchain concat
    // R7-11: `ops` replaces the bare royalty ref. CollectionStorage was already
    // at TON's four-reference ceiling (itemCode, collectionContent,
    // commonContent, royalty), so the staged-handover state nests alongside
    // royalty here rather than claiming a fifth ref that does not exist.
    ops: Cell<CollectionOps>

}

fun CollectionStorage.load(): CollectionStorage {
    return CollectionStorage.fromCell(contract.getData());
}

fun CollectionStorage.save(self) {
    contract.setData(self.toCell());
}

// Fix #9: royalty must satisfy numerator <= denominator (<=100%), and
// denominator must be non-zero. Called on SetRoyalty (construction is the
// deployer's responsibility, also asserted in the wrapper).
// R7-6. TEP-66 royalty_params is what every TON marketplace reads to split a
// secondary sale, and the only previous check was numerator <= denominator --
// so 10000/10000, a 100% royalty to an arbitrary address, was accepted and took
// effect on the next block. The seller sees a completed sale and no money.
//
// The registrar was hardened on exactly this axis: prices are clamped per tier,
// referral shares have hardcoded ceilings, partner shares are capped at 30%
// combined. A royalty is the same kind of number and now carries the same kind
// of ceiling. 30% mirrors PARTNER_BPS_CEIL rather than inventing a new limit.
const ROYALTY_MAX_BPS = 3000;        // 30%
const BPS_DENOM = 10000;

fun assertRoyaltyValid(r: RoyaltyParams) {
    assert (r.denominator > 0 && r.numerator <= r.denominator) throw ERR_BAD_ROYALTY;
    // R7-6: and no more than ROYALTY_MAX_BPS of the sale, whatever denominator
    // is chosen to express it. Compare in basis points so 1/1, 100/100 and
    // 10000/10000 are all caught by the same line.
    //
    // R15-10: CROSS-MULTIPLIED, because the divided form TRUNCATED. `num * 10000
    // / den` discards the remainder, so 17106/57001 — 30.0099998% — read as
    // exactly 3000 and was accepted while 17107/57001 was refused. A ceiling that
    // is only approximately the number it states is not a ceiling. Cross-
    // multiplying is exact and cannot overflow: both fields are uint16, so the
    // largest product is 65535 * 10000. 30% itself still passes (equality).
    assert ((r.numerator as int) * BPS_DENOM <= ROYALTY_MAX_BPS * (r.denominator as int))
        throw ERR_BAD_ROYALTY;
    // R17-28. THE DESTINATION IS THE HALF NOBODY CHECKED.
    //
    // `royalty_params` is what every marketplace reads to split a secondary sale,
    // and this validator ruled only on the ratio. ChangeAdmin, SetMinter and
    // SetResolver on this same contract all refuse a zero hash (410); the one
    // field that names a PAYOUT did not, so `SetRoyalty(dest = 0:0…0)` was exit 0
    // and the getter then published the zero address to every marketplace — a
    // seller's cut paid to an account nobody can spend from, permanently.
    //
    // The workchain half joins the basechain-payout family the registrar already
    // enforces (F-11 referrer, R7-17 partner, R16-3 resolver, R16V-1 bidder): a
    // masterchain destination is unroutable for a basechain marketplace's split.
    val (wc, hash) = r.destination.getWorkchainAndHash();
    assert (hash != 0) throw ERR_ZERO_ADDRESS;
    assert (wc == BASECHAIN) throw ERR_BAD_PAYOUT_WC;
}

// R17-30. THE URI FLOOR, PORTED FROM THE REGISTRAR (`checkUriSuffix`).
//
// The collection has two issuance doors and only one of them was vouching for
// anything. `Mint` from the ADMIN takes `individualContent` verbatim, so every
// composed-URI hazard the registrar spent R9-3/R9-4/V7-31 closing was reachable
// through it: NUL-tagged content, `.../item/../../evil`, raw `#` truncation that
// ALIASES one name's metadata onto another's, and ref-carrying payloads. That
// falsified the registrar's own claim that "a front end cannot reintroduce it
// later" — it could, through the other door.
//
// Byte alignment is load-bearing beyond the URI: `get_nft_content` returns the
// base prefix with this cell as its ref, and a snake decoder reads the two as one
// string. A ragged suffix makes the whole thing a non-multiple of 8, which is a
// hard parse error in tongo/tonapi ("text data is not multiple of 8 bits") — for
// this item, on every reader.
//
// Deliberately a copy and not a call: the registrar owns issuance policy and this
// contract owns nothing but the relay. Keeping the predicate identical is the
// point; keeping it in one place is not possible across two contracts.
// R20-6: and it walks the same bounded snake chain, for the same reason the
// registrar's does — full percent-encoding puts the worst registrable name at
// 252 bytes, past what one cell holds. The bound matters more here than there:
// this door's caller is the collection ADMIN with an arbitrary cell, so an
// unbounded ref walk is an admin-reachable gas bomb rather than a theoretical one.
const URI_CELL_BITS: int = 1016;      // 127 bytes, the byte-aligned cell ceiling
const URI_MAX_CELLS: int = 3;         // mirrors emoji_registrar_v4.tolk exactly

fun assertUriSuffix(content: cell) {
    var c = content.beginParse();
    var cells = 1;
    var totalBits = 0;
    var walking = true;
    while (walking) {
        val bits = c.remainingBitsCount();
        assert (bits % 8 == 0) throw ERR_BAD_URI_SUFFIX;
        assert (c.remainingRefsCount() <= 1) throw ERR_BAD_URI_SUFFIX;
        totalBits += bits;
        while (c.remainingBitsCount() >= 8) {
            val b = c.loadUint(8);
            // >= 0x21 and not DEL rejects NUL (a stray TEP-64 ContentData tag),
            // every C0 control byte and the space. `#` and `?` truncate the path
            // at the client; `/` and `\` let it escape the item route; `.` stays
            // legal for the reason the registrar documents at length. R20-6 adds
            // `< 0x80`: TEP-64 says the URI is ASCII, the suffix is immutable per
            // item, and a raw UTF-8 lead byte therefore breaks that item's
            // metadata forever on a strict reader.
            assert (b >= 0x21 && b < 0x80 && b != 0x7F
                 && b != 0x23 && b != 0x3F && b != 0x2F && b != 0x5C)
                throw ERR_BAD_URI_SUFFIX;
        }
        if (c.remainingRefsCount() == 0) {
            walking = false;
        } else {
            // a continuation is only meaningful off a FULL cell — see the registrar
            assert (bits == URI_CELL_BITS) throw ERR_BAD_URI_SUFFIX;
            cells += 1;
            assert (cells <= URI_MAX_CELLS) throw ERR_BAD_URI_SUFFIX;
            c = c.loadRef().beginParse();
        }
    }
    assert (totalBits >= 8) throw ERR_BAD_URI_SUFFIX;
}

// ---- item init state (must byte-match emoji_nft_item.tolk ItemStorage) ----

// MUST mirror emoji_nft_item.tolk's ItemStorage field-for-field and in order:
// this cell is hashed into the item's address. Adding a field here without
// adding it there (or vice versa) silently moves every item address.
struct ItemInitState {
    index: uint256
    collection: address
    owner: address?         // null pre-init
    expiresAt: uint32
    isReserved: bool
    emojiCount: uint8       // tier
    syncNonce: uint32       // F-12
    content: cell?
    label: cell?            // R20-7: raw UTF-8 name, empty in the INIT state
    // R12: the item now holds its own TEP-81 records (the .ton architecture — see
    // the header of emoji_nft_item.tolk). Both are empty in the INIT state, but
    // they MUST be declared here or this cell stops byte-matching ItemStorage and
    // every item address silently moves.
    recordCount: uint8
    records: cell?
}

// ---- messages ----

// registrar/admin -> collection
struct (0x1f04537a) Mint {
    queryId: uint64
    nameHash: uint256
    owner: address
    expiresAt: uint32       // 0 = never (reserved singles)
    isReserved: bool
    emojiCount: uint8       // tier, forwarded to the item
    syncNonce: uint32       // F-12, forwarded to the item
    // R14-3: the registrar's AdoptItem repair. Forwarded verbatim, but only ever
    // honoured when it arrives FROM THE MINTER — an admin Mint has no registry
    // record behind it, so it has nothing to adopt from and must not be able to
    // borrow the adopt branch's relaxed record handling. See the handler.
    adopt: bool
    individualContent: cell
    // R20-7: the raw UTF-8 name, so the item can answer `get_domain`. Optional
    // on the wire because the registrar's AdoptItem repair has no name to send
    // and because a foundation seed through the admin door may legitimately have
    // none — the item then reports "" rather than a name it cannot vouch for.
    label: cell?
}

struct (0x3c81aa02) UpdateExpiryReq {
    queryId: uint64
    nameHash: uint256
    newExpiresAt: uint32
    syncNonce: uint32       // R16-2: the issuance the registry records; relayed to the item
}

// item -> collection
struct (0x4d92bb13) SyncOwner {
    queryId: uint64
    index: uint256
    newOwner: address
    syncNonce: uint32
}

// collection -> registrar
struct (0x5ea3cc24) OwnerSynced {
    queryId: uint64
    nameHash: uint256
    newOwner: address
    syncNonce: uint32       // F-12: echoed from the item
}

// collection -> item (must byte-match item's structs)
// R7-10. The item's reassign guard reads its OWN replica of the term, and that
// replica is writable by the collection admin. Bounding those writes (R7-3/R7-4)
// shrank the damage but did not remove the class: an item pinned to now+10y
// still refuses reassignment for ten years while the registry record lapses in
// one, so every re-registration in between takes the buyer's money and fails to
// deliver the NFT.
//
// The registrar does not have a replica — it has the record. It only ever mints
// after its own assertAvailableForIssue() has passed, so on the question "may
// this name be issued to someone new" it is the authority and the item is not.
// A mint that originated at the minter therefore carries that authority through,
// and the item defers to it. Admin-originated mints do not, and keep the
// conservative clock check.
struct (0x2b71c34f) InitOrReassign {
    queryId: uint64
    owner: address
    expiresAt: uint32
    isReserved: bool
    emojiCount: uint8       // tier, stored on the item
    syncNonce: uint32       // F-12 anti-stale-sync
    content: cell?
    label: cell?            // R20-7: raw UTF-8 name; MUST mirror the item's struct
    authoritative: bool     // R7-10: the mint came from the minter (the registrar)
    adopt: bool             // R14-3: registrar repair re-stamp; see the item's handler
}

// R12-1-FIX. Carries the same minter-origin bit as InitOrReassign, for the same
// reason and with the same meaning: the registrar owns the term and has already
// ruled on it, so the item must not re-rule on a stale replica two hops later.
struct (0x3c81aa02) UpdateExpiryFwd {
    queryId: uint64
    newExpiresAt: uint32
    authoritative: bool     // R12-1-FIX: the write came from the minter (the registrar)
    syncNonce: uint32       // R16-2: which issuance the term belongs to; see the registrar's struct
}

// TEP-66
struct (0x693d3950) AskRoyaltyParams {
    queryId: uint64
}

struct (0xa8cb00ad) ReportRoyaltyParams {
    queryId: uint64
    numerator: uint16
    denominator: uint16
    destination: address
}

// R17-34. Outbound only — see the terminal arm of onInternalMessage. Same opcode
// and same layout as the registrar's, so one decoder reads a rejection from any
// contract in the system. Deliberately NOT in AllowedMessage: this contract never
// answers one, and adding an ingress arm would only turn a refund into a silent
// absorption.
// R24-4: the collection announcing itself to its minter. Opcode matches the
// registrar's `ConfirmNftCollection` (0x0000002a) byte for byte — this is an
// EGRESS shape here and an INGRESS shape there.
struct (0x0000002a) ConfirmNftCollection {
    queryId: uint64
}

// R24-4: the admin-triggered announce. Deliberately carries no address; the
// destination is `storage.minter`. See the handler.
struct (0x61b4dd3d) AnnounceMinter {
    queryId: uint64
}

struct (0x7e3a11c5) RejectedRefund {
    queryId: uint64
    reason: uint32
}

// R31-2. Named so the terminal `else` arm can decline it — R25-6b's guard, given
// to the registrar and not to this file. See the note at that arm.
const OP_REJECTED_REFUND: int = 0x7e3a11c5;

// admin ops
struct (0x94e81068) ChangeAdmin {
    queryId: uint64
    newAdmin: address
}

// R7-11 handover ops. ChangeAdmin/SetMinter now STAGE; these finish or abort.
struct (0x94e81069) AcceptAdmin { queryId: uint64 }
struct (0x94e8106a) CancelAdmin { queryId: uint64 }
// Permissionless on purpose: the change was already authorised when it was
// staged, so leaving the finish to the admin alone would let a lost admin key
// strand a correct, already-public minter change. Same reasoning as the
// registrar's ApplySigner.
struct (0x61b4dd36) ApplyMinter { queryId: uint64 }
// ONE-WAY: after this, every handover is staged. No op clears it.
struct (0x61b4dd38) LockHandover { queryId: uint64 }
struct (0x61b4dd37) CancelMinter { queryId: uint64 }

struct (0x61b4dd35) SetMinter {
    queryId: uint64
    newMinter: address
}

// R8-1. Same shape and the same guarantees as SetMinter/ApplyMinter/CancelMinter,
// deliberately: one pattern to reason about. Repointing `resolver` migrates every
// name in the collection to a new record contract in a single message, which is
// how a resolver upgrade ships without touching a single item.
struct (0x61b4dd3a) SetResolver {
    queryId: uint64
    newResolver: address
}
// Permissionless finish, for the same reason ApplyMinter is: the change was
// authorised when it was staged, and a lost admin key must not be able to strand
// a correct, already-public migration.
struct (0x61b4dd3b) ApplyResolver { queryId: uint64 }
struct (0x61b4dd3c) CancelResolver { queryId: uint64 }

struct (0x72c5ee46) SetContent {
    queryId: uint64
    collectionContent: cell
    commonContent: cell
}

struct (0x83d6ff57) SetRoyalty {
    queryId: uint64
    royalty: Cell<RoyaltyParams>
}

// R9-5. Same shape as ApplyResolver / CancelResolver, deliberately: one pattern.
struct (0x72c5ee47) ApplyContent { queryId: uint64 }
struct (0x72c5ee48) CancelContent { queryId: uint64 }

// R14-7. Same shape again. Permissionless finish, for the reason ApplyMinter /
// ApplyResolver / ApplyContent are: the change was authorised when it was staged
// and a lost admin key must not be able to strand it.
struct (0x83d6ff58) ApplyRoyalty { queryId: uint64 }
struct (0x83d6ff59) CancelRoyalty { queryId: uint64 }

type AllowedMessage =
    | Mint
    | UpdateExpiryReq
    | SyncOwner
    | AskRoyaltyParams
    | ChangeAdmin
    | SetMinter
    | AcceptAdmin | CancelAdmin | ApplyMinter | CancelMinter | LockHandover | AnnounceMinter
    | SetResolver | ApplyResolver | CancelResolver
    | SetContent | ApplyContent | CancelContent
    | SetRoyalty | ApplyRoyalty | CancelRoyalty;

// ---- helpers ----

fun calcItemDeploy(itemCode: cell, index: uint256): AutoDeployAddress {
    val initState: ItemInitState = {
        index: index,
        collection: contract.getAddress(),
        owner: null,
        expiresAt: 0,
        isReserved: false,
        emojiCount: 0,
        syncNonce: 0,
        content: null,
        label: null,        // R20-7
        recordCount: 0,     // R12
        records: null,      // R12
    };
    return AutoDeployAddress {
        workchain: BASECHAIN,
        stateInit: ContractState {
            code: itemCode,
            data: initState.toCell(),
        }
    };
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

    var storage = CollectionStorage.load();
    val msg = lazy AllowedMessage.fromSlice(in.body);

    match (msg) {
        Mint => {
            // registrar mints on registration; admin path kept for ops
            // (seeding the reserved-singles batch without routing through
            //  the registrar if desired)
            assert (in.senderAddress == storage.minter || in.senderAddress == storage.admin)
                throw ERR_NOT_MINTER;
            // R7-4 (CRITICAL). R7-3 bounded UpdateExpiryReq and left THIS door
            // open, which was the more dangerous of the two: the item's reassign
            // guard only runs when the item already has an owner, so a Mint onto
            // a never-minted nameHash is unguarded. One message with
            // expiresAt = 0xFFFFFFFF pre-seizes any name that has not been sold
            // yet -- including, before launch, every name -- and no later mint
            // from the registrar can ever reassign it. The registrar reports the
            // name as available the whole time, so the buyer pays in full and
            // the NFT is already someone else's, permanently.
            //
            // Same bound as UpdateExpiryReq. There is now no path by which this
            // collection writes an expiry the registrar would refuse.
            // The sentinel is legitimate ONLY from the minter: the registrar
            // writes it when a single is upgraded to a permanent term, and that
            // upgrade is gated, priced and irreversible on its side. The admin's
            // Mint exists to seed foundation items and has no business minting a
            // permanent term, so it gets the horizon and nothing else. Without
            // this split the bound is decorative — the attack above just uses
            // 0xFFFFFFFF instead of a large finite value.
            val fromMinter = in.senderAddress == storage.minter;
            assert ((fromMinter && msg.expiresAt == PERMANENT_EXPIRY)
                 || (msg.expiresAt as int) <= blockchain.now() + MAX_TOTAL_TERM + GRACE_PERIOD)
                throw ERR_EXPIRY_OUT_OF_RANGE;
            // R23-13. `expiresAt == 0` IS INTENDED HERE. THE COMMENT ABOVE WAS NOT.
            //
            // A fresh audit round flagged that `0` satisfies the `<= now + 10y +
            // grace` bound trivially while meaning NEVER-EXPIRES at the item
            // (`isWithinGrace()` is unconditionally true for it) and "long expired"
            // at the registrar — and therefore that the sentence one screen up,
            // "there is now no path by which this collection writes an expiry the
            // registrar would refuse", is false for exactly that value.
            //
            // The observation about the SENTENCE is correct. The proposed fix —
            // asserting `expiresAt != 0` — was wrong, and this note records why so
            // the next round does not re-propose it. `0` is the DOCUMENTED,
            // EXERCISED representation of a foundation reserved single: a name
            // seeded through this admin door with no rental term at all, held
            // non-transferable until released. tests/EmojiNft.spec.ts (9),
            // tests/V7Contracts.spec.ts (V7-9), tests/R7NftIntegrity.spec.ts and
            // tests/R8NftLayer.spec.ts all mint through this path with `0` and
            // assert `withinGrace == true`. Blocking it would break seeding, which
            // is this door's entire purpose.
            //
            // So the rule stated above is narrowed rather than enforced: the
            // horizon bounds every FINITE term the admin may write, and the two
            // sentinels — `0` (no term, foundation-held) and PERMANENT_EXPIRY
            // (minter only, a paid upgrade) — sit outside it deliberately, each
            // reachable from exactly one sender. That is the real invariant, and it
            // holds.
            // R17-30. WHAT THE ADMIN DOOR VOUCHES FOR, STATED EXACTLY.
            //
            // The two admin issuance doors disagreed about the floor, and the one
            // that enforced nothing is the one no runbook step uses. This closes
            // the half a collection CAN rule on. The registrar's `assertUriSuffix`
            // is byte-for-byte the same predicate over the same cell, so both
            // doors now compose the same URI space.
            //
            // Only the admin arm pays for it: the registrar has already run this
            // check on everything it forwards, and the mint path's gas budget is
            // measured (R15-3) — re-deriving an answer the authority has already
            // given, on every registration, is not defence in depth, it is a
            // second bill for one check.
            //
            // WHAT THIS DOOR STILL DOES NOT VOUCH FOR, and cannot: `nameHash` is
            // an opaque 256-bit index with no preimage on the wire, so the
            // NAMESPACE floor — canonical form, the 2,077-codepoint table, the
            // confusable list, tier equality — is unreachable from here. That
            // ruling needs `rawName`, and it belongs to the registrar, which holds
            // the frozen table and the policy hash. An index minted through this
            // door is therefore a name only if the admin says so, and the item and
            // every reader inherit exactly that much assurance. It is the same
            // principal in `deployPlan.ts` and the same multisig at launch step 7,
            // which is why this is a disclosure and not a gate.
            if (!fromMinter) {
                assertUriSuffix(msg.individualContent);
            }
            val deploy = calcItemDeploy(storage.itemCode, msg.nameHash);
            val toItem = createMessage({
                bounce: BounceMode.NoBounce,
                value: 0,
                dest: deploy,
                body: InitOrReassign {
                    queryId: msg.queryId,
                    owner: msg.owner,
                    expiresAt: msg.expiresAt,
                    isReserved: msg.isReserved,
                    emojiCount: msg.emojiCount,
                    // R13X-2 (HIGH). AN ADMIN MINT MUST NOT PRODUCE A RELAY THE
                    // REGISTRAR WILL ADOPT.
                    //
                    // V7-18 hardened SetNftCollection to close "point
                    // cfg.nftCollection at a wallet you control, send one
                    // hand-crafted OwnerSynced, take any name". The same primitive
                    // was still reachable through THIS, the real collection, for
                    // any registered name whose item does not exist yet — the
                    // deploy-window and post-rotation cohorts. The item's reassign
                    // guard is skipped entirely when owner == null, so an admin
                    // Mint onto a never-deployed item is accepted; then anyone
                    // fires the permissionless ResyncOwner and the REGISTRY
                    // follows. Everything the attacker needs is a public getter
                    // (ownerOf / expiryOf / emojiCountOf / syncNonceOf), so the
                    // F-12 equality guard was being satisfied with a nonce the
                    // admin simply read off-chain and echoed back.
                    //
                    // Measured: collection exit 0, item exit 0, registrar owner
                    // becomes the attacker. Control (item already exists): item
                    // 411 ERR_STILL_VALID, registry unchanged.
                    //
                    // issueName starts nonces at 1 and only increments, so 0 can
                    // never match a live record and the F-12 guard drops the relay
                    // on the floor. The admin Mint's one legitimate use is seeding
                    // foundation items for names the registrar has no record of,
                    // which needs no registry-visible nonce.
                    syncNonce: fromMinter ? msg.syncNonce : (0 as uint32),
                    content: msg.individualContent,
                    // R20-7. The label is gated on minter origin for exactly the
                    // reason `syncNonce` and `adopt` are, one clause below: the
                    // ADMIN door's `nameHash` is an opaque 256-bit index with no
                    // preimage the collection can check, so a label arriving here
                    // is a claim, not a fact. From the MINTER it has already been
                    // bound — `assertCanonicalName` proved sha256(rawName) ==
                    // nameHash before the mint was emitted. So the item's
                    // `get_domain` inherits exactly the assurance the registrar
                    // gave it, and an admin seed answers "" instead of a
                    // marketplace-rendered string nobody verified.
                    label: fromMinter ? msg.label : null,
                    authoritative: fromMinter,     // R7-10
                    // R14-3: `adopt` is gated on minter origin for the same
                    // reason `syncNonce` is. The adopt branch on the item skips
                    // the content overwrite and the record wipe, which is only
                    // correct when the write is the registrar re-asserting a
                    // record it holds. An admin Mint carrying adopt=true would
                    // otherwise be a way to rewrite an item's owner while leaving
                    // the previous holder's records and metadata in place.
                    adopt: fromMinter && msg.adopt,
                }
            });
            toItem.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        UpdateExpiryReq => {
            // R17-8. THE ADMIN ARM IS GONE. THE REGISTRAR OWNS EVERY TERM.
            //
            // R9-5 took the PERMANENT_EXPIRY sentinel away from the admin and left
            // the finite `now + 10y + grace` horizon admin-writable. That residue
            // was the whole finding: the item's UpdateExpiry is EXTEND-ONLY
            // (emoji_nft_item.tolk, ERR_EXPIRY_NOT_EXTEND), so one instant,
            // un-timelocked, LockHandover-exempt message inflates a LIVE item's
            // term by nine years with no way back — `PushTerm`, the documented
            // heal, answers 414. Past the registry's expiry+grace the item still
            // reports isWithinGrace and still transfers, so a marketplace buyer
            // pays for a name the registry has already released and the next
            // honest registrant takes it via the authoritative re-mint.
            //
            // WHY REMOVAL AND NOT A GATE. The stated justification for the arm is
            // seeding, and seeding is exactly the case it cannot serve: the item
            // asserts `owner != null` before it will look at a term at all, so a
            // relay aimed at an unseeded item is 405 ERR_NOT_INIT regardless. The
            // arm's ONLY reachable effect is on an item that already has an owner
            // — which is precisely the harm. Gating it to "not live" would leave
            // dead code; the collection cannot make that ruling anyway, because it
            // holds no per-name state and does not know the item's owner. Pushing
            // the ruling down to the item would need a new field on
            // `UpdateExpiryFwd`, whose layout is pinned byte-for-byte against the
            // registrar and the wrapper (scripts/r16-localnet-checks.ts).
            //
            // Seeding a term is `Mint`, which carries `expiresAt` at init. Repair
            // is the registrar's `PushTerm`. Both survive. No runbook step, script
            // or integration path used this door.
            assert (in.senderAddress == storage.minter) throw ERR_NOT_MINTER;
            // R7-3: the item can only ever EXTEND, so an out-of-range value here
            // is written once and irreversible. Everything except the permanent
            // sentinel must sit inside the registrar's own 10-year horizon —
            // mirroring the registrar's bound rather than trusting it, so the two
            // contracts cannot drift into disagreeing about what a legal term is.
            //
            // Same condition, same order, same error as `Mint` above. One rule.
            assert (msg.newExpiresAt == PERMANENT_EXPIRY
                 || (msg.newExpiresAt as int) <= blockchain.now() + MAX_TOTAL_TERM + GRACE_PERIOD)
                throw ERR_EXPIRY_OUT_OF_RANGE;
            val deploy = calcItemDeploy(storage.itemCode, msg.nameHash);
            val toItem = createMessage({
                // R17-19/B6. BOUNCEABLE, AND DELIBERATELY WITHOUT StateInit.
                //
                // `Mint` attaches StateInit because a mint is *meant* to deploy the
                // item. A term push is not: there is no term to extend at a name
                // that was never minted, and the item says so (405 ERR_NOT_INIT).
                // Attaching StateInit here would not rescue that message — it would
                // leave an ACTIVE null-owner shell behind (measured in R17-1, where
                // the same 405-after-deploy left the item `active balance 0.078`),
                // which is the shell a conformant TEP-62 reader throws on.
                //
                // So the asymmetry with `Mint` is the correct one, and what was
                // actually wrong is that the failure was silent: NoBounce parked the
                // relay's gas at an address with no code. Bouncing returns it to the
                // emitter and puts the failure in the transaction graph. The whole
                // 161-bit body fits inside Only256BitsOfBody, so unlike the
                // registrar's 256-bit-nameHash leg the bounce is fully informative.
                bounce: BounceMode.Only256BitsOfBody,
                value: 0,
                dest: deploy.calculateAddress(),
                body: UpdateExpiryFwd {
                    queryId: msg.queryId,
                    newExpiresAt: msg.newExpiresAt,
                    // R12-1-FIX. Unconditional since R17-8: the minter is now the
                    // only sender that reaches this handler.
                    authoritative: true,
                    syncNonce: msg.syncNonce,      // R16-2: pure relay, the collection does not rule on it
                }
            });
            toItem.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        SyncOwner => {
            // R26-5 (found by the R26 arithmetic/shape fuzz campaign). THE SAME
            // GAP R23-4 CLOSED ONE ARM BELOW, AND R26-3 CLOSED IN THE ITEM.
            //
            // `msg.index` is the FIRST field read on this arm, and Tolk's `lazy`
            // load fires at first field access — so a body carrying only the
            // 32-bit opcode, or any body under 352 bits, underflows on the very
            // next line. That is BEFORE the sender check, so any sender reaches
            // it. Measured on build 83BF3A15, plain treasury wallet, 0.1 GRAM:
            //
            //     bounceable      exit 9, 0.099852599 returned
            //     NON-bounceable  exit 9, 0.000000000 returned   <- absorbed
            //
            // Exit 9 is a bare cell-underflow: in no error table, untranslatable
            // by any front end. R8-12 measured a real wallet stripping the bounce
            // bit, so row 2 is a real population — and this contract is a one-way
            // value sink (no withdraw op, no RAWRESERVE, no setCode), so what it
            // absorbs is burned rather than merely misplaced.
            //
            // The contrast that makes this a defect rather than a style point is
            // its immediate neighbour: `AskRoyaltyParams` below takes exactly this
            // guard, for exactly this reason, and answers 468 with the value
            // returned on both bounce settings.
            //
            // 651 bits, 0 refs is the only well-formed shape — op(32) + queryId(64)
            // + index(256) + newOwner(267, always addr_std because the item sends
            // `self.owner!`) + syncNonce(32) — and the only legitimate sender is an
            // item, which always builds exactly that. Anything else is a different
            // message wearing this opcode.
            if (in.body.remainingBitsCount() != 651 || in.body.remainingRefsCount() != 0) {
                rejectAndRefund(in.senderAddress, ERR_BAD_BODY);
                return;
            }
            // authenticate: sender must be the item this collection would
            // deploy for that index
            val deploy = calcItemDeploy(storage.itemCode, msg.index);
            assert (in.senderAddress == deploy.calculateAddress()) throw ERR_NOT_ITEM;
            // Fix #2: require enough value to carry the relay to the registrar,
            // and make it BOUNCEABLE (no IGNORE_ERRORS) so a failed relay is
            // observable via onBouncedMessage rather than silently dropped.
            assert (in.valueCoins >= MIN_RELAY_VALUE) throw ERR_LOW_RELAY_VALUE;
            val relay = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                value: 0,
                dest: storage.minter,
                body: OwnerSynced {
                    queryId: msg.queryId,
                    nameHash: msg.index,
                    newOwner: msg.newOwner,
                    syncNonce: msg.syncNonce,
                }
            });
            relay.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        AskRoyaltyParams => {
            // R23-4 (found by TSA symbolic analysis). THE TEP-66 QUERY, WITH NO
            // BODY-SHAPE GUARD.
            //
            // Tolk's `lazy` load fires at first field access, so a body carrying
            // only the 32-bit opcode underflows on `msg.queryId` — exit 9,
            // uncatalogued, and since real wallets strip the bounce flag the value
            // is absorbed with no refund and no diagnostic. Measured pre-fix: 32-bit
            // body, exit 9, 0.100307 GRAM kept.
            //
            // This arm's callers are MARKETPLACES AND INDEXERS asking a standard
            // question, which is exactly the population the R17-34 refund policy
            // one screen below exists to serve: a wrong-shaped standard query
            // should error visibly, not cost the integrator its attached value.
            // The `else` arm already answers unknown ops that way; a KNOWN op with
            // a short payload never reached it.
            if (in.body.remainingBitsCount() != BODY_OP_QUERYID) {
                rejectAndRefund(in.senderAddress, ERR_BAD_BODY);
                return;
            }
            val royalty = storage.ops.load().royalty;
            val report = createMessage({
                bounce: BounceMode.NoBounce,
                value: 0,
                dest: in.senderAddress,
                body: ReportRoyaltyParams {
                    queryId: msg.queryId,
                    numerator: royalty.numerator,
                    denominator: royalty.denominator,
                    destination: royalty.destination,
                }
            });
            report.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS);
        }

        ChangeAdmin => {
            assert (in.senderAddress == storage.admin) throw ERR_NOT_ADMIN;
            // R7-8: the registrar refuses a zero successor (exit 422). Here it
            // was accepted, which turns any of the state-corrupting admin ops
            // into a permanent one -- corrupt, then burn the key on-chain so
            // nobody can ever repair it.
            assert (msg.newAdmin.getWorkchainAndHash().1 != 0) throw ERR_ZERO_ADDRESS;
            // R31-3. NOR THIS CONTRACT'S OWN ADDRESS — the same accident as zero,
            // with the same permanence and none of the visibility. The registrar
            // has ERR_SELF_REFERENCE at three sites (R17-9/R17-20); this file had
            // only the `!= 0` half. Measured: ChangeAdmin(self) returns exit 0, and
            // every subsequent admin op from the real operator answers 401 —
            // SetMinter, SetResolver, ChangeAdmin, LockHandover, SetContent,
            // SetRoyalty. The collection is then PERMANENTLY unadministrable, and
            // AcceptAdmin cannot rescue it because nothing is staged. ChangeAdmin
            // is instant during the bootstrap window, which is exactly when a
            // deploy script is typing addresses.
            assert (msg.newAdmin != contract.getAddress()) throw ERR_SELF_REFERENCE;
            var ops = storage.ops.load();
            if (!ops.handoverLocked) {          // bootstrap: apply immediately
                storage.admin = msg.newAdmin;
                storage.save();
                return;
            }
            ops.pendingAdmin = msg.newAdmin;
            ops.pendingAdminAt = (blockchain.now() + HANDOVER_TIMELOCK) as uint32;
            storage.ops = ops.toCell();
            storage.save();
        }

        // The successor accepts from their OWN address, which proves they hold
        // the key — a handover to a typo'd address can never complete.
        AcceptAdmin => {
            var ops = storage.ops.load();
            assert (ops.pendingAdmin != null) throw ERR_NOTHING_PENDING;
            assert (in.senderAddress == ops.pendingAdmin!) throw ERR_NOT_SUCCESSOR;
            assert (blockchain.now() >= (ops.pendingAdminAt as int)) throw ERR_TIMELOCK_ACTIVE;
            storage.admin = ops.pendingAdmin!;
            ops.pendingAdmin = null;
            ops.pendingAdminAt = 0;
            // R7-12. THE SUCCESSOR INHERITS NOTHING UNAPPROVED.
            //
            // ApplyMinter is permissionless once its own timer expires, so a
            // pending minter staged by the OUTGOING admin would land under the
            // incoming one — 48 hours after a handover, fired by anyone, with
            // the new admin never having consented and quite possibly not
            // watching. That is a delayed-action key the departing party keeps.
            //
            // Clearing it here makes the rule simple enough to state in one
            // line: only the sitting admin's own staged changes can complete.
            // A genuinely coordinated handover just re-stages the minter after
            // accepting, which is the party who should be approving it anyway.
            ops.pendingMinter = null;
            ops.pendingMinterAt = 0;
            // R8-6. THE DNS POINTER IS THE FIFTH SLOT OF THE SAME PATTERN, and
            // R8-1 gave it the SetMinter shape "deliberately: one pattern to
            // reason about" — while leaving out the half of that pattern which
            // lives in THIS handler. The security sweep found it and it is worse
            // than the minter case, because `dns.resolver` is the single
            // delegation point for the WHOLE zone:
            //
            //   t0        outgoing admin sends ChangeAdmin(successor)
            //   t0+48h-1m outgoing admin, still admin, stages SetResolver(evil)
            //   t0+48h    successor accepts. handover() reads completely clean.
            //   t0+96h    ANYONE sends ApplyResolver. Every name in the zone now
            //             resolves through a contract the revoked admin controls.
            //
            // Recovery costs a further 48 hours, because the new admin's own
            // SetResolver stages behind the same timelock. Reproduced end to end:
            // a name alice owns, with alice's record intact in the honest
            // resolver, paid mallory.
            var dnsCfg = ops.dns.load();
            dnsCfg.pendingResolver = null;
            dnsCfg.pendingResolverAt = 0;
            ops.dns = dnsCfg.toCell();
            // R9-5. THE SIXTH SLOT, AND THE SAME HALF WAS MISSING AGAIN.
            //
            // R8-6's own lesson was that adding a staged slot means adding it to
            // BOTH halves of the pattern, and the R9-5 content slot repeated the
            // omission on its first draft. A staged SetContent surviving a
            // handover is the delayed-action key R7-12 describes, pointed at the
            // metadata and artwork of every name in the collection: the outgoing
            // admin stages a repoint minutes before the successor accepts, and 48
            // hours later ANYONE can fire the permissionless ApplyContent.
            ops.pendingContent = null;
            // R14-7. THE SEVENTH SLOT, AND THE SAME HALF WOULD HAVE BEEN MISSING
            // AGAIN. R8-6 and R9-5 both record that adding a staged slot means
            // adding it to BOTH halves of the pattern, and both drafts forgot the
            // half that lives HERE. A staged SetRoyalty surviving a handover is
            // the delayed-action key R7-12 describes, pointed at the secondary-sale
            // proceeds of every name in the collection: the outgoing admin stages a
            // 100%-to-themselves royalty minutes before the successor accepts, and
            // 48 hours later anyone fires the permissionless ApplyRoyalty.
            //
            // R13X-5 is the boundary of this rule and it still holds: the clear
            // belongs in AcceptAdmin (admin-gated, and the moment authority moves)
            // and NOT in ApplyMinter / CancelMinter, which are not handovers —
            // ApplyMinter in particular is permissionless, so duplicating the clear
            // there hands any stranger a way to destroy admin state.
            ops.pendingRoyalty = null;
            storage.ops = ops.toCell();
            storage.save();
        }

        CancelAdmin => {
            assert (in.senderAddress == storage.admin) throw ERR_NOT_ADMIN;
            var ops = storage.ops.load();
            assert (ops.pendingAdmin != null) throw ERR_NOTHING_PENDING;
            ops.pendingAdmin = null;
            ops.pendingAdminAt = 0;
            storage.ops = ops.toCell();
            storage.save();
        }

        ApplyMinter => {
            var ops = storage.ops.load();
            assert (ops.pendingMinter != null) throw ERR_NOTHING_PENDING;
            assert (blockchain.now() >= (ops.pendingMinterAt as int)) throw ERR_TIMELOCK_ACTIVE;
            storage.minter = ops.pendingMinter!;
            ops.pendingMinter = null;
            ops.pendingMinterAt = 0;
            // R13X-5. R8-6's CLEAR DOES NOT BELONG HERE, AND COPYING IT IN MADE A
            // FREE GRIEF.
            //
            // R8-6's property is about a HANDOVER: a successor must not inherit
            // the outgoing admin's staged changes. `AcceptAdmin` enforces that and
            // is the right place for it — it is admin-gated and it is the moment
            // authority actually moves. This handler is PERMISSIONLESS. Duplicating
            // the clear here means any stranger can destroy an admin's matured
            // resolver migration by firing ApplyMinter at the right moment, for the
            // price of one message.
            //
            // Measured: LockHandover pulled, SetResolver(new) staged, SetMinter(new)
            // staged; 48h+10s later a stranger sends ApplyMinter — exit 0, minter
            // applied, pendingResolver NULL (discarded), resolver unchanged. The
            // asymmetry also pointed the wrong way: after ApplyResolver,
            // pendingMinter survives intact, and `pendingContent` — the slot with
            // real retroactive reach over every name's artwork — was never cleared
            // here at all.
            //
            // Blast radius is small today because R12 made `resolver` legacy and
            // the shipping config registers none. It is removed on principle: a
            // permissionless handler must not be able to discard admin state.
            // AcceptAdmin's copy stays exactly as it is.
            storage.ops = ops.toCell();
            storage.save();
        }

        LockHandover => {
            assert (in.senderAddress == storage.admin) throw ERR_NOT_ADMIN;
            var ops = storage.ops.load();
            ops.handoverLocked = true;
            storage.ops = ops.toCell();
            storage.save();
        }

        // R24-4. "COLLECTION, TELL YOUR MINTER YOU EXIST."
        //
        // The second half of the target-acknowledged wiring described at length in
        // emoji_registrar_v4.tolk's `SetNftCollection`. The registrar now STAGES
        // its collection pointer and promotes it only on a message that arrives
        // FROM the staged address; this is the op that sends that message.
        //
        // It carries NO address argument on purpose. The destination is
        // `storage.minter` — the field the collection already maintains, already
        // guards with a 48h staged handover, and already trusts as the only
        // address allowed to mint. So the two contracts verify each other from
        // opposite directions using only state each of them already owns:
        //
        //   registrar: "I will accept this only from the address I staged."
        //   collection: "I will announce only to the address I already obey."
        //
        // A wrong pointer in either direction therefore cannot complete the
        // handshake, and neither contract has to be told anything it does not
        // already know. Adding an address parameter would reintroduce exactly the
        // fat-finger surface the handshake exists to remove.
        //
        // Admin-gated because it is a deploy-runbook step, not an operating lever,
        // and it is freely REPEATABLE: the registrar's side is idempotent (a
        // second announce for an already-promoted pointer finds nothing staged and
        // refuses cleanly), so a lost or under-funded message is retried, never
        // recovered from.
        AnnounceMinter => {
            assert (in.senderAddress == storage.admin) throw ERR_NOT_ADMIN;
            if (in.body.remainingBitsCount() != BODY_OP_QUERYID) {
                rejectAndRefund(in.senderAddress, ERR_BAD_BODY);
                return;
            }
            // Value carried from the announcing message; mode 64 returns whatever
            // the registrar does not spend. Nothing of the collection's own rent
            // is touched, so this is safe at the storage floor.
            createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                value: 0,
                dest: storage.minter,
                body: ConfirmNftCollection { queryId: msg.queryId },
            }).send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        CancelMinter => {
            assert (in.senderAddress == storage.admin) throw ERR_NOT_ADMIN;
            var ops = storage.ops.load();
            assert (ops.pendingMinter != null) throw ERR_NOTHING_PENDING;
            ops.pendingMinter = null;
            ops.pendingMinterAt = 0;
            // R13X-5, same removal as ApplyMinter above. Cancelling a staged minter
            // change is not a handover, so R8-6's clear does not apply — and it is
            // strictly destructive here: an admin who changes their mind about a
            // minter rotation would silently lose an unrelated, already-matured
            // resolver migration in the same message. AcceptAdmin keeps the clear.
            storage.ops = ops.toCell();
            storage.save();
        }

        SetMinter => {
            assert (in.senderAddress == storage.admin) throw ERR_NOT_ADMIN;
            // R7-8: `minter` is load-bearing twice over -- it is the Mint sender
            // allow-list AND the destination of the item->registrar ownership
            // relay. A zero value silently severs both.
            assert (msg.newMinter.getWorkchainAndHash().1 != 0) throw ERR_ZERO_ADDRESS;
            // R31-3. SetMinter(self) is exit 0 on the shipped build, and
            // AnnounceMinter afterwards becomes a 543-transaction self-ping-pong:
            // the collection sends ConfirmNftCollection to itself, its own `else`
            // arm refuses it, its own `else` arm answers that. R31-2's
            // self-address guard now stops the loop; this stops the state.
            assert (msg.newMinter != contract.getAddress()) throw ERR_SELF_REFERENCE;
            var ops = storage.ops.load();
            if (!ops.handoverLocked) {          // bootstrap: apply immediately
                storage.minter = msg.newMinter;
                storage.save();
                return;
            }
            ops.pendingMinter = msg.newMinter;
            ops.pendingMinterAt = (blockchain.now() + HANDOVER_TIMELOCK) as uint32;
            storage.ops = ops.toCell();
            storage.save();
        }

        SetResolver => {
            assert (in.senderAddress == storage.admin) throw ERR_NOT_ADMIN;
            // A zero resolver would make every name in the collection stop
            // resolving at once, and ChangeAdmin to zero would make it permanent.
            assert (msg.newResolver.getWorkchainAndHash().1 != 0) throw ERR_ZERO_ADDRESS;
            // R31-3 DELIBERATELY HAS NO SELF-REFERENCE GUARD HERE, unlike ChangeAdmin
            // and SetMinter above. `resolver == this collection` is the DOCUMENTED
            // AND REQUIRED wiring, not an accident: deployPlan.ts:412 sends
            // `setResolverBody(collection)` labelled "points at ITSELF",
            // docs/LAUNCH_READINESS.md step 1 says so in words, preflight D-2 FAILs
            // on mainnet if it is anything else, and R8-1 is the reason — MyTonWallet
            // reads `zone.resolver` both as the dnsresolve target and as
            // `zone.resolver === nft.collectionAddress`.
            //
            // A guard was written here during R31 and measured: SetResolver returned
            // 410, `collection_resolver()` stayed on the deployer's wallet, and
            // because `dns.resolver` has exactly two writers — this op and
            // ApplyResolver, which only copies what this op stages — there was no
            // second path and no escape. It cannot be baked into genesis either,
            // since the collection's address derives from that storage. It would
            // have bricked a mandatory launch step, permanently, on an immutable
            // contract. Do not re-add it.
            var ops = storage.ops.load();
            var dns = ops.dns.load();
            if (!ops.handoverLocked) {          // bootstrap: apply immediately
                dns.resolver = msg.newResolver;
                dns.pendingResolver = null;
                dns.pendingResolverAt = 0;
                ops.dns = dns.toCell();
                storage.ops = ops.toCell();
                storage.save();
                return;
            }
            dns.pendingResolver = msg.newResolver;
            dns.pendingResolverAt = (blockchain.now() + HANDOVER_TIMELOCK) as uint32;
            ops.dns = dns.toCell();
            storage.ops = ops.toCell();
            storage.save();
        }

        ApplyResolver => {
            var ops = storage.ops.load();
            var dns = ops.dns.load();
            assert (dns.pendingResolver != null) throw ERR_NOTHING_PENDING;
            assert (blockchain.now() >= dns.pendingResolverAt) throw ERR_TIMELOCK_ACTIVE;
            dns.resolver = dns.pendingResolver!;
            dns.pendingResolver = null;
            dns.pendingResolverAt = 0;
            ops.dns = dns.toCell();
            storage.ops = ops.toCell();
            storage.save();
        }

        CancelResolver => {
            assert (in.senderAddress == storage.admin) throw ERR_NOT_ADMIN;
            var ops = storage.ops.load();
            var dns = ops.dns.load();
            // R14B1-12. THE ONLY `Cancel*` ON THIS CONTRACT WITHOUT THE GUARD.
            //
            // `CancelMinter`, `CancelContent` and `CancelRoyalty` all assert
            // "something is actually staged" and return 412 otherwise. This one
            // did not, so a `CancelResolver` against an empty slot returned exit 0
            // and wrote storage — an admin (or their ops script) reading a
            // successful transaction as "the pending resolver migration is
            // cancelled" when there was never one staged, or when the one they
            // meant to cancel had ALREADY BEEN APPLIED and the real state they
            // needed to change is `dns.resolver` itself.
            //
            // The four ops are documented as one pattern ("R8-1. Same shape and the
            // same guarantees as SetMinter/ApplyMinter/CancelMinter"), and a
            // pattern with one silent member is worse than no pattern: it is the
            // member an operator will trust by analogy. Same code, same meaning.
            assert (dns.pendingResolver != null) throw ERR_NOTHING_PENDING;
            dns.pendingResolver = null;
            dns.pendingResolverAt = 0;
            ops.dns = dns.toCell();
            storage.ops = ops.toCell();
            storage.save();
        }

        SetContent => {
            assert (in.senderAddress == storage.admin) throw ERR_NOT_ADMIN;
            // R7-7. get_nft_content builds
            //     storeUint(0x01, 8) . storeSlice(commonContent) . storeRef(individual)
            // and storeSlice copies REFS as well as bits. A commonContent root
            // carrying 4 refs therefore overflows to 5, and one carrying 1023
            // data bits leaves no room for the 8-bit tag -- either way the get
            // method aborts with exit 8 for EVERY index in the collection, since
            // commonContent is collection-wide. Metadata for every name ever
            // minted becomes unreadable at once, and ChangeAdmin to the zero
            // address makes it permanent.
            //
            // A base URI needs no refs at all (see wrappers/EmojiNft.ts
            // uriPrefixCell) and cannot sensibly approach 1023 bits, so this
            // bound refuses nothing legitimate.
            // Tightened after review: the bound was 2 refs, but storeSlice copies
            // them, so ANY ref on commonContent leaves the returned root with a
            // second ref and a snake decoder that follows the first one reads
            // commonContent's own tail instead of the item suffix -- every name
            // resolving to the same metadata. A base URI needs no refs at all;
            // wrappers/EmojiNft.ts uriPrefixCell() produces none. Zero it is.
            var cc = msg.commonContent.beginParse();
            assert (cc.remainingRefsCount() == 0) throw ERR_BAD_CONTENT;
            val ccBits = cc.remainingBitsCount();
            assert (ccBits <= MAX_COMMON_CONTENT_BITS) throw ERR_BAD_CONTENT;

            // R9-4. TWO THINGS R7-7 DID NOT CHECK, BOTH COLLECTION-WIDE.
            //
            // `commonContent` is read by `get_nft_content` AT CALL TIME, not at
            // mint time, so anything wrong here is wrong for EVERY item in the
            // collection at once, retroactively, including names sold years ago.
            // That is a much larger blast radius than the per-item suffix, and it
            // had one third of the per-item validation.
            //
            // 1. BYTE ALIGNMENT. A ragged prefix makes the composed root cell a
            //    non-multiple of 8, and @ton/core's own snake reader throws
            //    "Invalid string length: 257" on it — for every index at once.
            //    Measured: 256 bits parses, 257 and 260 throw.
            //
            // 2. TRAILING SLASH. The chain concatenates prefix and suffix with NO
            //    separator, so a prefix missing its `/` silently produces
            //    `…/item🚀🌙` — a path that resolves to nothing, for the whole
            //    collection. docs/VERCEL_NFT_PIPELINE.md states this as a rule
            //    and called forgetting it "silent, and only visible once it is
            //    too late"; a rule that important should not live only in prose.
            //
            // Both are refused rather than normalised: a base URI that cannot
            // satisfy either is a typo, and guessing at the operator's intent on
            // a value this load-bearing is worse than making them resend it.
            assert (ccBits >= 8 && ccBits % 8 == 0) throw ERR_BAD_CONTENT;
            cc.skipBits(ccBits - 8);
            assert (cc.loadUint(8) == 0x2F) throw ERR_BAD_CONTENT;   // '/'

            // R9-5. STAGED, like every other handover on this contract.
            //
            // Bootstrap first: `SetContent` MUST land before the first mint, and
            // at that point the collection has no holders to warn. Same carve-out
            // SetMinter and SetResolver take, and the same one-way LockHandover
            // closes it.
            var ops = storage.ops.load();
            if (!ops.handoverLocked) {
                storage.collectionContent = msg.collectionContent;
                storage.commonContent = msg.commonContent;
                ops.pendingContent = null;
                storage.ops = ops.toCell();
                storage.save();
                return;
            }
            ops.pendingContent = PendingContent {
                collectionContent: msg.collectionContent,
                commonContent: msg.commonContent,
                at: (blockchain.now() + HANDOVER_TIMELOCK) as uint32,
            }.toCell();
            storage.ops = ops.toCell();
            storage.save();
        }

        // R9-5. Permissionless, for the reason ApplyMinter and ApplyResolver are:
        // the change was authorised when it was staged, and a lost admin key must
        // not be able to strand a correct, already-public migration.
        ApplyContent => {
            var ops = storage.ops.load();
            assert (ops.pendingContent != null) throw ERR_NOTHING_PENDING;
            val p = ops.pendingContent!.load();
            assert (blockchain.now() >= (p.at as int)) throw ERR_TIMELOCK_ACTIVE;
            storage.collectionContent = p.collectionContent;
            storage.commonContent = p.commonContent;
            ops.pendingContent = null;
            storage.ops = ops.toCell();
            storage.save();
        }

        CancelContent => {
            assert (in.senderAddress == storage.admin) throw ERR_NOT_ADMIN;
            var ops = storage.ops.load();
            assert (ops.pendingContent != null) throw ERR_NOTHING_PENDING;
            ops.pendingContent = null;
            storage.ops = ops.toCell();
            storage.save();
        }

        SetRoyalty => {
            assert (in.senderAddress == storage.admin) throw ERR_NOT_ADMIN;
            assertRoyaltyValid(msg.royalty.load());
            // R14-7. STAGED, like every other admin write on this contract.
            //
            // This was the last one that applied INSTANTLY, and its reach is the
            // same as `SetContent`'s: `get_royalty_params` is read AT SALE TIME by
            // every marketplace, so one message re-prices the secondary cut of
            // every item ever minted, retroactively, on the next block. Measured
            // before the fix: royalty moved 5% -> 45% with `handoverLocked` pulled
            // and `get_royalty_params` reporting the new split in the same block,
            // on items sold long before. R7-6 bounded WHAT could be written and
            // left WHEN alone; `LockHandover` did not cover this op at all, so the
            // one-way commitment "every future change is visible for 48 hours" was
            // not true of the field a holder's sale proceeds actually depend on.
            //
            // Bootstrap carve-out first, exactly as SetMinter / SetResolver /
            // SetContent take it: before LockHandover the collection has no
            // holders to warn, and making an operator wait 48 hours to finish
            // wiring buys nothing.
            var o = storage.ops.load();
            if (!o.handoverLocked) {
                o.royalty = msg.royalty.load();
                o.pendingRoyalty = null;
                storage.ops = o.toCell();
                storage.save();
                return;
            }
            o.pendingRoyalty = PendingRoyalty {
                royalty: msg.royalty.load(),
                at: (blockchain.now() + HANDOVER_TIMELOCK) as uint32,
            }.toCell();
            storage.ops = o.toCell();
            storage.save();
        }

        // R14-7. Permissionless, for the reason ApplyMinter / ApplyResolver /
        // ApplyContent are: the change was authorised when it was staged, and a
        // lost admin key must not be able to strand a correct, already-public one.
        ApplyRoyalty => {
            var o = storage.ops.load();
            assert (o.pendingRoyalty != null) throw ERR_NOTHING_PENDING;
            val p = o.pendingRoyalty!.load();
            assert (blockchain.now() >= (p.at as int)) throw ERR_TIMELOCK_ACTIVE;
            o.royalty = p.royalty;
            o.pendingRoyalty = null;
            storage.ops = o.toCell();
            storage.save();
        }

        CancelRoyalty => {
            assert (in.senderAddress == storage.admin) throw ERR_NOT_ADMIN;
            var o = storage.ops.load();
            assert (o.pendingRoyalty != null) throw ERR_NOTHING_PENDING;
            o.pendingRoyalty = null;
            storage.ops = o.toCell();
            storage.save();
        }

        else => {
            // R17-34. `throw 0xffff` WAS CONFISCATION FOR HALF THE SENDERS.
            //
            // A throw refunds only if the sender set the bounce bit, and R8-12
            // recorded a wallet this project demoed with sending the non-bounceable
            // form at an EQ address anyway. Measured here: 1.0 GRAM in, 0 back.
            // R13X-6 converted the registrar and left the other three; this is the
            // contract a marketplace, an indexer and a mis-versioned front end all
            // talk to, so it sees more wrong opcodes than any of them.
            //
            // A genuine top-up never reaches here — the `remainingBitsCount() < 32`
            // guard at the entry point returns first — so the only bodies this arm
            // sees are ones this contract cannot interpret. Op 0 is the wallet
            // text-comment convention and stays a top-up; everything else goes
            // home, carrying the reason so the sender learns why and an indexer can
            // tell a rejection from a transfer.
            //
            // R31-2. R25-6b's peer-loop rule, which the registrar got and this file
            // did not: an incoming 0x7e3a11c5 IS the predicate, whoever sends it.
            // R17-36's "it needs a mis-wiring, not an attacker" is false here — one
            // ordinary TEP-62 transfer naming this collection as
            // `response_destination` sends it an Excesses it has no arm for, this
            // arm answers with a rejection, the item answers that, and the item's
            // whole above-reserve balance burns (measured: 1,647 transactions and
            // 0.468 GRAM at a 1.0 balance). No wallet or indexer builds this body;
            // it is emit-only in all four contracts, and a sender who does build it
            // is telling this contract it is refusing a payment.
            val opU = in.body.preloadUint(32);
            if (opU != 0 && opU != OP_REJECTED_REFUND) {
                rejectAndRefund(in.senderAddress, ERR_UNKNOWN_OP);
            }
            return;
        }
    }
}

// R23-4. The refund shape the `else` arm already used, factored out so the two
// sites cannot drift — the same move R21-2 made on the item. Value 0 +
// CARRY_ALL_REMAINING_MESSAGE_VALUE hands the sender's own value back and touches
// nothing of this contract's balance, so it is safe at the rent floor;
// IGNORE_ERRORS keeps a failed refund from turning a refusal into a throw. Only
// safe BEFORE any state write — every call site is.
fun rejectAndRefund(to: address, reason: int) {
    // R31-2. DO NOT ANSWER OURSELVES — the registrar's R17-36 guard. Reachable
    // through any config field that can point at this contract; R31-3 closes three
    // of those doors, and this closes the consequence for all of them at once.
    if (to == contract.getAddress()) { return; }
    createMessage({
        bounce: BounceMode.NoBounce,
        value: 0,
        dest: to,
        body: RejectedRefund { queryId: 0, reason: reason as uint32 },
    }).send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS);
}

// ---- bounce handler ----
//
// Fix #1/#2: a bounced OwnerSynced (registrar rejected / under-gas) means the
// registry lags the NFT. The collection holds no per-name ownership to revert;
// recovery is the item's permissionless ResyncOwner op, which re-drives this
// relay. No state change here.
fun onBouncedMessage(in: InMessageBounced) {
    return;
}

// ---- get methods ----

// TEP-62 required
// Self-describing version for integrators (wallets, indexers, marketplaces).
// Bump on any deployed logic change.
get fun version(): int {
    return 2;
}

get fun get_collection_data(): (int, cell, address) {
    val storage = CollectionStorage.load();
    return (-1, storage.collectionContent, storage.admin);   // -1 = non-sequential indexes
}

// R21-3 (LOW, TSA round 21). `get_nft_address_by_index(-1)` THREW EXIT 5, AND -1 IS
// THIS COLLECTION'S OWN ADVERTISED `next_item_index`.
//
// A TVM stack integer is 257-bit SIGNED; the `uint256` in the signature is a
// serialisation width, not a range check on the incoming argument. `calcItemDeploy`
// then does `storeUint(index, 256)` and STU raises integer-out-of-range. Measured
// (audit/round21/tsa/tests/R21TsaGetMethods.spec.ts):
//
//     index = 0, 1, 2^256-1  -> exit 0   (control)
//     index = -1, -2         -> exit 5
//     index = 2^256          -> not representable on the stack; never reaches us
//
// The caller is not hostile. `get_collection_data` above returns -1 for
// `next_item_index` — the `.ton`-domains "indexes are not sequential" convention —
// so an indexer that reads that field and probes it is doing the obvious thing.
//
// WHAT THE REFERENCE DOES: nothing different, and worse. `nft-collection.fc`'s
// `calculate_nft_item_state_init` is `begin_cell().store_uint(item_index, 64)…`
// (256 in the `.ton` dns-contract variant), so the reference throws the identical
// uncatalogued exit 5 on the identical input. There is no conformant behaviour to
// match here, only a bare arithmetic fault to make legible.
//
// WHY A REFUSAL AND NOT A SENTINEL. Returning `addr_none` was the other candidate
// and is rejected for the reason the item's tonapi note gives at length: a
// get-method that answers with a shape its declared type does not promise breaks
// the strict stack decoders the whole indexing layer is built on, and TEP-62 readers
// call `readAddress()` on this slot. Returning a DERIVED address (masking the index
// into 256 bits) is worse still — it would answer a different question silently, and
// map -1 and 2^256-1 onto the same item. The honest answer to "what is the address
// of item -1" is that there is none, and 479 says exactly that where exit 5 said
// only "some arithmetic overflowed somewhere".
//
// `get_nft_content` shares the parameter and is deliberately NOT guarded: it never
// serialises `index`, so a negative one already answers cleanly, and adding a throw
// there would turn a working call into a failing one for no gain.
get fun get_nft_address_by_index(index: uint256): address {
    assert ((index as int) >= 0) throw ERR_BAD_ITEM_INDEX;
    val storage = CollectionStorage.load();
    return calcItemDeploy(storage.itemCode, index).calculateAddress();
}

get fun get_nft_content(index: uint256, individualContent: cell): cell {
    val storage = CollectionStorage.load();
    // offchain concat: 0x01 + commonContent bits, ref -> individual content
    return beginCell()
        .storeUint(0x01, 8)
        .storeSlice(storage.commonContent.beginParse())
        .storeRef(individualContent)
        .endCell();
}

// TEP-66
/// TEP-81. R8-1 — THE DELEGATING STUB. See the DnsConfig note above for why the
/// collection answers this at all.
///
/// `.ton`'s collection consumes the top label and delegates to a PER-NAME item,
/// which then answers the leftover "\0" from its own storage. Ours cannot: our
/// records live in one contract keyed on the bare label, not in the item. So this
/// stub consumes ONLY the self-reference byte and hands the whole label onward —
/// `\0🚀🌙\0` in, 8 bits consumed, `🚀🌙\0` to the resolver, which is exactly the
/// shape it already accepts (tests/R7RootAgnostic.spec.ts, "THE BRIDGE").
///
/// A request must begin with `\0`. TEP-81 requires that of every non-root
/// resolver, and every real client does it — MyTonWallet prepends it in
/// `dnsResolve()`, tonweb in `Dns.resolve()`. Without it we cannot report a
/// prefix length that is both honest and non-zero, and 0 means LOOKUP FAILED.
get fun dnsresolve(subdomain: slice, category: uint256): (int, cell?) {
    var s = subdomain;
    val totalBits = s.remainingBitsCount();
    assert (totalBits % 8 == 0) throw ERR_BAD_SUBDOMAIN;
    if (totalBits == 0) {
        return (0, null);
    }
    // R23-2. A SUBDOMAIN THAT CONTINUES IN A REF IS NOT A SUBDOMAIN WE ANSWERED.
    //
    // Every length test in this function is `remainingBitsCount()`, which does
    // not see refs. So the "nothing may follow the separator" gate below passed
    // for a query whose ROOT CELL ends at the terminator but which continues in a
    // reference — and we answered `evil.🚀.emoji` with 🚀's delegation, i.e. a
    // deeper name silently resolving to its parent. TEP-81's internal
    // representation is a flat byte string and no conformant builder (tonweb,
    // tongo, MyTonWallet) splits one across cells, so this costs nothing and
    // removes a whole class of "the bytes I measured are not the bytes I was
    // given". Refuse rather than truncate: 0 means NOT FOUND, which is the honest
    // answer for a name we did not read in full.
    if (s.remainingRefsCount() != 0) {
        return (0, null);
    }
    // A bare "\0" asks about the zone itself. Resolved — we hold no records.
    if (totalBits == 8 && s.preloadUint(8) == 0) {
        return (8, null);
    }

    // R9-1. TWO CLIENT MODELS EXIST, AND WE ONLY SERVED ONE.
    //
    //   A) zone-table clients (MyTonWallet, tonapi, Tonkeeper) strip the suffix
    //      themselves and ask us "\0<label>\0". The stub below handles that: eat
    //      the self byte, hand the label on.
    //   B) root-walking clients (tonweb, OpenMask, anything built on
    //      TonWeb.dns.resolve) send the WHOLE internal name from whatever address
    //      is configured as their root — "\0emoji\0<label>\0". Until now we ate 8
    //      bits and handed `emoji\0<label>\0` to the resolver, which read the
    //      label `emoji`, saw a remainder, and returned (0, null). `.emoji`
    //      simply did not resolve for that entire class of client.
    //
    // Measured, not assumed (scripts/_rootbytes.ts, against mainnet bytecode):
    // the config-#4 root given "\0ton\0foo\0" returns bits=32 — it consumes the
    // self byte AND ITS OWN ZONE LABEL and leaves the trailing "\0". A zone
    // contract is expected to recognise its own name. Ours did not.
    //
    // So: if the query opens with our zone label, consume "\0emoji" and leave the
    // separator, byte-for-byte what the root does with "ton". The resolver then
    // sees "\0<label>\0", which its conditional leading-\0 skip already accepts,
    // and both models converge on the same second hop.
    //
    // NOT A NAME COLLISION. `emoji` is five ASCII letters; every registered name
    // is emoji-only, so no label in this namespace can ever equal the zone label
    // (asserted in tests/R9ZoneWalk.spec.ts against the frozen table). The one
    // behaviour that changes for a query we could already answer is the exact
    // string "\0emoji\0", which flips from NOT FOUND to resolved-with-no-records
    // — identical to the root's answer for "\0ton\0", and unreachable as a name.
    // R12. DELEGATE TO THE NAME'S OWN ITEM — `.ton`'s architecture.
    //
    // This used to hand every query to ONE shared resolver contract, which
    // therefore held per-name state for the whole namespace and hit TON's
    // 65,536-cell account ceiling near 16,000 names (see emoji_nft_item.tolk's
    // header for the measurement). Now the label is resolved to the item address
    // that already exists for that name — `index = nameHash`, the same derivation
    // `get_nft_address_by_index` uses — and the item answers from its own storage.
    // No shared contract grows with the namespace.
    //
    // BOTH client models converge here, and both leave exactly the trailing "\0"
    // the item expects as its self-reference byte:
    //   A · zone-table clients (MyTonWallet, tonapi, Tonkeeper) strip the suffix
    //       and send "\0<label>\0"       -> consume "\0<label>",        leave "\0"
    //   B · root-walking clients (tonweb, OpenMask) send the whole internal name
    //       "\0emoji\0<label>\0"         -> consume "\0emoji\0<label>",  leave "\0"
    // This mirrors what mainnet's own contracts do (measured in R9-1): a zone
    // consumes its own label and leaves the separator for the next hop.
    var consumed = 0;
    if (totalBits >= ZONE_SELF_BITS && s.preloadUint(ZONE_SELF_BITS) == ZONE_SELF_PREFIX) {
        s.skipBits(ZONE_LABEL_BITS);        // "\0emoji", leaving "\0<label>\0"
        consumed += ZONE_LABEL_BITS;
        // "\0emoji\0" on its own asks about the ZONE, not a name in it. Answer
        // exactly as mainnet's root answers "\0ton\0": resolved, no records.
        if (s.remainingBitsCount() == 8) {
            return (totalBits, null);
        }
    } else if (totalBits >= ZONE_ALT_BITS && s.preloadUint(ZONE_ALT_BITS) == ZONE_ALT_PREFIX) {
        // R23-EMJ. The `.emj` arm, byte-for-byte the same shape as `.emoji`
        // above. `else if` rather than a second `if` because the two prefixes are
        // mutually exclusive by construction (they differ at byte 4), so a second
        // test after a successful first match could only ever mis-fire on a NAME
        // that happened to begin with the other prefix's bytes — and chaining
        // them makes that structurally impossible rather than merely unlikely.
        s.skipBits(ZONE_ALT_LABEL_BITS);    // "\0emj", leaving "\0<label>\0"
        consumed += ZONE_ALT_LABEL_BITS;
        if (s.remainingBitsCount() == 8) {
            return (totalBits, null);
        }
    }
    // R12b. CONSUME THE NAME'S LEADING SEPARATOR **IF PRESENT**.
    //
    // This closes the case R9-1 documented as unfixable under the old design:
    // "if an operator points emojiverse.ton's dns_next_resolver at the COLLECTION,
    // the collection is asked '<label>\0' with no leading separator... a
    // pass-through stub cannot serve that."
    //
    // It could not, because a stub has nothing to consume that is not part of the
    // label it must forward, and TEP-81 reads resolved_bits == 0 as NOT FOUND. A
    // ROUTER has no such problem: it consumes the label itself and hands on the
    // trailing separator, so it can serve both parent shapes —
    //
    //   zone-style parent (root / .ton collection)  hands  "\0<label>\0"
    //   item-style parent (a .ton DOMAIN item)      hands    "<label>\0"
    //
    // Both leave exactly "\0" for the item, and both report a non-zero prefix.
    // The operator is therefore free to delegate emojiverse.ton to this ONE
    // address, which is what every zone-table integrator wants anyway.
    if (s.preloadUint(8) == 0) {
        s.skipBits(8);
        consumed += 8;
    }

    // read the label up to (not including) its terminator
    var label = beginCell();
    var labelBytes = 0;
    var atSep = false;
    while (!atSep && s.remainingBitsCount() >= 8) {
        val b = s.preloadUint(8);
        if (b == 0) {
            atSep = true;
        } else {
            s.skipBits(8);
            label.storeUint(b, 8);
            labelBytes += 1;
            consumed += 8;
        }
    }
    // A name must be terminated and non-empty, and NOTHING may follow the
    // separator: this zone serves names, not sub-zones, so a deeper query is
    // reported as not-found rather than silently resolved to the parent.
    if (!atSep || labelBytes == 0 || s.remainingBitsCount() != 8) {
        return (0, null);
    }

    // R23-EMJ / R23-3. A ZONE LABEL IS NEVER A NAME, WHICHEVER SHAPE DELIVERS IT.
    //
    // The two zone-label branches above only fire on the SEPARATOR-LED shape
    // ("\0emoji\0…", "\0emj\0…") that a root- or zone-style parent sends. An
    // ITEM-style parent — a `.ton` DOMAIN item delegating to us — hands the label
    // BARE ("emoji\0", "emj\0"), which fell straight through to the name path and
    // delegated to item(sha256("emoji")). So the same zone label resolved as the
    // ZONE under one parent and as a NAME under another, and the collection's
    // admin `Mint` door takes an opaque 256-bit index, so such an item can
    // actually exist. That is the one input where this router's root-agnostic
    // equivalence — the property the whole two-client design rests on — did not
    // hold.
    //
    // Both spellings now answer as the zone in both shapes: resolved, no records,
    // matching what mainnet's root answers for "\0ton\0". This is also what makes
    // "an emoji-only namespace cannot contain `emoji` or `emj`" a rule of THIS
    // contract rather than an inherited assumption about the registrar's filter.
    val labelSlice = label.endCell().beginParse();
    if ((labelBytes == 5 && labelSlice.preloadUint(ZONE_LABEL_EMOJI_BITS) == ZONE_LABEL_EMOJI)
     || (labelBytes == 3 && labelSlice.preloadUint(ZONE_LABEL_EMJ_BITS) == ZONE_LABEL_EMJ)) {
        return (totalBits, null);
    }

    // index = sha256(label bytes) = the registrar's nameHash = the item's index
    val labelHash = labelSlice.bitsHash();
    val itemAddr = calcItemDeploy(CollectionStorage.load().itemCode, labelHash).calculateAddress();
    return (consumed, beginCell()
        .storeUint(DNS_NEXT_RESOLVER, 16)
        .storeAddress(itemAddr)
        .endCell());
}

/// R8-6. `handover()` is the warning window R7-11 shipped, and a successor is
/// told to read it before accepting. It had no DNS field, so a staged zone
/// redirect was invisible in exactly the view meant to surface staged changes.
/// Returns (resolver, pendingResolver, pendingResolverAt) alongside it.
get fun handover_dns(): (address, address?, int) {
    val d = CollectionStorage.load().ops.load().dns.load();
    return (d.resolver, d.pendingResolver, d.pendingResolverAt);
}

/// R9-5. The staged content change, readable for the full 48 hours before it
/// lands. A timelock that nobody can observe buys no warning time — the same
/// argument R7-11 made for `handover()` and R8-6 made for `handover_dns()`.
/// Returns (pendingCollectionContent, pendingCommonContent, at); all null/0 when
/// nothing is staged.
get fun handover_content(): (cell?, cell?, int) {
    val o = CollectionStorage.load().ops.load();
    if (o.pendingContent == null) {
        return (null, null, 0);
    }
    val p = o.pendingContent!.load();
    return (p.collectionContent, p.commonContent, p.at);
}

/// R8-1. The pointer, and anything staged against it. Lets an integrator confirm
/// which record contract this zone currently delegates to, and see a pending
/// migration for the full 48 hours before it lands.
get fun collection_resolver(): (address, address?, int) {
    val dns = CollectionStorage.load().ops.load().dns.load();
    return (dns.resolver, dns.pendingResolver, dns.pendingResolverAt);
}

get fun royalty_params(): (uint16, uint16, address) {
    val storage = CollectionStorage.load();
    val royalty = storage.ops.load().royalty;
    return (royalty.numerator, royalty.denominator, royalty.destination);
}

/// R14-7. The staged royalty change, readable for the full 48 hours before it
/// lands — same argument R7-11 made for `handover()`, R8-6 for `handover_dns()`
/// and R9-5 for `handover_content()`. A timelock nobody can observe buys no
/// warning time, and this is the one field a seller's proceeds depend on at the
/// moment of sale. Returns (numerator, denominator, destination, at); all zero /
/// addr_none when nothing is staged.
get fun handover_royalty(): (int, int, address?, int) {
    val o = CollectionStorage.load().ops.load();
    if (o.pendingRoyalty == null) {
        return (0, 0, null, 0);
    }
    val p = o.pendingRoyalty!.load();
    return (p.royalty.numerator, p.royalty.denominator, p.royalty.destination, p.at);
}

// project-specific convenience
// R7-11: staged state must be readable, or the timelock buys no warning time.
// (admin, pendingAdmin, pendingAdminAt, minter, pendingMinter, pendingMinterAt)
get fun handover(): (address, address?, int, address, address?, int, bool) {
    val s = CollectionStorage.load();
    val o = s.ops.load();
    return (s.admin, o.pendingAdmin, o.pendingAdminAt,
            s.minter, o.pendingMinter, o.pendingMinterAt, o.handoverLocked);
}

get fun minter(): address {
    val storage = CollectionStorage.load();
    return storage.minter;
}
