// Per-job non-custodial escrow with HTLC-style release keyed on the quorum
// result hash (BLOCKCHAIN_ECONOMICS §6.2, §13). The requester locks the max bid
// B at deploy; settlement is gated on presenting the agreed quorum hash and is
// bounded by B with any remainder refunded to the requester; on timeout the full
// escrow refunds. No platform key can ever take custody.
//
// SECURITY HARDENING (see escrow_types.tolk for the full trust model):
//   B1  the arbiter can only pay requester-pre-committed candidates (and never
//       itself) — a single compromised arbiter cannot redirect funds.
//   B2  every pushed payout is BOUNCEABLE; a bounced payout is credited to a
//       pull-ledger (`pending`) keyed by the recipient, never silently lost.
//   B3  winner/fee/participants are paid as fixed bounceable sends, then the
//       requester is refunded with RAWRESERVE + CARRY_ALL_BALANCE so storage-rent
//       erosion can never make the trailing refund underpay.
//   B4  the participants set is bounded so all payouts fit one action phase.

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
    | EscrowClaim

// B2 bounce-safety: a pushed payout (winner / fee / participant / requester
// refund) that the recipient could not accept bounces back here. Credit the
// returned value to the pull-ledger keyed by the recipient (= the bounced-from
// address) so it is never lost; the recipient (or a keeper on their behalf) later
// pulls it with `EscrowClaim`. The amount is the bounced message value.
fun onBouncedMessage(in: InMessageBounced) {
    var body = in.bouncedBody;
    body.skipBouncedPrefix();
    val op = body.loadUint(32);
    if (op == OP_ESCROW_PAYOUT) {
        var storage = lazy EscrowStorage.load();
        val prev = storage.pending.get(in.senderAddress);
        val had: coins = prev.isFound ? prev.loadValue() : 0;
        storage.pending.set(in.senderAddress, had + in.valueCoins);
        storage.save();
    }
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToEscrow.fromSlice(in.body);

    match (msg) {
        EscrowSettle => {
            var storage = lazy EscrowStorage.load();
            assert (in.senderAddress == storage.arbiter) throw ErrCode.NOT_ARBITER;
            assert (!storage.settled) throw ErrCode.ALREADY_SETTLED;

            val terms = storage.terms.load();
            // HTLC lock: funds only unlock for the agreed quorum result hash.
            assert (msg.resultHash == terms.expectedHash) throw ErrCode.HASH_MISMATCH;

            // B1: the candidate set must be EXACTLY what the requester pre-committed
            // to at open. This is what stops a compromised arbiter from naming an
            // arbitrary payee (e.g. itself) — every payee is checked for membership
            // below, and the set itself is requester-authorized.
            assert (candidatesCommitment(msg.candidates) == terms.candidatesHash) throw ErrCode.SETTLE_POLICY_MISMATCH;
            // B1 defense-in-depth: the arbiter can never be the winner.
            assert (msg.winner != storage.arbiter) throw ErrCode.NOT_OWNER_SIG;
            // B1: the winner must be a requester-authorized candidate.
            assert (msg.candidates.exists(msg.winner)) throw ErrCode.SETTLE_POLICY_MISMATCH;

            // Sum participation commissions, bound the count (B4), and verify each
            // participant is also a requester-authorized candidate (B1).
            var participantsTotal: coins = 0;
            var count = 0;
            var entry = msg.participants.findFirst();
            while (entry.isFound) {
                count += 1;
                assert (count <= MAX_SETTLE_PARTICIPANTS) throw ErrCode.TOO_MANY_PARTICIPANTS;
                val who = entry.getKey();
                assert (msg.candidates.exists(who)) throw ErrCode.SETTLE_POLICY_MISMATCH;
                participantsTotal += entry.loadValue();
                entry = msg.participants.iterateNext(entry);
            }

            val total = msg.winnerAmount + msg.platformFee + participantsTotal;
            assert (total <= storage.escrowAmount) throw ErrCode.PAYOUT_EXCEEDS_ESCROW;

            storage.settled = true;
            storage.save();

            // B3: keep a minimal storage buffer so the contract survives (and can
            // still receive bounces), then pay the fixed amounts and finally sweep
            // the TRUE remainder to the requester with CARRY_ALL_BALANCE — so rent
            // erosion can never make the requester's refund silently underpay.
            reserveToncoinsOnBalance(MIN_TONS_FOR_STORAGE, RESERVE_MODE_EXACT_AMOUNT);

            // Winner: base + perf bonus (bounceable; bounce → pull-ledger).
            if (msg.winnerAmount > 0) {
                payout(msg.winner, msg.winnerAmount, msg.queryId);
            }
            // Platform fee (treasury is from terms, never arbiter-chosen).
            if (msg.platformFee > 0) {
                payout(terms.treasury, msg.platformFee, msg.queryId);
            }
            // Fixed participation commission to each agreeing non-winner.
            var p = msg.participants.findFirst();
            while (p.isFound) {
                val who = p.getKey();
                val amt = p.loadValue();
                if (amt > 0) {
                    payout(who, amt, msg.queryId);
                }
                p = msg.participants.iterateNext(p);
            }
            // Refund the unspent escrow slack to the requester (§4.2) via
            // carry-remaining so the requester gets exactly what is left after the
            // fixed payouts + reserved buffer — never a stale computed slack.
            refundRemaining(storage.requester, msg.queryId);
        }

        // Refund-on-timeout: if the job is not settled by the deadline, anyone can
        // trigger a full refund to the requester (funds always go to the requester).
        EscrowRefund => {
            var storage = lazy EscrowStorage.load();
            assert (!storage.settled) throw ErrCode.ALREADY_SETTLED;
            assert (blockchain.now() >= storage.deadline) throw ErrCode.TIMEOUT_NOT_REACHED;

            storage.settled = true;
            storage.save();

            val refundMsg = createMessage({
                bounce: BounceMode.NoBounce,
                dest: storage.requester,
                value: 0,
            });
            refundMsg.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
        }

        // B2 pull path: deliver a queued/bounced payout to the recipient it is
        // keyed under. Anyone may trigger it (keeper-friendly), but the funds can
        // only go to that recipient — so it cannot be used to redirect a payout.
        EscrowClaim => {
            var storage = lazy EscrowStorage.load();
            val found = storage.pending.get(msg.recipient);
            assert (found.isFound) throw ErrCode.PAYOUT_EXCEEDS_ESCROW;
            val amount = found.loadValue();
            assert (amount > 0) throw ErrCode.PAYOUT_EXCEEDS_ESCROW;
            storage.pending.delete(msg.recipient);
            storage.save();
            // Re-deliver bounceable; if it bounces again it is re-credited.
            payout(msg.recipient, amount, msg.queryId);
        }

        EscrowTopUp => {
            // accept additional funding / storage rent
        }

        else => {
            assert (in.body.isEmpty()) throw ErrCode.INVALID_OP;
        }
    }
}

// B2/B3: a single fixed-value payout, BOUNCEABLE with an op-tagged body so a
// failed delivery returns the funds here and `onBouncedMessage` can credit the
// pull-ledger. PAY_FEES_SEPARATELY so the recipient receives EXACTLY `amount`.
// NOT IGNORE_ERRORS: we want a real bounce (recoverable), not a silent drop.
fun payout(to: address, amount: coins, queryId: int) {
    val m = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: to,
        value: amount,
        body: EscrowPayout { queryId: queryId as uint64 },
    });
    m.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

// B3: refund the requester with carry-remaining semantics — sends whatever
// balance is left after the fixed payouts and the reserved storage buffer. Made
// bounceable so a failed refund is credited to the pull-ledger rather than lost.
fun refundRemaining(to: address, queryId: int) {
    val m = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: to,
        value: 0,
        body: EscrowPayout { queryId: queryId as uint64 },
    });
    m.send(SEND_MODE_CARRY_ALL_BALANCE);
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
        paramsVersion: storage.terms.load().paramsVersion,
    };
}

// The GlobalParams version this job was opened under (bound into terms), so
// settlement / dispute resolution references the exact params in force.
get fun get_params_version(): int {
    val storage = lazy EscrowStorage.load();
    return storage.terms.load().paramsVersion;
}

get fun get_requester(): address {
    val storage = lazy EscrowStorage.load();
    return storage.requester;
}

get fun get_expected_hash(): int {
    val storage = lazy EscrowStorage.load();
    return storage.terms.load().expectedHash;
}

// B1: the requester's pre-committed candidate-set commitment (so the off-chain
// coordinator/bridge can confirm the escrow binds the candidate set it expects).
get fun get_candidates_hash(): int {
    val storage = lazy EscrowStorage.load();
    return storage.terms.load().candidatesHash;
}

// B2: the queued/bounced pull-balance for a recipient (0 if none). Lets a
// recipient/keeper see what is claimable via `EscrowClaim`.
get fun get_pending(recipient: address): int {
    val storage = lazy EscrowStorage.load();
    val found = storage.pending.get(recipient);
    if (!found.isFound) {
        return 0;
    }
    return found.loadValue();
}
