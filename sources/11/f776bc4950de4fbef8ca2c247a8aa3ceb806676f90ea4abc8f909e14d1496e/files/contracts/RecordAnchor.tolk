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
    | AnchorUpgradeCode

// A1 bounce-safety: a bond refund that the recipient could not accept bounces
// back here. Recover the `disputeId` (first 32 bits after the 0xFFFFFFFF prefix
// and the op tag) and RE-OPEN the dispute (status → 0) so the authority can
// re-resolve it. The bounced TON returns to this (non-custodial) contract, so the
// bond is never lost and accounting is restored.
fun onBouncedMessage(in: InMessageBounced) {
    var body = in.bouncedBody;
    body.skipBouncedPrefix();          // drop 0xFFFFFFFF
    val op = body.loadUint(32);
    if (op == OP_ANCHOR_BOND_REFUND) {
        val disputeId = body.loadUint(32) as uint32;
        var storage = lazy AnchorStorage.load();
        val found = storage.disputes.get(disputeId);
        if (found.isFound) {
            var dispute = found.loadValue();
            dispute.status = 0;        // re-open: the verdict can be re-applied
            storage.disputes.set(disputeId, dispute);
            storage.save();
        }
    }
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToAnchor.fromSlice(in.body);

    match (msg) {
        AnchorSubmitRoot => {
            var storage = lazy AnchorStorage.load();
            val cfg = storage.config.load();

            // A3: gate submission to the authorized keeper (NOT permissionless).
            // `stakeWeight` is still an unverified number — see AnchorConfig.keeper
            // for the documented residual assumption.
            val auth = cfg.auth.load();
            assert (in.senderAddress == auth.keeper) throw ErrCode.NOT_ANCHOR_KEEPER;
            // A5: enforce the dispute-bond floor at first use (the config is set at
            // deploy and has no on-chain setter, so genesis is the validation point).
            validateAnchorConfig(cfg);
            // A6: refuse an empty / all-zero root. A zero root would otherwise pass
            // the genesis prevRoot==0 chain check and anchor a meaningless epoch.
            assert (msg.root != 0) throw ErrCode.ZERO_ROOT;
            // Epochs advance monotonically; each root chains to the previous one.
            assert (msg.epoch == storage.currentEpoch + 1) throw ErrCode.EPOCH_REGRESSION;
            assert (msg.prevRoot == storage.lastRoot) throw ErrCode.BAD_PREV_ROOT;
            // Stake-weighted acceptance: the aggregate weight backing the root
            // must clear the threshold (anchoring is not a trust bottleneck).
            assert (msg.stakeWeight >= cfg.minStakeWeight) throw ErrCode.INSUFFICIENT_ANCHOR_STAKE;

            storage.currentEpoch = msg.epoch;
            storage.lastRoot = msg.root;
            // A2: record the authoritative per-epoch root for later dispute
            // verification (proofs verify against THIS, not an attacker root).
            storage.roots.set(msg.epoch, msg.root);
            storage.save();
            // (A small keeper reward could be paid here from accumulated fees.)
        }

        AnchorOpenDispute => {
            var storage = lazy AnchorStorage.load();
            val cfg = storage.config.load();
            assert (in.valueCoins >= cfg.disputeBondMin) throw ErrCode.DISPUTE_BOND_TOO_LOW;

            // A2: look up the STORED root for this epoch. An epoch that was never
            // anchored cannot be disputed (rejects forged / unknown-epoch claims).
            val rootFound = storage.roots.get(msg.epoch);
            assert (rootFound.isFound) throw ErrCode.UNKNOWN_EPOCH;
            val anchoredRoot = rootFound.loadValue();

            // The inclusion proof must reproduce the contract's OWN anchored root
            // (A2) using the leaf-domain-separated fold (A7). Both the root and the
            // leaf are thus constrained to real anchored state.
            val recomputed = computeRootFromProof(msg.leaf, msg.proof);
            assert (recomputed == anchoredRoot) throw ErrCode.BAD_INCLUSION_PROOF;

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
            assert (in.senderAddress == cfg.verdictAuthority) throw ErrCode.NOT_VERDICT_AUTHORITY;

            val found = storage.disputes.get(msg.disputeId);
            assert (found.isFound) throw ErrCode.NO_SUCH_DISPUTE;
            var dispute = found.loadValue();
            // A1 [CRITICAL]: refund/payout exactly ONCE. Without this guard,
            // re-sending the same disputeId re-pays the bond and drains other
            // challengers' commingled bonds. Require the open (0) state, and set
            // the terminal status + persist BEFORE sending the bond out.
            assert (dispute.status == 0) throw ErrCode.DISPUTE_NOT_OPEN;

            if (msg.upheld) {
                // Challenge upheld: return the bond to the challenger (the actual
                // stake slash + challenger bounty is applied on the cheater's
                // StakeVault via the slasher path).
                dispute.status = 1;
            } else {
                // Frivolous challenge: forfeit the bond to the treasury.
                dispute.status = 2;
            }
            // Persist the terminal status FIRST (effects before interactions), so a
            // bounce / re-delivery cannot re-enter and double-pay.
            storage.disputes.set(msg.disputeId, dispute);
            storage.save();

            if (msg.upheld) {
                refundBond(dispute.challenger, dispute.bond, msg.disputeId);
            } else {
                refundBond(cfg.auth.load().treasury, dispute.bond, msg.disputeId);
            }
        }

        // Authority-gated IN-PLACE code upgrade (§12.1). Replaces the CODE via
        // TVM `SETCODE` (postponed to after this run) at a STABLE address,
        // preserving the anchored epoch chain + open disputes, so the
        // anchor/dispute logic can evolve without orphaning history at a new
        // address. D2: gated to `upgradeAuthority`, a DISTINCT authority from the
        // dispute `verdictAuthority`, so a compromised dispute-resolver key cannot
        // also swap the contract code (separation of duties; meant to be a
        // multisig). `codeVersion` is bumped by the contract.
        AnchorUpgradeCode => {
            var storage = lazy AnchorStorage.load();
            val cfg = storage.config.load();
            assert (in.senderAddress == cfg.auth.load().upgradeAuthority) throw ErrCode.UPGRADE_NOT_AUTHORITY;
            contract.setCodePostponed(msg.newCode);
            storage.codeVersion += 1;
            storage.save();
        }

        else => {
            assert (in.body.isEmpty()) throw ErrCode.INVALID_OP;
        }
    }
}

// A1 bounce-safety: send the bond BOUNCEABLE with an op-tagged body so a failed
// delivery returns the funds here AND lets `onBouncedMessage` re-open the dispute.
// `Only256BitsOfBody` keeps the bounce cheap while preserving op + disputeId in
// the first 256 bounced bits. NOT IGNORE_ERRORS: we want a genuine bounce on
// failure (so accounting can be restored), not a silent drop.
fun refundBond(to: address, amount: coins, disputeId: int) {
    val m = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: to,
        value: amount,
        body: AnchorBondRefund { disputeId: disputeId as uint32 },
    });
    m.send(SEND_MODE_PAY_FEES_SEPARATELY);
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

// Monotonic CODE version/seqno — bumped on every successful in-place
// `upgrade_code` (§12.1). 0 = original deployed code. The anchor's code can be
// upgraded at a STABLE address (TVM SETCODE), so the anchored epoch chain is
// never orphaned by a logic change.
get fun get_code_version(): int {
    val storage = lazy AnchorStorage.load();
    return storage.codeVersion;
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
