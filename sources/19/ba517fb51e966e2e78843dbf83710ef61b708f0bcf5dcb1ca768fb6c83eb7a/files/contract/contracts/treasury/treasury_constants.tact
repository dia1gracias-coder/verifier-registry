import "../constants";

const ERR_PAUSED:       Int = 700;
const ERR_SIG_INVALID:  Int = 701;
const ERR_EXPIRED:      Int = 702;
const ERR_BAD_NONCE:    Int = 703;
const ERR_BAD_CONTRACT: Int = 704;
const ERR_MIN_AMOUNT:   Int = 705;
const ERR_MAX_AMOUNT:   Int = 706;

// TON to attach when asking the wallet to transfer out
const TREASURY_SEND_VALUE: Int = GasTransfer + GasNotification + GasExcesses;

// Mode: keep simple & safe; pay fwd fees separately
const TREASURY_SEND_MODE: Int = SendPayGasSeparately;
