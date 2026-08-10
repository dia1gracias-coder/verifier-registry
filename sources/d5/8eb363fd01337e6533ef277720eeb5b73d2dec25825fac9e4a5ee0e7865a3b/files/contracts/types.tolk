tolk 1.4.1

// Storage layout, wire format and error codes for TonPassVault.
// Acton generates both the Tolk wrapper and the TypeScript wrapper from these
// declarations, so this file is the single source of truth — nothing downstream
// is hand-written.

enum Errors {
    // payout
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
    // voucher payment
    NotJettonWallet = 200
    PaymentTooSmall = 201
    BadFeeBps = 202
    PaymentGasTooLow = 203
    InvalidMessage = 0xFFFF
}

const CAP_WINDOW = 86400
const BPS_DENOM = 10000

/// TVM allows 255 out-actions per transaction and every batch spends one of them
/// returning the unused value to the gas wallet, so the payouts themselves can
/// never exceed 254. Enforced independently of `maxBatch` so that setting
/// `maxBatch` to 255 cannot brick every batch.
const MAX_PAYOUTS_PER_BATCH = 254

/// Left on the balance so the contract can always pay storage and bounce fees.
const MIN_TON_RESERVE = 50000000 // 0.05 TON

/// Held back from a buyer's attached TON to cover the compute phase; the rest
/// funds the two outgoing legs of their payment.
const COMPUTE_RESERVE = 10000000 // 0.01 TON

// ---- storage ----
// Split across ref cells because Tolk does not auto-split a struct and a cell
// holds 1023 bits; three addresses already come to 801.

/// owner is the cold multisig. It also doubles as the funding address: USDT
/// arriving from `owner` is treated as topping up the payout float, anything
/// else is a voucher purchase.
struct AdminKeys {
    owner: address
    guardian: address
    signerKey: uint256
}

/// gasWallet is the only sender allowed to submit a batch. excessTo receives
/// TEP-74 excesses from payouts — pointing it at the gas wallet returns leftover
/// TON to the account that paid it and keeps N receipts off this contract.
struct Routing {
    gasWallet: address
    excessTo: address
    jettonWallet: address?
}

/// Where a voucher payment is split to. Both are fixed by the owner and never
/// read from the incoming payload, so a buyer can never redirect their payment.
struct VoucherRoutes {
    revenueWallet: address
    coldWallet: address
}

/// maxBatch / tonPerPayout / batchOverhead are settable because the real numbers
/// can only come from measuring gas on a live network.
///
/// The daily cap is a tumbling 24h window, not a true sliding one: a sliding
/// window needs a ring buffer of timestamps and its cost grows per batch. The
/// tradeoff is that up to 2x dailyCap can leave across a window boundary.
///
/// `paused` stops payouts AND voucher payments. A payment that arrives while
/// paused strands in this contract, because a jetton transfer cannot be refused;
/// `WithdrawJettons` is how it is refunded.
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
    /// Fee quoted ON TOP of the voucher face value: a 100 voucher at 3% is paid
    /// as 103, so the fee is feeBps/(10000+feeBps) of what arrives — NOT
    /// feeBps/10000, which would take 3.09 out of 103 and short the cold wallet.
    feeBps: uint16
    /// Floor on the `forward_ton_amount` a buyer must attach. It funds the
    /// compute phase AND both outgoing legs, so it is around 0.1 TON — too low
    /// and the action phase fails and the payment strands.
    minPaymentGas: coins
}

struct Storage {
    admin: Cell<AdminKeys>
    routing: Cell<Routing>
    voucher: Cell<VoucherRoutes>
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

struct (0x2f1a000c) SetVoucherRoutes {
    queryId: uint64
    revenueWallet: address
    coldWallet: address
}

struct (0x2f1a000d) SetVoucherParams {
    queryId: uint64
    feeBps: uint16
    minPaymentGas: coins
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
    | SetVoucherRoutes
    | SetVoucherParams
    | JettonNotify
    | JettonExcesses
