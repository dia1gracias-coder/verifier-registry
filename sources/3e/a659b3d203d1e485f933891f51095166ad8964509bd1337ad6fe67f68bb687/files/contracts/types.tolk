tolk 1.4.1

// Storage layout, wire format and error codes for the payout distributor.
// Acton generates both the Tolk wrapper and the TypeScript wrapper from these
// declarations, so this file is the single source of truth — nothing downstream
// is hand-written.

enum Errors {
    NotOwner = 100
    NotGuardian = 101
    NotGasWallet = 102
    Paused = 103
    NoJettonWallet = 104
    BadSignature = 105
    StaleBatchId = 106
    Expired = 107
    BatchTooLarge = 108
    EmptyBatch = 109
    InsufficientGas = 110
    PayoutTooLarge = 111
    ZeroAmount = 112
    BadWorkchain = 113
    CountMismatch = 114
    TotalMismatch = 115
    DailyCap = 116
    InsufficientTon = 117
    InvalidMessage = 0xFFFF
}

const CAP_WINDOW = 86400

/// Left on the balance so the contract can always pay storage and bounce fees.
const MIN_TON_RESERVE = 50000000 // 0.05 TON

// ---- storage ----
// Split across two ref cells because Tolk does not auto-split a struct: four
// addresses is 1068 bits and a cell holds 1023.

/// owner is the cold multisig; guardian is an online key that may pause but
/// never unpause and never move funds.
struct AdminKeys {
    owner: address
    guardian: address
    signerKey: uint256
}

/// gasWallet is the only sender allowed to submit a batch. excessTo receives
/// TEP-74 excesses — pointing it at the gas wallet returns leftover TON to the
/// account that paid it and keeps N receipts off the fund-holding contract.
struct Routing {
    gasWallet: address
    excessTo: address
    jettonWallet: address?
}

/// maxBatch / tonPerPayout / batchOverhead are settable because the real numbers
/// can only come from measuring gas on a live network.
///
/// The daily cap is a tumbling 24h window, not a true sliding one: a sliding
/// window needs a ring buffer of timestamps and its cost grows per batch. The
/// tradeoff is that up to 2x dailyCap can leave across a window boundary.
struct Limits {
    paused: bool
    maxBatch: uint16
    tonPerPayout: coins
    batchOverhead: coins
    maxPerPayout: coins
    dailyCap: coins
    daySpent: coins
    windowStartedAt: uint32
    lastBatchId: uint64
}

struct Storage {
    admin: Cell<AdminKeys>
    routing: Cell<Routing>
    limits: Limits
}

fun Storage.load(): Storage {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self) {
    contract.setData(self.toCell());
}

// ---- batch payload ----

/**
 * One line of a batch. Nodes are chained by ref rather than held in a dict:
 * walking the chain costs one cell load (100 gas) per line and stays flat,
 * whereas dict cost grows with trie depth — and the 1M gas ceiling per
 * transaction is what actually caps batch size.
 *
 * `payoutId` is the DB row id. It travels as the jetton transfer query_id, so
 * both the excesses receipt and any bounce carry it back.
 */
struct PayoutNode {
    payoutId: uint64
    recipient: address
    amount: coins
    next: Cell<PayoutNode>?
}

/**
 * Exactly what the signer key signs. `distributor` binds the signature to one
 * contract instance so a payload cannot be replayed against a second
 * deployment; `batchId` binds it to one slot in the monotonic sequence.
 */
struct SignedBatch {
    distributor: address
    batchId: uint64
    validUntil: uint32
    count: uint16
    totalAmount: coins
    payouts: Cell<PayoutNode>
}

// ---- incoming messages ----

struct (0x2f1a0100) BatchPayout {
    queryId: uint64
    signature: bits512
    batchId: uint64
    validUntil: uint32
    count: uint16
    totalAmount: coins
    payouts: Cell<PayoutNode>
}

struct (0x2f1a0001) SetJettonWallet {
    queryId: uint64
    jettonWallet: address
}

struct (0x2f1a0002) SetSigner {
    queryId: uint64
    signerKey: uint256
}

struct (0x2f1a0003) SetRouting {
    queryId: uint64
    gasWallet: address
    excessTo: address
}

struct (0x2f1a0004) SetGuardian {
    queryId: uint64
    guardian: address
}

struct (0x2f1a0005) SetCaps {
    queryId: uint64
    maxPerPayout: coins
    dailyCap: coins
}

struct (0x2f1a0006) SetGasParams {
    queryId: uint64
    tonPerPayout: coins
    batchOverhead: coins
    maxBatch: uint16
}

struct (0x2f1a0007) SetPaused {
    queryId: uint64
    paused: bool
}

struct (0x2f1a0008) TransferOwner {
    queryId: uint64
    newOwner: address
}

struct (0x2f1a0009) WithdrawJettons {
    queryId: uint64
    to: address
    amount: coins
    tonAmount: coins
}

struct (0x2f1a000a) WithdrawTon {
    queryId: uint64
    to: address
    amount: coins
}

struct (0x2f1a000b) TopUp {
    queryId: uint64
}

// ---- TEP-74 ----

struct (0x0f8a7ea5) JettonTransfer {
    queryId: uint64
    amount: coins
    destination: address
    responseDestination: address
    customPayload: cell?
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x7362d09c) JettonNotify {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0xd53276db) JettonExcesses {
    queryId: uint64
}

type InboundMessage =
    | BatchPayout
    | SetJettonWallet
    | SetSigner
    | SetRouting
    | SetGuardian
    | SetCaps
    | SetGasParams
    | SetPaused
    | TransferOwner
    | WithdrawJettons
    | WithdrawTon
    | TopUp
    | JettonNotify
    | JettonExcesses
