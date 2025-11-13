// General
const MAX_SUPPLY: int = 13800000000000000000;
const DECIMALS: int = 9;
const MINT_BUFFER: int       = ton("0.01");
const MIN_DEPLOY_GRAMS: int  = ton("0.02");
const MAX_DEPLOY_GRAMS: int  = ton("0.25");
const MASTER_FEE_BUFFER: int = ton("0.02");
const WALLET_DEPLOY_GRAMS: int = ton("0.03"); // Balanced for 0.04 TON from minter.org
const FORWARD_TON_MAX: int = ton("1");  // or higher if you like
const DEFAULT_FORWARD_AMOUNT: int = ton("0.001"); // Default forward for mint notifications
const MIN_FORWARD_AMOUNT: int = ton("0.001"); // Minimum forward to ensure notification executes
const PROVIDE_ADDRESS_GAS: int = ton("0.01");  // Min gas for wallet discovery

// Safety / UX - Reference project style (minimal constants)
const LOCAL_RESERVE: int = ton("0.01"); // minTonsForStorage equivalent
const MIN_RETURN: int    = ton("0.01"); // gasConsumption equivalent
const OUTFLOW_BASE: int = ton("0.01"); // Minimal base, SendRemainingValue handles the rest
const EXEC_BUFFER: int  = ton("0.005"); // Minimal buffer for dynamic calculation
const EXEC_ONLY_GRAMS: int = ton("0.03"); // Reduced for wallet operations

// Version control
const M_VERSION_MAJOR: int = 1;
const M_VERSION_MINOR: int = 0;
const M_VERSION_PATCH: int = 0;

const W_VERSION_MAJOR: int = 1;
const W_VERSION_MINOR: int = 0;
const W_VERSION_PATCH: int = 0;

// Operation codes (TEP-74 + Extensions)
enum OpCode: uint32 {
    // TEP-74 Standard Operations
    TRANSFER = 0x0f8a7ea5,
    TRANSFER_NOTIFICATION = 0x7362d09c,
    INTERNAL_TRANSFER = 0x178d4519,
    EXCESSES = 0xd53276db,
    BURN = 0x595f07bc,
    BURN_NOTIFICATION = 0x7bdd97de,  // emitted by master

    // Admin Operations
    TRANSFER_ADMIN = 3,               // legacy small int
    REVOKE_ADMIN = 0x6d8e888c,
    MINT = 21,                        // 0x15 - used by minter.org
    CHANGE_CONTENT = 4,
    FREEZE_MINTING = 0x1b6a7d12,
    SET_DEPLOY_GRAMS = 0x4a6fbd23,

    // Code Upgrade Operations
    SET_WALLET_CODE = 0x5a3f9c01,     // master -> wallet code ref update
    UPGRADE_CODE = 0x7a1e3c55,        // in-place code upgrade (setCodePostponed)

    // TEP-89: Jetton Wallet Discovery (DeDust/DEX integration)
    PROVIDE_WALLET_ADDRESS = 0x2c76b973,
    TAKE_WALLET_ADDRESS = 0xd1735400
}

// Wallet errors (700-710 range)
enum WalletError: uint16 {
    NOT_OWNER = 700,
    NOT_VALID_WALLET = 701,
    INSUFFICIENT_BALANCE = 702,
    INSUFFICIENT_GAS = 703,
    INVALID_AMOUNT = 704,
    NOT_ENOUGH_TON = 705,
    NULL_RESPONSE = 706,
    SELF_TRANSFER = 707,
    UNKNOWN_OP = 708,
    EXTERNAL_DISABLED = 709,
    INVALID_ADDRESS = 710
}

// Master errors (720-739 range, plus high codes)
enum MasterError: uint16 {
    NOT_ADMIN = 720,
    INSUFFICIENT_GAS = 721,
    INVALID_AMOUNT = 722,
    MAX_SUPPLY_EXCEEDED = 723,
    UNAUTHORIZED_WALLET = 724,
    INVALID_BURN_AMOUNT = 725,
    SUPPLY_UNDERFLOW = 726,
    FORWARD_TOO_LARGE = 727,
    MINT_FROZEN = 728,
    INVALID_ADDRESS = 729,
    UNKNOWN_OP = 0x9001,
    CODE_LOCKED = 0x9002
}
