// ===============================
// Reekt.Fun — Protocol Opcodes & Errors (shared)
// ===============================

// Storage versioning (bump when layout changes)
const STORAGE_VERSION: Int = 13;

const OP_CREATE_GAME: Int      = 0x01;
const OP_CASHOUT: Int          = 0x02;
const OP_MARK_LOST: Int        = 0x03;
const OP_REFUND: Int           = 0x04;

const OP_LOGIC_REQUEST: Int    = 0x10;  // proxy → logic wrapper
const OP_LOGIC_RESPONSE: Int   = 0x11;  // logic → proxy wrapper

const PERCENT_BASE: Int        = 10000;

// Error codes
// TVM reserves 0..255 for system/VM; keep app errors >= 256 (see docs)
// https://docs.tact-lang.org/book/gas-best-practices/#use-throwunless-over-require
const ERROR_INSUFFICIENT_FUNDS: Int      = 700;
const ERROR_INVALID_SIGNATURE: Int       = 701;
const ERROR_CONTRACT_PAUSED: Int         = 702;
const ERROR_UNAUTHORIZED: Int            = 703;
const ERROR_BET_TOO_HIGH: Int            = 704;
const ERROR_PAYOUT_TOO_HIGH: Int         = 705;
// 706 reserved; lockup enforcement removed in immediate payout design
const ERROR_GAME_NOT_FOUND: Int          = 707;
const ERROR_RESERVE_VIOLATION: Int       = 708;
const ERROR_NONCE_MISMATCH: Int          = 709;
const ERROR_SIGNATURE_EXPIRED: Int       = 710;
const ERROR_INVALID_COMMISSION: Int      = 711;
const ERROR_INVALID_RESPONSE: Int        = 712;
const ERROR_NOT_INITIALIZED: Int         = 713;
const ERROR_NO_UPGRADE_PROPOSED: Int     = 714;
const ERROR_ETA_NOT_REACHED: Int         = 715;
const ERROR_INVALID_PARAMS: Int          = 716;
const ERROR_GAME_NOT_CREATED: Int        = 717;
const ERROR_CASHOUT_FAILED: Int          = 718;
const ERROR_MARK_LOST_FAILED: Int        = 719;

// --- Message Opcodes (for cross-contract communication) ---
// These are now explicit and stable.
const OP_MSG_CREATE_GAME_REQ: Int       = 0x10000001;
const OP_MSG_CASHOUT_REQ: Int           = 0x10000002;
const OP_MSG_MARK_LOST_REQ: Int         = 0x10000003;
const OP_MSG_REFUND_REQ: Int            = 0x10000004;
const OP_MSG_CREATE_GAME_RESP: Int      = 0x20000001;
const OP_MSG_CASHOUT_RESP: Int          = 0x20000002;
const OP_MSG_MARK_LOST_RESP: Int        = 0x20000003;
const OP_MSG_REFUND_RESP: Int           = 0x20000004;

// --- Affiliate Direct Withdrawal ---
const OP_AFFILIATE_WITHDRAW_DIRECT: Int = 0xF8; // legacy-compatible value
// --- Server-signed affiliate registration (v2: binds codeHash) ---
const OP_REGISTER_AFFILIATE_V2: Int = 0xF4;

// --- Admin Operation Opcodes ---
// Must remain in 0xF00..0xFFF range to match router check
const OP_ADMIN_TOGGLE_PAUSE: Int     = 0xF00;
const OP_ADMIN_UPGRADE_LOGIC: Int    = 0xF01;
const OP_ADMIN_SET_SERVER_KEY: Int   = 0xF02;
const OP_ADMIN_ADJUST_LIMITS: Int    = 0xF03;
const OP_ADMIN_WITHDRAW_HOUSE: Int   = 0xF04;
const OP_ADMIN_WITHDRAW_POOL: Int    = 0xF05;
const OP_ADMIN_ADD_POOL_CAPITAL: Int = 0xF06;
const OP_ADMIN_MOVE_TO_POOL: Int     = 0xF07;
const OP_ADMIN_MOVE_TO_HOUSE: Int    = 0xF08;
const OP_ADMIN_PROPOSE_LOGIC_UPGRADE: Int = 0xF09;
const OP_ADMIN_ACTIVATE_LOGIC_UPGRADE: Int = 0xF0A;
const OP_ADMIN_CANCEL_LOGIC_UPGRADE: Int   = 0xF0B;
const OP_ADMIN_BAN_AFFILIATE: Int          = 0xF0C;
// Merkle-based admin ops
const OP_ADMIN_SET_AFFILIATE_ROOT: Int     = 0xF0D;
const OP_ADMIN_SET_AFF_EPOCH_ROOT: Int     = 0xF0E;
const OP_ADMIN_ROLL_AFF_EPOCH: Int         = 0xF0F;
// Games sealing
const OP_ADMIN_SET_GAMES_EPOCH_ROOT: Int   = 0xF10; // epoch + root
const OP_ADMIN_PRUNE_GAMES_BATCH: Int      = 0xF11; // ref(ids)