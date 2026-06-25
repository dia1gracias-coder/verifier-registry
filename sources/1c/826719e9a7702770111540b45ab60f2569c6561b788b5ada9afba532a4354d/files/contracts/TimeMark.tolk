import "types"

// TimeMark — AntiHater's on-chain time mark for forensic evidence.
//
// Purpose: time-mark the SHA-256 digest of a case-file forensic bundle on TON so
// that the bundle's existence and content are provable as-of a specific block
// time, by anyone, without trusting AntiHater. The TON transaction's block time
// is the time mark.
//
// Design (locked):
//   - One `mark(digest)` operation. The digest is sha256(manifest.json).
//   - NO per-mark state writes. The only stored value is the owner address,
//     fixed at deploy. Each mark lives in its transaction's inbound message
//     body, so the transaction history is the immutable audit log.
//   - Owner-restricted: only the AntiHater time-marking wallet can mark, so every
//     successful mark transaction is — by contract rule, on-chain — AntiHater's.
//
// Verification (third-party, no AntiHater software required):
//   1. Recompute sha256(manifest.json) from the delivered bundle.
//   2. Find the time-mark transaction on a public TON explorer (toncenter / tonviewer).
//   3. Decode its inbound message body: opcode 0x6d61726b + 256-bit digest.
//   4. Confirm the digest matches step 1 and the block time predates the dispute.
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

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessage.fromSlice(in.body);

    match (msg) {
        Mark => {
            // Read-only owner check. No save() — marking never mutates storage.
            // The digest is now permanently recorded in this transaction's body,
            // and the transaction's block time is the time mark.
            val storage = lazy Storage.load();
            assert (in.senderAddress == storage.owner) throw Errors.NotOwner;
        }
        ChangeOwner => {
            var storage = lazy Storage.load();
            assert (in.senderAddress == storage.owner) throw Errors.NotOwner;
            storage.owner = msg.newOwner;
            storage.save();
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
