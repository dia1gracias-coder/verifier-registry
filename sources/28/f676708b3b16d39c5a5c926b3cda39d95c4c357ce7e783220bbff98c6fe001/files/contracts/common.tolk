// Shared error codes, opcodes and constants for the duckdb-p2p settlement layer.
//
// These contracts implement the *paid* path of the economic layer described in
// `docs/BLOCKCHAIN_ECONOMICS.md`. Free jobs never touch any of this code — the
// requester runs them through the off-chain coordinator with the `NoopSettlement`
// path and there is zero on-chain interaction (see §8.2 "Free vs paid path").
//
// Design constraints honoured here (BLOCKCHAIN_ECONOMICS §1, §8):
//   * sharded per-node state (no global contract): one StakeVault per node,
//     one JobEscrow per job — never a single hot contract.
//   * non-custodial: release is governed entirely by contract code (quorum
//     result-hash, challenge window, unbonding cooldown), never a platform key.
//   * defensive TON style: explicit gas floors, bounce-safe, carry-value.
// ---------------------------------------------------------------------------
// Error codes — a typed `enum` (Tolk production guidance) instead of loose
// `const`s, so every `throw`/`assert` is checked against a single named set and
// a typo can't silently invent a new code. The backing type is `int32` (the TVM
// exit-code width); the numeric values are FROZEN — they are the contract ABI
// that off-chain code and tests assert against — so they are kept verbatim.
// Reference members as `ErrCode.NOT_OWNER`, etc.
// ---------------------------------------------------------------------------

enum ErrCode: int32 {
    // Jetton / receipt wallet
    NOT_OWNER = 132            // sender is not the contract owner
    NOT_FROM_MASTER = 133      // sender is not the jetton master (vault)
    NOT_VALID_WALLET = 134     // sender is not a legitimate sibling receipt wallet
    UNAUTHORIZED_BURN = 135    // burn notification not from the owner's wallet
    BALANCE_NEGATIVE = 136     // resulting balance would be negative
    NOT_ENOUGH_GAS = 137       // attached value too small to cover the operation
    RECEIPT_LOCKED = 138       // stake-receipt jetton is non-transferable (anti-exit)
    INVALID_OP = 0xffff        // unknown opcode

    // Stake vault
    NOT_SLASHER = 200          // sender is not the authorized slasher (dispute contract)
    NOTHING_TO_UNBOND = 201    // unbond requested but no eligible stake
    UNBOND_IN_PROGRESS = 202   // a prior unbond is still cooling down
    COOLDOWN_NOT_ELAPSED = 203 // withdraw before the unbonding cooldown finished
    NO_UNBONDING = 204         // withdraw with nothing in the unbonding bucket
    KEEPER_TOO_EARLY = 205     // keeper withdraw before the owner-grace window
    SLASH_EXCEEDS_STAKE = 206  // slash amount larger than slashable stake
    INVALID_SPLIT = 207        // slash split bps do not sum to 10000
    // Timelocked governance code upgrade (§8.6) — preserves the non-custodial
    // guarantee: an announced code swap can only be APPLIED after a delay >= the
    // unbonding window, so stakers can exit before any new code takes effect.
    NO_PENDING_UPGRADE = 208   // apply/cancel with nothing announced
    UPGRADE_TIMELOCK_ACTIVE = 209 // apply before the timelock delay elapsed
    UPGRADE_CODE_MISMATCH = 210 // applied code != the announced (hash-committed) code

    // Escrow
    ESCROW_NOT_FUNDED = 220    // escrow opened without the requester's max-bid B
    NOT_REQUESTER = 221        // settle/refund by someone other than the requester
    NOT_ARBITER = 222          // settle by someone other than the bound arbiter
    HASH_MISMATCH = 223        // provided result hash != the committed quorum hash
    ALREADY_SETTLED = 224      // escrow already released
    TIMEOUT_NOT_REACHED = 225  // refund-on-timeout before the deadline
    PAYOUT_EXCEEDS_ESCROW = 226 // requested payout exceeds the locked escrow B

    // Record anchor / dispute
    BAD_PREV_ROOT = 240        // submitted root does not chain to the stored prev_root
    EPOCH_REGRESSION = 241     // epoch did not advance monotonically
    INSUFFICIENT_ANCHOR_STAKE = 242 // keeper stake-weight below the acceptance threshold
    BAD_INCLUSION_PROOF = 243  // Merkle inclusion proof does not reproduce the root
    DISPUTE_BOND_TOO_LOW = 244 // challenger bond below the configured minimum
    NO_SUCH_DISPUTE = 245      // verdict for an unknown dispute id
    NOT_VERDICT_AUTHORITY = 246 // verdict from a non-authoritative source
    // --- Appended (security hardening; never renumber the frozen codes above) ---
    DISPUTE_NOT_OPEN = 247     // resolve a dispute that is not in the open (0) state (double-resolve)
    UNKNOWN_EPOCH = 248        // dispute references an epoch that was never anchored
    PROOF_TOO_DEEP = 249       // Merkle proof exceeds the max depth bound (gas-griefing guard)
    NOT_ANCHOR_KEEPER = 250    // root submitted by an address that is not the authorized keeper
    ZERO_ROOT = 251            // refuse anchoring an empty / all-zero root
    BOND_FLOOR_TOO_LOW = 252   // configured disputeBondMin is below the on-chain floor (> 0)

    // Global params (platform-wide config)
    NOT_ADMIN = 260            // sender is not the configured admin (or multisig)
    PARAMS_OUT_OF_BOUNDS = 261 // proposed params violate a §12 invariant

    // --- Appended: escrow / vault payout-authorization + bounce hardening ------
    NOT_OWNER_SIG = 280        // settle split not authorized by the fund-owner (requester) commitment
    SETTLE_POLICY_MISMATCH = 281 // settle payload does not match the requester's pre-committed policy hash
    TOO_MANY_PARTICIPANTS = 282  // participants map exceeds the on-chain payout bound (action/gas safety)
    UPGRADE_NOT_AUTHORITY = 283  // upgrade announced/applied by a non-upgrade-authority (separated from slasher)
    BAD_BOUNTY_BPS = 284         // keeperBountyBps out of [0, BPS_DENOM] (config sanity)
}

// ---------------------------------------------------------------------------
// Opcodes — keep TEP-74 standard values verbatim for ecosystem interop.
// ---------------------------------------------------------------------------

// TEP-74 jetton standard
const OP_JETTON_TRANSFER = 0x0f8a7ea5
const OP_JETTON_TRANSFER_INTERNAL = 0x178d4519
const OP_JETTON_NOTIFICATION = 0x7362d09c
const OP_JETTON_EXCESSES = 0xd53276db
const OP_JETTON_BURN = 0x595f07bc
const OP_JETTON_BURN_NOTIFICATION = 0x7bdd97de
const OP_PROVIDE_WALLET_ADDRESS = 0x2c76b973
const OP_TAKE_WALLET_ADDRESS = 0xd1735400

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const MIN_TONS_FOR_STORAGE = ton("0.05")
const BPS_DENOM = 10000 // basis-points denominator for splits/fractions

// Status bit flags for the stake-receipt wallet.
const RECEIPT_STATUS_LOCKED = 1 // bit 0: outgoing transfers locked (default)

// Max Merkle inclusion-proof depth the on-chain verifier will walk before
// aborting (A4: an attacker-supplied proof chain is otherwise unbounded → gas
// griefing). 32 levels = up to 2^32 leaves per epoch, far beyond any realistic
// epoch batch, so this never rejects an honest proof.
const MAX_MERKLE_PROOF_DEPTH = 32

// On-chain floor for the dispute bond minimum (A5): a config that sets
// disputeBondMin below this is rejected at deploy/validate time so near-zero-bond
// griefing is impossible. 0.01 TON is a token but non-trivial anti-spam cost.
const MIN_DISPUTE_BOND_FLOOR = ton("0.01")

// Upper bound on the number of agreeing non-winners paid in a single settle
// action phase (B4): bounding the participants map keeps the settle within the
// TVM action/gas limit so a payout can never be partial. 32 covers the realistic
// committee size (N_max=10) with wide headroom.
const MAX_SETTLE_PARTICIPANTS = 32
