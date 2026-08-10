tolk 1.4.1

import "types"

/**
 * TonPassVault — one contract, both directions of USDT.
 *
 * OUT: push payout. The gas wallet submits a signed batch; the vault sends one
 * jetton transfer per recipient, bounded by a per-payout cap and a rolling daily
 * cap. There is no entry point a stranger can use to trigger a payout.
 *
 * IN: voucher payment. A buyer pays face value plus a fee; the fee goes to the
 * revenue wallet and the face value to cold storage, in the same transaction.
 * The vault does not know voucher prices — it splits by `feeBps` and the backend
 * reconciles the amount against the order.
 *
 * Incoming USDT is one or the other, told apart by who sent it: from `owner` it
 * is a top-up of the payout float, from anyone else it is a purchase. That way a
 * buyer is never mistaken for a funder, which is the failure that would cost
 * them money.
 *
 * A jetton payment cannot be refused: by the time transfer_notification arrives
 * the jettons are already in this vault's wallet, and throwing only bounces the
 * notification while the money stays. So every rejection on the IN path means
 * "held here for the owner to sweep", never "reverted".
 */
contract TonPassVault {
    version: "1.0.0"
    description: "Push payout with hard caps, plus a voucher payment splitter"
    storage: Storage
    incomingMessages: InboundMessage
}

/// An empty forward payload is a single `0` bit (the Either selector), not an
/// empty slice.
fun emptyForwardPayload(): slice {
    return beginCell().storeBool(false).endCell().beginParse();
}

fun assertOwner(admin: AdminKeys, sender: address) {
    assert (sender == admin.owner) throw Errors.NotOwner;
}

fun sendJettons(
    jettonWallet: address,
    queryId: int,
    amount: coins,
    to: address,
    value: coins,
    responseTo: address,
    sendMode: int,
) {
    val leg = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        value,
        dest: jettonWallet,
        body: JettonTransfer {
            queryId,
            amount,
            destination: to,
            responseDestination: responseTo,
            customPayload: null,
            forwardTonAmount: 0,
            forwardPayload: emptyForwardPayload(),
        },
    });
    leg.send(sendMode | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
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
            assert (msg.count <= MAX_PAYOUTS_PER_BATCH) throw Errors.BatchTooLarge;

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

                sendJettons(
                    jettonWallet,
                    node.payoutId,
                    node.amount,
                    node.recipient,
                    st.limits.tonPerPayout,
                    routing.excessTo,
                    SEND_MODE_PAY_FEES_SEPARATELY,
                );

                cur = node.next;
            }

            // The chain is what the signer signed; count and total are what the
            // caps were checked against. If they disagree, the caps were checked
            // against the wrong numbers, so reject the whole batch.
            assert (seen == msg.count) throw Errors.CountMismatch;
            assert (total == msg.totalAmount) throw Errors.TotalMismatch;

            // Hand back whatever the batch did not spend. Without this the
            // batchOverhead piles up here forever and the gas wallet looks like
            // it is draining when the TON has only moved.
            //
            // IGNORE_ERRORS is deliberate and applies to THIS message alone. The
            // rule against it protects payouts, where a silently skipped send
            // would commit dedup state without moving money. Here the opposite is
            // true: if the leftover cannot cover its own forward fee, skipping
            // the refund loses nothing — the TON simply stays. Failing the action
            // phase instead would undo payouts that already succeeded.
            val refund = createMessage({
                bounce: BounceMode.NoBounce,
                value: 0,
                dest: routing.gasWallet,
            });
            refund.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS);
        }

        JettonNotify => {
            val st = lazy Storage.load();
            val routing = st.routing.load();

            val jettonWallet = routing.jettonWallet;
            assert (jettonWallet != null) throw Errors.NoJettonWallet;
            // Without this, anyone could forge a notification and move the
            // vault's jettons to the revenue and cold wallets at will.
            assert (in.senderAddress == jettonWallet) throw Errors.NotJettonWallet;

            // From the owner this is a top-up of the payout float: hold it.
            val admin = st.admin.load();
            if (msg.sender == admin.owner) {
                return;
            }

            // Otherwise it is a voucher purchase.
            assert (!st.limits.paused) throw Errors.Paused;
            assert (in.valueCoins >= st.limits.minPaymentGas) throw Errors.PaymentGasTooLow;

            val fee = msg.amount * st.limits.feeBps / (BPS_DENOM + st.limits.feeBps);
            val faceValue = msg.amount - fee;
            assert (faceValue > 0) throw Errors.PaymentTooSmall;

            // The buyer funds their own split: both legs get explicit values that
            // together spend everything except COMPUTE_RESERVE, and unused gas
            // goes home because responseDestination is the buyer.
            //
            // CARRY_ALL_REMAINING is NOT usable for the last leg. It ignores
            // messages already queued in this action phase, so the earlier leg
            // would be paid from the vault's balance while the last one still
            // took the whole inbound value — measured on testnet as 0.069 TON
            // drained per payment.
            val available = in.valueCoins - COMPUTE_RESERVE;
            val feeLegValue = fee > 0 ? available / 2 : 0;
            val routes = st.voucher.load();

            if (fee > 0) {
                sendJettons(
                    jettonWallet,
                    msg.queryId,
                    fee,
                    routes.revenueWallet,
                    feeLegValue,
                    msg.sender,
                    SEND_MODE_REGULAR,
                );
            }
            sendJettons(
                jettonWallet,
                msg.queryId,
                faceValue,
                routes.coldWallet,
                available - feeLegValue,
                msg.sender,
                SEND_MODE_REGULAR,
            );
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

        SetVoucherRoutes => {
            var st = lazy Storage.load();
            assertOwner(st.admin.load(), in.senderAddress);
            st.voucher = VoucherRoutes {
                revenueWallet: msg.revenueWallet,
                coldWallet: msg.coldWallet,
            }.toCell();
            st.save();
        }

        SetVoucherParams => {
            var st = lazy Storage.load();
            assertOwner(st.admin.load(), in.senderAddress);
            // 10000 bps would make the face value zero.
            assert (msg.feeBps < BPS_DENOM) throw Errors.BadFeeBps;
            st.limits.feeBps = msg.feeBps;
            st.limits.minPaymentGas = msg.minPaymentGas;
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
            // Guardian can stop the vault but only the cold owner can restart it.
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

            sendJettons(
                jettonWallet,
                msg.queryId,
                msg.amount,
                msg.to,
                msg.tonAmount,
                routing.excessTo,
                SEND_MODE_PAY_FEES_SEPARATELY,
            );
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

        // Plain TON top-ups and excesses from our own sends; never throw.
        JettonExcesses => {}
        TopUp => {}

        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {
    // A transfer our own jetton wallet refused — hop 1. Batch state already
    // committed, so there is nothing to roll back; the TON comes home and the
    // indexer reconciles from the missing excesses receipt. A hop-2 failure
    // never reaches this handler at all.
}

get fun adminKeys(): AdminKeys {
    return Storage.load().admin.load();
}

get fun routing(): Routing {
    return Storage.load().routing.load();
}

get fun voucherRoutes(): VoucherRoutes {
    return Storage.load().voucher.load();
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

/// What a payment of `amount` would split into. Lets the backend quote a price
/// and check it against the vault without duplicating the rounding rule.
get fun previewSplit(amount: coins): (coins, coins) {
    val limits = Storage.load().limits;
    val fee = amount * limits.feeBps / (BPS_DENOM + limits.feeBps);
    return (fee, amount - fee);
}
