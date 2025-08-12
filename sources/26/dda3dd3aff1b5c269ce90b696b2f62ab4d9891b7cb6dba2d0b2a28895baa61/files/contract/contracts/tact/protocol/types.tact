// ===============================
// Reekt.Fun — Shared Protocol Types (storage-blind views + requests/responses)
// ===============================

import "./opcodes.tact";

struct KeysView {
  adminPublicKey: Int;
  serverPublicKey: Int;
}

struct FinancialView {
  poolLiquidity: Int;
}

struct ConfigView {
  maxBetPercent: Int;
  maxPayoutPercent: Int;
  withdrawalFeePercent: Int;
  affiliateCommissionPercent: Int;
  lockupPeriod: Int;
}

struct SystemView {
  isPaused: Bool;
}

// ---- Requests sent by proxy to logic (one per op) ----
// NOTE: Use plain structs to avoid auto-generated typed-union decoders
// Logic and Storage manually serialize/deserialize with OP_* prefix

struct CreateGameRequest {
  // Views
  sys: SystemView;
  keys: KeysView;
  fin: FinancialView;
  cfg: ConfigView;

  // Params
  player: Address;
  betAmount: Int;
  hashCommitment: Cell;
  affiliateCode: Cell?;
  gameConfig: Cell;
  serverTimestamp: Int;
  serverSignature: Cell;

  // Context from Proxy
  allocatedGameId: Int;
  expectedServerNonce: Int;
  existingUserCell: Cell?; // Pass user data if it exists
}

struct CashoutRequest {
  sys: SystemView;
  keys: KeysView;
  fin: FinancialView;
  cfg: ConfigView;

  // Params
  payoutAmount: Int;
  multiplier: Int;
  moves: Cell;
  gameSeed: Cell;
  gameSalt: Cell;
  finalGameState: Cell;
  backendCommissionAmount: Int;
  serverSignature: Cell;

  // Context from Proxy
  gameId: Int;
  expectedServerNonce: Int;
  existingGameCell: Cell; // MUST be provided by proxy
  existingUserCell: Cell; // MUST be provided by proxy
}

struct MarkLostRequest {
  sys: SystemView;
  keys: KeysView;

  // Params
  gameSeed: Cell;
  gameSalt: Cell;
  finalGameState: Cell;
  serverSignature: Cell;

  // Context from Proxy
  gameId: Int;
  expectedServerNonce: Int;
  existingGameCell: Cell; // MUST be provided by proxy
  existingUserCell: Cell; // MUST be provided by proxy
}

// ---- Responses returned by logic to proxy ----

struct PoolDelta {
  houseBalanceDelta: Int;
  poolLiquidityDelta: Int;
}

struct NonceDelta {
  serverNonce: Int; // absolute new nonce
}

message(OP_MSG_CREATE_GAME_RESP) CreateGameResponse {
  ok: Bool;
  gameId: Int;
  pool: PoolDelta;
  nonces: NonceDelta;
  gameCell: Cell;
  userDelta: Cell;
  confirmation: Cell;
}

message(OP_MSG_CASHOUT_RESP) CashoutResponse {
  ok: Bool;
  gameId: Int;
  pool: PoolDelta;
  nonces: NonceDelta;
  updatedGameCell: Cell;
  userDelta: Cell;
  payoutMsg: Cell;
  affiliateDelta: Cell; // presence-bit + address + amount
}

message(OP_MSG_MARK_LOST_RESP) MarkLostResponse {
  ok: Bool;
  gameId: Int;
  pool: PoolDelta;
  nonces: NonceDelta;
  updatedGameCell: Cell;
  userDelta: Cell;
  confirmMsg: Cell;
}