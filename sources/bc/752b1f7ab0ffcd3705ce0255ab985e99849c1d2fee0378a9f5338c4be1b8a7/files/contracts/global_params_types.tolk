// Storage, messages and on-chain bounds validation for the platform-wide
// `GlobalParams` contract (BLOCKCHAIN_ECONOMICS §4–§8, §12).
//
// This is the ONE ecosystem-wide contract: it holds the economic parameters
// every other contract / off-chain node reads (fees, surcharge, participation
// commission, slash %s + split, min-stake tiers, stake cap, unbonding /
// challenge windows, default selection N/quorum/checksum, ranking weights, fee
// recipient). It is **editable in place**: an admin-gated `update_params`
// MUTATES STORAGE — there is no redeploy — so the contract **address is stable**
// and other contracts can hard-reference it. The admin is a single configurable
// address today but is designed to later point at a multisig (admin rotation via
// `update_admin`).
//
// Every update is **bounds-validated on-chain**, mirroring the §12 cross-field
// invariants enforced off-chain in `crates/config` (so the chain is the source
// of truth and cannot be driven into an inconsistent state even by the admin).

import "common"

const OP_UPDATE_PARAMS = 0x47504101 // "GPA" 01
const OP_UPDATE_ADMIN = 0x47504102  // "GPA" 02
const OP_SET_BLOCKLISTED = 0x47504103 // "GPA" 03 — governance blocklist (anti-abuse)
const OP_UPGRADE_CODE = 0x47504104  // "GPA" 04 — admin-gated, TIMELOCKED apply (step 2)
const OP_ANNOUNCE_CODE = 0x47504105 // "GPA" 05 — admin-gated upgrade announce (step 1)
const OP_CANCEL_CODE = 0x47504106   // "GPA" 06 — admin-gated upgrade cancel

// Log topic for the emitted "code upgraded" event (external-out message), so
// off-chain indexers can watch in-place code upgrades without parsing internals.
const EVENT_CODE_UPGRADED = 0x6770_7570 + 1 // "gpup"+1

// Log topic for the emitted "params updated" event (external-out message), so
// off-chain indexers can watch parameter changes without parsing internals.
const EVENT_PARAMS_UPDATED = 0x6770_7570 // "gpup"

// Bulk economic parameters, kept in a child cell (bit budget). All fractions are
// basis points (bps, /10000); stakes are coins; windows are seconds; selection
// counts are small ints; ranking weights are bps.
struct EcoParams {
    platformFeeBps: uint16
    surchargeBps: uint16
    participationCommissionBps: uint16   // κ — must be small (<= 1000 bps = 10%)
    slashWrongBps: uint16
    slashCheatBps: uint16
    slashDowntimeBps: uint16
    slashEquivocationBps: uint16
    splitChallengerBps: uint16
    splitRedundancyBps: uint16
    splitBurnBps: uint16
    splitTreasuryBps: uint16
    minStake: coins
    minStakeInternal: coins
    minStakeSensitive: coins
    stakeCap: coins
    unbondingSecs: uint32
    challengeWindowSecs: uint32
    nPublic: uint8
    nDefault: uint8
    nMax: uint8
    quorum: uint8
    checksumMin: uint8
    wQualityBps: uint16
    wStakeBps: uint16
    wPriceBps: uint16
    // --- Resilience / fairness gating (ARCHITECTURE §8/§11) ----------------
    // These are the ecosystem-wide resilience knobs that affect DISPUTE
    // FAIRNESS, so all parties must agree on the values a job ran under (they
    // are additive — appended after the original economic params to keep the
    // cell layout backward-compatible).
    //
    // Fine (bps of bonded stake) for a broken commitment to PAID work: a
    // provider that accepted/bid then failed to deliver a valid result by the
    // deadline while the job was demonstrably feasible (§8.3).
    slashFailedCommitmentBps: uint16
    // Requester per-attempt deadline (ms): an attempt going silent past this is
    // treated as inconclusive (job-fault, NO provider penalty). The boundary
    // between "inconclusive" and "broken commitment" — hence on-chain.
    attemptDeadlineMs: uint32
    // Expected progress/heartbeat interval (ms) the host streams at; with
    // progressStallMult it derives the stall timeout that gates a failed
    // commitment.
    progressIntervalMs: uint32
    // Stall-timeout multiplier: an attempt is declared stalled (re-dispatched)
    // after progressIntervalMs * progressStallMult with no heartbeat.
    progressStallMult: uint8
}

struct GlobalParamsStorage {
    admin: address          // gate for update_params / update_admin (→ multisig later)
    feeRecipient: address   // platform fee destination (configurable, §8.2)
    params: Cell<EcoParams> // the bulk params child cell
    // Governance blocklist (ARCHITECTURE "Abuse resistance"): admin-gated, for
    // egregious PROVABLE cases. Keyed by the subject's 256-bit account hash;
    // value 1 = blocked. Nodes may optionally consult this on-chain list, but
    // each still decides independently (it is an additional source, not a
    // central authority that forces refusal).
    blocklist: map<uint256, uint1>
    // Monotonic parameters version/seqno. Bumped by the contract on EVERY
    // successful `update_params` (the admin never sets it directly), so a job
    // can pin the EXACT params set it ran under for settlement / dispute
    // resolution. Appended last → additive, address-stable layout change.
    paramsVersion: uint32
    // Monotonic CODE version/seqno (separate from `paramsVersion`). Bumped by the
    // contract on EVERY successful in-place `upgrade_code` (admin never sets it
    // directly). This is the in-place upgradeability win (§12.1): the CODE can be
    // replaced via TVM `SETCODE` WITHOUT changing the contract address or losing
    // storage, so adding a field/getter no longer forces a redeploy to a new
    // address. Appended last (additive). 0 = original deployed code (never
    // upgraded). Storage-migration rule: keep storage changes additive and
    // append new fields LAST; new code reads the existing layout (older fields
    // unchanged), and a real layout migration would be staged inside the
    // `upgrade_code` handler (the OLD code can `setData()` the migrated layout in
    // the same tx, because `SETCODE` is postponed to after this run completes).
    codeVersion: uint32
    // D2: TIMELOCKED code-upgrade state. A single-key INSTANT SETCODE is a
    // protocol-wide instant-compromise vector (this contract is hard-pinned by
    // every other contract/node), so code upgrades follow the StakeVault
    // announce → wait(upgradeDelay) → apply discipline with a code-hash
    // commitment. `pendingCodeHash`/`pendingCodeAt` are 0 when nothing is
    // announced; `apply` is rejected before `pendingCodeAt + upgradeDelay` and
    // unless the applied code's hash matches the announced one. Appended last
    // (additive). `upgradeDelay` is configurable (seconds) and validated > 0.
    upgradeDelay: uint32
    pendingCodeHash: uint256
    pendingCodeAt: uint32
}

fun GlobalParamsStorage.load(): GlobalParamsStorage {
    return GlobalParamsStorage.fromCell(contract.getData());
}

fun GlobalParamsStorage.save(self) {
    contract.setData(self.toCell());
}

// Admin-gated parameter update. Mutates storage in place (no redeploy → address
// unchanged). `feeRecipient` and the full `params` cell are replaced atomically.
struct (0x47504101) UpdateParams {
    queryId: uint64
    feeRecipient: address
    params: Cell<EcoParams>
}

// Admin rotation (e.g. hand off to a multisig once one is deployed).
struct (0x47504102) UpdateAdmin {
    queryId: uint64
    newAdmin: address
}

// Admin-gated governance blocklist update (anti-abuse). `subject` is the 256-bit
// account hash of the actor; `blocked = true` adds it, `false` clears it.
struct (0x47504103) SetBlocklisted {
    queryId: uint64
    subject: uint256
    blocked: bool
}

// D2 step 1/2 — ANNOUNCE the successor code (by its cell hash). Admin-gated.
// Records the hash + now; re-announcing overwrites and RESETS the timelock clock.
// Publicly observable via `get_pending_upgrade` so the ecosystem can react.
struct (0x47504105) AnnounceCode {
    queryId: uint64
    newCodeHash: uint256
}

// D2 step 2/2 — APPLY the announced code (§12.1). Replaces this contract's CODE
// via TVM `SETCODE` (postponed) WITHOUT changing the address or touching storage.
// Admin-gated, allowed only after `pendingCodeAt + upgradeDelay`, and only if
// `newCode.hash() == pendingCodeHash` (commit-then-reveal, no bait-and-switch).
// `codeVersion` is bumped by the contract (the admin never sets it directly).
struct (0x47504104) UpgradeCode {
    queryId: uint64
    newCode: cell
}

// D2 — abort a pending code-upgrade announcement (admin-gated safety valve).
struct (0x47504106) CancelCode {
    queryId: uint64
}

// Emitted as an external-out log on every successful in-place code upgrade.
// Carries the new monotonic `codeVersion` + the upgraded code's cell hash so
// off-chain indexers can track which code is now live at this (stable) address.
struct CodeUpgraded {
    queryId: uint64
    codeVersion: uint32
    codeHash: uint256
}

// Emitted as an external-out log on every successful update. Carries the new
// monotonic `version` so off-chain indexers can track which params set is live.
struct ParamsUpdated {
    queryId: uint64
    version: uint32
    platformFeeBps: uint16
    minStake: coins
}

// Getter shape returned by `get_params`.
struct GlobalParamsView {
    admin: address
    feeRecipient: address
    params: Cell<EcoParams>
    paramsVersion: uint32
}

// D2: getter shape for `get_pending_upgrade`. `pendingCodeHash`/`pendingAt` are 0
// when nothing is announced; `readyAt` is the unix ts the announced upgrade
// becomes applyable (`pendingAt + upgradeDelay`, 0 when none).
struct GlobalParamsUpgradeView {
    codeVersion: uint32
    pendingCodeHash: uint256
    pendingAt: uint32
    readyAt: uint32
}

// On-chain bounds validation, mirroring the §12 cross-field invariants enforced
// off-chain by `EconomicsConfig::validate`. Throws ErrCode.PARAMS_OUT_OF_BOUNDS on
// any violation so a bad admin update is rejected and storage stays consistent.
fun validateEcoParams(p: EcoParams) {
    // All bps fractions within [0, 10000].
    assert (p.platformFeeBps <= BPS_DENOM) throw ErrCode.PARAMS_OUT_OF_BOUNDS;
    assert (p.surchargeBps <= BPS_DENOM) throw ErrCode.PARAMS_OUT_OF_BOUNDS;
    assert (p.slashWrongBps <= BPS_DENOM) throw ErrCode.PARAMS_OUT_OF_BOUNDS;
    assert (p.slashCheatBps <= BPS_DENOM) throw ErrCode.PARAMS_OUT_OF_BOUNDS;
    assert (p.slashDowntimeBps <= BPS_DENOM) throw ErrCode.PARAMS_OUT_OF_BOUNDS;
    assert (p.slashEquivocationBps <= BPS_DENOM) throw ErrCode.PARAMS_OUT_OF_BOUNDS;
    assert (p.wQualityBps <= BPS_DENOM) throw ErrCode.PARAMS_OUT_OF_BOUNDS;
    assert (p.wStakeBps <= BPS_DENOM) throw ErrCode.PARAMS_OUT_OF_BOUNDS;
    assert (p.wPriceBps <= BPS_DENOM) throw ErrCode.PARAMS_OUT_OF_BOUNDS;
    // Failed-commitment slash is a stake fraction, so it too is in [0, 10000].
    assert (p.slashFailedCommitmentBps <= BPS_DENOM) throw ErrCode.PARAMS_OUT_OF_BOUNDS;

    // κ (participation commission) must be small: <= 10% (§4.2).
    assert (p.participationCommissionBps <= 1000) throw ErrCode.PARAMS_OUT_OF_BOUNDS;

    // Resilience gating must be coherent: a positive progress interval and a
    // non-zero stall multiplier, else the stall timeout would be ill-defined.
    assert (p.progressIntervalMs >= 1) throw ErrCode.PARAMS_OUT_OF_BOUNDS;
    assert (p.progressStallMult >= 1) throw ErrCode.PARAMS_OUT_OF_BOUNDS;

    // Slash split must sum to exactly 100%.
    val splitSum = p.splitChallengerBps + p.splitRedundancyBps + p.splitBurnBps + p.splitTreasuryBps;
    assert (splitSum == BPS_DENOM) throw ErrCode.PARAMS_OUT_OF_BOUNDS;

    // Per-class min-stake monotonicity + cap >= min.
    assert (p.minStakeSensitive >= p.minStakeInternal) throw ErrCode.PARAMS_OUT_OF_BOUNDS;
    assert (p.minStakeInternal >= p.minStake) throw ErrCode.PARAMS_OUT_OF_BOUNDS;
    assert (p.stakeCap >= p.minStake) throw ErrCode.PARAMS_OUT_OF_BOUNDS;

    // Unbonding must outlast the challenge window (§8.4).
    assert (p.unbondingSecs >= p.challengeWindowSecs) throw ErrCode.PARAMS_OUT_OF_BOUNDS;

    // Selection ordering: n_max >= n_default >= n_public >= checksum_min >= 1, and
    // a sane quorum (1 <= quorum <= n_default).
    assert (p.checksumMin >= 1) throw ErrCode.PARAMS_OUT_OF_BOUNDS;
    assert (p.nPublic >= p.checksumMin) throw ErrCode.PARAMS_OUT_OF_BOUNDS;
    assert (p.nDefault >= p.nPublic) throw ErrCode.PARAMS_OUT_OF_BOUNDS;
    assert (p.nMax >= p.nDefault) throw ErrCode.PARAMS_OUT_OF_BOUNDS;
    assert (p.quorum >= 1 && p.quorum <= p.nDefault) throw ErrCode.PARAMS_OUT_OF_BOUNDS;
}
