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

// mark("mark") — time-mark one forensic bundle digest.
// `digest` is sha256(manifest.json) for the case-file evidence bundle (32 bytes / 256 bits).
// Handling it writes no storage; the value — together with the transaction's block
// time — is recorded permanently in this transaction's inbound message body.
struct (0x6d61726b) Mark {
    digest: uint256
}

// Rotate the time-marking wallet (e.g. proactive key rotation). Owner-only.
struct (0x2ce05111) ChangeOwner {
    newOwner: address
}
