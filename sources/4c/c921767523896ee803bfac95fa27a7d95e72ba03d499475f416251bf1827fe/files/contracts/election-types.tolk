// Election storage and message schemas. Spec: docs/spec/election.md.
// One instance per epoch, deployed by the Registry; runs both seat 3's (Master of Laws)
// rank-weighted election and seat 7's (Lord Justiciar) doyen-of-merit challenge.

import "title-item-types"

// Bounded MAX_CANDIDATES entry (docs/spec/election.md "Storage").
struct CandidateInfo {
    weight: coins
    lastVoteAt: uint32
    deposit: coins
}

// Bounded MAX_DOYEN_CLAIMS entry (docs/spec/election.md "Storage").
struct DoyenClaimInfo {
    merit: coins
    claimedAt: uint32
}

// Deployed with just {registry, electionSeqno} (loader pattern, mirroring SeatAuction's own
// registry/auctionSeqno prefix) — the real config arrives as a follow-up ElectionInit message.
struct ElectionStorage {
    registry: address
    electionSeqno: uint32
    treasury: address
    itemCode: cell
    candidateWindowEnd: uint32
    votingEnd: uint32
    executed: bool
    totalCastWeight: coins
    candidateCount: uint8
    doyenClaimCount: uint8
    candidates: map<address, CandidateInfo>
    ballots: map<address, bool>
    doyenClaims: map<address, DoyenClaimInfo>
}

struct ElectionStorageTail {
    treasury: address
    itemCode: cell
    candidateWindowEnd: uint32
    votingEnd: uint32
    executed: bool
    totalCastWeight: coins
    candidateCount: uint8
    doyenClaimCount: uint8
    candidates: map<address, CandidateInfo>
    ballots: map<address, bool>
    doyenClaims: map<address, DoyenClaimInfo>
}

struct ElectionStorageLoader {
    registry: address
    electionSeqno: uint32
    private rest: RemainingBitsAndRefs
}

fun ElectionStorage.startLoading(): ElectionStorageLoader {
    return ElectionStorageLoader.fromCell(contract.getData());
}

fun ElectionStorage.save(self) {
    contract.setData(self.toCell());
}

fun ElectionStorageLoader.isInitialized(self): bool {
    return !self.rest.isEmpty();
}

fun ElectionStorageLoader.endLoading(self): ElectionStorage {
    val tail = ElectionStorageTail.fromSlice(self.rest);
    return {
        registry: self.registry,
        electionSeqno: self.electionSeqno,
        treasury: tail.treasury,
        itemCode: tail.itemCode,
        candidateWindowEnd: tail.candidateWindowEnd,
        votingEnd: tail.votingEnd,
        executed: tail.executed,
        totalCastWeight: tail.totalCastWeight,
        candidateCount: tail.candidateCount,
        doyenClaimCount: tail.doyenClaimCount,
        candidates: tail.candidates,
        ballots: tail.ballots,
        doyenClaims: tail.doyenClaims,
    };
}

// Registry -> this contract, deploy+message (docs/spec/election.md "ElectionInit").
struct (0x444e0701) ElectionInit {
    queryId: uint64
    treasury: address
    itemCode: cell
    candidateWindowEnd: uint32
    votingEnd: uint32
}

// Any wallet -> this contract (docs/spec/election.md "RegisterCandidate"). Permissionless: no
// rank requirement, deposit is the only spam guard.
struct (0x444e0702) RegisterCandidate {
    queryId: uint64
}

// Anyone -> this contract (docs/spec/election.md "Finalize"). Permissionless trigger.
struct (0x444e0703) Finalize {
    queryId: uint64
}

// The 1-bit-tagged union decoded from ChainProof.payload (docs/spec/election.md "Storage").
// Tag 0 (ballot, seat 3): the voter's chosen candidate. Tag 1 (doyen, seat 7): carries nothing
// further — the merit value itself travels as ChainProof's own top-level `merit` field.
struct (0b0) BallotPayload {
    candidate: address
}

struct (0b1) DoyenPayload {}

type ElectionPayload = BallotPayload | DoyenPayload

// ChainProof (0x444e0242, ballot or doyen claim) is imported from title-item-types — the same
// message shape CouncilGate consumes, plus the additive `merit` field (docs/spec/election.md
// "Key decisions" #2).
type ElectionMessage = ElectionInit | RegisterCandidate | ChainProof | Finalize
