// Factory v2: deploys one coin (RewardMaster + RewardVault + FeeSplitter + Curve) per launch.
// Codes and roles change through a 48 h timelock; config is bounded by asserts.
import "fee-splitter-types"

/// Delay between a proposal (codes, roles) and its application.
const FACTORY_DELAY = 172800

const PROPOSAL_CODES = 1
const PROPOSAL_ROLES = 2

/// Gas the Curve takes out of `graduationFee` (must match CurveV2.GRADUATION_GAS) + margin required by the Factory.
const CURVE_GRADUATION_GAS = ton("0.3")
const GRADUATION_FEE_MARGIN = ton("0.1")

/// Largest premint list accepted in one launch (one message per holder).
const MAX_PREMINT = 200

/// Smallest `minBuy` a config may set.
const MIN_BUY_FLOOR = ton("0.01")

struct FactoryRoles {
    admin: address
    /// Keeper of every RewardVault created (bounded conversions).
    keeper: address
    /// Protocol treasury: launch fees, graduation fees, protocol share of coin fees.
    protocol: address
}

struct FactoryRoutes {
    pot: address
    buyback: address
}

struct CurveDefaults {
    feeBps: uint16
    curveSupply: coins
    poolSupply: coins
    graduationTon: coins
    graduationFee: coins
    minBuy: coins
    poolLpFeeBps: uint16
    poolProtocolFeeBps: uint16
    virtualTon0: coins
    virtualToken0: coins
    /// D4-2: when true `graduationTon` may be unreachable (the curve graduates on sell-out, the UI says so).
    sellOutGraduation: bool
}

struct FactoryConfig {
    /// Fixed fee paid to the protocol per launch.
    launchFee: coins
    /// TON kept by each RewardVault (storage + gas headroom).
    vaultReserve: coins
    vaultPendingTimeout: uint32
    /// Minimum accrued fee before a FeeSplitter splits.
    minSplit: coins
    /// Floor of the protocol share in every FeeSplitter (default splits and later SetSplits).
    minProtocolBps: uint16
    splits: FeeSplits
    curve: Cell<CurveDefaults>
    /// DeDust native vault + pools whitelisted for every RewardVault (swap bodies are built on-chain).
    dexVault: address
    dexPools: map<address, bool>
    /// Reward jetton masters a launch may pay dividends in (D4-4).
    rewardWhitelist: map<address, bool>
}

/// Codes of the deployed contracts (4 refs) + the RewardWallet code handed to the vault.
struct FactoryCodes {
    master: cell
    vault: cell
    splitter: cell
    more: Cell<FactoryCodesMore>
}

struct FactoryCodesMore {
    curve: cell
    wallet: cell
}

/// Admin-only launch option (migration of an existing coin): `holders` receive their coins outside the
/// curve, which starts as if `sold` coins had been bought for `seedTon` TON (attached by the admin).
struct Premint {
    holders: map<address, coins>
    sold: coins
    seedTon: coins
}

struct RolesProposal {
    roles: Cell<FactoryRoles>
    routes: Cell<FactoryRoutes>
}

struct FactoryProposal {
    kind: uint8
    payload: cell
    readyAt: uint32
}

/// Sub-cell: what the timelock governs (the root cell is limited to 4 refs).
struct FactoryGovernance {
    codes: Cell<FactoryCodes>
    proposal: Cell<FactoryProposal>?
}

struct FactoryStorage {
    seq: uint64
    paused: bool
    roles: Cell<FactoryRoles>
    routes: Cell<FactoryRoutes>
    config: Cell<FactoryConfig>
    gov: Cell<FactoryGovernance>
}

fun FactoryStorage.load(): FactoryStorage {
    return FactoryStorage.fromCell(contract.getData());
}

fun FactoryStorage.save(self) {
    contract.setData(self.toCell());
}

struct FactoryDataReply {
    seq: int
    paused: bool
    roles: FactoryRoles
    routes: FactoryRoutes
    config: FactoryConfig
    proposal: FactoryProposal?
}

/// Addresses of the four contracts of launch `seq`.
struct LaunchAddresses {
    master: address
    vault: address
    more: Cell<LaunchAddressesMore>
}

struct LaunchAddressesMore {
    splitter: address
    curve: address
}
