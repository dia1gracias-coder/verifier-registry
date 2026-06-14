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

fun onBouncedMessage(_in: InMessageBounced) {}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToGlobalParams.fromSlice(in.body);

    match (msg) {
        // Admin-gated, in-place parameter update. Address is unchanged because we
        // setData (mutate) rather than redeploy.
        UpdateParams => {
            var storage = lazy GlobalParamsStorage.load();
            assert (in.senderAddress == storage.admin) throw ERROR_NOT_ADMIN;

            // Bounds-validate on-chain BEFORE persisting (reject bad updates).
            val newParams = msg.params.load();
            validateEcoParams(newParams);

            storage.feeRecipient = msg.feeRecipient;
            storage.params = msg.params;
            storage.save();

            // Emit a "params updated" event for off-chain indexers.
            val ev = createExternalLogMessage({
                dest: ExtOutLogBucket { topic: EVENT_PARAMS_UPDATED },
                body: ParamsUpdated {
                    queryId: msg.queryId,
                    platformFeeBps: newParams.platformFeeBps,
                    minStake: newParams.minStake,
                },
            });
            ev.send(SEND_MODE_REGULAR);
        }

        // Admin rotation (single key -> multisig handoff). Admin-gated.
        UpdateAdmin => {
            var storage = lazy GlobalParamsStorage.load();
            assert (in.senderAddress == storage.admin) throw ERROR_NOT_ADMIN;
            storage.admin = msg.newAdmin;
            storage.save();
        }

        // Governance blocklist update (anti-abuse). Admin-gated, mutates storage
        // in place. Sets the subject blocked (1) or clears it (0).
        SetBlocklisted => {
            var storage = lazy GlobalParamsStorage.load();
            assert (in.senderAddress == storage.admin) throw ERROR_NOT_ADMIN;
            storage.blocklist.set(msg.subject, (msg.blocked ? 1 : 0) as uint1);
            storage.save();
        }

        else => {
            assert (in.body.isEmpty()) throw ERROR_INVALID_OP;
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
    };
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
