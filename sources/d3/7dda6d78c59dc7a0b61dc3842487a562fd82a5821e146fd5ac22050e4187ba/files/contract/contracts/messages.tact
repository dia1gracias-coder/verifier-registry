struct JettonData {
    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell;
    walletCode: Cell;
}

struct JettonWalletData {
    balance: Int;
    owner: Address;
    master: Address;
    walletCode: Cell;
}

message Mint {
    amount: Int as coins;
}

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}

message(0x178d4519) TokenTransferInternal {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}

message(0x595f07bc) TokenBurn {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    response_destination: Address;
}

message(0x7bdd97de) TokenBurnNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    response_destination: Address?;
}

message(0xd53276db) TokenExcesses {
    queryId: Int as uint64;
}

message TokenUpdateContent {
    content: Cell;
}

// ;; common

// const op::transfer = 0xf8a7ea5;
// const op::transfer_notification = 0x7362d09c;
// const op::internal_transfer = 0x178d4519;
// const op::excesses = 0xd53276db;
// const op::burn = 0x595f07bc;
// const op::burn_notification = 0x7bdd97de;

// const op::provide_wallet_address = 0x2c76b973;
// const op::take_wallet_address = 0xd1735400;

// const op::top_up = 0xd372158c;

// const error::invalid_op = 72;
// const error::wrong_op = 0xffff;
// const error::not_owner = 73;
// const error::not_valid_wallet = 74;
// const error::wrong_workchain = 333;

// ;; jetton-minter

// const op::mint = 0x642b7d07;
// const op::change_admin = 0x6501f354;
// const op::claim_admin = 0xfb88e119;
// const op::upgrade = 0x2508d66a;
// const op::change_metadata_uri = 0xcb862902;
// const op::drop_admin = 0x7431f221;
// const op::merkle_airdrop_claim = 0x0df602d6; ;; TODO

// ;; jetton-wallet
// const error::balance_error = 47;
// const error::not_enough_gas = 48;
// const error::invalid_message = 49;
// const error::airdrop_already_claimed = 54;
// const error::airdrop_not_ready = 55;
// const error::airdrop_finished = 56;
// const error::unknown_custom_payload = 57;
// const error::non_canonical_address = 58;
