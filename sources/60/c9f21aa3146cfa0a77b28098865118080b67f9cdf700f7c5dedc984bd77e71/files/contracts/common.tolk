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
// Error codes (numeric, cheap to assert against in tests)
// ---------------------------------------------------------------------------

const ERROR_NOT_OWNER = 132 // sender is not the contract owner
const ERROR_NOT_FROM_MASTER = 133 // sender is not the jetton master (vault)
const ERROR_NOT_VALID_WALLET = 134 // sender is not a legitimate sibling receipt wallet
const ERROR_UNAUTHORIZED_BURN = 135 // burn notification not from the owner's wallet
const ERROR_BALANCE_NEGATIVE = 136 // resulting balance would be negative
const ERROR_NOT_ENOUGH_GAS = 137 // attached value too small to cover the operation
const ERROR_RECEIPT_LOCKED = 138 // stake-receipt jetton is non-transferable (anti-exit)
const ERROR_WRONG_WORKCHAIN = 333 // address is not in the basechain
const ERROR_INVALID_OP = 0xffff // unknown opcode

// Stake vault
const ERROR_NOT_SLASHER = 200 // sender is not the authorized slasher (dispute contract)
const ERROR_NOTHING_TO_UNBOND = 201 // unbond requested but no eligible stake
const ERROR_UNBOND_IN_PROGRESS = 202 // a prior unbond is still cooling down
const ERROR_COOLDOWN_NOT_ELAPSED = 203 // withdraw before the unbonding cooldown finished
const ERROR_NO_UNBONDING = 204 // withdraw with nothing in the unbonding bucket
const ERROR_KEEPER_TOO_EARLY = 205 // keeper withdraw before the owner-grace window
const ERROR_SLASH_EXCEEDS_STAKE = 206 // slash amount larger than slashable stake
const ERROR_INVALID_SPLIT = 207 // slash split bps do not sum to 10000

// Escrow
const ERROR_ESCROW_NOT_FUNDED = 220 // escrow opened without the requester's max-bid B
const ERROR_NOT_REQUESTER = 221 // settle/refund by someone other than the requester
const ERROR_NOT_ARBITER = 222 // settle by someone other than the bound arbiter
const ERROR_HASH_MISMATCH = 223 // provided result hash != the committed quorum hash
const ERROR_ALREADY_SETTLED = 224 // escrow already released
const ERROR_TIMEOUT_NOT_REACHED = 225 // refund-on-timeout before the deadline
const ERROR_PAYOUT_EXCEEDS_ESCROW = 226 // requested payout exceeds the locked escrow B

// Record anchor / dispute
const ERROR_BAD_PREV_ROOT = 240 // submitted root does not chain to the stored prev_root
const ERROR_EPOCH_REGRESSION = 241 // epoch did not advance monotonically
const ERROR_INSUFFICIENT_ANCHOR_STAKE = 242 // keeper stake-weight below the acceptance threshold
const ERROR_BAD_INCLUSION_PROOF = 243 // Merkle inclusion proof does not reproduce the root
const ERROR_DISPUTE_BOND_TOO_LOW = 244 // challenger bond below the configured minimum
const ERROR_NO_SUCH_DISPUTE = 245 // verdict for an unknown dispute id
const ERROR_NOT_VERDICT_AUTHORITY = 246 // verdict from a non-authoritative source

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

fun assertBasechain(addr: address) {
    assert (addr.getWorkchain() == BASECHAIN) throw ERROR_WRONG_WORKCHAIN;
}
