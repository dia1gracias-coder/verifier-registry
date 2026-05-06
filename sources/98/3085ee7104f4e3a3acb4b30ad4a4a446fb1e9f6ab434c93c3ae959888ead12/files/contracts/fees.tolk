tolk 1.3

// Gas / storage reserves. Conservative — refine later via @stdlib/gas-payments.

// Minimum value a child game contract must hold to cover storage rent
// for the duration the game stays around (~5 years of basechain rent).
const MIN_GAME_STORAGE_RESERVE: int = 10000000;     // 0.01 TON

// Headroom required on top of the bet itself when CreateNativeGame arrives.
// Covers: master compute, deploy fees, child compute on init, child storage reserve.
const GAS_FOR_NATIVE_CREATE: int = 50000000;        // 0.05 TON

// Headroom for an admin-submitted CashOut/MarkLost arriving at the master.
const GAS_FOR_CASHOUT_RELAY: int = 50000000;        // 0.05 TON

// Headroom the game contract reserves before sending a native payout.
const GAS_FOR_NATIVE_PAYOUT: int = 10000000;        // 0.01 TON

// Value attached to outgoing jetton transfers from master to player.
// Covers: master's jetton wallet compute, transfer fee, dest jetton wallet
// compute (if needs deploy), and the optional forward TON amount.
const GAS_FOR_JETTON_PAYOUT: int = 80000000;        // 0.08 TON

// Headroom for the master to refund a jetton bet on failed game create.
const GAS_FOR_JETTON_REFUND: int = 80000000;        // 0.08 TON

// Mandatory delay between ProposeUpgrade and ExecuteUpgrade — gives users
// time to exit before any code change takes effect.
const UPGRADE_TIMELOCK_SECS: int = 48 * 60 * 60;    // 48 hours

// Minimum master treasury reserve to keep storage rent paid even after a
// withdrawal. Owner-initiated withdrawals can't drain below this.
const MIN_MASTER_STORAGE_RESERVE: int = 100000000;  // 0.1 TON
