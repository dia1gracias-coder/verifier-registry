tolk 1.3

// Error codes. Stay >= 256 (TVM reserves 0-127, Tolk reserves 128-255).
// Each value is unique across both contracts to make debugging unambiguous.

const ERR_NOT_OWNER: int = 256
const ERR_OWNER_DROPPED: int = 257
const ERR_NOT_NEXT_OWNER: int = 258
const ERR_NO_PENDING_OWNER: int = 259

const ERR_NOT_ADMIN_PUBKEY: int = 270
const ERR_INVALID_SIGNATURE: int = 271
const ERR_DEADLINE_EXPIRED: int = 272
const ERR_ADMIN_ALREADY_EXISTS: int = 273
const ERR_ADMIN_NOT_FOUND: int = 274

const ERR_GAME_ALREADY_EXISTS: int = 290
const ERR_GAME_NOT_ACTIVE: int = 291
const ERR_NOT_GAME_PLAYER: int = 292
const ERR_NOT_FROM_MASTER: int = 293
const ERR_NOT_FROM_GAME: int = 294
const ERR_INVALID_GAME_ADDR: int = 295
const ERR_SEED_HASH_MISMATCH: int = 296

const ERR_INSUFFICIENT_VALUE: int = 310
const ERR_INSUFFICIENT_BALANCE: int = 311
const ERR_PAYOUT_OVERFLOW: int = 312

const ERR_JETTON_NOT_ACCEPTED: int = 330
const ERR_FAKE_JETTON_WALLET: int = 331

const ERR_NO_PENDING_UPGRADE: int = 350
const ERR_UPGRADE_TOO_EARLY: int = 351

// 0xFFFF is the canonical "wrong opcode" error in TON.
const ERR_WRONG_OPCODE: int = 0xFFFF
