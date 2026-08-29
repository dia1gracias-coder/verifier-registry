// SPDX-License-Identifier: MIT
// BURN Jetton wallet (TEP-74). Base transfer/mint/burn only; fees in P5-1-2-1.

const gasForBurn: Int = 6700;
const gasForTransfer: Int = 10500;
const minTonsForStorage: Int = ton("0.01");
/// Default recipient-leg deploy value (IMP-MNAUD-F22: governance-tunable, this const
/// is the default AND the lower cap — lowering below the proven W1 floor is impossible).
const perInternalDeployTon: Int = ton("0.55");
/// Minimum TON attach gate for fee-split path (uniform entry gate, strict `>`).
/// IMP-MNAUD-F17 (W1): pool/treasury legs are warm `message()` sends (~0.11 / ~0.04 TON),
/// so the fanout no longer needs 3×perInternalDeployTon. Sandbox floors (2026-08-22):
/// direct first credit 0.91–0.93 TON; resolve→commit credits ≥ 0.89 (fanout-throw at
/// master ≤ 0.88 — F10 strand band, gate must stay above it with margin). 1.0 keeps
/// ~0.07 TON margin for mainnet forward-fee variance. Recommended attach ~1.2 TON warm.
/// IMP-MNAUD-F22: this const is the DEFAULT of the governance-tunable gate
/// (`SetGasParams`); wallets read the effective gate from their feeConfig snapshot.
const minTonFeePath: Int = ton("1.0");
/// Legacy excluded-path floor (F16 ≈ 0.58). Unused as JettonTransfer entry gate after
/// IMP-MNAUD-F11 (claimed-excluded always resolves → minTonFeePath). Kept for docs/parity.
const minTonExcludedPath: Int = ton("0.58");
/// Forward TON at or above this threshold triggers live excluded resolution on master (staking deposits).
const minForwardForLiveExcludedCheck: Int = ton("1");
/// TON StakingPool attaches on StakeFeeRewardsAccrue (shared with staking-pool.tact).
const gasPoolToMasterAccrual: Int = ton("0.06");
/// Floor for staking-leg JettonNotification forward (notify handler + accrual msg).
const gasPoolForwardMin: Int = ton("0.07");
/// Floor for treasury-leg JettonNotification forward (Treasury.total_received accounting).
/// 1 nano fails on testnet (`cskip_no_gas`: fwd_fee alone exceeds attach).
const gasTreasuryForwardMin: Int = ton("0.01");
/// Headroom on computed pool forward for forward-fee variance.
const gasPoolForwardEpsilon: Int = ton("0.005");
/// Default TON attached to the burn-leg JettonBurnNotification (fee path).
/// IMP-MNAUD-F22: governance-tunable; this const is the default and the lower cap.
const gasBurnNotifyTon: Int = ton("0.06");
/// Default TON attached to each PropagateFeeConfigToOwner push (fee path sends 3,
/// so the legacy fanout pad 0.15 = 3× this value). IMP-MNAUD-F22: governance-tunable;
/// this const is the default and the lower cap.
const gasPropagateTon: Int = ton("0.05");
/// Extra TON per deliver leg on top of forward amount + fwd fee + storage.
const gasDeliverPadTon: Int = ton("0.02");

// --- IMP-MNAUD-F22: const caps for the governance-tunable gas params -----------
// Pattern mirrors MAX_TOTAL_FEE_BPS: hard compile-time bounds that neither the
// Timelock nor a buggy master push can escape (wallets re-validate on receipt).
/// Lower cap for the entry gate: above the worst measured W1 first-credit (0.93 TON,
/// IMP-MNAUD-F17 gate-floor evidence) and well above the resolve→commit strand band
/// (throw ≤ 0.88). Governance can never re-open the F10 band by lowering the gate.
const GAS_MIN_TON_FEE_PATH_FLOOR: Int = ton("0.95");
/// Upper cap for the entry gate: bounds worst-case censorship-by-cost if governance
/// is compromised (a transfer can never be forced to cost more than 5 TON attach).
const GAS_MIN_TON_FEE_PATH_CEIL: Int = ton("5");
/// Upper cap shared by the five deliver/forward tunables (per-leg budget bound).
const GAS_DELIVER_CEIL: Int = ton("1");
/// Conservative forward-fee bound used by the SetGasParams coherence invariant
/// (~25× the sandbox forward fee for these messages; if mainnet fwd fees ever
/// exceed this, governance must raise the gate — which is exactly what F22 enables).
const GAS_INVARIANT_FWD_CEIL: Int = ton("0.01");

const Basechain: Int = 0;
const walletStateInitCells: Int = 30;
const walletStateInitBits: Int = 20000;
/// Max excluded owner addresses on the exclusion list (gas bounded scan on transfer).
const MAX_EXCLUDED_ADDRESSES: Int = 64;
/// MNAUD-9/M-1 (IMP-MNAUD-F06): on-chain cap for the TOTAL transfer fee
/// (burn + staking + treasury), uniform regardless of dynamicBurnEnabled.
/// Matches the TOKENOMICS governance range ceiling of 5%.
const MAX_TOTAL_FEE_BPS: Int = 500;

struct BurnJettonData {
    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell;
    jettonWalletCode: Cell;
}

struct BurnJettonWalletData {
    balance: Int;
    owner: Address;
    minter: Address;
    code: Cell;
}

message(4) JettonUpdateContent {
    queryId: Int as uint64;
    content: Cell;
}

message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0x178d4519) JettonTransferInternal {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    responseDestination: Address?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0x7362d09c) JettonNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}

message(0x595f07bc) JettonBurn {
    queryId: Int as uint64;
    amount: Int as coins;
    responseDestination: Address?;
    customPayload: Cell?;
}

message(0x7bdd97de) JettonBurnNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    responseDestination: Address?;
}

message(0xd53276db) JettonExcesses {
    queryId: Int as uint64;
}

message(0x2c76b973) ProvideWalletAddress {
    queryId: Int as uint64;
    ownerAddress: Address;
    includeAddress: Bool;
}

message(0xd1735400) TakeWalletAddress {
    queryId: Int as uint64;
    walletAddress: Address;
    ownerAddress: Cell?;
}

message(0x642b7d07) Mint {
    queryId: Int as uint64;
    receiver: Address;
    mintMessage: JettonTransferInternal;
}

message(3) ChangeOwner {
    queryId: Int as uint64;
    newOwner: Address;
}

/// Admin updates global fee BPS on master (see burn-jetton-master).
message(0x1a72d4e2) SetFeeParams {
    queryId: Int as uint64;
    burn_rate_bps: Int;
    staking_rate_bps: Int;
    treasury_rate_bps: Int;
}

/// Admin sets staking pool and treasury owner addresses on master (their jetton wallets receive fee shares).
message(0x2b59c1a7) SetFeeDestinations {
    queryId: Int as uint64;
    staking_pool: Address;
    treasury: Address;
}

/// Admin: push cached fee config from master to one holder's jetton wallet.
message(0x3c8f9013) SyncFeeConfigToWallet {
    queryId: Int as uint64;
    owner: Address;
}

/// Jetton wallet asks master to push fee config to a transfer recipient (TEP-74 address unchanged).
message(0x6a3b2c1d) PropagateFeeConfigToOwner {
    queryId: Int as uint64;
    sender_owner: Address;
    recipient_owner: Address;
}

/// Sender wallet defers to master for live excluded-list check when local fee-config snapshot is stale (IMP-STKFEE-02).
message(0x6a3b2c20) ResolveJettonTransfer {
    queryId: Int as uint64;
    sender_owner: Address;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    forwardTonAmount: Int as coins;
    forwardPayload: Cell;
}

/// Master commits transfer execution after authoritative excluded resolution (IMP-STKFEE-02).
message(0x6a3b2c21) CommitJettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    forwardTonAmount: Int as coins;
    forwardPayload: Cell;
    excludedTransfer: Bool;
}

/// Wallet → owner: commit-stage transfer failed (insufficient jetton balance after the
/// resolve hop). A throw here would bounce to master and be silently swallowed, so the
/// owner (StakingPool / Treasury) would never roll back its accounting (IMP-MNAUD-F18).
message(0x6a3b2c22) JettonTransferCommitFailed {
    queryId: Int as uint64;
    amount: Int as coins;
}

/// Master emit: a CommitJettonTransfer bounced back for a non-balance failure
/// (balance failures are reported wallet-side via JettonTransferCommitFailed).
/// The bounce prefix carries no owner address, so off-chain monitoring is the
/// only possible delivery (IMP-MNAUD-F18).
message(0x6a3b2c23) CommitJettonTransferBounced {
    queryId: Int as uint64;
    amount: Int as coins;
}

/// Master-only: update fee parameters and destination owner addresses on a wallet.
/// IMP-MNAUD-F22: carries the governance gas params; the wallet re-validates them
/// against the const caps + coherence invariant before accepting the snapshot.
message(0x4d7e2bc4) JettonUpdateFeeConfig {
    queryId: Int as uint64;
    burn_rate_bps: Int;
    staking_rate_bps: Int;
    treasury_rate_bps: Int;
    staking_pool: Address;
    treasury: Address;
    dynamic_burn_enabled: Bool;
    large_tx_threshold: Int as coins;
    activity_threshold: Int;
    max_burn_rate_bps: Int;
    tx_count_snapshot: Int;
    activity_hour_bucket: Int;
    low_supply_mode: Bool;
    excluded_count: Int;
    excluded_head: Cell;
    gas_min_ton_fee_path: Int as coins;
    gas_per_internal_deploy_ton: Int as coins;
    gas_pool_forward_min: Int as coins;
    gas_treasury_forward_min: Int as coins;
    gas_burn_notify_ton: Int as coins;
    gas_propagate_ton: Int as coins;
}

/// Admin: add holder address to the excluded-from-fees list (TEP owner address, not jetton wallet).
message(0x5a1c8f01) AddExcluded {
    queryId: Int as uint64;
    address: Address;
}

/// Admin: remove holder address from the excluded-from-fees list.
message(0x5a1c8f02) RemoveExcluded {
    queryId: Int as uint64;
    address: Address;
}

/// Admin: toggle dynamic burn bonuses (large tx + activity snapshot).
message(0x5a1c8f03) SetDynamicBurnEnabled {
    queryId: Int as uint64;
    enabled: Bool;
}

/// Admin: thresholds for dynamic burn (BPS bonuses are fixed: +25 large tx, +12 activity).
message(0x5a1c8f04) SetDynamicBurnThresholds {
    queryId: Int as uint64;
    large_tx_threshold: Int as coins;
    activity_threshold: Int;
}

/// Admin: low-supply auto fee reduction parameters.
message(0x5a1c8f05) SetAutoReduceParams {
    queryId: Int as uint64;
    threshold: Int as coins;
    low_burn_bps: Int;
    low_staking_bps: Int;
    low_treasury_bps: Int;
}

/// Timelock-authority transfer for fee/exclusion/dynamic-burn governance.
/// Only the current timelock can hand control to a new controller — bootstrap
/// flips the deployer-held authority over to the on-chain Timelock contract
/// once fee setup is done. Mirrors `ChangeOwner` for the admin field.
message(0x5a1c8f06) SetTimelock {
    queryId: Int as uint64;
    newTimelock: Address;
}

/// Timelock: update the governance-tunable TON gas gates (IMP-MNAUD-F22).
/// Survival insurance against network fee drift — defaults equal the post-F17 W1
/// constants; master validates against const caps AND the fanout coherence
/// invariant (no configuration may pass the entry gate yet fail the fanout).
message(0x5a1c8f07) SetGasParams {
    queryId: Int as uint64;
    min_ton_fee_path: Int as coins;
    per_internal_deploy_ton: Int as coins;
    gas_pool_forward_min: Int as coins;
    gas_treasury_forward_min: Int as coins;
    gas_burn_notify_ton: Int as coins;
    gas_propagate_ton: Int as coins;
}

/// Admin: permanently and irreversibly close minting on the master.
/// Gated on `admin` (same authority as `Mint`); after bootstrap `admin` is the
/// on-chain Timelock contract, so close-mint is governance-controlled. There is
/// no inverse message — once closed, `mintable` can never become true again.
/// Distinct opcode from the timelock-gated 0x5a1c8f0X family on purpose.
message(0x5a1ca001) CloseMint {
    queryId: Int as uint64;
}

struct FeeParts {
    burn: Int;
    staking: Int;
    treasury: Int;
    net: Int;
}

/// Single empty cell for all wallets at deploy so address depends only on (owner, master, balance).
inline fun jettonWalletEmptyFeeConfig(): Cell {
    return beginCell().endCell();
}

/// Governance-tunable TON gas params (IMP-MNAUD-F22). Shared by master state view,
/// wallet snapshot and validation; defaults equal the post-F17 W1 constants.
struct GasParamsView {
    minTonFeePath: Int;
    perInternalDeployTon: Int;
    poolForwardMin: Int;
    treasuryForwardMin: Int;
    burnNotifyTon: Int;
    propagateTon: Int;
}

inline fun defaultGasParams(): GasParamsView {
    return GasParamsView {
        minTonFeePath: minTonFeePath,
        perInternalDeployTon: perInternalDeployTon,
        poolForwardMin: gasPoolForwardMin,
        treasuryForwardMin: gasTreasuryForwardMin,
        burnNotifyTon: gasBurnNotifyTon,
        propagateTon: gasPropagateTon,
    };
}

/// IMP-MNAUD-F22: const-cap + coherence validation, enforced on master
/// (`SetGasParams`) AND re-checked on every wallet (`JettonUpdateFeeConfig`).
/// The coherence invariant rejects any configuration where the entry gate could
/// admit an attach that then fails the fee-fanout require — evaluated at the
/// worst case (cold recipient deploy leg, forward fee at GAS_INVARIANT_FWD_CEIL),
/// so governance can never open an F10 strand band within a single config.
inline fun isValidGasParams(g: GasParamsView): Bool {
    if (g.minTonFeePath < GAS_MIN_TON_FEE_PATH_FLOOR || g.minTonFeePath > GAS_MIN_TON_FEE_PATH_CEIL) {
        return false;
    }
    if (g.perInternalDeployTon < perInternalDeployTon || g.perInternalDeployTon > GAS_DELIVER_CEIL) {
        return false;
    }
    if (g.poolForwardMin < gasPoolForwardMin || g.poolForwardMin > GAS_DELIVER_CEIL) {
        return false;
    }
    if (g.treasuryForwardMin < gasTreasuryForwardMin || g.treasuryForwardMin > GAS_DELIVER_CEIL) {
        return false;
    }
    if (g.burnNotifyTon < gasBurnNotifyTon || g.burnNotifyTon > GAS_DELIVER_CEIL) {
        return false;
    }
    if (g.propagateTon < gasPropagateTon || g.propagateTon > GAS_DELIVER_CEIL) {
        return false;
    }
    let worstPoolFwd = max(
        g.poolForwardMin,
        gasPoolToMasterAccrual + GAS_INVARIANT_FWD_CEIL + minTonsForStorage + gasPoolForwardEpsilon,
    );
    let worstPoolDeliver = worstPoolFwd + GAS_INVARIANT_FWD_CEIL + minTonsForStorage + gasDeliverPadTon;
    let worstTreasDeliver = g.treasuryForwardMin + GAS_INVARIANT_FWD_CEIL + minTonsForStorage + gasDeliverPadTon;
    let worstFanout =
        g.perInternalDeployTon + worstPoolDeliver + worstTreasDeliver + g.burnNotifyTon + 3 * g.propagateTon;
    return g.minTonFeePath >= worstFanout;
}

inline fun packGasParamsCell(g: GasParamsView): Cell {
    return beginCell()
        .storeCoins(g.minTonFeePath)
        .storeCoins(g.perInternalDeployTon)
        .storeCoins(g.poolForwardMin)
        .storeCoins(g.treasuryForwardMin)
        .storeCoins(g.burnNotifyTon)
        .storeCoins(g.propagateTon)
        .endCell();
}

inline fun parseGasParamsCell(c: Cell): GasParamsView {
    let s = c.beginParse();
    let mtf = s.loadCoins();
    let pid = s.loadCoins();
    let pfm = s.loadCoins();
    let tfm = s.loadCoins();
    let bnt = s.loadCoins();
    let prt = s.loadCoins();
    return GasParamsView {
        minTonFeePath: mtf,
        perInternalDeployTon: pid,
        poolForwardMin: pfm,
        treasuryForwardMin: tfm,
        burnNotifyTon: bnt,
        propagateTon: prt,
    };
}

struct DecodedFeeConfig {
    active: Bool;
    burnBps: Int;
    stakeBps: Int;
    treasBps: Int;
    poolOwner: Address;
    treasuryOwner: Address;
    dynamicBurnEnabled: Bool;
    largeTxThreshold: Int;
    activityThreshold: Int;
    maxBurnRateBps: Int;
    txCountSnapshot: Int;
    activityHourBucket: Int;
    lowSupplyMode: Bool;
    excludedCount: Int;
    excludedHead: Cell;
    gas: GasParamsView;
}

inline fun emptyExcludedHead(): Cell {
    return beginCell().endCell();
}

inline fun isExcludedChainEmpty(head: Cell): Bool {
    let s = head.beginParse();
    return s.bits() == 0 && s.refs() == 0;
}

fun isInExcludedChain(addr: Address, head: Cell): Bool {
    if (isExcludedChainEmpty(head)) {
        return false;
    }
    let s = head.beginParse();
    let a = s.loadAddress();
    if (a == addr) {
        return true;
    }
    if (s.refs() == 0) {
        return false;
    }
    return isInExcludedChain(addr, s.loadRef());
}

inline fun isExcludedMember(addr: Address, head: Cell, count: Int): Bool {
    if (count == 0 || isExcludedChainEmpty(head)) {
        return false;
    }
    return isInExcludedChain(addr, head);
}

fun excludedChainPrepend(head: Cell, addr: Address): Cell {
    return beginCell().storeAddress(addr).storeRef(head).endCell();
}

fun excludedChainRemove(addr: Address, head: Cell): Cell {
    if (isExcludedChainEmpty(head)) {
        return head;
    }
    let s = head.beginParse();
    let a = s.loadAddress();
    let tail = s.loadRef();
    if (a == addr) {
        return tail;
    }
    let newTail = excludedChainRemove(addr, tail);
    return beginCell().storeAddress(a).storeRef(newTail).endCell();
}

inline fun computeDynamicBurnBps(cfg: DecodedFeeConfig, amount: Int): Int {
    if (cfg.lowSupplyMode || !cfg.dynamicBurnEnabled) {
        return cfg.burnBps;
    }
    let bps0 = cfg.burnBps;
    let bps1 = amount > cfg.largeTxThreshold ? bps0 + 25 : bps0;
    let bps2 = cfg.txCountSnapshot > cfg.activityThreshold ? bps1 + 12 : bps1;
    // MNAUD-9/M-1: dynamic bonus must not push the effective total
    // (burn + staking + treasury) above MAX_TOTAL_FEE_BPS. Base params already
    // satisfy the cap (master-side SetFeeParams check), so burnBps <= headroom.
    let burnCap = min(cfg.maxBurnRateBps, MAX_TOTAL_FEE_BPS - cfg.stakeBps - cfg.treasBps);
    return bps2 > burnCap ? burnCap : bps2;
}

inline fun decodeFeeConfig(cfg: Cell): DecodedFeeConfig {
    let s = cfg.beginParse();
    if (s.bits() == 0) {
        return DecodedFeeConfig {
            active: false,
            burnBps: 0,
            stakeBps: 0,
            treasBps: 0,
            poolOwner: newAddress(0, 0),
            treasuryOwner: newAddress(0, 0),
            dynamicBurnEnabled: false,
            largeTxThreshold: 0,
            activityThreshold: 100,
            maxBurnRateBps: 100,
            txCountSnapshot: 0,
            activityHourBucket: 0,
            lowSupplyMode: false,
            excludedCount: 0,
            excludedHead: emptyExcludedHead(),
            gas: defaultGasParams(),
        };
    }
    let active = s.loadUint(1) == 1;
    let b = s.loadUint(16);
    let st = s.loadUint(16);
    let tr = s.loadUint(16);
    let p = s.loadAddress();
    let t = s.loadAddress();
    if (s.refs() == 0) {
        return DecodedFeeConfig {
            active: active,
            burnBps: b,
            stakeBps: st,
            treasBps: tr,
            poolOwner: p,
            treasuryOwner: t,
            dynamicBurnEnabled: false,
            largeTxThreshold: 10 * pow(10, 9),
            activityThreshold: 100,
            maxBurnRateBps: 100,
            txCountSnapshot: 0,
            activityHourBucket: 0,
            lowSupplyMode: false,
            excludedCount: 0,
            excludedHead: emptyExcludedHead(),
            gas: defaultGasParams(),
        };
    }
    let ext = s.loadRef().beginParse();
    let dynamicBurnEnabled = ext.loadBit();
    let largeTxThreshold = ext.loadCoins();
    let activityThreshold = ext.loadUint(32);
    let maxBurnRateBps = ext.loadUint(16);
    let txCountSnapshot = ext.loadUint(32);
    let activityHourBucket = ext.loadUint(32);
    let lowSupplyMode = ext.loadBit();
    let excludedCount = ext.loadUint(16);
    let excludedHead = ext.loadRef();
    // IMP-MNAUD-F22: gas section is a second ref of the extension cell; a legacy
    // (pre-F22) snapshot without it falls back to the const defaults — coherent
    // with the pre-F22 behavior (same gate, same deliver values).
    let gas = defaultGasParams();
    if (ext.refs() > 0) {
        gas = parseGasParamsCell(ext.loadRef());
    }
    return DecodedFeeConfig {
        active: active,
        burnBps: b,
        stakeBps: st,
        treasBps: tr,
        poolOwner: p,
        treasuryOwner: t,
        dynamicBurnEnabled: dynamicBurnEnabled,
        largeTxThreshold: largeTxThreshold,
        activityThreshold: activityThreshold,
        maxBurnRateBps: maxBurnRateBps,
        txCountSnapshot: txCountSnapshot,
        activityHourBucket: activityHourBucket,
        lowSupplyMode: lowSupplyMode,
        excludedCount: excludedCount,
        excludedHead: excludedHead,
        gas: gas,
    };
}

inline fun packFeeConfigExtension(
    dynamicBurnEnabled: Bool,
    largeTxThreshold: Int,
    activityThreshold: Int,
    maxBurnRateBps: Int,
    txCountSnapshot: Int,
    activityHourBucket: Int,
    lowSupplyMode: Bool,
    excludedCount: Int,
    excludedHead: Cell,
    gas: GasParamsView,
): Cell {
    return beginCell()
        .storeBit(dynamicBurnEnabled)
        .storeCoins(largeTxThreshold)
        .storeUint(activityThreshold, 32)
        .storeUint(maxBurnRateBps, 16)
        .storeUint(txCountSnapshot, 32)
        .storeUint(activityHourBucket, 32)
        .storeBit(lowSupplyMode)
        .storeUint(excludedCount, 16)
        .storeRef(excludedHead)
        .storeRef(packGasParamsCell(gas))
        .endCell();
}

inline fun packFeeConfigCell(
    burnBps: Int,
    stakeBps: Int,
    treasBps: Int,
    poolOwner: Address,
    treasuryOwner: Address,
    ext: Cell,
): Cell {
    return beginCell()
        .storeUint(1, 1)
        .storeUint(burnBps, 16)
        .storeUint(stakeBps, 16)
        .storeUint(treasBps, 16)
        .storeAddress(poolOwner)
        .storeAddress(treasuryOwner)
        .storeRef(ext)
        .endCell();
}

inline fun computeFeeParts(amount: Int, burnBps: Int, stakeBps: Int, treasBps: Int): FeeParts {
    let b = amount * burnBps / 10000;
    let s = amount * stakeBps / 10000;
    let t = amount * treasBps / 10000;
    let n = amount - b - s - t;
    return FeeParts { burn: b, staking: s, treasury: t, net: n };
}

/// Return attach surplus to owner after fee/excluded transfer out msgs (IMP-JETTON-GAS-07).
inline fun returnTransferSurplusToOwner(
    queryId: Int,
    responseDestination: Address?,
    owner: Address,
) {
    nativeReserve(minTonsForStorage, ReserveAtMost);
    let dest = responseDestination != null ? responseDestination!! : owner;
    message(MessageParameters {
        to: dest,
        value: 0,
        mode: SendRemainingBalance + SendIgnoreErrors,
        bounce: false,
        body: JettonExcesses { queryId: queryId }.toCell(),
    });
}

inline fun requestRecipientFeeConfigSync(
    master: Address,
    queryId: Int,
    senderOwner: Address,
    recipientOwner: Address,
    propagateTon: Int,
) {
    message(MessageParameters {
        to: master,
        value: propagateTon,
        mode: SendPayGasSeparately,
        bounce: true,
        body: PropagateFeeConfigToOwner {
            queryId: queryId,
            sender_owner: senderOwner,
            recipient_owner: recipientOwner,
        }.toCell(),
    });
}

/// Per-leg deliver values and the total fee-fanout requirement, computed from ONE
/// gas snapshot (IMP-MNAUD-F22: entry gate and all deliver values must come from
/// the same local snapshot — self-consistent execution even when stale).
struct FeeFanoutPlan {
    deliverTon: Int;
    poolFwdTon: Int;
    poolDeliverTon: Int;
    treasFwdTon: Int;
    treasDeliverTon: Int;
    requiredTon: Int;
}

inline fun computeFeeFanoutPlan(gas: GasParamsView, forwardTonAmount: Int, fwd: Int): FeeFanoutPlan {
    let deliverTon = max(
        gas.perInternalDeployTon,
        forwardTonAmount + fwd + minTonsForStorage + gasDeliverPadTon,
    );
    let poolFwdTon = max(
        gas.poolForwardMin,
        gasPoolToMasterAccrual + fwd + minTonsForStorage + gasPoolForwardEpsilon,
    );
    let poolDeliverTon = poolFwdTon + fwd + minTonsForStorage + gasDeliverPadTon;
    let treasFwdTon = gas.treasuryForwardMin;
    let treasDeliverTon = treasFwdTon + fwd + minTonsForStorage + gasDeliverPadTon;
    // recipient + pool + treasury legs + burn notify + 3× fee-config propagate
    let requiredTon =
        deliverTon + poolDeliverTon + treasDeliverTon + gas.burnNotifyTon + 3 * gas.propagateTon;
    return FeeFanoutPlan {
        deliverTon: deliverTon,
        poolFwdTon: poolFwdTon,
        poolDeliverTon: poolDeliverTon,
        treasFwdTon: treasFwdTon,
        treasDeliverTon: treasDeliverTon,
        requiredTon: requiredTon,
    };
}

inline fun checkEitherForwardPayload(forwardPayload: Slice) {
    if (forwardPayload.preloadUint(1) == 1) {
        let bitsAndRefs = calculateSliceBitsAndRefs(forwardPayload);
        throwUnless(9, (bitsAndRefs.refs == 1) && (bitsAndRefs.bits == 1));
    }
}

struct SliceBitsAndRefs {
    bits: Int;
    refs: Int;
}

asm fun calculateSliceBitsAndRefs(slice: Slice): SliceBitsAndRefs {
    SBITREFS
}

inline fun makeTakeWalletAddressMsg(targetJettonWallet: BasechainAddress, msg: ProvideWalletAddress): Cell {
    return beginCell()
        .storeUint(TakeWalletAddress.opcode(), 32)
        .storeUint(msg.queryId, 64)
        .storeBasechainAddress(targetJettonWallet)
        .storeMaybeRef(msg.includeAddress ? beginCell().storeAddress(msg.ownerAddress).endCell() : null)
        .endCell();
}

inline fun packForwardPayloadCell(forwardPayload: Slice): Cell {
    return beginCell().storeSlice(forwardPayload).endCell();
}

contract BurnJettonWallet(
    owner: Address,
    master: Address,
    balance: Int as coins,
    feeConfig: Cell,
) {
    receive(msg: JettonUpdateFeeConfig) {
        require(sender() == self.master, "Incorrect sender");
        require(
            msg.burn_rate_bps + msg.staking_rate_bps + msg.treasury_rate_bps <= MAX_TOTAL_FEE_BPS,
            "Invalid fee bps",
        );
        // IMP-MNAUD-F22: wallet-side re-validation of the governance gas params —
        // parity with the bps re-check above. Even a buggy/compromised master push
        // cannot install a snapshot outside the const caps or one that opens an
        // entry-gate/fanout strand band.
        let gas = GasParamsView {
            minTonFeePath: msg.gas_min_ton_fee_path,
            perInternalDeployTon: msg.gas_per_internal_deploy_ton,
            poolForwardMin: msg.gas_pool_forward_min,
            treasuryForwardMin: msg.gas_treasury_forward_min,
            burnNotifyTon: msg.gas_burn_notify_ton,
            propagateTon: msg.gas_propagate_ton,
        };
        require(isValidGasParams(gas), "Invalid gas params");
        let ext = packFeeConfigExtension(
            msg.dynamic_burn_enabled,
            msg.large_tx_threshold,
            msg.activity_threshold,
            msg.max_burn_rate_bps,
            msg.tx_count_snapshot,
            msg.activity_hour_bucket,
            msg.low_supply_mode,
            msg.excluded_count,
            msg.excluded_head,
            gas,
        );
        self.feeConfig = packFeeConfigCell(
            msg.burn_rate_bps,
            msg.staking_rate_bps,
            msg.treasury_rate_bps,
            msg.staking_pool,
            msg.treasury,
            ext,
        );
    }

    /// Shared JettonTransfer execution after excluded resolution (local snapshot or master commit).
    fun executeJettonTransfer(
        queryId: Int,
        amount: Int,
        destination: Address,
        responseDestination: Address?,
        forwardTonAmount: Int,
        forwardPayload: Slice,
        excludedTransfer: Bool,
    ) {
        let cfg = decodeFeeConfig(self.feeConfig);
        require(cfg.active, "Fee destinations not configured");
        forceBasechain(cfg.poolOwner);
        forceBasechain(cfg.treasuryOwner);

        let emptyCfg = jettonWalletEmptyFeeConfig();
        let ctx = context();
        let fwd = ctx.readForwardFee();
        // IMP-MNAUD-F22: every deliver value below comes from the SAME snapshot
        // (cfg.gas) that gated the entry — self-consistent execution even when
        // the snapshot is stale relative to master (availability risk only).
        let plan = computeFeeFanoutPlan(cfg.gas, forwardTonAmount, fwd);
        let deliverTon = plan.deliverTon;

        if (excludedTransfer) {
            self.balance -= amount;
            require(self.balance >= 0, "Incorrect balance after send");

            deploy(DeployParameters {
                value: deliverTon,
                bounce: true,
                mode: SendPayGasSeparately,
                body: JettonTransferInternal {
                    queryId: queryId,
                    amount: amount,
                    sender: self.owner,
                    responseDestination: responseDestination,
                    forwardTonAmount: forwardTonAmount,
                    forwardPayload: forwardPayload,
                }.toCell(),
                init: initOf BurnJettonWallet(destination, self.master, 0, emptyCfg),
            });
            requestRecipientFeeConfigSync(self.master, queryId, self.owner, destination, cfg.gas.propagateTon);
            returnTransferSurplusToOwner(queryId, responseDestination, self.owner);
            return;
        }

        let burnBps = computeDynamicBurnBps(cfg, amount);
        let parts = computeFeeParts(amount, burnBps, cfg.stakeBps, cfg.treasBps);
        require(parts.burn + parts.staking + parts.treasury + parts.net == amount, "Fee split invariant");

        // IMP-MNAUD-F17 (W1): pool/treasury legs are warm `message()` sends without
        // StateInit — fee sinks are deployed and fee-config-synced at bootstrap
        // (IMP-MNAUD-F14: master pushFeeConfigToOwner deploys with StateInit), so
        // the perInternalDeployTon floor no longer applies to these two legs.
        // If a sink is unexpectedly cold (pre-bootstrap edge) the leg bounces and
        // bounced<JettonTransferInternal> restores the wallet balance — no jetton
        // loss; that transfer's staking/treasury fee is skipped, and the F14
        // propagate below deploys the sink so the next transfer credits normally.
        let poolFwdTon = plan.poolFwdTon;
        let poolDeliverTon = plan.poolDeliverTon;
        let treasFwdTon = plan.treasFwdTon;
        let treasDeliverTon = plan.treasDeliverTon;
        require(ctx.value >= plan.requiredTon, "Insufficient TON for fee fanout");

        self.balance -= amount;
        require(self.balance >= 0, "Incorrect balance after send");

        let poolWalletInit = initOf BurnJettonWallet(cfg.poolOwner, self.master, 0, emptyCfg);
        let treasWalletInit = initOf BurnJettonWallet(cfg.treasuryOwner, self.master, 0, emptyCfg);

        deploy(DeployParameters {
            value: deliverTon,
            bounce: true,
            mode: SendPayGasSeparately,
            body: JettonTransferInternal {
                queryId: queryId,
                amount: parts.net,
                sender: self.owner,
                responseDestination: responseDestination,
                forwardTonAmount: forwardTonAmount,
                forwardPayload: forwardPayload,
            }.toCell(),
            init: initOf BurnJettonWallet(destination, self.master, 0, emptyCfg),
        });

        message(MessageParameters {
            to: contractAddress(poolWalletInit),
            value: poolDeliverTon,
            bounce: true,
            mode: SendPayGasSeparately,
            body: JettonTransferInternal {
                queryId: queryId,
                amount: parts.staking,
                sender: self.owner,
                responseDestination: responseDestination,
                forwardTonAmount: poolFwdTon,
                forwardPayload: beginCell().storeUint(0, 1).asSlice(),
            }.toCell(),
        });

        // Forward enough TON so Treasury receives `JettonNotification` for total_received stats (P5-3-2-1).
        message(MessageParameters {
            to: contractAddress(treasWalletInit),
            value: treasDeliverTon,
            bounce: true,
            mode: SendPayGasSeparately,
            body: JettonTransferInternal {
                queryId: queryId,
                amount: parts.treasury,
                sender: self.owner,
                responseDestination: responseDestination,
                forwardTonAmount: treasFwdTon,
                forwardPayload: beginCell().storeUint(0, 1).asSlice(),
            }.toCell(),
        });

        message(MessageParameters {
            to: self.master,
            value: cfg.gas.burnNotifyTon,
            mode: SendPayGasSeparately,
            bounce: true,
            body: JettonBurnNotification {
                queryId: queryId,
                amount: parts.burn,
                sender: self.owner,
                responseDestination: responseDestination,
            }.toCell(),
        });

        requestRecipientFeeConfigSync(self.master, queryId, self.owner, destination, cfg.gas.propagateTon);
        // IMP-MNAUD-F14: fee sinks are deployed with emptyCfg on first fanout —
        // push feeConfig to pool/treasury JW so later spend/relay paths are not
        // stuck at exit 21507 when bootstrap sync raced an uninit wallet.
        requestRecipientFeeConfigSync(self.master, queryId, self.owner, cfg.poolOwner, cfg.gas.propagateTon);
        requestRecipientFeeConfigSync(self.master, queryId, self.owner, cfg.treasuryOwner, cfg.gas.propagateTon);
        returnTransferSurplusToOwner(queryId, responseDestination, self.owner);
    }

    receive(msg: JettonTransfer) {
        forceBasechain(msg.destination);
        require(sender() == self.owner, "Incorrect sender");
        require(msg.amount > 0, "Amount must be positive");

        let cfg = decodeFeeConfig(self.feeConfig);
        require(cfg.active, "Fee destinations not configured");
        forceBasechain(cfg.poolOwner);
        forceBasechain(cfg.treasuryOwner);

        checkEitherForwardPayload(msg.forwardPayload);

        let senderExcludedLocal = isExcludedMember(
            self.owner,
            cfg.excludedHead,
            cfg.excludedCount,
        );
        let destExcludedLocal = isExcludedMember(
            msg.destination,
            cfg.excludedHead,
            cfg.excludedCount,
        );

        let ctx = context();
        let fwd = ctx.readForwardFee();
        let recipientForwards = 1 + sign(msg.forwardTonAmount);
        // IMP-MNAUD-F11: local snapshot claiming excluded is NOT authoritative —
        // that branch always hops to ResolveJettonTransfer (may execute fee path
        // after RemoveExcluded). Entry gate is therefore always minTonFeePath;
        // surplus is refunded when master confirms the transfer is still excluded.
        // (Warm P2P with neither side locally excluded keeps the direct fee path.)
        // IMP-MNAUD-F22: the gate is read from the local snapshot (governance
        // default = the minTonFeePath const), same snapshot as the fanout values.
        let minTonRequired = cfg.gas.minTonFeePath;
        require(
            ctx.value > msg.forwardTonAmount + recipientForwards * fwd + minTonRequired,
            "Insufficient amount of TON attached",
        );

        // IMP-MNAUD-F11 / STKFEE-02: never trust local excluded==true (stale-remove
        // fee-bypass). Also resolve when forward ≥ 1 TON (stale-add / staking).
        if (
            senderExcludedLocal ||
            destExcludedLocal ||
            msg.forwardTonAmount >= minForwardForLiveExcludedCheck
        ) {
            // IMP-MNAUD-F18: pre-check the balance before the resolve hop. Post-F11 the
            // deduction happens only at CommitJettonTransfer, whose bounce dies at master —
            // failing the inbound transfer here restores the natural bounce to the owner's
            // rollback handlers (bounced<JettonTransferOut> / bounced<JettonTransfer>).
            // The commit-stage re-check covers in-flight races (JettonTransferCommitFailed).
            require(self.balance >= msg.amount, "Incorrect balance after send");
            nativeReserve(minTonsForStorage, ReserveAtMost);
            message(MessageParameters {
                to: self.master,
                value: 0,
                mode: SendRemainingBalance + SendIgnoreErrors,
                bounce: true,
                body: ResolveJettonTransfer {
                    queryId: msg.queryId,
                    sender_owner: self.owner,
                    amount: msg.amount,
                    destination: msg.destination,
                    responseDestination: msg.responseDestination,
                    forwardTonAmount: msg.forwardTonAmount,
                    forwardPayload: packForwardPayloadCell(msg.forwardPayload),
                }.toCell(),
            });
            return;
        }

        self.executeJettonTransfer(
            msg.queryId,
            msg.amount,
            msg.destination,
            msg.responseDestination,
            msg.forwardTonAmount,
            msg.forwardPayload,
            false,
        );
    }

    /// F18 pattern: report a commit-stage failure to the owner with the incoming TON
    /// instead of throwing (a throw would bounce to master and strand the value).
    fun reportCommitFailure(queryId: Int, amount: Int) {
        let tonBalanceBeforeMsg = myBalance() - context().value;
        nativeReserve(max(tonBalanceBeforeMsg, minTonsForStorage), ReserveAtMost);
        message(MessageParameters {
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors,
            bounce: false,
            body: JettonTransferCommitFailed {
                queryId: queryId,
                amount: amount,
            }.toCell(),
        });
    }

    receive(msg: CommitJettonTransfer) {
        require(sender() == self.master, "Incorrect sender");
        let payload = msg.forwardPayload.beginParse();
        checkEitherForwardPayload(payload);
        // IMP-MNAUD-F18: a commit-stage balance failure must not throw — the bounce
        // returns to master where no owner routing is possible (only the queryId/amount
        // prefix survives). Report the failure to the owner explicitly; the incoming
        // TON is forwarded with the signal so nothing strands on the wallet (MNAUD-10).
        if (self.balance < msg.amount) {
            self.reportCommitFailure(msg.queryId, msg.amount);
            return;
        }
        // IMP-MNAUD-F22: commit executes with the snapshot the master pushed right
        // before this message. If governance raised the gas params while this
        // transfer entered through the OLD (lower) gate, the fanout requirement can
        // now exceed the attached value — a throw here would bounce to master and
        // strand the user's TON (transition-window F10 band). Pre-check the value
        // and refund via the F18 signal instead of throwing.
        let cfg = decodeFeeConfig(self.feeConfig);
        let ctx = context();
        let plan = computeFeeFanoutPlan(cfg.gas, msg.forwardTonAmount, ctx.readForwardFee());
        let requiredTon = msg.excludedTransfer
            ? plan.deliverTon + cfg.gas.propagateTon
            : plan.requiredTon;
        if (ctx.value < requiredTon) {
            self.reportCommitFailure(msg.queryId, msg.amount);
            return;
        }
        self.executeJettonTransfer(
            msg.queryId,
            msg.amount,
            msg.destination,
            msg.responseDestination,
            msg.forwardTonAmount,
            payload,
            msg.excludedTransfer,
        );
    }

    receive(msg: JettonTransferInternal) {
        self.balance += msg.amount;

        let wallet: StateInit = initOf BurnJettonWallet(msg.sender, self.master, 0, jettonWalletEmptyFeeConfig());
        if (!wallet.hasSameBasechainAddress(sender())) {
            require(self.master == sender(), "Incorrect sender");
        }

        let ctx: Context = context();
        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg = myBalance() - msgValue;

        if (msg.forwardTonAmount > 0) {
            let fwdFee: Int = ctx.readForwardFee();
            msgValue -= msg.forwardTonAmount + fwdFee;
            message(MessageParameters {
                to: self.owner,
                value: msg.forwardTonAmount,
                mode: SendPayGasSeparately,
                bounce: false,
                body: JettonNotification {
                    queryId: msg.queryId,
                    amount: msg.amount,
                    sender: msg.sender,
                    forwardPayload: msg.forwardPayload,
                }.toCell(),
            });
        }
        nativeReserve(max(tonBalanceBeforeMsg, minTonsForStorage), ReserveAtMost);
        if (msg.responseDestination != null && msgValue > 0) {
            message(MessageParameters {
                to: msg.responseDestination!!,
                value: msgValue,
                mode: SendRemainingBalance + SendIgnoreErrors,
                bounce: false,
                body: JettonExcesses { queryId: msg.queryId }.toCell(),
            });
        }
    }

    receive(msg: JettonBurn) {
        require(sender() == self.owner, "Incorrect sender");

        self.balance -= msg.amount;
        require(self.balance >= 0, "Incorrect balance after send");

        let ctx = context();
        let fwdFee: Int = ctx.readForwardFee();
        require(ctx.value > (fwdFee + 2 * getComputeFee(gasForBurn, false)), "Insufficient amount of TON attached");

        message(MessageParameters {
            to: self.master,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: JettonBurnNotification {
                queryId: msg.queryId,
                amount: msg.amount,
                sender: self.owner,
                responseDestination: msg.responseDestination,
            }.toCell(),
        });
    }

    bounced(msg: bounced<JettonTransferInternal>) {
        self.balance += msg.amount;
    }

    /// Burn notify to master failed — restore deducted burn leg so wallet balance matches totalSupply.
    bounced(msg: bounced<JettonBurnNotification>) {
        self.balance += msg.amount;
    }

    get fun get_wallet_data(): BurnJettonWalletData {
        return BurnJettonWalletData {
            balance: self.balance,
            owner: self.owner,
            minter: self.master,
            code: myCode(),
        };
    }

    /// Whether master pushed fee config (for tests / off-chain reads).
    get fun get_fee_config_active(): Bool {
        return decodeFeeConfig(self.feeConfig).active;
    }

    /// Effective TON gas params from the local snapshot (IMP-MNAUD-F22);
    /// const defaults when the snapshot is empty or pre-F22 legacy.
    get fun get_gas_config(): GasParamsView {
        return decodeFeeConfig(self.feeConfig).gas;
    }
}
