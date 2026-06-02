tolk 1.3

// Gas / storage reserves for the single-contract Cash-or-Crash.

const GAS_CREATE: int = 20000000;            // 0.02 TON
const GAS_RESOLVE: int = 20000000;           // 0.02 TON
const GAS_FOR_JETTON_PAYOUT: int = 50000000; // 0.05 TON
const MIN_TREASURY_RESERVE: int = 100000000; // 0.1 TON
const UPGRADE_TIMELOCK_SECS: int = 48 * 60 * 60;
