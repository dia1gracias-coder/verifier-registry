// TitleItem storage and message schemas. Spec: docs/spec/title-item.md.

// Initialized storage. The first two fields match TitleItemInitData exactly, so the
// uninitialized state (as deployed) is a strict prefix of this layout (NFT-item loader pattern).
struct ItemStorage {
    registry: address
    owner: address
    rank: uint8
    patron: address
    budget: uint8
    revokedAt: uint32
    merit: coins
    chainValidUntil: uint32
    pendingPatent: Cell<PendingPatent>?
    pendingRepledge: Cell<PendingRepledge>? = null
}

// One pending patent per item at a time (docs/spec/title-item.md, Promotion ops).
struct PendingPatent {
    patronItem: address
    patronOwner: address
    targetRank: uint8
    coSponsored: bool
    grantedAt: uint32
}

// Repledge intent (Task 4); a new Repledge overwrites it, no expiry.
struct PendingRepledge {
    newPatronOwner: address
    approved: bool
    requestedAt: uint32
}

struct ItemStorageTail {
    rank: uint8
    patron: address
    budget: uint8
    revokedAt: uint32
    merit: coins
    chainValidUntil: uint32
    pendingPatent: Cell<PendingPatent>?
    pendingRepledge: Cell<PendingRepledge>?
}

struct ItemStorageLoader {
    registry: address
    owner: address
    private rest: RemainingBitsAndRefs
}

fun ItemStorage.startLoading(): ItemStorageLoader {
    return ItemStorageLoader.fromCell(contract.getData());
}

fun ItemStorage.save(self) {
    contract.setData(self.toCell());
}

fun ItemStorageLoader.isInitialized(self): bool {
    return !self.rest.isEmpty();
}

fun ItemStorageLoader.endLoading(self): ItemStorage {
    val tail = ItemStorageTail.fromSlice(self.rest);
    return {
        registry: self.registry,
        owner: self.owner,
        rank: tail.rank,
        patron: tail.patron,
        budget: tail.budget,
        revokedAt: tail.revokedAt,
        merit: tail.merit,
        chainValidUntil: tail.chainValidUntil,
        pendingPatent: tail.pendingPatent,
        pendingRepledge: tail.pendingRepledge,
    };
}

// Custom ops (0x444e = "DN" namespace).

struct (0x444e0210) Initialize {
    queryId: uint64
    rank: uint8
    patron: address
    budget: uint8
    treasury: address
    price: coins
}

struct (0x444e0212) DukeGrant {
    queryId: uint64
    budget: uint8
    treasury: address
    price: coins
}

// Item -> registry: a DukeGrant could not be applied; the duke slot returns to the market.
struct (0x444e0213) DukeRejected {
    queryId: uint64
    owner: address
}

// Revocation & repledge ops (Task 4).

struct (0x444e0230) RevokeVassal {
    queryId: uint64
    vassal: address
    reason: cell?
}

struct (0x444e0231) RevokeByPatron {
    queryId: uint64
    patronOwner: address
    reason: cell?
}

struct (0x444e0233) Repledge {
    queryId: uint64
    newPatron: address
}

struct (0x444e0235) AcceptRepledge {
    queryId: uint64
    vassal: address
}

struct (0x444e0236) RepledgeApproved {
    queryId: uint64
    patronOwner: address
    patronRank: uint8
}

struct (0x444e0239) FinalizeRepledge {
    queryId: uint64
}

struct (0x444e0237) RepledgeFee {
    queryId: uint64
    owner: address
    rank: uint8
}

struct (0x444e0238) RepledgeDone {
    queryId: uint64
    fee: coins
}

// External out-message: revocations carry logged reasons (architecture §5).
struct (0x444e0e02) RevocationEvent {
    vassal: address
    patronItem: address
    ts: uint32
    reason: cell?
}

// Promotion ops (Task 3). Target rank is always patron rank - 1.

struct (0x444e0220) PromoteVassal {
    queryId: uint64
    candidate: address
}

struct (0x444e0221) GrantPatent {
    queryId: uint64
    targetRank: uint8
    patronOwner: address
    grantedAt: uint32
}

struct (0x444e0222) PatentRejected {
    queryId: uint64
    candidateOwner: address
}

struct (0x444e0223) CoSponsor {
    queryId: uint64
    candidate: address
}

struct (0x444e0224) CoSponsorGrant {
    queryId: uint64
    sponsorOwner: address
    sponsorRank: uint8
}

struct (0x444e0225) AcceptPatent {
    queryId: uint64
}

struct (0x444e0226) PatentFee {
    queryId: uint64
    owner: address
    currentRank: uint8
    targetRank: uint8
}

struct (0x444e0227) PatentApproved {
    queryId: uint64
    targetRank: uint8
    newBudget: uint8
    fee: coins
}

struct (0x444e0228) ReclaimPatent {
    queryId: uint64
    candidate: address
}

struct (0x444e0229) PatentReclaim {
    queryId: uint64
    patronOwner: address
}

struct (0x444e022a) PatentReturned {
    queryId: uint64
    candidateOwner: address
}

// Chain-proof walk (Task 5). See docs/spec/title-item.md "Chain-proof walk (Task 5)".

struct (0x444e0240) ChainProve {
    queryId: uint64
    dest: address
    payload: cell
}

struct (0x444e0241) ChainProveHop {
    queryId: uint64
    dest: address
    initiatorOwner: address
    initiatorRank: uint8
    hopCount: uint8
    linkOwner: address
    payload: cell
}

// Finalizing item -> `dest` (any external contract, e.g. a CouncilGate, an Election).
// `merit` is an additive field (Task 9, docs/spec/election.md "Key decisions" #2): the
// finalizing item's own `storage.merit`, cumulative nanoTON paid in — the only way a consumer
// like Election can trust a merit value with no synchronous cross-contract reads (architecture
// §4). Irrelevant to every other consumer (CouncilGate never reads it, exactly as it already
// ignores payload's content).
struct (0x444e0242) ChainProof {
    queryId: uint64
    topOwner: address
    topRank: uint8
    initiatorOwner: address
    initiatorRank: uint8
    payload: cell
    cached: bool
    merit: coins
}

// Top item -> initiator's own item, direct message (not part of the walk fan-out).
struct (0x444e0243) CacheOk {
    queryId: uint64
    topOwner: address
}

// TEP-85 SBT ops (opcodes fixed by the standard).

struct (0x04ded148) ProveOwnership {
    queryId: uint64
    dest: address
    forwardPayload: cell
    withContent: bool
}

struct (0x0524c7ae) OwnershipProof {
    queryId: uint64
    itemId: uint256
    owner: address
    data: cell
    revokedAt: uint64
    content: cell?
}

struct (0xd0c3bfea) RequestOwner {
    queryId: uint64
    dest: address
    forwardPayload: cell
    withContent: bool
}

struct (0x0dd607e3) OwnerInfo {
    queryId: uint64
    itemId: uint256
    initiator: address
    owner: address
    data: cell
    revokedAt: uint64
    content: cell?
}

struct (0x6f89f5e3) Revoke {
    queryId: uint64
}

struct (0x1f04537a) Destroy {
    queryId: uint64
}

struct (0xd53276db) Excesses {
    queryId: uint64
}

// TEP-62 NFT transfer — parsed only to be rejected (soulbound).
struct (0x5fcc3d14) NftTransfer {
    queryId: uint64
    rest: RemainingBitsAndRefs
}

type ItemMessage =
    | Initialize
    | DukeGrant
    | PromoteVassal
    | GrantPatent
    | PatentRejected
    | CoSponsor
    | CoSponsorGrant
    | AcceptPatent
    | PatentApproved
    | ReclaimPatent
    | PatentReclaim
    | PatentReturned
    | RevokeVassal
    | RevokeByPatron
    | Repledge
    | AcceptRepledge
    | RepledgeApproved
    | FinalizeRepledge
    | RepledgeDone
    | ChainProve
    | ChainProveHop
    | CacheOk
    | ProveOwnership
    | RequestOwner
    | Revoke
    | Destroy
    | NftTransfer
