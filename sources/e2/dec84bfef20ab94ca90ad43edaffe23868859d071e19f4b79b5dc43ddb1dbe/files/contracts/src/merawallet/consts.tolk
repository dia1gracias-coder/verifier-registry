/// Shared constants for `MeraWallet` and `OperationStorage`. Spec §7.3 and event topics.

/// Numeric rank: Primary=1 < Backup=2 < Emergency=3 (see Solidity `MERAWalletConstants`).
const ROLE_RANK_NONE: uint32 = 0
const ROLE_RANK_PRIMARY: uint32 = 1
const ROLE_RANK_BACKUP: uint32 = 2
const ROLE_RANK_EMERGENCY: uint32 = 3

/// Default role timelocks (seconds). Spec §7.3.
const DEFAULT_PRIMARY_TIMELOCK: uint32 = 86400
const DEFAULT_BACKUP_TIMELOCK: uint32 = 43200
const DEFAULT_EMERGENCY_TIMELOCK: uint32 = 0
const OWNERSHIP_AND_ROLE_GRANT_EMERGENCY_DELAY: uint32 = 43200
const MAX_TIMELOCK_DELAY: uint32 = 7776000

const SAFE_MODE_MIN_DURATION: uint32 = 2592000
const SAFE_MODE_MAX_DURATION: uint32 = 7776000
const DEFAULT_EMERGENCY_AGENT_LIFETIME: uint32 = 2592000
const MAX_EMERGENCY_AGENT_LIFETIME: uint32 = 7776000
const PROPOSAL_STORAGE_TOPUP: coins = 50000000
const PROPOSAL_REGISTERED_TOPIC: uint248 = 0x51002
const PENDING_TRANSACTION_CANCELLED_TOPIC: uint248 = 0x61003
const PENDING_TRANSACTION_VETOED_TOPIC: uint248 = 0x61001
const PENDING_TRANSACTION_VETO_CLEARED_TOPIC: uint248 = 0x61002

/// `MAX_CALLS_PER_BATCH` caps `Call[]` / batch ingress (Tolk `array<T>` holds at most 255 elements).
/// Solidity `MERAWalletConstants.MAX_CALLS_PER_BATCH` is 256; TON v1 uses 255.
const MAX_CALLS_PER_BATCH: uint32 = 255

/// Minimum `Call.value` for batch execution (`executeCalls`).
const MIN_CALL_VALUE: coins = ton("0.01")

/// Standard zero address (workchain 0, hash all zeros). Used for `newPrimary != 0` and init checks.
const ADDRESS_ZERO: address = address("0:0000000000000000000000000000000000000000000000000000000000000000")
