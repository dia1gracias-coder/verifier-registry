// Platform-wide economic parameters contract (BLOCKCHAIN_ECONOMICS §4–§8, §12).
//
// Editable in place, address stable: `update_params` is admin-gated and MUTATES
// STORAGE (no redeploy), so every other contract / off-chain node can hard-pin
// this address. Each update is bounds-validated on-chain (mirroring the §12
// invariants), emits a `ParamsUpdated` log, and rejects unauthorized senders.
// The admin is a single configurable address today, designed to later point at a
// multisig (rotate via `update_admin`).

import "common"
import "global_params_types"

contract GlobalParams {
    storage: GlobalParamsStorage
    incomingMessages: AllowedMessageToGlobalParams
}

type AllowedMessageToGlobalParams =
    | UpdateParams
    | UpdateAdmin
    | SetBlocklisted
    | AnnounceCode
    | UpgradeCode
    | CancelCode

fun onBouncedMessage(_in: InMessageBounced) {}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToGlobalParams.fromSlice(in.body);

    match (msg) {
        // Admin-gated, in-place parameter update. Address is unchanged because we
        // setData (mutate) rather than redeploy.
        UpdateParams => {
            var storage = lazy GlobalParamsStorage.load();
            assert (in.senderAddress == storage.admin) throw ErrCode.NOT_ADMIN;

            // Bounds-validate on-chain BEFORE persisting (reject bad updates).
            val newParams = msg.params.load();
            validateEcoParams(newParams);

            storage.feeRecipient = msg.feeRecipient;
            storage.params = msg.params;
            // Monotonic bump on EVERY successful update so jobs can pin the
            // exact params set in force. The admin never controls this counter.
            storage.paramsVersion += 1;
            storage.save();

            // Emit a "params updated" event for off-chain indexers, carrying the
            // new version so they can track which params set is now live.
            val ev = createExternalLogMessage({
                dest: ExtOutLogBucket { topic: EVENT_PARAMS_UPDATED },
                body: ParamsUpdated {
                    queryId: msg.queryId,
                    version: storage.paramsVersion,
                    platformFeeBps: newParams.platformFeeBps,
                    minStake: newParams.minStake,
                },
            });
            ev.send(SEND_MODE_REGULAR);
        }

        // Admin rotation (single key -> multisig handoff). Admin-gated.
        UpdateAdmin => {
            var storage = lazy GlobalParamsStorage.load();
            assert (in.senderAddress == storage.admin) throw ErrCode.NOT_ADMIN;
            storage.admin = msg.newAdmin;
            storage.save();
        }

        // Governance blocklist update (anti-abuse). Admin-gated, mutates storage
        // in place. Sets the subject blocked (1) or clears it (0).
        SetBlocklisted => {
            var storage = lazy GlobalParamsStorage.load();
            assert (in.senderAddress == storage.admin) throw ErrCode.NOT_ADMIN;
            storage.blocklist.set(msg.subject, (msg.blocked ? 1 : 0) as uint1);
            storage.save();
        }

        // D2 step 1/2 — ANNOUNCE: commit to the successor code's hash + start the
        // timelock clock. Admin-gated. Re-announcing resets the clock.
        AnnounceCode => {
            var storage = lazy GlobalParamsStorage.load();
            assert (in.senderAddress == storage.admin) throw ErrCode.NOT_ADMIN;
            storage.pendingCodeHash = msg.newCodeHash;
            storage.pendingCodeAt = blockchain.now() as uint32;
            storage.save();
        }

        // D2 step 2/2 — APPLY the announced IN-PLACE code upgrade (§12.1). Swaps
        // this contract's CODE via TVM `SETCODE` while the ADDRESS and all STORAGE
        // stay intact (we never redeploy; we never wipe data), so adding a new
        // EcoParams field/getter no longer forces a move to a new address.
        // `SETCODE` is POSTPONED: the new code takes effect only after this
        // transaction terminates successfully. D2 hardening: this is now
        // TIMELOCKED — rejected before `pendingCodeAt + upgradeDelay`, and only the
        // exact announced code (hash-committed) may be applied, so a single key can
        // no longer instantly swap protocol-wide code. The monotonic `codeVersion`
        // is bumped by the contract (never set by the admin).
        UpgradeCode => {
            var storage = lazy GlobalParamsStorage.load();
            assert (in.senderAddress == storage.admin) throw ErrCode.NOT_ADMIN;
            assert (storage.pendingCodeHash != 0) throw ErrCode.NO_PENDING_UPGRADE;
            assert (msg.newCode.hash() == storage.pendingCodeHash) throw ErrCode.UPGRADE_CODE_MISMATCH;
            val readyAt = storage.pendingCodeAt + storage.upgradeDelay;
            assert (blockchain.now() >= readyAt) throw ErrCode.UPGRADE_TIMELOCK_ACTIVE;

            // Queue the code swap (effective after this run) and persist the
            // bumped version + cleared pending state. Storage layout is unchanged
            // here; a future migration would be applied to `storage` BEFORE save()
            // in this same handler (the OLD code controls the layout until the
            // postponed SETCODE lands).
            contract.setCodePostponed(msg.newCode);
            storage.codeVersion += 1;
            storage.pendingCodeHash = 0;
            storage.pendingCodeAt = 0;
            storage.save();

            val ev = createExternalLogMessage({
                dest: ExtOutLogBucket { topic: EVENT_CODE_UPGRADED },
                body: CodeUpgraded {
                    queryId: msg.queryId,
                    codeVersion: storage.codeVersion,
                    codeHash: msg.newCode.hash(),
                },
            });
            ev.send(SEND_MODE_REGULAR);
        }

        // D2 — abort a pending announcement (admin-gated safety valve).
        CancelCode => {
            var storage = lazy GlobalParamsStorage.load();
            assert (in.senderAddress == storage.admin) throw ErrCode.NOT_ADMIN;
            assert (storage.pendingCodeHash != 0) throw ErrCode.NO_PENDING_UPGRADE;
            storage.pendingCodeHash = 0;
            storage.pendingCodeAt = 0;
            storage.save();
        }

        else => {
            assert (in.body.isEmpty()) throw ErrCode.INVALID_OP;
        }
    }
}

// ---------------------------------------------------------------------------
// Getters
// ---------------------------------------------------------------------------

get fun get_params(): GlobalParamsView {
    val storage = lazy GlobalParamsStorage.load();
    return {
        admin: storage.admin,
        feeRecipient: storage.feeRecipient,
        params: storage.params,
        paramsVersion: storage.paramsVersion,
    };
}

// Monotonic params version/seqno — the single authoritative value a job binds
// to so all parties agree which params it ran under. Read cheaply via RPC
// (the off-chain coordinator pins this into each job record / escrow).
get fun get_params_version(): int {
    val storage = lazy GlobalParamsStorage.load();
    return storage.paramsVersion;
}

// Monotonic CODE version/seqno — bumped on every successful in-place
// `upgrade_code` (§12.1). 0 = original deployed code (never upgraded). Distinct
// from `paramsVersion`: this tracks CODE swaps (TVM SETCODE) at a STABLE
// address, that one tracks data/param edits. Off-chain code can read this to
// learn which contract code is live without the address ever changing.
get fun get_code_version(): int {
    val storage = lazy GlobalParamsStorage.load();
    return storage.codeVersion;
}

// D2: the pending timelocked code upgrade (announced hash, when, and the earliest
// applyable ts = announce + upgradeDelay). All 0 when none pending — so the
// ecosystem can observe (and react to) a queued protocol-wide code change.
get fun get_pending_upgrade(): GlobalParamsUpgradeView {
    val storage = lazy GlobalParamsStorage.load();
    val readyAt = storage.pendingCodeAt == 0 ? 0 : storage.pendingCodeAt + storage.upgradeDelay;
    return {
        codeVersion: storage.codeVersion,
        pendingCodeHash: storage.pendingCodeHash,
        pendingAt: storage.pendingCodeAt,
        readyAt: readyAt as uint32,
    };
}

// Scalar policy getters (single-int read path for the off-chain `run_get_int`
// RPC seam): the ecosystem-wide values paid jobs read as authoritative,
// overriding local defaults. Each loads the child `EcoParams` cell.
get fun get_platform_fee_bps(): int {
    return GlobalParamsStorage.load().params.load().platformFeeBps;
}

get fun get_participation_commission_bps(): int {
    return GlobalParamsStorage.load().params.load().participationCommissionBps;
}

get fun get_slash_failed_commitment_bps(): int {
    return GlobalParamsStorage.load().params.load().slashFailedCommitmentBps;
}

get fun get_attempt_deadline_ms(): int {
    return GlobalParamsStorage.load().params.load().attemptDeadlineMs;
}

get fun get_progress_interval_ms(): int {
    return GlobalParamsStorage.load().params.load().progressIntervalMs;
}

get fun get_progress_stall_mult(): int {
    return GlobalParamsStorage.load().params.load().progressStallMult;
}

get fun get_admin(): address {
    val storage = lazy GlobalParamsStorage.load();
    return storage.admin;
}

get fun get_fee_recipient(): address {
    val storage = lazy GlobalParamsStorage.load();
    return storage.feeRecipient;
}

// Whether a subject (256-bit account hash) is on the governance blocklist.
get fun get_blocklisted(subject: int): bool {
    val storage = lazy GlobalParamsStorage.load();
    val found = storage.blocklist.get(subject as uint256);
    if (!found.isFound) {
        return false;
    }
    return found.loadValue() == 1;
}
