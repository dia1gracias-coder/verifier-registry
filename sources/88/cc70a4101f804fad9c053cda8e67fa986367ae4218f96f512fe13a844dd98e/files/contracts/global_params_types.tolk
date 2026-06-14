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

// Emitted as an external-out log on every successful update.
struct ParamsUpdated {
    queryId: uint64
    platformFeeBps: uint16
    minStake: coins
}

// Getter shape returned by `get_params`.
struct GlobalParamsView {
    admin: address
    feeRecipient: address
    params: Cell<EcoParams>
}

// On-chain bounds validation, mirroring the §12 cross-field invariants enforced
// off-chain by `EconomicsConfig::validate`. Throws ERROR_PARAMS_OUT_OF_BOUNDS on
// any violation so a bad admin update is rejected and storage stays consistent.
fun validateEcoParams(p: EcoParams) {
    // All bps fractions within [0, 10000].
    assert (p.platformFeeBps <= BPS_DENOM) throw ERROR_PARAMS_OUT_OF_BOUNDS;
    assert (p.surchargeBps <= BPS_DENOM) throw ERROR_PARAMS_OUT_OF_BOUNDS;
    assert (p.slashWrongBps <= BPS_DENOM) throw ERROR_PARAMS_OUT_OF_BOUNDS;
    assert (p.slashCheatBps <= BPS_DENOM) throw ERROR_PARAMS_OUT_OF_BOUNDS;
    assert (p.slashDowntimeBps <= BPS_DENOM) throw ERROR_PARAMS_OUT_OF_BOUNDS;
    assert (p.slashEquivocationBps <= BPS_DENOM) throw ERROR_PARAMS_OUT_OF_BOUNDS;
    assert (p.wQualityBps <= BPS_DENOM) throw ERROR_PARAMS_OUT_OF_BOUNDS;
    assert (p.wStakeBps <= BPS_DENOM) throw ERROR_PARAMS_OUT_OF_BOUNDS;
    assert (p.wPriceBps <= BPS_DENOM) throw ERROR_PARAMS_OUT_OF_BOUNDS;

    // κ (participation commission) must be small: <= 10% (§4.2).
    assert (p.participationCommissionBps <= 1000) throw ERROR_PARAMS_OUT_OF_BOUNDS;

    // Slash split must sum to exactly 100%.
    val splitSum = p.splitChallengerBps + p.splitRedundancyBps + p.splitBurnBps + p.splitTreasuryBps;
    assert (splitSum == BPS_DENOM) throw ERROR_PARAMS_OUT_OF_BOUNDS;

    // Per-class min-stake monotonicity + cap >= min.
    assert (p.minStakeSensitive >= p.minStakeInternal) throw ERROR_PARAMS_OUT_OF_BOUNDS;
    assert (p.minStakeInternal >= p.minStake) throw ERROR_PARAMS_OUT_OF_BOUNDS;
    assert (p.stakeCap >= p.minStake) throw ERROR_PARAMS_OUT_OF_BOUNDS;

    // Unbonding must outlast the challenge window (§8.4).
    assert (p.unbondingSecs >= p.challengeWindowSecs) throw ERROR_PARAMS_OUT_OF_BOUNDS;

    // Selection ordering: n_max >= n_default >= n_public >= checksum_min >= 1, and
    // a sane quorum (1 <= quorum <= n_default).
    assert (p.checksumMin >= 1) throw ERROR_PARAMS_OUT_OF_BOUNDS;
    assert (p.nPublic >= p.checksumMin) throw ERROR_PARAMS_OUT_OF_BOUNDS;
    assert (p.nDefault >= p.nPublic) throw ERROR_PARAMS_OUT_OF_BOUNDS;
    assert (p.nMax >= p.nDefault) throw ERROR_PARAMS_OUT_OF_BOUNDS;
    assert (p.quorum >= 1 && p.quorum <= p.nDefault) throw ERROR_PARAMS_OUT_OF_BOUNDS;
}
