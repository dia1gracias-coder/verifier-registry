import "factory-types"
import "fee-splitter-types"

/// Creator -> Factory. `rewards` lists the reward jetton masters (0 = pending, 1 = single,
/// 2..5 = cycle), each one whitelisted in the config. `firstBuyTon` is spent on the curve for the
/// creator before anyone else can trade. Value must cover launchFee + firstBuyTon + LAUNCH_GAS
/// (+ premint.seedTon + holders × PREMINT_VALUE for an admin premint).
struct (0x46410001) CreateLaunch {
    queryId: uint64
    metadata: cell
    rewards: map<uint8, address>
    firstBuyTon: coins
    /// Admin only: fee split of this launch. Null = factory default.
    splits: FeeSplits?
    /// Admin only: migration premint (see factory-types.Premint).
    premint: Cell<Premint>?
}

struct (0x46410010) SetFactoryPaused {
    queryId: uint64
    paused: bool
}

/// Admin: applies right away (bounded by asserts; only future launches are affected).
struct (0x46410011) SetFactoryConfig {
    queryId: uint64
    config: Cell<FactoryConfig>
}

/// Admin: propose new codes (kind = PROPOSAL_CODES, payload = Cell<FactoryCodes>) or new roles
/// (kind = PROPOSAL_ROLES, payload = Cell<RolesProposal>); applicable after FACTORY_DELAY.
struct (0x46410013) ProposeFactoryChange {
    queryId: uint64
    kind: uint8
    payload: cell
}

/// Admin: apply the pending proposal once its delay elapsed.
struct (0x46410014) ApplyFactoryChange {
    queryId: uint64
}

const EVENT_TOPIC_LAUNCH_CREATED = 0x4641E001
const EVENT_TOPIC_FACTORY_CHANGED = 0x4641E002

struct LaunchCreatedEvent {
    seq: uint64
    creator: address
    addresses: Cell<LaunchAddresses>
    rewardCount: uint8
    firstBuyTon: coins
    codeVersion: uint16
    preminted: coins
}

/// Emitted when a change is proposed (applied = false, readyAt = when it can be applied) and when it is applied.
struct FactoryChangedEvent {
    kind: uint8
    applied: bool
    readyAt: uint32
}
