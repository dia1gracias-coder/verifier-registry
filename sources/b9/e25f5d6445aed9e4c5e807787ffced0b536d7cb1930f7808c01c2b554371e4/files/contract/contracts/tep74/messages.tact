/// @dev Return type of the JettonMaster storage variables
struct JettonData {
    total_supply:           Int as coins;   // the total number of issues jettons
    mintable:               Bool;           // flag which indicates whether number of jettons can increase admin_address
    admin:                  Address;        // address of smart-contrac which control Jetton
    content:                Cell;           // data in accordance to Token Data Standard #64
    wallet_code:            Cell;           // code of the wallet for that jetton
}

/// @dev Return type of the wallet Sorage
struct JettonWalletData {
    balance: Int;
    owner: Address;
    master: Address;
    code: Cell;
}

message(0xf8a7ea5) TokenTransfer {
    query_id:               Int as uint64;
    amount:                 Int as coins;
    sender:                 Address;
    response_destination:   Address?;
    custom_payload:         Cell?;
    forward_ton_amount:     Int as coins;
    forward_payload:        Slice as remaining; 
}

message(0x178d4519) TokenTransferInternal {
    query_id:               Int as uint64;
    amount:                 Int as coins;
    from:                   Address;
    response_destination:   Address?;
    forward_ton_amount:     Int as coins;
    forward_payload:        Slice as remaining;
}

message(0x7362d09c) TokenNotification {
    query_id:               Int as uint64;
    amount:                 Int as coins;
    from:                   Address;
    forward_payload:        Slice as remaining;
}

message(0x595f07bc) TokenBurn {
    query_id:               Int as uint64;
    amount:                 Int as coins;
    response_destination:   Address?;
    custom_payload:         Cell?;
}

message(0x7bdd97de) TokenBurnNotification {
    query_id:               Int as uint64;
    amount:                 Int as coins;
    sender:                 Address;
    response_destination:   Address?;
}

message(0xd53276db) TokenExcesses {
    query_id:               Int as uint64;
}

message TokenUpdateContent {
    content:                Cell;
}

// ==== TEP89: Jetton Wallet Discovery ====
message(0x2c76b973) ProvideWalletAddress {
    query_id:               Int as uint64;
    owner_address:          Address;
    include_address:        Bool;
}

// take_wallet_address#d1735400 
// query_id:uint64 wallet_address:MsgAddress owner_address:(Maybe ^MsgAddress) = InternalMsgBody;
message(0xd1735400) TakeWalletAddress {
    query_id:               Int as uint64;
    wallet_address:         Address;
    owner_address:          Slice as remaining;
}

// =======

message (0x89b71d09) JettonMint {
    origin:                 Address;    // address of origin mint request (may be wallet v4)
    receiver:               Address;    // address of receiver
    amount:                 Int;        // amount of jettons to mint
    custom_payload:         Cell?;      // optional custom data
    forward_ton_amount:     Int as coins;
    forward_payload:        Slice as remaining;
}

// =======
// Used for creating a staking position for the new owner of the LP token
message (0xba07912d) UpdateDeposits {
    amount:                 Int;        // number of transferred LP tokens
    sender:                 Address;    // address of the old owner
    receiver:               Address;    // address of the new owner
}