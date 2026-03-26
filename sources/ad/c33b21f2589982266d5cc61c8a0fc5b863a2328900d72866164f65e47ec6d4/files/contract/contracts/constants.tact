// ─── JettonMaker V4 — constants.tact ─────────────────────────────────────────

// ─── Gas & reserve constants ──────────────────────────────────────────────────
const MIN_TON_RESERVE:   Int = ton("0.05");
const MINTER_DEPLOY_GAS: Int = ton("0.15");
const WALLET_DEPLOY_GAS: Int = ton("0.05");
const FORWARD_GAS:       Int = ton("0.01");
const TOTAL_DEPLOY_GAS:  Int = ton("0.3");   // attached on top of platform fee

// ─── Platform fees ────────────────────────────────────────────────────────────
const BASE_FEE: Int = ton("0.6");
const PRO_FEE:  Int = ton("0.7");
