/// Common enums for `MeraWallet` and `OperationStorage`.
/// See docs/ton-mera-spec-v1.md. Constants: `@contracts/consts`. Errors: `@contracts/errors`.

enum RoleLevel {
    None = 0
    Primary = 1
    Backup = 2
    Emergency = 3
}

enum ProposalStatus {
    None = 0
    Pending = 1
    Vetoed = 2
    Executed = 3
    Cancelled = 4
}

/// Who may call delayed execution after timelock (Solidity `RelayExecutorPolicy`). Used with `OperationStorageState.relay`.
enum RelayExecutorPolicy {
    CoreExecute = 0
    Anyone = 1
    Designated = 2
    Whitelist = 3
}

struct CallPathPolicy {
    flags: uint8
    primaryDelay: uint32
    backupDelay: uint32
    emergencyDelay: uint32
    /// When false on `setTargetSelectorCallPolicies`, removes the pair (Solidity `exists`).
    exists: bool
}

/// One upsert row for `SetTargetCallPolicies` (`target` + policy in a single struct).
struct TargetCallPolicyEntry {
    target: address
    policy: CallPathPolicy
}

/// One upsert row for `SetSelectorCallPolicies` (`selector` = bytes4 / opcode + policy).
struct SelectorCallPolicyEntry {
    selector: uint32
    policy: CallPathPolicy
}

/// One upsert row for `SetTargetSelectorCallPolicies` (target + selector + policy).
struct TargetSelectorCallPolicyEntry {
    target: address
    selector: uint32
    policy: CallPathPolicy
}

/// Default timelocks per role (seconds), Solidity `mapping(Role => uint256) roleTimelock`.
/// Flat fields (not `map<RoleLevel, …>`) so `@ton/tolk-abi-to-typescript` / `@ton/core` can codegen ABI.
struct RoleTimelocks {
    primaryDelay: uint256
    backupDelay: uint256
    emergencyDelay: uint256
}

struct Agent {
    roleLevel: uint2
    activeFrom: uint32
}

struct AgentsState {
    agents: map<address, Agent>
}

/// One row for `SetAgents`: `roleLevelBits` 0 = remove agent; 1/2/3 = Primary/Backup/Emergency
/// (matches `RoleLevel` discriminant; `uint2` avoids Acton codegen crash on enum-in-struct in messages).
struct AgentEntry {
    agent: address
    roleLevelBits: uint2
}

struct SafeMode {
    activeUntil: uint32
}

struct LifeControl {
    enabled: bool
    timeout: uint32
    lastAlive: uint32
    controllers: map<address, uint8>
}

struct Policies {
    callByTarget: map<address, CallPathPolicy>
    callBySelector: map<uint32, CallPathPolicy>
    callByTargetSelector: map<uint256, CallPathPolicy>
}
