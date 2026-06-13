// Storage + messages for the record-anchor / dispute contract.
// See BLOCKCHAIN_ECONOMICS §7 (hybrid records: off-chain receipts batched into a
// per-epoch Merkle tree, only the ROOT anchored on-chain), §7.2 (permissionless
// keepers + stake-weighted acceptance, chained roots via prev_root) and §11
// (optimistic settlement + bonded fraud proofs).
//
// Hash domain note: the off-chain epoch tree is built with BLAKE3 over canonical
// JobRecords (Rust side, p2p-settlement). The ON-CHAIN inclusion verifier below
// uses TON cell-representation hashing (`cell.hash()`), which is what an on-chain
// dispute proof is constructed against. Production aligns the two by also
// publishing a cell-hash root; here the contract treats the anchored root as an
// opaque 256-bit commitment and the verifier is self-consistent on-chain.

import "common"

const OP_ANCHOR_SUBMIT = 0x414e_4301
const OP_ANCHOR_DISPUTE = 0x414e_4302
const OP_ANCHOR_VERDICT = 0x414e_4303

// One sibling on a Merkle inclusion path. `dir = 0`: sibling is the RIGHT node
// (current is the left child); `dir = 1`: sibling is the LEFT node.
struct MerkleStep {
    dir: uint1
    sibling: uint256
    next: Cell<MerkleStep>?
}

struct AnchorConfig {
    minStakeWeight: coins     // stake-weighted threshold a submitted root must clear (§7.2)
    disputeBondMin: coins     // anti-griefing challenger bond (§13)
    verdictAuthority: address // committee/oracle that resolves disputes (§11)
    treasury: address         // forfeited bonds / fees
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
    config: Cell<AnchorConfig>
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
struct (0x414e_4302) AnchorOpenDispute {
    queryId: uint64
    epoch: uint32
    leaf: uint256
    claimedRoot: uint256 // the anchored root the leaf is proven against
    proof: Cell<MerkleStep>?
}

// Verdict from the authoritative committee/oracle.
struct (0x414e_4303) AnchorResolveDispute {
    queryId: uint64
    disputeId: uint32
    upheld: bool
}

struct AnchorState {
    currentEpoch: uint32
    lastRoot: uint256
    nextDisputeId: uint32
}

// ---------------------------------------------------------------------------
// Merkle helpers (TON cell-hash domain; self-consistent on-chain)
// ---------------------------------------------------------------------------

fun hashPair(left: int, right: int): int {
    return beginCell().storeUint(left, 256).storeUint(right, 256).endCell().hash();
}

// Fold a leaf up to the root along the supplied sibling path.
fun computeRootFromProof(leaf: int, proof: Cell<MerkleStep>?): int {
    var acc = leaf;
    var cur = proof;
    while (cur != null) {
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
