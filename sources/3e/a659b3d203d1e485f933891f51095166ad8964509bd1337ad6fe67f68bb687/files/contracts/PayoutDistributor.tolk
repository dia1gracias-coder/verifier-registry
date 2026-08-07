tolk 1.4.1

import "types"

/**
 * Payout distributor — push-only jetton payout with on-chain hard caps.
 *
 * Holds the jettons. The online gas wallet holds only TON. A batch is accepted
 * only when it arrives from the gas wallet AND carries a valid signature from a
 * separate signer key, so compromising either one alone pays out nothing.
 *
 * There is deliberately no external() receiver: nothing outside can make this
 * contract spend its own gas.
 *
 * Everything that can fail is checked in the compute phase, so a bad batch
 * reverts cleanly and bounces back to the gas wallet. Sends never use
 * SEND_MODE_IGNORE_ERRORS: a silently skipped transfer would leave the dedup
 * state committed with no money moved and no signal that it happened.
 */
contract PayoutDistributor {
    version: "1.0.0"
    description: "Push-only jetton payout with per-payout and rolling daily caps"
    storage: Storage
    incomingMessages: InboundMessage
}

/// An empty forward payload is a single `0` bit (the Either selector), not an
/// empty slice. Built once and reused for every transfer in the batch.
fun emptyForwardPayload(): slice {
    return beginCell().storeBool(false).endCell().beginParse();
}

fun assertOwner(admin: AdminKeys, sender: address) {
    assert (sender == admin.owner) throw Errors.NotOwner;
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy InboundMessage.fromSlice(in.body);

    match (msg) {
        BatchPayout => {
            var st = lazy Storage.load();
            val admin = st.admin.load();
            val routing = st.routing.load();

            assert (in.senderAddress == routing.gasWallet) throw Errors.NotGasWallet;
            assert (!st.limits.paused) throw Errors.Paused;

            val jettonWallet = routing.jettonWallet;
            assert (jettonWallet != null) throw Errors.NoJettonWallet;

            // Replay protection is a strictly increasing batch id, not a dict:
            // it is one comparison instead of a trie write whose cost grows
            // with depth. It also makes retry-after-bounce correct for free —
            // a bounced batch reverted this field, so resubmitting the same
            // batchId works; a batch that already landed cannot be resubmitted.
            assert (msg.batchId > st.limits.lastBatchId) throw Errors.StaleBatchId;
            assert (blockchain.now() < msg.validUntil) throw Errors.Expired;
            assert (msg.count > 0) throw Errors.EmptyBatch;
            assert (msg.count <= st.limits.maxBatch) throw Errors.BatchTooLarge;

            val signed: SignedBatch = {
                distributor: contract.getAddress(),
                batchId: msg.batchId,
                validUntil: msg.validUntil,
                count: msg.count,
                totalAmount: msg.totalAmount,
                payouts: msg.payouts,
            };
            assert (
                isSignatureValid(signed.toCell().hash(), msg.signature as slice, admin.signerKey)
            ) throw Errors.BadSignature;

            // Every send must be funded from the incoming value, otherwise the
            // action phase fails on message k and reverts the whole batch.
            val need = msg.count * st.limits.tonPerPayout + st.limits.batchOverhead;
            assert (in.valueCoins >= need) throw Errors.InsufficientGas;

            if (blockchain.now() >= st.limits.windowStartedAt + CAP_WINDOW) {
                st.limits.windowStartedAt = blockchain.now();
                st.limits.daySpent = 0;
            }
            assert (
                st.limits.daySpent + msg.totalAmount <= st.limits.dailyCap
            ) throw Errors.DailyCap;

            st.limits.daySpent += msg.totalAmount;
            st.limits.lastBatchId = msg.batchId;
            st.save();

            val fwd = emptyForwardPayload();
            var cur: Cell<PayoutNode>? = msg.payouts;
            var seen: int = 0;
            var total: coins = 0;

            while (cur != null) {
                val node = cur.load();

                assert (node.amount > 0) throw Errors.ZeroAmount;
                assert (node.amount <= st.limits.maxPerPayout) throw Errors.PayoutTooLarge;
                assert (node.recipient.getWorkchain() == BASECHAIN) throw Errors.BadWorkchain;

                total += node.amount;
                seen += 1;

                val transfer = createMessage({
                    bounce: BounceMode.Only256BitsOfBody,
                    value: st.limits.tonPerPayout,
                    dest: jettonWallet,
                    body: JettonTransfer {
                        queryId: node.payoutId,
                        amount: node.amount,
                        destination: node.recipient,
                        responseDestination: routing.excessTo,
                        customPayload: null,
                        forwardTonAmount: 0,
                        forwardPayload: fwd,
                    },
                });
                transfer.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);

                cur = node.next;
            }

            // The chain is what the signer signed; count and total are what the
            // caps were checked against. If they disagree, the caps were checked
            // against the wrong numbers, so reject the whole batch.
            assert (seen == msg.count) throw Errors.CountMismatch;
            assert (total == msg.totalAmount) throw Errors.TotalMismatch;
        }

        SetJettonWallet => {
            var st = lazy Storage.load();
            assertOwner(st.admin.load(), in.senderAddress);
            var routing = st.routing.load();
            routing.jettonWallet = msg.jettonWallet;
            st.routing = routing.toCell();
            st.save();
        }

        SetSigner => {
            var st = lazy Storage.load();
            var admin = st.admin.load();
            assertOwner(admin, in.senderAddress);
            admin.signerKey = msg.signerKey;
            st.admin = admin.toCell();
            st.save();
        }

        SetRouting => {
            var st = lazy Storage.load();
            assertOwner(st.admin.load(), in.senderAddress);
            var routing = st.routing.load();
            routing.gasWallet = msg.gasWallet;
            routing.excessTo = msg.excessTo;
            st.routing = routing.toCell();
            st.save();
        }

        SetGuardian => {
            var st = lazy Storage.load();
            var admin = st.admin.load();
            assertOwner(admin, in.senderAddress);
            admin.guardian = msg.guardian;
            st.admin = admin.toCell();
            st.save();
        }

        SetCaps => {
            var st = lazy Storage.load();
            assertOwner(st.admin.load(), in.senderAddress);
            st.limits.maxPerPayout = msg.maxPerPayout;
            st.limits.dailyCap = msg.dailyCap;
            st.save();
        }

        SetGasParams => {
            var st = lazy Storage.load();
            assertOwner(st.admin.load(), in.senderAddress);
            st.limits.tonPerPayout = msg.tonPerPayout;
            st.limits.batchOverhead = msg.batchOverhead;
            st.limits.maxBatch = msg.maxBatch;
            st.save();
        }

        SetPaused => {
            var st = lazy Storage.load();
            val admin = st.admin.load();
            // Guardian can stop payouts but only the cold owner can restart them.
            if (msg.paused) {
                assert (
                    in.senderAddress == admin.owner || in.senderAddress == admin.guardian
                ) throw Errors.NotGuardian;
            } else {
                assertOwner(admin, in.senderAddress);
            }
            st.limits.paused = msg.paused;
            st.save();
        }

        TransferOwner => {
            var st = lazy Storage.load();
            var admin = st.admin.load();
            assertOwner(admin, in.senderAddress);
            admin.owner = msg.newOwner;
            st.admin = admin.toCell();
            st.save();
        }

        WithdrawJettons => {
            val st = lazy Storage.load();
            assertOwner(st.admin.load(), in.senderAddress);
            val routing = st.routing.load();
            val jettonWallet = routing.jettonWallet;
            assert (jettonWallet != null) throw Errors.NoJettonWallet;

            val sweep = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                value: msg.tonAmount,
                dest: jettonWallet,
                body: JettonTransfer {
                    queryId: msg.queryId,
                    amount: msg.amount,
                    destination: msg.to,
                    responseDestination: routing.excessTo,
                    customPayload: null,
                    forwardTonAmount: 0,
                    forwardPayload: emptyForwardPayload(),
                },
            });
            sweep.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
        }

        WithdrawTon => {
            val st = lazy Storage.load();
            assertOwner(st.admin.load(), in.senderAddress);
            assert (
                contract.getOriginalBalance() - msg.amount >= MIN_TON_RESERVE
            ) throw Errors.InsufficientTon;

            val payout = createMessage({
                bounce: BounceMode.NoBounce,
                value: msg.amount,
                dest: msg.to,
            });
            payout.send(SEND_MODE_PAY_FEES_SEPARATELY);
        }

        // Funding arrives as a jetton transfer_notification and plain TON
        // top-ups arrive with an empty body. Neither may throw: a throw would
        // bounce the funding straight back out.
        JettonNotify => {}
        JettonExcesses => {}
        TopUp => {}

        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {
    // A bounce here is a transfer our own jetton wallet refused — hop 1. The
    // batch already committed, so there is nothing to roll back; the TON comes
    // home and the indexer reconciles from the missing excesses receipt.
    // Note that a hop-2 failure never reaches this handler at all.
}

get fun adminKeys(): AdminKeys {
    return Storage.load().admin.load();
}

get fun routing(): Routing {
    return Storage.load().routing.load();
}

get fun limits(): Limits {
    return Storage.load().limits;
}

/// How much may still leave in the current window, accounting for a window that
/// has already expired but not yet been reset by a batch.
get fun dailyRemaining(): coins {
    val limits = Storage.load().limits;
    if (blockchain.now() >= limits.windowStartedAt + CAP_WINDOW) {
        return limits.dailyCap;
    }
    return limits.dailyCap - limits.daySpent;
}
