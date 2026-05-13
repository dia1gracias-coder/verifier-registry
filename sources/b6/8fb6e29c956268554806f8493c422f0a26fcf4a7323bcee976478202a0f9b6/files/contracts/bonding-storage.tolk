// Storage for BondingCurveMaster (factory) and BondingCurve (per-launch).

// Curve lifecycle. uint8 keeps storage compact.
const CURVE_STATE_INITIALIZING: uint8 = 0
const CURVE_STATE_TRADING: uint8 = 1
const CURVE_STATE_GRADUATING: uint8 = 2
const CURVE_STATE_MIGRATED: uint8 = 3

struct MasterStorage {
    admin: address
    nextAdmin: address?
    treasury: address
    totalLaunches: uint64
    feesBalance: coins // cumulative authenticated fees received from launches
}

fun MasterStorage.load(): MasterStorage {
    return MasterStorage.fromCell(contract.getData());
}

fun MasterStorage.save(self) {
    contract.setData(self.toCell());
}

// Immutable per-launch wiring + constants. Stored as a ref so hot cell stays <= 1023 bits.
// jettonMinter is NOT here: mutable, filled on InitializeCurve, breaks state-init circular dep.
// `salt` differentiates curves with the same creator so each launch gets a unique address.
struct LaunchConfig {
    master: address
    creator: address
    salt: uint64
    curveSupply: coins
    dexReserveSupply: coins
    graduationThreshold: coins
}

struct BondingCurveStorage {
    state: uint8
    jettonMinter: address?
    virtualTonReserve: coins
    realTonReserve: coins
    curveJettonBalance: coins // swap-eligible inventory; filled on init mint
    feeAccrued: coins
    config: Cell<LaunchConfig>
}

fun BondingCurveStorage.load(): BondingCurveStorage {
    return BondingCurveStorage.fromCell(contract.getData());
}

fun BondingCurveStorage.save(self) {
    contract.setData(self.toCell());
}

struct MasterDataReply {
    admin: address
    nextAdmin: address?
    treasury: address
    totalLaunches: uint64
    feesBalance: coins
}

struct BondingCurveDataReply {
    state: uint8
    creator: address
    salt: uint64
    jettonMinter: address?
    virtualTonReserve: coins
    realTonReserve: coins
    curveJettonBalance: coins
    curveSupply: coins
    dexReserveSupply: coins
    graduationThreshold: coins
    feeAccrued: coins
}
