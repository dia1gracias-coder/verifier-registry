/// Messages the `MeraWallet` contract accepts (user, agents, and self-calls). Spec §6.1–6.2.

import "internal-messages"
import "types"
import "types"
import "operation/types"

// --- Self-call config (0x11_xxx, 0x21_xxx, 0x27_xxx, 0x71_xxx) ---

struct (0x11001) SetPrimary {
    newPrimary: address
    /// Effective core role during self-call (Solidity transient `EXECUTION_CONTEXT_ROLE`).
    contextRole: RoleLevel
}

struct (0x11002) SetBackup {
    newBackup: address
    /// Effective core role during self-call (Solidity transient `EXECUTION_CONTEXT_ROLE`).
    contextRole: RoleLevel
}

struct (0x11003) SetEmergency {
    newEmergency: address
    /// Used for self-call path only (`_onlySelfAsEmergency`); ignored when `sender == guardian`.
    contextRole: RoleLevel
}

struct (0x11004) SetGuardian {
    guardian: address
    /// Effective core role during self-call (Solidity transient `EXECUTION_CONTEXT_ROLE`).
    contextRole: RoleLevel
}

struct (0x11005) SetEmergencyAgentLifetime {
    lifetime: uint32
    /// Effective core role during self-call (Solidity transient `EXECUTION_CONTEXT_ROLE`).
    contextRole: RoleLevel
}

struct (0x21001) SetRoleTimelock {
    role: uint2
    delay: uint32
    /// Effective core role during self-call (Solidity transient `EXECUTION_CONTEXT_ROLE`).
    contextRole: RoleLevel
}

struct (0x21002) SetTargetCallPolicies {
    entries: array<TargetCallPolicyEntry>
    /// Effective core role during self-call (Solidity transient `EXECUTION_CONTEXT_ROLE`).
    contextRole: RoleLevel
}

struct (0x21003) SetSelectorCallPolicies {
    entries: array<SelectorCallPolicyEntry>
    /// Effective core role during self-call (Solidity transient `EXECUTION_CONTEXT_ROLE`).
    contextRole: RoleLevel
}

struct (0x21004) SetTargetSelectorCallPolicies {
    entries: array<TargetSelectorCallPolicyEntry>
    /// Effective core role during self-call (Solidity transient `EXECUTION_CONTEXT_ROLE`).
    contextRole: RoleLevel
}

struct (0x27001) SetAgents {
    entries: array<AgentEntry>
    /// Effective core role during self-call (Solidity transient `EXECUTION_CONTEXT_ROLE`).
    contextRole: RoleLevel
}

struct (0x71001) SetLifeControl {
    enabled: bool
    timeout: uint32
}

struct (0x71002) SetLifeControllers {
    enabled: bool
    controllers: array<address>
}

// --- External actions ---

struct (0x51001) ExecuteTransaction {
    calls: CallList
    salt: uint256
}

struct (0x51002) ProposeTransaction {
    calls: CallList
    salt: uint256
}

struct (0x51003) ExecutePending {
    operationId: uint256
}

/// Immediate native TON transfer (Solidity `MERAWalletNative.transferNative`).
struct (0x51004) TransferNative {
    to: address
    amount: coins
    /// Must be `MERA_ADDRESS_ZERO` in v1 (optional checkers not wired).
    checker: address
    checkerData: cell
    salt: uint256
}

struct (0x61001) VetoPending {
    operationId: uint256
}

struct (0x61002) ClearVeto {
    operationId: uint256
}

struct (0x61003) CancelPending {
    operationId: uint256
}

struct (0x31001) SetFrozenPrimary {
    value: bool
    /// For self-call (`sender == wallet`); use `RoleLevel.None` when calling from a controller address.
    contextRole: RoleLevel
}

struct (0x31002) SetFrozenBackup {
    value: bool
    /// For self-call (`sender == wallet`); use `RoleLevel.None` when calling from a controller address.
    contextRole: RoleLevel
}

struct (0x41001) EnterSafeMode {
    duration: uint32
}

struct (0x41002) ResetSafeMode {
    /// Effective core role during self-call (Solidity transient `EXECUTION_CONTEXT_ROLE`).
    contextRole: RoleLevel
}

struct (0x73001) ConfirmAlive {}

/// Testnet / emulation only: set `primary` / `backup` / `guardian` without self-call timelocks.
struct (0x7F001) SetDirectForTest {
    primary: address
    backup: address
    guardian: address
}

type MeraWalletIncoming =
    | SetPrimary
    | SetBackup
    | SetEmergency
    | SetGuardian
    | SetEmergencyAgentLifetime
    | SetRoleTimelock
    | SetTargetCallPolicies
    | SetSelectorCallPolicies
    | SetTargetSelectorCallPolicies
    | SetAgents
    | SetLifeControl
    | SetLifeControllers
    | ExecuteTransaction
    | ProposeTransaction
    | ExecutePending
    | TransferNative
    | VetoPending
    | ClearVeto
    | CancelPending
    | SetFrozenPrimary
    | SetFrozenBackup
    | EnterSafeMode
    | ResetSafeMode
    | ConfirmAlive
    | SetDirectForTest

/// Wallet also accepts callbacks from `OperationStorage`.
type MeraWalletAnyIncoming =
    | MeraWalletIncoming
    | ProposalExecutePayload
    | ProposalVetoPrepared
    | ProposalVetoAck
    | ProposalClearVetoAck
    | ProposalCancelAck
    | ProposalAck
