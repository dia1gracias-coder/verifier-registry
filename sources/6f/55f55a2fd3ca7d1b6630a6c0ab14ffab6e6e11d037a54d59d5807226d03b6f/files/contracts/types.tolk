// Storage, messages and error codes for the TimeMark contract.
//
// The contract holds a single owner address (the AntiHater time-marking wallet),
// written once at deploy time and never grown. Marking writes NO state: the
// digest travels in the inbound message body, so the contract's transaction
// history IS the append-only log of every time-marked evidence bundle.

enum Errors {
    NotOwner = 100         // sender is not the time-marking wallet
    InvalidMessage = 0xFFFF // unrecognised opcode on a non-empty body
}

struct Storage {
    owner: address
}

fun Storage.load(): Storage {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self) {
    contract.setData(self.toCell());
}

// Mark — time-mark one forensic bundle digest, sent as a standard TON TEXT
// COMMENT: opcode 0x00000000 followed by UTF-8 text. EVERY TON explorer and
// wallet renders an opcode-0 body as a human-readable "Comment", so a
// non-technical verifier just reads the digest straight off the explorer page
// and matches it to the AntiHater platform — no API, no decoding, no tools.
// The text is "AntiHater forensic time-mark sha256:<64-hex-digest>", where the
// digest is sha256(manifest.json) for the case-file evidence bundle. The contract
// does not parse the text; the value — together with the transaction's block time
// — is recorded permanently in this transaction's inbound message body.
struct (0x00000000) Mark {
    comment: RemainingBitsAndRefs
}

// Rotate the time-marking wallet (e.g. proactive key rotation). Owner-only.
struct (0x2ce05111) ChangeOwner {
    newOwner: address
}

// Withdraw — sweep the contract's whole TON balance to the owner. Owner-only.
// A recovery/retirement valve: normal marks REFUND their forwarded value (see
// TimeMark.tolk), so the contract doesn't accumulate — this exists only to
// reclaim the deploy reserve, any manual top-up, or value stranded by a refund
// edge case (e.g. a mark forwarded too little to cover the refund's own fee).
// Opcode `0x77697468` = ASCII "with".
struct (0x77697468) Withdraw {}
