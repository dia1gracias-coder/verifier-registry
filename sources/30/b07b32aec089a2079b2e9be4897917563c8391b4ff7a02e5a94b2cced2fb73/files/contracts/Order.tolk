import "types"

// How long a courier has to deliver, counted from the moment they accept.
// Production value for mainnet: 14 days.
const DEADLINE = 14 * 24 * 60 * 60 // 14 days, in seconds

// Lowest value a courier must attach to accept: a flat 0.1 TON service fee
// (from the UI) that stays on the contract and is NEVER refunded.
// Together with the 0.1 TON the sender added
// at create time it makes up the ~0.2 TON the platform keeps on a simple
// completed order. All such fees accumulate on the contract balance and are paid
// out to the owner only when the order reaches a terminal state. This floor also
// rejects grossly under-funded direct callers that bypass the UI.
const MIN_ACCEPT_FEE = ton("0.1")

// Extra service fee the sender pays to CANCEL an order they created while it is
// still Open. It is on top of the 0.1 TON create fee they already paid: the
// create fee stays with the platform and this 0.3 is added, so a cancel earns the
// platform ~0.4 TON in total. The reward is always returned to the sender in full.
const CANCEL_FEE = ton("0.3")

// Extra service fee the courier pays to RELEASE (give up) an order they already
// accepted. It is on top of the 0.1 TON accept fee they already paid (which is
// NOT refunded). Both stay on the contract balance — nothing is sent out on a
// release — so the platform's eventual earnings grow by ~0.3 TON, collected when
// the order finally settles. The reward and the sender's create fee also stay on
// the contract for the next courier (the order reopens, it does not close).
const RELEASE_FEE = ton("0.2")

// Pay the referral chat HALF of the fee pool, if a referral is set. Called on
// every terminal path right after the reward leaves and right before the owner
// sweep (mode 128+32), so the owner naturally receives the other half minus the
// network fees — the platform carries the gas, the chat gets a clean 50%.
// `pool` is computed by the caller (the formula differs per send mode of the
// reward, see each call site). The guard `half > 0` is defensive: the pool is
// always >= ~0.2 (create fee + at least one accept/cancel fee) on every real
// path. NoBounce because the chat's wallet may never have been deployed and the
// order self-destructs in this same transaction, so a bounce could not return.
// Returns the amount actually sent to the chat (0 when no referral is set) so
// the terminal event can record the exact referral payout.
fun sendReferralHalf(referral: address?, pool: coins): coins {
    if (referral != null) {
        val half = pool / 2;
        if (half > 0) {
            val pay = createMessage({
                bounce: BounceMode.NoBounce,
                value: half,
                dest: referral!,
            });
            pay.send(SEND_MODE_PAY_FEES_SEPARATELY);
            return half;
        }
    }
    return 0;
}

// One delivery order: an escrow plus a small state machine.
//   Open --AcceptOrder(courier, +0.1 fee)--> Accepted
//        --ConfirmWithCode(the courier only, +0.05 gas)--> Completed  (reward + courier's change in ONE transfer, ~0.2 buffer -> owner, self-destruct)
//        --ClaimExpired(sender, after deadline)--> Expired  (reward + sender's change in ONE transfer, ~0.2 buffer -> owner, courier gets nothing, self-destruct)
//        --CourierRelease(courier, +0.2 fee, BEFORE deadline only)--> Open  (order reopens; accept fee + release fee accumulate in contract; owner paid at terminal state only; courier gets nothing back. After the deadline this is rejected — the courier has no actions left.)
//   Open --CancelOrder(sender, +0.3 fee)--> Cancelled       (reward -> sender; the create fee is kept and the 0.3 cancel fee is added, so ~0.4 -> owner, self-destruct)
//
// Delivery is confirmed by a CODE, not a button: the sender's app picks a 256-bit
// secret at create time and puts only its hash on-chain (secretHash). The courier
// learns the secret from the sender at hand-off (a QR code) and reveals it with
// ConfirmWithCode; the reward is paid only when hash(secret) == secretHash AND the
// caller is the courier who accepted the order. So the courier is paid ONLY with
// the sender's code, and only the courier can trigger that payment — there is no
// sender "confirm" button
// to stall, and a courier with no code cannot be paid (the order expires to the
// sender). The contract checks an objective math fact (the hash), so neither side's
// word matters and no arbiter is needed.
contract Order {
    author: "SwiftDelivery"
    version: "1.20.0"
    description: "A single delivery order with escrow"
    storage: OrderStorage
    incomingMessages: OrderMessage
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy OrderMessage.fromSlice(in.body);
    var s = lazy OrderStorage.load();

    match (msg) {
        AcceptOrder => {
            assert (s.status == OrderStatus.Open) throw OrderErrors.WrongStatus;
            // The courier attaches a flat 0.1 TON service fee (from the UI),
            // which stays on the contract and is NOT refunded — it becomes
            // part of the platform's ~0.2 TON earnings.
            assert (in.valueCoins >= MIN_ACCEPT_FEE) throw OrderErrors.FeeTooLow;
            s.courier = in.senderAddress;
            s.status = OrderStatus.Accepted;
            s.acceptedAt = blockchain.now() as uint32; // start the delivery clock
            // courierContact lives in the referenced extra cell: load it, set
            // the courier's contact, and re-pack the ref.
            var extra = s.extra.load();
            extra.courierContact = msg.courierContact;
            s.extra = extra.toCell();
            s.save();
            emitEvent(OrderAccepted { courier: in.senderAddress });
        }
        ConfirmWithCode => {
            assert (s.status == OrderStatus.Accepted) throw OrderErrors.WrongStatus;
            // Only the courier who accepted this order may confirm it. The secret
            // is the delivery proof, but binding the call to s.courier matches the
            // real hand-off (only the courier scans the sender's QR) and closes the
            // gap where ANYONE who learned a leaked secret could force settlement
            // before delivery. status Accepted guarantees courier is set, so `!` is
            // safe. It also means the single payee is the courier, which lets the
            // reward and the courier's gas change merge into ONE transfer below.
            assert (s.courier! == in.senderAddress) throw OrderErrors.NotCourier;
            // Delivery proof: the hash of the revealed secret must match the one
            // fixed at create time. hash(secret) is the representation hash of a
            // cell holding the 256-bit secret, which the frontend reproduces with
            // @ton/core (round-trip covered by a test). The preimage becomes public
            // here, but the order turns terminal in the same transaction, so a
            // replay is impossible.
            val extra = s.extra.load();
            val h = beginCell().storeUint(msg.secret, 256).endCell().hash();
            assert (h == extra.secretHash) throw OrderErrors.BadCode;
            s.status = OrderStatus.Completed;
            s.save();
            // 1. The reward (the sender's escrow) goes to the courier in ONE
            //    message. Because the caller is now guaranteed to BE the courier,
            //    the reward and the courier's gas change go to the same wallet, so
            //    they merge: value = the reward, and mode 64 carries the unused part
            //    of THIS message's value (the ~0.05 gas change) on top. The courier
            //    receives the full reward plus most of their gas back, paying only
            //    the tx fee — the same merge ClaimExpired/CancelOrder use, no
            //    two-messages-to-one-wallet. The ~0.2 buffer stays on the balance.
            val pay = createMessage({
                bounce: BounceMode.NoBounce,
                value: s.reward,
                dest: s.courier!,
            });
            pay.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
            // 2. Referral: half of the fee pool goes to the chat whose link
            //    brought this order. The pool is what remains after the reward
            //    leaves: getOriginalBalance() already includes this message's
            //    value, and mode 64 above carries both the reward and that value
            //    away, so pool = balance - incoming - reward. NoBounce: the ref
            //    wallet may not be deployed, and the contract self-destructs in
            //    this same transaction — a bounce would be lost anyway. Fees come
            //    from the balance (mode 1), i.e. out of the owner's half.
            val referralPayout = sendReferralHalf(extra.referral,
                contract.getOriginalBalance() - in.valueCoins - s.reward);
            // 3. Log the completion (before the sweep below drains the balance
            //    that pays the emit's forward fee).
            emitEvent(OrderCompleted {
                courier: s.courier!,
                reward: s.reward,
                referralPayout,
            });
            // 4. Everything left over (the owner's half of the fee pool, minus
            //    gas) is the platform's earnings; send it to the owner and
            //    self-destruct.
            val fee = createMessage({
                bounce: BounceMode.NoBounce,
                value: 0 as coins,
                dest: extra.owner,
            });
            // SAFETY: terminal state. The reward already left for the courier above;
            // only the fee buffer remains, which is the platform's earnings.
            // Draining it and destroying the contract is the intended end of a
            // completed order.
            fee.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_DESTROY);
        }
        ClaimExpired => {
            // After the deadline the order can be unwound — a TON contract cannot
            // fire on a timer by itself, so the app shows the sender a "Claim"
            // button. Only the SENDER may claim: the reward returns to them and no
            // one else has any reason to trigger this. Restricting it to the sender
            // also means there is a single payee, so the reward and the sender's
            // gas change merge into ONE transfer (no double payment to one wallet).
            assert (s.status == OrderStatus.Accepted) throw OrderErrors.WrongStatus;
            assert (blockchain.now() > s.acceptedAt + DEADLINE) throw OrderErrors.NotExpired;
            assert (s.sender == in.senderAddress) throw OrderErrors.NotSender;
            s.status = OrderStatus.Expired;
            s.save();
            // The courier did not deliver in time, so they get nothing. The reward
            // returns to the sender in ONE message: value = the reward, and mode 64
            // carries the unused part of THIS message's value (the sender's change
            // from the ~0.05 gas they attached) on top. So the sender receives
            // reward + change as a single transfer and pays only the tx fee — the
            // same merge CancelOrder uses, no two-messages-to-one-wallet problem.
            val refund = createMessage({
                bounce: BounceMode.NoBounce,
                value: s.reward,
                dest: s.sender,
            });
            refund.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
            val extra = s.extra.load();
            // Referral: half of the fee pool to the chat. Same formula as
            // ConfirmWithCode — the refund above is mode 64, so it carries the
            // reward plus this message's value away (see the comment there).
            val referralPayout = sendReferralHalf(extra.referral,
                contract.getOriginalBalance() - in.valueCoins - s.reward);
            // Log the expiry (before the sweep below drains the balance that
            // pays the emit's forward fee). status Accepted guaranteed courier
            // was set, so `!` is safe: this names who failed to deliver.
            emitEvent(OrderExpired {
                courier: s.courier!,
                reward: s.reward,
                referralPayout,
            });
            // The rest of the buffer (the owner's half of the accumulated
            // service fees) goes to the platform owner; contract self-destructs.
            val fee = createMessage({
                bounce: BounceMode.NoBounce,
                value: 0 as coins,
                dest: extra.owner,
            });
            // SAFETY: terminal state. The reward already left for the sender and
            // the caller's change was returned above; the rest (the fee buffer)
            // belongs to the platform. Draining it and destroying the contract
            // ends an expired order.
            fee.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_DESTROY);
        }
        CancelOrder => {
            assert (s.status == OrderStatus.Open) throw OrderErrors.WrongStatus;
            assert (s.sender == in.senderAddress) throw OrderErrors.NotSender;
            // Cancelling costs a flat 0.3 TON service fee, on top of the 0.1 TON
            // the sender already paid at create time. Reject a caller who did not
            // attach it so the platform always earns the cancel fee (and a direct
            // caller cannot cancel for free, bypassing the UI).
            assert (in.valueCoins >= CANCEL_FEE) throw OrderErrors.FeeTooLow;
            s.status = OrderStatus.Cancelled;
            s.save();
            // 1. Return the reward to the sender — EXACTLY the reward, with the
            //    forwarding fee taken from the contract balance (PAY_FEES_SEPARATELY).
            //    We do NOT carry the message value back this time: the 0.3 TON the
            //    sender attached is the cancel fee and must stay for the platform,
            //    so it is not refunded as change.
            val refund = createMessage({
                bounce: BounceMode.NoBounce,
                value: s.reward,
                dest: s.sender,
            });
            refund.send(SEND_MODE_PAY_FEES_SEPARATELY);
            val extra = s.extra.load();
            // 2. Referral: half of the fee pool to the chat. Unlike the mode-64
            //    finals, the refund above sends EXACTLY the reward and the
            //    incoming cancel fee stays on the balance (it is part of the
            //    pool), so pool = balance - reward. getOriginalBalance() already
            //    includes this message's value.
            val referralPayout = sendReferralHalf(extra.referral,
                contract.getOriginalBalance() - s.reward);
            // 3. Log the cancellation (before the sweep below drains the
            //    balance that pays the emit's forward fee).
            emitEvent(OrderCancelled {
                reward: s.reward,
                referralPayout,
            });
            // 4. Everything left over goes to the platform owner and the contract
            //    self-destructs. That leftover is the owner's half of the fee
            //    pool: the 0.1 TON create fee the order already held plus the
            //    0.3 TON cancel fee just attached (minus the referral's half
            //    when a chat is set).
            val fee = createMessage({
                bounce: BounceMode.NoBounce,
                value: 0 as coins,
                dest: extra.owner,
            });
            // SAFETY: terminal state. The reward already left above; the rest is the
            // platform's cancellation fee (create fee + cancel fee). Draining it and
            // destroying the contract is the intended cancel path.
            fee.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_DESTROY);
        }
        CourierRelease => {
            // Only the courier who accepted this order may give it up, and only
            // while it is still Accepted (not yet delivered or expired).
            assert (s.status == OrderStatus.Accepted) throw OrderErrors.WrongStatus;
            // status Accepted guarantees courier is set, so `!` is safe here.
            assert (s.courier! == in.senderAddress) throw OrderErrors.NotCourier;
            // A courier may give up ONLY before the deadline. Once the delivery
            // window has passed there is no point reopening an order that is two
            // weeks (or more) stale — a new courier has nothing left to deliver — so after
            // the deadline the courier cannot release, and the order is settled by
            // ClaimExpired (the sender) or ConfirmWithCode (the courier). This guard
            // is the exact mirror of ClaimExpired's `now > acceptedAt + DEADLINE`:
            // up to and including the deadline only release is possible; strictly
            // after it only claim is, so the two can never race.
            assert (blockchain.now() <= s.acceptedAt + DEADLINE) throw OrderErrors.DeadlinePassed;
            // Giving up an accepted order costs a flat 0.2 TON service fee, on
            // top of the 0.1 TON accept fee the courier already paid (which is
            // NOT refunded). Reject a caller who did not attach it.
            assert (in.valueCoins >= RELEASE_FEE) throw OrderErrors.FeeTooLow;
            // The order does NOT close — it reopens so another courier can take
            // it. Reset it to exactly the Open shape it had before this courier
            // accepted: clear the courier, the accept time, and their contact.
            s.status = OrderStatus.Open;
            s.courier = null;
            s.acceptedAt = 0;
            var extra = s.extra.load();
            extra.courierContact = createEmptyCell();
            s.extra = extra.toCell();
            s.save();
            // All service fees accumulate in the contract balance. The 0.1 accept
            // fee already held and the 0.2 release fee just received stay here and
            // are paid to the owner as part of the final mode-128 transfer when the
            // order reaches a terminal state (ConfirmWithCode, CancelOrder, or
            // ClaimExpired). No internal message is sent here — only the event.
            emitEvent(OrderReopened { courier: in.senderAddress });
        }
        else => {
            // Empty body (e.g. the deploy message) is accepted as a no-op.
            assert (in.body.isEmpty()) throw OrderErrors.InvalidMessage;
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {}

get fun orderData(): OrderStorage {
    val s = lazy OrderStorage.load();
    return s;
}

get fun status(): OrderStatus {
    val s = lazy OrderStorage.load();
    return s.status;
}
