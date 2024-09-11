import "./messages";

message DeployCountryTokenEvent {
    id: Int;
    country: String;
    content: Cell;
    tx_fee: Int as uint16;
    fee_wallet: Address;
    timestamp: Int as uint32;
}

message RewardWinnerEvent {
    nonce: Int;
    country: Int;
    user_amount: map<Int as uint16, UserAmount>;
    timestamp: Int as uint32;
}

message PunishLoserEvent {
    nonce: Int;
    country: Int;
    user_amount: map<Int as uint16, UserAmount>;
    timestamp: Int as uint32;
}

message ChangeTransactionFeeEvent {
    country: Int;
    tx_fee: Int as uint16;
    timestamp: Int as uint32;
}

message ChangeFeeWalletEvent {
    country: Int;
    fee_wallet: Address;
    timestamp: Int as uint32;
}

message BuyTokenEvent {
    country: Int;
    amount: Int as coins;
    timestamp: Int as uint32;
}

message SellTokenEvent {
    country: Int;
    amount: Int as coins;
    timestamp: Int as uint32;
}
