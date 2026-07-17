// NobilityRegistry storage and message schemas. Spec: docs/spec/registry.md.

import "shared"
import "title-item-types"

// TEP-64 content: `meta` is the collection metadata cell, `commonBase` holds raw URI bytes
// that prefix each item's individual content in get_nft_content.
struct RegistryContent {
    meta: cell
    commonBase: cell
}

// Bounded by the 49-duke cap — the one map the Registry may hold (not per-user title state).
struct PendingDuke {
    price: coins
    ts: uint32
}

// Nested in Task 5 (docs/spec/registry.md "Storage") to keep the root RegistryStorage cell at
// its 4-ref ceiling while adding `gateCode` — see the spec note for the full rationale.
// Task 6 adds `orderCode` (the ConsulOrder code cell) for the same ref-budget reason. Task 8
// adds `auctionCode` (the SeatAuction code cell), filling StaticCodes's fourth and last direct
// ref. Task 9 (docs/spec/election.md "Key decisions" #1) restructures rather than extends:
// `auctionCode` moves into a nested `codes2: Cell<StaticCodes2>`, freeing room for
// `electionCode` and two more code cells beyond that before this problem recurs.
struct StaticCodes {
    itemCode: cell
    gateCode: cell
    orderCode: cell
    codes2: Cell<StaticCodes2>
}

// docs/spec/election.md "Key decisions" #1 / "RegistryStorage / StaticCodes changes".
struct StaticCodes2 {
    auctionCode: cell
    electionCode: cell
}

// Task 6: pendingDukes (previously a bare top-level field) and the new seatHolders roster map
// are bundled into one ref cell to keep RegistryStorage's root at its 4-ref ceiling — pure
// ref-budget fix, no semantic relationship between the two maps (docs/spec/registry.md
// "Storage"). Task 7 adds founder/vipPubkey/heir for the same ref-budget reason (genesis
// address/key fields cannot fit the already-4-ref root) — again no semantic relationship, just
// where the bits fit. No compile-time defaults make sense for these three (genesis-supplied
// addresses/a key, docs/spec/registry.md "Ref/bit budget"); every construction site names them.
struct Ledgers {
    pendingDukes: map<address, PendingDuke> = []
    seatHolders: map<uint8, address> = []
    founder: address
    vipPubkey: uint256
    heir: address
}

struct RegistryStorage {
    emperor: address
    treasury: address
    paused: bool
    dukeCount: uint8 = 0
    pendingDukeCount: uint8 = 0
    // Task 6: next ConsulOrder seqno (a plain counter, like dukeCount) and the one-way seat
    // ratchet mask (bit i set the first time seat i is ever claimed, never cleared).
    nextOrderSeqno: uint32 = 0
    claimedSeatsMask: uint8 = 0
    // Task 7: interim-vs-mechanism precedence bit (bit i set while seat i's holder was
    // installed by AppointInterim, cleared on any replacement), the emperor's one-way
    // renunciation flag, and seat 1's dead-man-switch activity clock (docs/spec/registry.md
    // "Task 7 — offices & accession", "Storage additions").
    interimSeatsMask: uint8 = 0
    imperiumRenounced: bool = false
    seat1LastActiveAt: uint32 = 0
    // Task 8: next SeatAuction round seqno (a plain counter, like nextOrderSeqno) and the
    // single-flight lock preventing a second concurrent round for seat 2 (docs/spec/registry.md
    // "Task 8 — auction hook").
    auctionSeqno: uint32 = 0
    auctionOpen: bool = false
    // Task 9: next Election round seqno, the single-flight lock for seats 3/7's shared cycle,
    // and the epoch clock itself (docs/spec/registry.md "Task 9 — election hook").
    electionSeqno: uint32 = 0
    electionOpen: bool = false
    nextEpochAt: uint32 = 0
    baronPop: uint16 = 0
    countPop: uint16 = 0
    baronBootstrapClosed: bool = false
    countBootstrapClosed: bool = false
    codes: Cell<StaticCodes>
    params: Cell<Params>
    ledgers: Cell<Ledgers>
    content: Cell<RegistryContent>
}

fun RegistryStorage.load(): RegistryStorage {
    return RegistryStorage.fromCell(contract.getData());
}

fun RegistryStorage.save(self) {
    contract.setData(self.toCell());
}

struct (0x444e0101) BuyCitizenship {
    queryId: uint64
}

struct (0x444e0102) BuyDukedom {
    queryId: uint64
}

// ConfirmDukedom (0x444e0103) is retired in Task 6: the emperor-direct shortcut is replaced
// by CouncilAction kind COUNCIL_KIND_CONFIRM_DUKEDOM, proposed via NewProposal and approved
// 4/7 (docs/spec/registry.md "ConfirmDukedom — retired in Task 6").

// CouncilGate factory (Task 5, docs/spec/registry.md "DeployGate"). `actions` mirrors the
// CouncilGate storage field of the same shape (docs/spec/council-gate.md).
struct (0x444e0110) DeployGate {
    queryId: uint64
    quorum: uint8
    minRank: uint8
    expiry: uint32
    maxProofAge: uint32
    salt: uint64
    actions: Cell<ActionNode>?
}

// NewProposal/CouncilAction (Task 6, docs/spec/registry.md "NewProposal"). `body`'s shape
// depends on `kind` — one wrapper struct per kind, decoded with XBody.fromCell(msg.body).

struct (0x444e0111) NewProposal {
    queryId: uint64
    expiry: uint32
    kind: uint8
    body: cell
}

// A ConsulOrder child -> Registry, once its own weighted quorum executes (kind 1..7 only;
// kind 0 messages Treasury directly, docs/spec/consul-order.md "ApproveOrder").
struct (0x444e0112) CouncilAction {
    queryId: uint64
    orderSeqno: uint32
    kind: uint8
    body: cell
}

struct TreasuryActionsBody {
    actions: Cell<ActionNode>?
}

struct SetParamsBody {
    newParams: Cell<Params>
}

struct RevokeTitleBody {
    targetOwner: address
    reason: cell?
}

struct RemoveOfficerBody {
    seatIndex: uint8
}

struct AppointInterimBody {
    seatIndex: uint8
    interim: address
}

struct ConfirmDukedomBody {
    candidate: address
}

struct RejectDukedomBody {
    candidate: address
}

struct SetPausedBody {
    paused: bool
}

// AwardSeat (kind 8, committee awards for seats 4/5, docs/spec/registry.md "AwardSeat"): rides
// the NewProposal/CouncilAction wire — 0x444e0117 is reserved but deliberately unused.
struct AwardSeatBody {
    seatIndex: uint8
    awardee: address
}

// Task 7 accession machinery (docs/spec/registry.md "Task 7 — offices & accession").

struct (0x444e0113) DesignateHeir {
    queryId: uint64
    heir: address
}

struct (0x444e0114) ClaimSeatHeir {
    queryId: uint64
}

struct (0x444e0115) AbdicateSeat {
    queryId: uint64
    seatIndex: uint8
}

struct (0x444e0116) ClaimSeatVip {
    queryId: uint64
    claimant: address
    signature: bits512
}

// The exact payload signed off-chain and re-derived on-chain for ClaimSeatVip: binding the
// registry address prevents cross-deployment replay, binding claimant makes the signature a
// credential for that wallet (docs/spec/registry.md "ClaimSeatVip").
struct VipClaimPayload {
    registry: address
    claimant: address
}

struct (0x444e0118) RenounceImperium {
    queryId: uint64
}

// Genesis treasury wiring (docs/spec/registry.md "SetTreasury"). Founder wallet -> registry,
// one-shot: the guard is `storage.treasury == ledgers.founder` (the genesis-placeholder
// convention scripts/genesis.tolk now uses instead of the old plain-wallet sink), so once this
// succeeds the same guard can never pass again — no separate lock bit needed.
struct (0x444e0121) SetTreasury {
    queryId: uint64
    treasury: address
}

// A ConsulOrder child -> Registry, sent from ApproveOrder when the matched approval seat is
// seat 1 (docs/spec/registry.md "SeatActive") — the one ConsulOrder change Task 7 makes.
struct (0x444e011c) SeatActive {
    queryId: uint64
    orderSeqno: uint32
    holder: address
}

// Task 8 — auction hook (seat 2, docs/spec/registry.md "Task 8 — auction hook").

// Permissionless — anyone -> registry (docs/spec/registry.md "StartAuction"). Covers both the
// genesis auction (seat 2 never claimed) and a re-auction on vacancy with one message.
struct (0x444e011d) StartAuction {
    queryId: uint64
}

// A SeatAuction child -> registry, once its own round settles (docs/spec/seat-auction.md
// "Settle"). Escrow-until-ack amendment: the winning bid stays held at the auction until this
// handler's AuctionCollect/AuctionRefund reply resolves it — `amount` is carried for
// completeness (a record of what was escrowed) but the auction resolves its own forward from
// its own storage, not from this field.
struct (0x444e0119) AuctionResult {
    queryId: uint64
    auctionSeqno: uint32
    winner: address?
    amount: coins
}

// Task 9 — election hook (seats 3/7, docs/spec/registry.md "Task 9 — election hook").

// Permissionless — anyone -> registry. Covers both seats' unconditional re-contest every cycle
// (no vacancy precondition, unlike StartAuction — docs/spec/election.md "Key decisions" #14).
struct (0x444e0120) StartElection {
    queryId: uint64
}

// An Election child -> registry, seat 3 (Master of Laws), once its own round settles
// (docs/spec/election.md "Finalize").
struct (0x444e011a) ElectionResult {
    queryId: uint64
    electionSeqno: uint32
    winner: address?
}

// An Election child -> registry, seat 7 (Lord Justiciar), once its own round settles
// (docs/spec/election.md "Finalize"). Arrives as an independent message/transaction from
// ElectionResult (docs/spec/election.md "Key decisions" #10).
struct (0x444e011b) DoyenClaim {
    queryId: uint64
    electionSeqno: uint32
    winner: address?
}

type RegistryMessage =
    | BuyCitizenship
    | BuyDukedom
    | DukeRejected
    | PatentFee
    | RepledgeFee
    | DeployGate
    | NewProposal
    | CouncilAction
    | DesignateHeir
    | ClaimSeatHeir
    | AbdicateSeat
    | ClaimSeatVip
    | RenounceImperium
    | SetTreasury
    | SeatActive
    | StartAuction
    | AuctionResult
    | StartElection
    | ElectionResult
    | DoyenClaim
