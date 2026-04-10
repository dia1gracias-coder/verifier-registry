const JETTON_TRANSFER_GAS: coins = ton("0.04");
const MIN_MSG_VALUE_TON: coins = ton("0.1");
const MIN_MSG_VALUE_JETTON: coins = ton("0.25");  // 0.04 * 3 + 0.1 = 0.22
const MAX_CANCEL_FEE: coins = ton("0.5");

enum Err {
    Forbidden = 1000,
    OfferCompleted = 1001,
    DestroyModeNotAllowed = 1002,
    TooCloseToSwap = 1003,
    ProfitTooLow = 1004,

    InvalidSignature = 1100,
    NotJettonOffer = 1101,
    JettonWalletAlreadySet = 1102,
}
