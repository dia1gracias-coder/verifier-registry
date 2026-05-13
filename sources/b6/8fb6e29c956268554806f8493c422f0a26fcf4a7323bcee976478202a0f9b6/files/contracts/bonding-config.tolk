// Curve and protocol constants. Tuned for pump.fun-style economics.
// All token amounts use 9 decimals (TON Jetton standard).

// Total token supply minted per launch: 1B with 9 decimals
const TOTAL_SUPPLY: coins = 1000000000 * 1000000000

// Jettons available to sell via the curve (99.9% of supply). pump.fun-style: ALL but the
// DEX reserve is sold along the curve, producing a ~1000x markup from seed to graduation.
const CURVE_SUPPLY: coins = 999000000 * 1000000000

// Jettons reserved on the curve for DeDust seed at graduation (0.1% of supply).
// This sits idle while the curve trades; the BuyJettons floor check protects it.
const DEX_RESERVE_SUPPLY: coins = 1000000 * 1000000000

// Initial virtual TON reserve. Sets the starting price along the x*y=k curve.
// price_0 = VIRTUAL_TON_RESERVE / TOTAL_SUPPLY (approximately).
//
// CRITICAL — graduation reachability: with curveJettons clamped at the floor
// (== DEX_RESERVE_SUPPLY), the AMM gives realTon_max = V × (S/DEX - 1) = V × 999.
// We need realTon_max > GRADUATION_THRESHOLD_TON for graduation to fire AT ALL through
// regular trading. With V=22, realTon_max ≈ 21978 TON, leaving ~2k TON of safety margin
// above the 20000 TON marketed threshold. (V=20 was unreachable: max=19980 < 20000.)
const VIRTUAL_TON_RESERVE_INIT: coins = ton("22")

// Graduation eligibility threshold: when realTonReserve crosses this, Graduate becomes
// callable. The actual graduation moment is when curveJettons hits the floor exactly,
// which occurs at realTon ≈ 21978 TON with current V/S/DEX. The excess between threshold
// and actual graduation realTon is partially captured as MIGRATION_FEE (see below).
const GRADUATION_THRESHOLD_TON: coins = ton("20000")

// Flat fee charged at graduation, diverted to master.feesBalance before pool seed.
// Pump.fun uses 6 SOL (~$1k) flat. We charge 100 TON (~$320) — modest, predictable.
// Pool seed amounts: pool_seed_ton = realTon - MIGRATION_FEE
//                    pool_seed_jettons = pool_seed_ton × dexReserve / (V + realTon)
// The seed_jettons formula preserves price continuity (P_curve_last == P_dedust_seed),
// at the cost of leaving a few thousand jettons stranded in the curve forever
// (mathematically locked, ~$300-400 of stranded value at typical graduation prices).
const MIGRATION_FEE: coins = ton("100")

// Protocol fee in basis points: 1% = 100 bps. Applied on both buy and sell sides.
const PROTOCOL_FEE_BPS: int = 100
const BPS_DENOMINATOR: int = 10000

// Flat fee charged on every CreateLaunch. Two purposes:
//   1. Anti-spam: prevents trivial-cost flooding of bogus launches that pollute frontends.
//   2. Direct protocol revenue independent of trading volume.
// Credited to MasterStorage.feesBalance and withdrawn by admin alongside trading fees.
const CREATE_LAUNCH_FEE: coins = ton("0.2")

// Minimum value the user must attach to CreateLaunch. Derived as:
//   CREATE_LAUNCH_FEE (0.2) + minterDeployValue (0.03) + curve init mint chain budget (~0.25)
// where the chain budget is empirically 0.15-0.2 TON post-tightening (dynamic mint tonAmount
// via calcMinimalTransferAmount, 0.02 notif, 0.02 drop) and 0.05 TON of buffer for chain
// retries / future storage rent on the curve.
const MIN_CREATE_LAUNCH_VALUE: coins = ton("0.5")

// Gas reserve for one full TEP-74 transfer chain initiated by the curve. Covers:
//   curve compute (~0.002) + 2× forward fee (~0.002) + sender wallet compute (~0.002)
//   + recipient wallet compute (~0.002) + state-init for new wallets (~0.005)
//   + forwardTonAmount carried to the recipient (CURVE_TRANSFER_NOTIFICATION).
//
// Total ≈ 0.023 TON in current TON gas pricing (post-catchain-v2 optimizations).
// 0.05 TON gives ~2× safety margin while letting users buy with as little as ~0.06 TON.
//
// If gas prices change, override via constant or switch to `calcMinimalTransferAmount` from
// the template's fees-management.tolk (dynamic computation using `in.originalForwardFee`).
const CURVE_TRANSFER_VALUE: coins = ton("0.05")

// TON forwarded to the recipient wallet for processing the TransferNotification.
const CURVE_TRANSFER_NOTIFICATION: coins = ton("0.01")
