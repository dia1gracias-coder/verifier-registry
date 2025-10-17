// General
const MAX_SUPPLY: int = 13800000000000000000;
const DECIMALS: int = 9;
const MINT_BUFFER: int       = ton("0.01");
const MIN_DEPLOY_GRAMS: int  = ton("0.02");
const MAX_DEPLOY_GRAMS: int  = ton("0.25");
const MASTER_FEE_BUFFER: int = ton("0.02");
const WALLET_DEPLOY_GRAMS: int = ton("0.03"); // Balanced for 0.04 TON from minter.org
const FORWARD_TON_MAX: int     = ton("0.2");
const DEFAULT_FORWARD_AMOUNT: int = ton("0.001"); // Default forward for mint notifications

// Version control
const M_VERSION_MAJOR: int = 1;
const M_VERSION_MINOR: int = 0;
const M_VERSION_PATCH: int = 0;

const W_VERSION_MAJOR: int = 1;
const W_VERSION_MINOR: int = 0;
const W_VERSION_PATCH: int = 0;

// Ops
const OP_TRANSFER: int                = 0x0f8a7ea5;
const OP_TRANSFER_NOTIFICATION: int   = 0x7362d09c;
const OP_INTERNAL_TRANSFER: int       = 0x178d4519;
const OP_EXCESSES: int                = 0xd53276db;
const OP_BURN: int                    = 0x595f07bc;
const OP_BURN_NOTIFICATION: int       = 0x7bdd97de;  // emitted by master
const OP_SET_WALLET_CODE: int         = 0x5a3f9c01;  // master -> wallet code ref update
const OP_UPGRADE_CODE: int            = 0x7a1e3c55;  // in-place code upgrade (setCodePostponed)
const OP_TRANSFER_ADMIN: int          = 3;          // admin ops (legacy small ints ok)
const OP_REVOKE_ADMIN: int            = 0x6d8e888c;  // dedicated admin revocation
const OP_MINT: int                    = 21;  // 0x15 - used by minter.org
const OP_CHANGE_CONTENT: int          = 4;
const OP_FREEZE_MINTING: int          = 0x1b6a7d12;
const OP_SET_DEPLOY_GRAMS: int        = 0x4a6fbd23;

// Wallet errors
const W_ERR_NOT_OWNER: int            = 700;
const W_ERR_NOT_VALID_WALLET: int     = 701;
const W_ERR_INSUFFICIENT_BALANCE: int = 702;
const W_ERR_INSUFFICIENT_GAS: int     = 703;
const W_ERR_INVALID_AMOUNT: int       = 704;
const W_ERR_NOT_ENOUGH_TON: int       = 705;
const W_ERR_NULL_RESPONSE: int        = 706;
const W_ERR_SELF_TRANSFER: int        = 707;
const W_ERR_UNKNOWN_OP: int           = 708;
const W_ERR_EXTERNAL_DISABLED: int    = 709;

// Master errors (720–739)
const M_ERR_NOT_ADMIN: int            = 720;
const M_ERR_INSUFFICIENT_GAS: int     = 721;
const M_ERR_INVALID_AMOUNT: int       = 722;
const M_ERR_MAX_SUPPLY_EXCEEDED: int  = 723;
const M_ERR_UNAUTHORIZED_WALLET: int  = 724;
const M_ERR_INVALID_BURN_AMOUNT: int  = 725;
const M_ERR_SUPPLY_UNDERFLOW: int     = 726;
const M_ERR_FORWARD_TOO_LARGE: int    = 727;
const M_ERR_MINT_FROZEN: int          = 728;
const M_ERR_INVALID_ADDRESS: int      = 729;
const M_ERR_UNKNOWN_OP: int = 0x9001;
const M_ERR_CODE_LOCKED: int = 0x9002;

// Safety / UX - Reference project style (minimal constants)
const LOCAL_RESERVE: int = ton("0.01"); // minTonsForStorage equivalent
const MIN_RETURN: int    = ton("0.01"); // gasConsumption equivalent
const OUTFLOW_BASE: int = ton("0.01"); // Minimal base, SendRemainingValue handles the rest
const EXEC_BUFFER: int  = ton("0.005"); // Minimal buffer for dynamic calculation
const EXEC_ONLY_GRAMS: int = ton("0.03"); // Reduced for wallet operations
