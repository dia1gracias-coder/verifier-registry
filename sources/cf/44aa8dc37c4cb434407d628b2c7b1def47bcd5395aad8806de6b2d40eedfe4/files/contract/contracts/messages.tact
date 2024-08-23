struct JettonData {
    total_supply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell;
    wallet_code: Cell;
}

struct JettonWalletData {
    balance: Int;
    owner: Address;
    master: Address;
    code: Cell;
}

message(0xf8a7ea5) TokenTransfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; 
}

message(0x178d4519) TokenTransferInternal {
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x7362d09c) TokenNotification {
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining;
}

message(0x595f07bc) TokenBurn {
    query_id: Int as uint64;
    amount: Int as coins;
    response_destination: Address?;
    custom_payload: Cell?;
}

message(0x7bdd97de) TokenBurnNotification {
    query_id: Int as uint64;
    amount: Int as coins;
    sender: Address;
    response_destination: Address?;
}

message(0xd53276db) TokenExcesses {
    query_id: Int as uint64;
}

message TokenUpdateContent {
    content: Cell;
}

message Mint {
}

// ==== TEP89: Jetton Wallet Discovery ====
message(0x2c76b973) ProvideWalletAddress {
    query_id: Int as uint64;
    owner_address: Address;
    include_address: Bool;
}

// take_wallet_address#d1735400 
// query_id:uint64 wallet_address:MsgAddress owner_address:(Maybe ^MsgAddress) = InternalMsgBody;
message(0xd1735400) TakeWalletAddress {
    query_id: Int as uint64;
    wallet_address: Address;
    owner_address: Slice as remaining;
}

message InitReferral {
    referrer: Address;
}

message Buy {
    tonAmount: Int;
    minOut: Int;
    referrer: Address;
    referrerDl1: Address;
    referrerDl2: Address;
    treasury: Address;
    trader: Address;
}

message BuyCall {
    tonAmount: Int;
    minOut: Int;
    referrer: Address;
    jetton: Address;    
}

message SellCall {
    referrer: Address;
    jetton: Address;
    jettonAmount: Int;
    minTonOut: Int;
}

message Sell {
    referrerDl1: Address;
    referrerDl2: Address;
    treasury: Address;
    trader: Address;
    jettonAmount: Int;
    minTonOut: Int;
    referrer: Address;
}

message RefReward {
    totalFee: Int;
    level: Int as uint8;
}

message ClaimToken {
    owner: Address;
}

message BounceRefReward {}

message CreateEvent {
    content: Cell;
    jetton: Address;
    creator: Address;
}

message CompleteEvent {
    jetton: Address;
}

message TradeEvent {
    tonAmount: Int;
    jettonAmount: Int;
    jetton: Address;
    virtualTonReserve: Int;
    virtualTokenReserve: Int;
    trader: Address;
    isBuy: Bool;
    balance: Int;
}

message ClaimEvent {
    jetton: Address;
    user: Address;
    balance: Int;
}