import "@stdlib/deploy";

//////////////////////////////
// Project-wide constants
//////////////////////////////

// PRMD token constants
const MAX_SUPPLY: Int = ton("1000000000"); // 1 billion tokens (9 decimals)
const EMISSION_RATE: Int = ton("1"); // 1 token per second (9 decimals)
const FORWARD_AMOUNT: Int = ton("0.005");

// === TEP-74 jetton gas constants (mirrors the reference tact-lang/jetton) ===
// Minimum TON a jetton wallet/master keeps on its balance so it never freezes.
const minTonsForStorage: Int = ton("0.01");
// Gas units consumed by a single transfer / burn compute phase (used to assert
// the sender attached enough TON; intentionally generous).
const gasForTransfer: Int = 10500;
const gasForBurn: Int = 6700;
// Approximate state-init size of a jetton wallet, used to price the forward fee
// that deploys the destination wallet on first transfer. Real values are below
// these bounds; over-estimating only makes the attached-TON check slightly stricter.
const walletStateInitCells: Int = 30;
const walletStateInitBits: Int = 20000;

// === Jetton master rent self-refill ===
// Approximate full account size of the master (code + data + content),
// over-estimated: a bigger estimate only asks for the refill a bit earlier
// and tops up a bit more.
const masterStorageCells: Int = 100;
const masterStorageBits: Int = 60000;
// The master keeps enough TON to pay its storage rent for this long.
const MASTER_RENT_TARGET_SECONDS: Int = 315360000; // 10 years
// Below this horizon the master starts signalling its minter for a refill.
// High enough that the master is still far from freezing (and still solvent
// enough to fund the signal itself) when the alert fires.
const MASTER_RENT_ALERT_SECONDS: Int = 220752000; // 7 years
// TON attached to the refill request: pays the minter's compute so the
// request is processable even when the minter gets no other traffic.
const MASTER_RENT_SIGNAL_VALUE: Int = ton("0.02");
// Do not repeat the signal more often than this, even if the refill has not
// arrived yet — hot traffic must not turn into request spam.
const MASTER_RENT_SIGNAL_COOLDOWN: Int = 86400; // 1 day

// Referral system constants
const REFERRAL_LEVELS: Int = 5; // 5 referral levels
const REFERRAL_SHARE_PERCENT: Int = 20; // each level takes 20% of the remaining amount
const OWNER_REFERRER_KEY: Int = 0; // owner's key, used as the default referrer
// Maximum number of digits parsed from a text referral comment. Invite keys
// travel as uint64 (KeyPointer ids), so anything longer than 20 digits (or
// above the uint64 range) is not a key — the parser rejects it and the buy
// falls back to the default referrer.
const MAX_REFERRER_KEY_DIGITS: Int = 20;
const MAX_REFERRER_KEY: Int = 18446744073709551615; // 2^64 - 1

// Lottery constants
const MIN_LOTTERY_ENTRY: Int = ton("1"); // 1 TON minimum entry
// Gifted tickets: budget of the on-chain KeyPointer lookup, paid by the
// lottery bank (round-trips with the answer; the change returns to the
// bank), and the pending-gift queue bound.
const GIFT_KEY_LOOKUP_VALUE: Int = ton("0.05");
const MAX_PENDING_GIFTS: Int = 64;
const LOTTERY_WINNER_SHARE: Int = 20; // winner receives 20% of the bank
const LOTTERY_OWNER_PERCENT: Int = 5; // owner receives 5% of the bank
const LOTTERY_ROUND_DURATION: Int = 60 * 60 * 24 * 7; // 7 days


// Contract storage horizon
const STORAGE_PERIOD: Int = 10 * 365 * 24 * 3600; // 10 years of storage

// Basechain gas limit (gas_limit = 1M = 0.4 TON)
const MAX_GAS_PER_TX: Int = 1000000;

// Gas budget for a single draw chunk (leaves headroom for finalization)
const DRAW_GAS_CHUNK_LIMIT: Int = 600000;

// Value of the self-message that starts/continues a draw (full gas budget for the TX)
const DRAW_TRIGGER_VALUE: Int = ton("0.4");

// === Amortized pruning of inactive users ===
// How long a user may stay inactive before becoming a candidate for removal.
const ACTIVITY_TTL: Int = 365 * 24 * 3600; // 1 year without activity
// How many dense-index slots are checked per incoming buy. Pruning is amortized
// over the contract's lifetime (continuous pruning) instead of one yearly sweep:
// the ring cursor advances on each buy and inactive users are removed inline. A
// value > 1 guarantees the scan outpaces registration (<= 1 new user per buy),
// keeping state pruned without an expensive spike.
const PRUNE_SCAN_PER_TX: Int = 4;

// Minimum physical TON balance the contract keeps.
const MIN_CONTRACT_BALANCE: Int = ton("0.05");

// === Draw watchdog (resumable process via self-messages) ===
// Seconds without progress on the next draw chunk before the self-message chain
// is considered stalled. While chunks run, lastProgressTime is updated every
// block (~5s), so the threshold is generous to avoid false positives on a long
// legitimate draw, while still letting an incoming transaction restart a broken
// chain. (Pruning is now amortized and uses no self-messages, so it needs no watchdog.)
const STALL_TIMEOUT: Int = 600; // 10 minutes
