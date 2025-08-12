// ===============================
// Reekt.Fun — Protocol Opcodes & Errors (shared)
// ===============================

// Storage versioning (bump when layout changes)
const STORAGE_VERSION: Int = 2;

const OP_CREATE_GAME: Int      = 0x01;
const OP_CASHOUT: Int          = 0x02;
const OP_MARK_LOST: Int        = 0x03;

const OP_LOGIC_REQUEST: Int    = 0x10;  // proxy → logic wrapper
const OP_LOGIC_RESPONSE: Int   = 0x11;  // logic → proxy wrapper

const PERCENT_BASE: Int        = 10000;

// Error codes
const ERROR_INSUFFICIENT_FUNDS: Int      = 100;
const ERROR_INVALID_SIGNATURE: Int       = 101;
const ERROR_CONTRACT_PAUSED: Int         = 102;
const ERROR_UNAUTHORIZED: Int            = 103;
const ERROR_BET_TOO_HIGH: Int            = 104;
const ERROR_PAYOUT_TOO_HIGH: Int         = 105;
const ERROR_LOCKUP_ACTIVE: Int           = 106;
const ERROR_GAME_NOT_FOUND: Int          = 107;
const ERROR_RESERVE_VIOLATION: Int       = 108;
const ERROR_NONCE_MISMATCH: Int          = 110;
const ERROR_SIGNATURE_EXPIRED: Int       = 111;
const ERROR_INVALID_COMMISSION: Int      = 121;
const ERROR_INVALID_RESPONSE: Int        = 118;

// --- Message Opcodes (for cross-contract communication) ---
// These are now explicit and stable.
const OP_MSG_CREATE_GAME_REQ: Int  = 0x10000001;
const OP_MSG_CASHOUT_REQ: Int      = 0x10000002;
const OP_MSG_MARK_LOST_REQ: Int    = 0x10000003;
const OP_MSG_CREATE_GAME_RESP: Int = 0x20000001;
const OP_MSG_CASHOUT_RESP: Int     = 0x20000002;
const OP_MSG_MARK_LOST_RESP: Int   = 0x20000003;

// --- Affiliate Direct Withdrawal ---
const OP_AFFILIATE_WITHDRAW_DIRECT: Int = 0xF8; // legacy-compatible value

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