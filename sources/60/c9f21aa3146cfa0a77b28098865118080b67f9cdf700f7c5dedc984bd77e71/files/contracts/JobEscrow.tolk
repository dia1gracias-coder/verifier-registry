// Per-job non-custodial escrow with HTLC-style release keyed on the quorum
// result hash (BLOCKCHAIN_ECONOMICS §6.2, §13). The requester locks the max bid
// B at deploy; settlement is gated on presenting the agreed quorum hash and is
// bounded by B with any remainder refunded to the requester; on timeout the full
// escrow refunds. No platform key can ever take custody.

import "common"
import "escrow_types"

contract JobEscrow {
    storage: EscrowStorage
    incomingMessages: AllowedMessageToEscrow
}

type AllowedMessageToEscrow =
    | EscrowSettle
    | EscrowRefund
    | EscrowTopUp

fun onBouncedMessage(_in: InMessageBounced) {}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToEscrow.fromSlice(in.body);

    match (msg) {
        EscrowSettle => {
            var storage = lazy EscrowStorage.load();
            assert (in.senderAddress == storage.arbiter) throw ERROR_NOT_ARBITER;
            assert (!storage.settled) throw ERROR_ALREADY_SETTLED;

            val terms = storage.terms.load();
            // HTLC lock: funds only unlock for the agreed quorum result hash.
            assert (msg.resultHash == terms.expectedHash) throw ERROR_HASH_MISMATCH;

            // Sum participation commissions.
            var participantsTotal: coins = 0;
            var entry = msg.participants.findFirst();
            while (entry.isFound) {
                participantsTotal += entry.loadValue();
                entry = msg.participants.iterateNext(entry);
            }

            val total = msg.winnerAmount + msg.platformFee + participantsTotal;
            assert (total <= storage.escrowAmount) throw ERROR_PAYOUT_EXCEEDS_ESCROW;

            storage.settled = true;
            storage.save();

            // Winner: base + perf bonus.
            if (msg.winnerAmount > 0) {
                sendValue(msg.winner, msg.winnerAmount);
            }
            // Platform fee.
            if (msg.platformFee > 0) {
                sendValue(terms.treasury, msg.platformFee);
            }
            // Fixed participation commission to each agreeing non-winner.
            var p = msg.participants.findFirst();
            while (p.isFound) {
                val who = p.getKey();
                val amt = p.loadValue();
                if (amt > 0) {
                    sendValue(who, amt);
                }
                p = msg.participants.iterateNext(p);
            }
            // Refund the unspent escrow slack to the requester (§4.2).
            val refund = storage.escrowAmount - total;
            if (refund > 0) {
                sendValue(storage.requester, refund);
            }
        }

        // Refund-on-timeout: if the job is not settled by the deadline, anyone can
        // trigger a full refund to the requester (funds always go to the requester).
        EscrowRefund => {
            var storage = lazy EscrowStorage.load();
            assert (!storage.settled) throw ERROR_ALREADY_SETTLED;
            assert (blockchain.now() >= storage.deadline) throw ERROR_TIMEOUT_NOT_REACHED;

            storage.settled = true;
            storage.save();

            val refundMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: storage.requester,
                value: 0,
            });
            refundMsg.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
        }

        EscrowTopUp => {
            // accept additional funding / storage rent
        }

        else => {
            assert (in.body.isEmpty()) throw ERROR_INVALID_OP;
        }
    }
}

fun sendValue(to: address, amount: coins) {
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

get fun get_escrow_state(): EscrowState {
    val storage = lazy EscrowStorage.load();
    return {
        escrowAmount: storage.escrowAmount,
        deadline: storage.deadline,
        settled: storage.settled,
    };
}

get fun get_requester(): address {
    val storage = lazy EscrowStorage.load();
    return storage.requester;
}

get fun get_expected_hash(): int {
    val storage = lazy EscrowStorage.load();
    return storage.terms.load().expectedHash;
}
