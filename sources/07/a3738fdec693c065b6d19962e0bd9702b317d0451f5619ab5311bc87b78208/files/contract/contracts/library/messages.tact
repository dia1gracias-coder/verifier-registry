import "./constant";
import "./struct";

message JettonMint {
    origin: Address;        // address of origin mint request (may be wallet v4)
    receiver: Address;      // address of receiver
    amount: Int;            // amount of jettons to mint
    custom_payload: Cell?;  // optional custom data
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}


message(0x0f8a7ea5) JettonTransfer {
    query_id: Int as uint64;                // arbitrary request number
    amount: Int as coins;                   // amount of jettons to transfer
    destination: Address;                   // address of the new owner of the jettons
    response_destination: Address;          // address where to send a response with confirmation of a successful transfer and the rest of the incoming message Toncoins.
    custom_payload: Cell?;                  // optional custom payload
    forward_ton_amount: Int as coins;       // the amount of nanotons to be sent to the destination address.
    forward_payload: Slice as remaining;    // optional custom data that should be sent to the destination address.
}

message(0x7362d09c) JettonTransferNotification {
    query_id: Int as uint64;                // arbitrary request number
    amount: Int as coins;                   // amount of jettons to transfer
    sender: Address;                        // address of the sender of the jettons
    forward_payload: Slice as remaining;    // optional custom payload
}

message(0x595f07bc) JettonBurn {
    query_id: Int as uint64;        // arbitrary request number
    amount: Int as coins;           // amount of jettons to burn
    response_destination: Address;  // address where to send a response with confirmation of a successful burn and the rest of the incoming message coins.
    custom_payload: Cell?;          // optional custom payload
}

message(0xd53276db) JettonExcesses {
    query_id: Int as uint64;        // arbitrary request number
}

message(0x178d4519) JettonInternalTransfer {
    query_id: Int as uint64;                // arbitrary request number
    amount: Int as coins;                   // amount of jettons to transfer
    from: Address;                          // address of the sender of the jettons 
    response_address: Address;              // address where to send a response with confirmation of a successful transfer and the rest of the incoming message coins.
    forward_ton_amount: Int as coins;       // the amount of nanotons to be sent to the destination address.
    forward_payload: Slice as remaining;    // optional custom data that should be sent to the destination address.
}

message(0x7bdd97de) JettonBurnNotification {
    query_id: Int as uint64;          // arbitrary request number
    amount: Int as coins;             // amount of jettons to burn
    sender: Address;                  // address of the sender of the jettons
    response_destination: Address;    // address where to send a response with confirmation of a successful burn and the rest of the incoming message coins.
}

struct WalletData {
    balance: Int as coins;      // amount of jettons on wallet
    owner: Address;             // address of wallet owner;
    jetton: Address;            // address of Jetton master-address
    jetton_wallet_code: Cell;   // with code of this wallet
}

// Custom Message

message Mint {
    amount: Int as coins;
    receiver: Address;
}

message AdminMint {
    country: Int;
    amount: Int as coins;
    receiver: Address;
}

message BuyToken {
    country: Int;
    amount: Int as coins;
}

message SellToken {
    country: Int;
    amount: Int as coins;
}

message BuyTokenInternal {
    amount: Int as coins;
    receiver: Address;
}

message SellTokenInternal {
    amount: Int as coins;
    seller: Address;
}

message BurnTokenInternal {
    amount: Int as coins;
    user: Address;
}

message DeployCountryToken {
    id: Int;
    country: String;
    content: Cell;
    tx_fee: Int as uint16;
    fee_wallet: Address;
}

message ChangeTransactionFee {
    country: Int;
    tx_fee: Int as uint16;
}

message ChangeFeeWallet {
    country: Int;
    fee_wallet: Address;
}

message ChangeTransactionFeeInternal {
    tx_fee: Int as uint16
}

message ChangeFeeWalletInternal {
    fee_wallet: Address;
}

// world pvp main

message RewardWinner {
    nonce: Int;
    country: Int;
    user_amount: map<Int as uint16, UserAmount>;
    length: Int as uint16;
}

message PunishLoser {
    nonce: Int;
    country: Int;
    user_amount: map<Int as uint16, UserAmount>;
    length: Int as uint16;
}