// Record-anchor + dispute contract (BLOCKCHAIN_ECONOMICS §7, §11).
// Permissionless keepers anchor a per-epoch Merkle root (chained to the previous
// root, gated by a stake-weighted threshold). Anyone can open a bonded dispute
// with a Merkle inclusion proof; an authoritative committee resolves it
// (upheld => challenger bond returned + slashing happens via the StakeVault
// slasher path; rejected => bond forfeited, anti-griefing).
//
// Only PAID jobs are anchored. Free jobs keep their signed receipts purely
// off-chain and are never written here (§8.2).

import "anchor_types"
import "common"

contract RecordAnchor {
    storage: AnchorStorage
    incomingMessages: AllowedMessageToAnchor
}

type AllowedMessageToAnchor =
    | AnchorSubmitRoot
    | AnchorOpenDispute
    | AnchorResolveDispute

fun onBouncedMessage(_in: InMessageBounced) {}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToAnchor.fromSlice(in.body);

    match (msg) {
        AnchorSubmitRoot => {
            var storage = lazy AnchorStorage.load();
            val cfg = storage.config.load();

            // Epochs advance monotonically; each root chains to the previous one.
            assert (msg.epoch == storage.currentEpoch + 1) throw ERROR_EPOCH_REGRESSION;
            assert (msg.prevRoot == storage.lastRoot) throw ERROR_BAD_PREV_ROOT;
            // Stake-weighted acceptance: the aggregate weight backing the root
            // must clear the threshold (anchoring is not a trust bottleneck).
            assert (msg.stakeWeight >= cfg.minStakeWeight) throw ERROR_INSUFFICIENT_ANCHOR_STAKE;

            storage.currentEpoch = msg.epoch;
            storage.lastRoot = msg.root;
            storage.save();
            // (A small keeper reward could be paid here from accumulated fees.)
        }

        AnchorOpenDispute => {
            var storage = lazy AnchorStorage.load();
            val cfg = storage.config.load();
            assert (in.valueCoins >= cfg.disputeBondMin) throw ERROR_DISPUTE_BOND_TOO_LOW;

            // The inclusion proof must reproduce the claimed (anchored) root.
            val recomputed = computeRootFromProof(msg.leaf, msg.proof);
            assert (recomputed == msg.claimedRoot) throw ERROR_BAD_INCLUSION_PROOF;

            val id = storage.nextDisputeId;
            storage.nextDisputeId = id + 1;
            storage
                .disputes
                .set(
                    id,
                    {
                        challenger: in.senderAddress,
                        epoch: msg.epoch,
                        leaf: msg.leaf,
                        bond: in.valueCoins,
                        status: 0,
                    },
                );
            storage.save();
        }

        AnchorResolveDispute => {
            var storage = lazy AnchorStorage.load();
            val cfg = storage.config.load();
            assert (in.senderAddress == cfg.verdictAuthority) throw ERROR_NOT_VERDICT_AUTHORITY;

            val found = storage.disputes.get(msg.disputeId);
            assert (found.isFound) throw ERROR_NO_SUCH_DISPUTE;
            var dispute = found.loadValue();

            if (msg.upheld) {
                // Challenge upheld: return the bond to the challenger (the actual
                // stake slash + challenger bounty is applied on the cheater's
                // StakeVault via the slasher path).
                dispute.status = 1;
                refund(dispute.challenger, dispute.bond);
            } else {
                // Frivolous challenge: forfeit the bond to the treasury.
                dispute.status = 2;
                refund(cfg.treasury, dispute.bond);
            }
            storage.disputes.set(msg.disputeId, dispute);
            storage.save();
        }

        else => {
            assert (in.body.isEmpty()) throw ERROR_INVALID_OP;
        }
    }
}

fun refund(to: address, amount: coins) {
    val m = createMessage({
        bounce: BounceMode.NoBounce,
        dest: to,
        value: amount,
    });
    m.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_IGNORE_ERRORS);
}

// ---------------------------------------------------------------------------
// Getters
// ---------------------------------------------------------------------------

get fun get_anchor_state(): AnchorState {
    val storage = lazy AnchorStorage.load();
    return {
        currentEpoch: storage.currentEpoch,
        lastRoot: storage.lastRoot,
        nextDisputeId: storage.nextDisputeId,
    };
}

get fun get_dispute(disputeId: int): DisputeInfo? {
    val storage = lazy AnchorStorage.load();
    val found = storage.disputes.get(disputeId as uint32);
    if (!found.isFound) {
        return null;
    }
    return found.loadValue();
}

// Pure inclusion verifier (also used by tests): does `leaf` + `proof` reproduce
// `root`?
get fun verify_inclusion(leaf: int, root: int, proof: Cell<MerkleStep>?): bool {
    return computeRootFromProof(leaf, proof) == root;
}

get fun compute_root(leaf: int, proof: Cell<MerkleStep>?): int {
    return computeRootFromProof(leaf, proof);
}
