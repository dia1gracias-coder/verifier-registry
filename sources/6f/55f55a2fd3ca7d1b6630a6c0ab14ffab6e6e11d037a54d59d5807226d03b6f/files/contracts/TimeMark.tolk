import "types"

// TimeMark — AntiHater's on-chain time mark for forensic evidence.
//
// Purpose: time-mark the SHA-256 digest of a case-file forensic bundle on TON so
// that the bundle's existence and content are provable as-of a specific block
// time, by anyone, without trusting AntiHater. The TON transaction's block time
// is the time mark.
//
// Design (locked):
//   - One `mark` operation, sent as a standard TON TEXT COMMENT (opcode
//     0x00000000 + the digest as UTF-8 text) so every explorer/wallet shows the
//     digest as a human-readable "Comment". The digest is sha256(manifest.json).
//   - NO per-mark state writes. The only stored value is the owner address,
//     fixed at deploy. Each mark lives in its transaction's inbound message
//     body, so the transaction history is the immutable audit log.
//   - Owner-restricted: only the AntiHater time-marking wallet can mark, so every
//     successful mark transaction is — by contract rule, on-chain — AntiHater's.
//   - Marking REFUNDS its forwarded value to the owner (send mode 64), so the
//     contract never accumulates TON — the real per-mark cost is just gas
//     (~0.003 TON). `Withdraw` (owner-only, send mode 128) reclaims the deploy
//     reserve or any stray value when retiring the contract.
//
// Verification (third-party, NON-TECHNICAL — no AntiHater software, no tools):
//   1. Read the digest the AntiHater platform shows for the bundle.
//   2. Open the time-mark transaction on any public TON explorer (tonscan / tonviewer).
//   3. Read its "Comment" — it is the digest in plain text — and confirm it matches.
//   4. Confirm the block time predates the dispute and the sender is AntiHater's
//      published wallet. (To re-derive the digest yourself: `sha256sum manifest.json`.)
contract TimeMark {
    author: "AntiHater"
    version: "1.0.0"
    description: "Time-marks SHA-256 forensic-bundle digests on TON; tx history is the audit log"
    storage: Storage
    incomingMessages: AllowedMessage
}

type AllowedMessage =
    | Mark
    | ChangeOwner
    | Withdraw

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessage.fromSlice(in.body);

    match (msg) {
        Mark => {
            // Owner check only — marking never mutates storage. The digest text is
            // now permanently recorded in this transaction's body (the comment);
            // the transaction's block time is the time mark.
            val storage = lazy Storage.load();
            assert (in.senderAddress == storage.owner) throw Errors.NotOwner;
            // Refund the mark's leftover value to the owner so the contract keeps
            // nothing and never accumulates. Mode 64 carries the remaining value of
            // THIS inbound message (after gas); the contract's own balance/reserve
            // is untouched. Best-effort (IGNORE_ERRORS): a refund failure must never
            // undo the time mark, which is the whole point of the transaction.
            createMessage({
                bounce: BounceMode.NoBounce,
                value: ton("0"),
                dest: in.senderAddress,
            }).send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS);
        }
        ChangeOwner => {
            var storage = lazy Storage.load();
            assert (in.senderAddress == storage.owner) throw Errors.NotOwner;
            storage.owner = msg.newOwner;
            storage.save();
        }
        Withdraw => {
            // Owner-only sweep of the entire balance (recovery / retirement). Mode
            // 128 carries all balance; no per-mark state is kept, so a later
            // empty-body top-up revives the contract if it's ever needed again.
            val storage = lazy Storage.load();
            assert (in.senderAddress == storage.owner) throw Errors.NotOwner;
            createMessage({
                bounce: BounceMode.NoBounce,
                value: ton("0"),
                dest: in.senderAddress,
            }).send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
        }
        else => {
            // Allow plain (empty-body) transfers — e.g. topping up the contract
            // for rent — but reject any unrecognised opcode.
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {}

get fun owner(): address {
    val storage = lazy Storage.load();
    return storage.owner;
}
