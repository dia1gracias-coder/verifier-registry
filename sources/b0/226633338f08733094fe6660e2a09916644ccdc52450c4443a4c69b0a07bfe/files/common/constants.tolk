tolk 1.4.1

// Wallet permission states. The canonical address-derivation template always
// uses STATUS_BLOCKED; STATUS_ALLOWED is reachable only via the minter.
const STATUS_BLOCKED = 0;
const STATUS_ALLOWED = 1;

// Custom op codes (namespaced 0x7463_00xx, "tg"). Standard TEP-74 op codes live
// as struct prefixes in messages.tolk. Keep these in sync with wrappers/constants.ts.
const OP_MINT = 0x74630001;
const OP_ACTIVATE_WALLET = 0x74630002;
const OP_BLOCK_WALLET = 0x74630003;
const OP_SET_WALLET_STATUS = 0x74630004;
const OP_CHANGE_ADMIN = 0x74630005;
const OP_CHANGE_CONTENT = 0x74630006;
const OP_SET_MINTING_ENABLED = 0x74630007;
const OP_SET_GLOBAL_PAUSE = 0x74630008;
const OP_CHANGE_TREASURY_OWNER = 0x74630009;

// Gas / storage reserves.
const MIN_TONS_FOR_STORAGE = ton("0.01");
const GAS_CONSUMPTION = ton("0.011");
