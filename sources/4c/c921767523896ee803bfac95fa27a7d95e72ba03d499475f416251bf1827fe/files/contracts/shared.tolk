// Shared constants and types for Digital Nobility contracts.
// Spec of record: docs/architecture.md; per-contract details in docs/spec/.

// Ranks (Consul is an office, not a rank — architecture §8).
const RANK_CITIZEN = 0
const RANK_KNIGHT = 1
const RANK_BARON = 2
const RANK_COUNT = 3
const RANK_DUKE = 4

// Immutable invariants (architecture §8) — never adjustable by any order.
const MAX_DUKES = 49
const MAX_BUDGET = 9
const EPOCH_FLOOR = 10368000 // 4 months in seconds
const QUORUM_ORDINARY = 4
const QUORUM_REMOVAL = 6
const TOTAL_SEATS = 7

// Rent endowment kept on each TitleItem, and the per-purchase gas margin.
const ITEM_ENDOWMENT = ton("0.05")
const GAS_MARGIN = ton("0.05")
// Value attached to a DukeRejected notice; absorbed by the registry as a top-up.
const DUKE_REJECT_NOTICE = ton("0.02")
// Pending patents expire after 30 days (architecture §11); compile-time, revisable pre-mainnet.
const PATENT_EXPIRY = 2592000
// Chain-proof cache lifetime (docs/spec/title-item.md "Chain-proof walk").
const PROOF_TTL = 86400
// CouncilGate action-list cap, enforced once at Registry DeployGate time (docs/spec/registry.md).
const MAX_GATE_ACTIONS = 10
// ConsulOrder treasury-spend action-list cap, enforced once at Registry NewProposal time
// (docs/spec/registry.md "NewProposal") — a separate constant from MAX_GATE_ACTIONS even
// though both currently equal 10 (independent tuning knobs, per spec).
const MAX_ORDER_ACTIONS = 10
// Rent endowment kept on a freshly-deployed ConsulOrder (docs/spec/consul-order.md), same
// shape as ITEM_ENDOWMENT but a separate tuning knob for a different contract's rent floor.
const ORDER_ENDOWMENT = ton("0.05")

// NewProposal `kind` values (docs/spec/registry.md "NewProposal") — each maps to exactly one
// seat's proposal domain, and to either a Treasury spend (0) or a Registry CouncilAction (1..7).
const COUNCIL_KIND_TREASURY_SPEND = 0
const COUNCIL_KIND_SET_PARAMS = 1
const COUNCIL_KIND_REVOKE_TITLE = 2
const COUNCIL_KIND_REMOVE_OFFICER = 3
const COUNCIL_KIND_APPOINT_INTERIM = 4
const COUNCIL_KIND_CONFIRM_DUKEDOM = 5
const COUNCIL_KIND_REJECT_DUKEDOM = 6
const COUNCIL_KIND_SET_PAUSED = 7
// Task 7: committee awards for seats 4/5, ridden on the same NewProposal/CouncilAction wire
// (docs/spec/registry.md "AwardSeat") rather than a parallel message pipeline.
const COUNCIL_KIND_AWARD_SEAT = 8

// Adjustable parameters (consul order, Task 6), defaults in architecture §9/§11.
// ponytail: grows task by task — 7 var-length `coins` fields would overflow the 1023-bit
// cell; split rarely-read groups into ref cells when the promotion fees land (Task 3).
struct Params {
    citizenshipPrice: coins
    knightFee: coins
    baronFee: coins
    countFee: coins
    dukeBasePrice: coins
    dukeGrowthPermille: uint16
    baronBudget: uint8
    countBudget: uint8
    dukeBudget: uint8
    baronQuota: uint16
    countQuota: uint16
    dukeConfirmationRequired: bool
    verificationFee: coins
    gateDeployFee: coins
    // Task 6: the one governance-clamped-by-invariant field promoted into Params (SetParams
    // clamps this at EPOCH_FLOOR, docs/spec/registry.md "NewProposal"). Defaulted so every
    // pre-Task-6 Params literal keeps compiling; default matches architecture §9/§11 (12mo).
    epochSeconds: uint32 = 31536000
}

// Merit ledger event, emitted as an external out-message on every economic action
// (architecture §7). `kind` for issuance equals the acquired rank; other kinds below.
const MERIT_KIND_VERIFICATION = 5
const MERIT_KIND_REPLEDGE = 6
const MERIT_KIND_CO_SPONSORSHIP = 7
// Emitted only when an Election candidate's deposit is forfeited (real revenue to treasury),
// never on a refund or on a ballot/doyen claim itself (docs/spec/election.md "New merit-ledger
// kind").
const MERIT_KIND_ELECTION_FORFEIT = 8

struct (0x444e0e01) MeritEvent {
    actor: address
    kind: uint8
    amount: coins
    ts: uint32
}

enum RegistryErr {
    Paused = 100
    InsufficientValue = 101
    DukeCapReached = 102
    AlreadyPending = 103
    NotAuthorized = 104
    NoPendingDuke = 105
    NotTitleItem = 106
    BadTransition = 107
    TooManyActions = 108
    BadDomain = 109
    BadClamp = 110
    NotConsulOrder = 111
    SeatNotHeld = 112
    SeatNotVacant = 113
    // Task 7 (docs/spec/registry.md "Errors (Task 7)").
    BadSignature = 114
    HolderActive = 115
    // Task 8 (docs/spec/registry.md "Errors (Task 8)").
    AuctionOpen = 116
    NotAuction = 117
    // Task 9 (docs/spec/registry.md "Errors (Task 9)").
    EpochNotDue = 118
    NotElection = 119
    // Task 11 (docs/spec/registry.md "SetTreasury"): the combined founder-sender +
    // still-placeholder guard, one code for both failure shapes since SetTreasury has no
    // other way to fail.
    TreasuryWiringClosed = 120
    InvalidMessage = 0xFFFF
}

enum ItemErr {
    NotRegistry = 200
    NotOwner = 201
    Soulbound = 202
    AlreadyRevoked = 203
    Destroyed = 204
    NotInitialized = 205
    NotTitleItem = 206
    CannotPromote = 207
    PatentPending = 208
    NoPatent = 209
    PatentExpired = 210
    PatentNotExpired = 211
    NeedsCoSponsor = 212
    SponsorRankTooLow = 213
    InsufficientValue = 214
    NotPatron = 215
    CannotRepledge = 216
    NoRepledge = 217
    RankTooLow = 218
    NotApproved = 219
    ChainTooDeep = 220
    InvalidMessage = 0xFFFF
}

// CouncilGate errors (docs/spec/council-gate.md), own 300s namespace.
enum GateErr {
    NotTitleItem = 300
    BadProof = 301
    ProofStale = 302
    RankTooLow = 303
    AlreadyApproved = 304
    Expired = 305
    AlreadyExecuted = 306
    InvalidMessage = 0xFFFF
}

// DemoTreasury errors (docs/spec/demo-treasury.md), own 400s namespace.
enum TreasuryErr {
    NotGate = 400
    InvalidMessage = 0xFFFF
}

// Treasury errors (docs/spec/treasury.md), own 500s namespace — deliberately not named
// TreasuryErr, since that identifier already belongs to DemoTreasury's own 400s enum above.
enum CoinTreasuryErr {
    NotConsulOrder = 500
    InvalidMessage = 0xFFFF
}

// ConsulOrder errors (docs/spec/consul-order.md), own 600s namespace.
enum ConsulOrderErr {
    NotRegistry = 600
    AlreadyInitialized = 601
    NotRoster = 602
    AlreadyApproved = 603
    Expired = 604
    AlreadyExecuted = 605
    NotInitialized = 606
    InvalidMessage = 0xFFFF
}

// TitleItem addresses are deterministic from (item_code, registry, owner) — the
// jetton-wallet pattern. This initial data cell is the whole uninitialized state.
struct TitleItemInitData {
    registry: address
    owner: address
}

fun titleItemDeployAddress(itemCode: cell, registry: address, owner: address): AutoDeployAddress {
    return { stateInit: { code: itemCode, data: TitleItemInitData { registry, owner }.toCell() } };
}

// A CouncilGate's one-shot, pre-baked outgoing message list (docs/spec/council-gate.md):
// a Maybe-terminated forward list of fully-formed raw message cells, sent as-is (mode 0).
struct ActionNode {
    message: cell
    next: Cell<ActionNode>?
}

// Generic deterministic-address helper for any {code, data} pair, mirroring
// titleItemDeployAddress — used for CouncilGate deploys (docs/spec/council-gate.md,
// docs/spec/registry.md "DeployGate").
fun councilGateDeployAddress(gateCode: cell, data: cell): AutoDeployAddress {
    return { stateInit: { code: gateCode, data } };
}

// A ConsulOrder child -> Treasury, once its own weighted quorum executes a kind-0 (treasury
// spend) order (docs/spec/treasury.md, docs/spec/consul-order.md "ApproveOrder"). Lives here
// (not in a Treasury-only file) since ConsulOrder is the one that constructs it.
struct (0x444e0401) ExecuteActions {
    queryId: uint64
    orderSeqno: uint32
    actions: Cell<ActionNode>?
}

// A ConsulOrder's address depends only on {registry, orderSeqno} (docs/spec/consul-order.md
// "Storage") — its actual config (kind/body/roster snapshot) arrives as a follow-up OrderInit
// message, exactly like TitleItem.Initialize, so it never enters the address computation.
struct ConsulOrderInitData {
    registry: address
    orderSeqno: uint32
}

fun consulOrderDeployAddress(
    orderCode: cell,
    registry: address,
    orderSeqno: uint32,
): AutoDeployAddress {
    return {
        stateInit: { code: orderCode, data: ConsulOrderInitData { registry, orderSeqno }.toCell() },
    };
}

// Fragment-style English auction for seat 2 (Master of Coin), docs/spec/seat-auction.md.
// Compile-time, not Params — see the spec's "Key decisions" #2: caller-supplied would be
// exploitable (StartAuction is permissionless) and Params has no bit budget left for six more
// fields.
const AUCTION_DURATION = 259200 // 3 days
const AUCTION_ANTISNIPE_WINDOW = 600 // 10 minutes before end_at
const AUCTION_ANTISNIPE_EXTENSION = 600 // extends end_at to now() + this, on a late bid
const AUCTION_MIN_BID = ton("50") // first-bid floor (indicative, revisable pre-mainnet)
const AUCTION_MIN_INCREMENT = ton("5") // flat min raise over the current highest bid
// Reserved on the SeatAuction contract from StartAuction time, spent at Settle/AuctionResult
// time to fund the AuctionResult -> Registry hop and its downstream claimSeat/DukeGrant deploy
// plus the AuctionCollect/AuctionRefund reply hop back — same sizing as ClaimSeatHeir/
// ClaimSeatVip's ITEM_ENDOWMENT + 2*GAS_MARGIN floor.
const AUCTION_ENDOWMENT = ton("0.15")

// A SeatAuction's address depends only on {registry, auctionSeqno} (docs/spec/seat-auction.md
// "Storage") — its actual config (treasury/endAt) arrives as a follow-up AuctionInit message,
// exactly like ConsulOrder's own OrderInit.
struct SeatAuctionInitData {
    registry: address
    auctionSeqno: uint32
}

fun seatAuctionDeployAddress(
    auctionCode: cell,
    registry: address,
    auctionSeqno: uint32,
): AutoDeployAddress {
    return {
        stateInit: {
            code: auctionCode,
            data: SeatAuctionInitData { registry, auctionSeqno }.toCell(),
        },
    };
}

// SeatAuction errors (docs/spec/seat-auction.md), own 700s namespace.
enum SeatAuctionErr {
    NotRegistry = 700
    AlreadyInitialized = 701
    NotInitialized = 702
    AuctionEnded = 703
    AuctionNotEnded = 704
    AlreadySettled = 705
    BidTooLow = 706
    InsufficientValue = 707
    InvalidMessage = 0xFFFF
}

// Master of Laws election + Lord Justiciar doyen challenge, docs/spec/election.md.
// Window lengths are compile-time, decoupled from params.epochSeconds (decision 12): epoch
// length governs cadence between election cycles, not a single cycle's own duration.
const ELECTION_WINDOW = 2592000 // 30 days total (candidate + voting phases)
const ELECTION_CANDIDATE_WINDOW = ELECTION_WINDOW / 4 // first quarter, 7.5 days
const ELECTION_CANDIDATE_DEPOSIT = ton("10") // flat floor, indicative, revisable pre-mainnet
const MAX_CANDIDATES = 10 // matches MAX_GATE_ACTIONS/MAX_ORDER_ACTIONS
const MAX_DOYEN_CLAIMS = 10
// 10% of the sum of architecture's fixed rank caps at full capacity (decision 4):
// 49*16 + 147*8 + 735*4 + 2205*2 = 9310; floor = 931. Citizens excluded (unbounded supply,
// no finite theoretical max) — conservative in the floor's own favor.
const ELECTION_TURNOUT_FLOOR_WEIGHT = 931
// Per-registry-hop endowment (ElectionResult, DoyenClaim), mirrors AUCTION_ENDOWMENT sizing.
const ELECTION_ENDOWMENT = ton("0.15")
// Carried through StartElection -> ElectionInit: funds up to two ELECTION_ENDOWMENT reserves
// (one per eventual result message) plus Finalize's own bounded fanout gas.
const ELECTION_DEPLOY_ENDOWMENT = ton("0.4")
const ELECTION_FINALIZE_MIN = ton("0.15") // flat floor, same idiom as Settle's 2*GAS_MARGIN

// An Election's address depends only on {registry, electionSeqno} (docs/spec/election.md
// "Storage") — its actual config (treasury/itemCode/window boundaries) arrives as a follow-up
// ElectionInit message, exactly like SeatAuctionInitData/AuctionInit.
struct ElectionInitData {
    registry: address
    electionSeqno: uint32
}

fun electionDeployAddress(
    electionCode: cell,
    registry: address,
    electionSeqno: uint32,
): AutoDeployAddress {
    return {
        stateInit: {
            code: electionCode,
            data: ElectionInitData { registry, electionSeqno }.toCell(),
        },
    };
}

// Election errors (docs/spec/election.md), own 800s namespace.
enum ElectionErr {
    NotRegistry = 800
    AlreadyInitialized = 801
    NotInitialized = 802
    CandidateWindowClosed = 803
    VotingNotOpen = 804
    VotingNotEnded = 805
    AlreadyFinalized = 806
    TooManyCandidates = 807
    AlreadyCandidate = 808
    UnknownCandidate = 809
    NotTitleItem = 810
    BadProof = 811
    AlreadyVoted = 812
    NotDuke = 813
    InsufficientValue = 814
    InvalidMessage = 0xFFFF
}
