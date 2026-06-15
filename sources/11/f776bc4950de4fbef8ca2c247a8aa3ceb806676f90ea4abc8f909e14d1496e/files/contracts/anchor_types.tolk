// Storage + messages for the record-anchor / dispute contract.
// See BLOCKCHAIN_ECONOMICS §7 (hybrid records: off-chain receipts batched into a
// per-epoch Merkle tree, only the ROOT anchored on-chain), §7.2 (permissionless
// keepers + stake-weighted acceptance, chained roots via prev_root) and §11
// (optimistic settlement + bonded fraud proofs).
//
// Hash domain note (ALIGNED, end-to-end): the off-chain epoch tree and this
// on-chain verifier use the SAME internal-node hash so a proof built off-chain
// reproduces the anchored root here. A raw leaf is a BLAKE3(canonical JobRecord)
// 256-bit commitment (Rust side, p2p-settlement::types::JobRecord::leaf); before
// it is folded it is DOMAIN-SEPARATED via `hashLeaf` below — the cell
// representation hash of a ref-less cell holding one 256-bit int,
// `sha256(0x00 0x40 ‖ leaf)` (the A7 second-preimage fix, mirrored by the Rust
// `hash_leaf`), so a leaf value can never equal an interior node. Each parent is
// the TON cell
// representation hash of an ordinary ref-less cell holding `left ‖ right` (two
// 256-bit big-endian ints) — `hashPair` below. The Rust side reproduces this as
// `sha256(0x00 0x80 ‖ left ‖ right)` (see crates/settlement/src/merkle.rs); the
// `00 80` prefix is the cell descriptor for 512 byte-aligned data bits. `dir = 0`
// keeps the running accumulator on the LEFT (sibling on the right) and `dir = 1`
// on the right, matching the off-chain `(sibling_is_left, sibling)` proof order.

import "common"

const OP_ANCHOR_SUBMIT = 0x414e_4301
const OP_ANCHOR_DISPUTE = 0x414e_4302
const OP_ANCHOR_VERDICT = 0x414e_4303
const OP_ANCHOR_UPGRADE_CODE = 0x414e_4304 // "ANC" 04 — authority-gated in-place SETCODE upgrade
const OP_ANCHOR_BOND_REFUND = 0x414e_4305  // "ANC" 05 — bounce-safe bond refund (carries disputeId)

// One sibling on a Merkle inclusion path. `dir = 0`: sibling is the RIGHT node
// (current is the left child); `dir = 1`: sibling is the LEFT node.
struct MerkleStep {
    dir: uint1
    sibling: uint256
    next: Cell<MerkleStep>?
}

// Anchor authority addresses, grouped in a child cell so the root config cell
// stays within the 1023-bit budget (four addresses inline would overflow it).
struct AnchorAuthorities {
    treasury: address         // forfeited bonds / fees
    // A3: authorized anchor keeper. Root submission is gated to this address
    // (a configured keeper/authority — meant to be a keeper allowlist front or a
    // governance/oracle contract), NOT permissionless. `stakeWeight` in the
    // submission is still an unverified number, so the RESIDUAL ASSUMPTION is that
    // this keeper is honest about the aggregate stake backing a root; full
    // stake-proof aggregation is out of scope for a single contract. Restricting
    // who may submit removes the "anyone anchors a chosen root" attack.
    keeper: address
    // D2: distinct upgrade authority, separated from the verdictAuthority so a
    // single compromised dispute-resolver key cannot also swap the contract code.
    // Meant to be a multisig/governance contract.
    upgradeAuthority: address
}

struct AnchorConfig {
    minStakeWeight: coins     // stake-weighted threshold a submitted root must clear (§7.2)
    disputeBondMin: coins     // anti-griefing challenger bond (§13)
    verdictAuthority: address // committee/oracle that resolves disputes (§11)
    auth: Cell<AnchorAuthorities> // treasury + keeper + upgrade authority (child cell)
}

// status: 0 = open, 1 = upheld (challenger wins), 2 = rejected (bond forfeited)
struct DisputeInfo {
    challenger: address
    epoch: uint32
    leaf: uint256
    bond: coins
    status: uint2
}

struct AnchorStorage {
    currentEpoch: uint32 // last anchored epoch (0 = none yet)
    lastRoot: uint256    // last anchored root (the prev_root for the next epoch)
    nextDisputeId: uint32
    disputes: map<uint32, DisputeInfo>
    // A2: authoritative per-epoch anchored roots. A dispute's inclusion proof is
    // verified against the STORED root for `msg.epoch` (looked up here), NOT
    // against an attacker-supplied `claimedRoot`. Updated on every accepted
    // `AnchorSubmitRoot`. Unknown epochs are rejected (UNKNOWN_EPOCH), so a
    // dispute can only be opened against a root the contract actually anchored.
    roots: map<uint32, uint256>
    config: Cell<AnchorConfig>
    // Monotonic CODE version/seqno for in-place upgradeability (§12.1). Bumped by
    // the contract on every successful authority-gated `upgrade_code` (TVM
    // SETCODE), which swaps the CODE at a STABLE address without touching storage
    // — so the anchor/dispute logic can evolve (new getter/field, fixed verifier)
    // without forcing a redeploy that would orphan the anchored epoch chain.
    // Appended last (additive); 0 = original deployed code. Storage migrations
    // stay additive (append new fields LAST; older fields read unchanged).
    codeVersion: uint32
}

fun AnchorStorage.load(): AnchorStorage {
    return AnchorStorage.fromCell(contract.getData());
}

fun AnchorStorage.save(self) {
    contract.setData(self.toCell());
}

// Permissionless keeper submits the per-epoch root. `prevRoot` must chain to the
// stored `lastRoot`; `stakeWeight` is the aggregate staked weight backing this
// root (collected off-chain) and must clear the configured threshold.
struct (0x414e_4301) AnchorSubmitRoot {
    queryId: uint64
    epoch: uint32
    root: uint256
    prevRoot: uint256
    stakeWeight: coins
}

// Open a bonded dispute with a Merkle inclusion proof of the contested record.
// A2: `claimedRoot` is REMOVED — the proof is now verified against the root the
// contract has STORED for `epoch` (`storage.roots[epoch]`), so neither the root
// nor "which root" is attacker-controlled. The proof must fold (with the v2
// leaf-domain-separated `computeRootFromProof`) to that stored root.
struct (0x414e_4302) AnchorOpenDispute {
    queryId: uint64
    epoch: uint32
    leaf: uint256
    proof: Cell<MerkleStep>?
}

// Verdict from the authoritative committee/oracle.
struct (0x414e_4303) AnchorResolveDispute {
    queryId: uint64
    disputeId: uint32
    upheld: bool
}

// Outgoing bond-refund payload (A1 bounce-safety). The bond is returned to the
// challenger (upheld) or treasury (rejected) with this op-tagged body so that, if
// the recipient cannot accept it and the message BOUNCES, `onBouncedMessage` can
// recover the `disputeId` (from the first 256 bounced bits) and RE-OPEN the
// dispute (status → 0) — restoring accounting instead of silently losing the bond.
struct (0x414e_4305) AnchorBondRefund {
    disputeId: uint32
}

// Authority-gated IN-PLACE code upgrade (§12.1). Swaps this contract's CODE via
// TVM `SETCODE` (postponed to after this run) at a STABLE address, preserving the
// anchored epoch chain + open disputes. Gated to `config.verdictAuthority` (the
// same committee/oracle that resolves disputes — the anchor's governance
// authority); `newCode` is carried as a ^ref; `codeVersion` is bumped by the
// contract.
struct (0x414e_4304) AnchorUpgradeCode {
    queryId: uint64
    newCode: cell
}

struct AnchorState {
    currentEpoch: uint32
    lastRoot: uint256
    nextDisputeId: uint32
}

// ---------------------------------------------------------------------------
// Merkle helpers (TON cell-hash domain; self-consistent on-chain)
//
// MERKLE v2 (A7) — domain-separated leaf hashing (second-preimage fix). The leaf
// and the internal node now use DIFFERENT cell shapes, so a raw internal-node
// value can no longer be replayed as a leaf:
//   * INTERNAL node (UNCHANGED): hashPair(l, r) = repr-hash of a 0-ref cell with
//     TWO uint256  = sha256(0x00 0x80 ‖ l ‖ r). The `00 80` descriptor is an
//     ordinary ref-less cell with 512 byte-aligned data bits.
//   * LEAF (NEW): hashLeaf(x) = repr-hash of a 0-ref cell with ONE uint256
//     = sha256(0x00 0x40 ‖ x). The `00 40` descriptor is an ordinary ref-less
//     cell with 256 byte-aligned data bits (floor(256/8)=ceil(256/8)=32 → 0x40).
// The off-chain Rust builder (crates/settlement/src/merkle.rs) MUST byte-match
// these two constructions and build leaves as [hashLeaf(v0), hashLeaf(v1), ...],
// pairing with hashPair and PROMOTING a lone odd node UNCHANGED (no
// self-duplication) — so a promoted node contributes no proof step.
// ---------------------------------------------------------------------------

fun hashPair(left: int, right: int): int {
    return beginCell().storeUint(left, 256).storeUint(right, 256).endCell().hash();
}

// NEW (A7): domain-separated leaf hash. A 0-ref cell holding ONE uint256, whose
// representation hash is sha256(0x00 0x40 ‖ x). This is the second-preimage fix:
// the accumulator is seeded with hashLeaf(leaf), so the raw `leaf` integer is
// never itself a valid node value an attacker could substitute for an interior
// hash.
fun hashLeaf(x: int): int {
    return beginCell().storeUint(x, 256).endCell().hash();
}

// Fold a leaf up to the root along the supplied sibling path.
// A7: the accumulator is INITIALIZED to hashLeaf(leaf) (not the raw leaf).
// A4: the path is depth-capped at MAX_MERKLE_PROOF_DEPTH; an over-long
// attacker-supplied chain throws PROOF_TOO_DEEP instead of burning unbounded gas.
fun computeRootFromProof(leaf: int, proof: Cell<MerkleStep>?): int {
    var acc = hashLeaf(leaf);
    var cur = proof;
    var depth = 0;
    while (cur != null) {
        depth += 1;
        assert (depth <= MAX_MERKLE_PROOF_DEPTH) throw ErrCode.PROOF_TOO_DEEP;
        val step = cur.load();
        if (step.dir == 0) {
            acc = hashPair(acc, step.sibling);
        } else {
            acc = hashPair(step.sibling, acc);
        }
        cur = step.next;
    }
    return acc;
}

// A5: on-chain validation of the anchor config at deploy/upgrade time. Rejects a
// dispute bond minimum below the on-chain floor (a 0 / near-0 bond would enable
// griefing) so the bond can never be configured into uselessness.
fun validateAnchorConfig(cfg: AnchorConfig) {
    assert (cfg.disputeBondMin >= MIN_DISPUTE_BOND_FLOOR) throw ErrCode.BOND_FLOOR_TOO_LOW;
}
