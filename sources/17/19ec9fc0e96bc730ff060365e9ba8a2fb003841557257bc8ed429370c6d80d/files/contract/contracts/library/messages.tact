struct JettonData {
    total_supply: Int as coins; // the total number of issues jettons
    mintable: Bool;             // flag which indicates whether number of jettons can increase admin_address
    admin_address: Address;     // address of smart-contrac which control Jetton
    jetton_content: Cell;       // data in accordance to Token Data Standard #64
    jetton_wallet_code: Cell;   // code of wallet for that jetton
}

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

message DeployCountryToken {
    id: Int;
    country: String;
    content: Cell;
}
message NewCountryToken {
    address: Address;
}

const ONE_TON: Int = ton("1");