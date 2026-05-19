// Exit codes thrown by `throw_if`/`throw_unless` in pool contracts.
// Stable codes — clients depend on these for error reporting.

// Generic / dispatch
const ERR_UNKNOWN_OP: int = 0xfffe // 0xffff is reserved for empty top-up
const ERR_EMPTY_MESSAGE_REJECTED: int = 0xffff
const ERR_PAUSED: int = 100
const ERR_NOT_OWNER: int = 101
const ERR_INSUFFICIENT_GAS: int = 102
const ERR_BAD_ADDR_FORMAT: int = 103
const ERR_BOUNCED_UNHANDLED: int = 104
// Admin-recover-stuck would dip into depositor backing funds. Cap is
// `balance - (outstanding_deposits * denomination) - safety_margin`.
const ERR_RECOVER_EXCEEDS_EXCESS: int = 105

// Deposit-side errors
const ERR_WRONG_DENOMINATION: int = 200
const ERR_DUPLICATE_COMMITMENT: int = 201
const ERR_TREE_FULL: int = 202
const ERR_COMMITMENT_OUT_OF_FIELD: int = 203

// Withdraw-side errors
const ERR_UNKNOWN_ROOT: int = 300
const ERR_ALREADY_SPENT: int = 301
const ERR_PROOF_INVALID: int = 302
const ERR_FEE_EXCEEDS_DENOM: int = 303
const ERR_REFUND_NOT_ZERO_NATIVE: int = 304
const ERR_NULLIFIER_OUT_OF_FIELD: int = 305
const ERR_ROOT_OUT_OF_FIELD: int = 306
const ERR_RECIPIENT_FIELD_OUT_OF_RANGE: int = 307
const ERR_RELAYER_FIELD_OUT_OF_RANGE: int = 308
const ERR_FEE_OUT_OF_FIELD: int = 309
const ERR_REFUND_OUT_OF_FIELD: int = 310

// Jetton-pool-specific
const ERR_WRONG_JETTON_WALLET: int = 400
const ERR_WRONG_FORWARD_PAYLOAD: int = 401
const ERR_REFUND_EXCEEDS_BALANCE: int = 402
// The pool's own jetton wallet hasn't been bound yet via
// AdminBindJettonWallet — refuse to accept deposits or withdraws so
// counterfeit-jetton senders can't be confused with the legitimate one.
const ERR_JETTON_WALLET_NOT_BOUND: int = 403
// AdminBindJettonWallet is a one-shot: the pool refuses to rebind once
// poolJettonWallet has been set to a non-sentinel value.
const ERR_JETTON_WALLET_ALREADY_BOUND: int = 404
// Withdraw `refund` exceeds the per-tx cap. Jetton pools allow a small
// TON refund so the recipient can pay gas in their freshly-created
// jetton wallet — capped to keep fee-fingerprint risk bounded.
const ERR_REFUND_EXCEEDS_CAP: int = 405
// Sentinel addresses (workchain=0, hash=0x00…00) are not allowed for
// fields that need to be a callable contract. We accept them ONLY for
// the burn-key OWNER (docs/threat-model.md) and the placeholder
// poolJettonWallet pre-bind. Any other slot rejecting them is here.
const ERR_FORBIDDEN_BURN_ADDRESS: int = 406

// Merkle internal
const ERR_INVALID_LEVEL: int = 500
const ERR_ZEROS_PLACEHOLDER: int = 501 // zeros[] table not regenerated yet
// Genesis state mismatch — the operator initialized `currentRoot` with
// something other than the canonical EMPTY_TREE_ROOT_HEIGHT_20
// (= Poseidon-chain of ZERO_VALUE at height 20). Thrown on the FIRST
// deposit (nextIndex == 0) only; once the first commitment lands,
// currentRoot evolves via the field-range-checked merge proof.
const ERR_BAD_GENESIS_ROOT: int = 502
