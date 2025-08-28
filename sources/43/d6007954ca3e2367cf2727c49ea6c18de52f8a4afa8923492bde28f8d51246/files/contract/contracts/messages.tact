message(0x1674b0a0) Mint {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    notification: Int as coins;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0xf8a7ea5) Transfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x178d4519) InternalTransfer {
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x7362d09c) TransferNotification {
    query_id: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forward_payload: Slice as remaining;
}

message(0x05138d91) NftOwnershipAssigned {
    query_id: Int as uint64;
    prev_owner: Address;
    forward_payload: Slice as remaining;
}

message(0x6f89f5e3) SbtRevoke {
    query_id: Int as uint64;
}

struct Honeypot {
    address: Address;
    amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0xabcdef13) Claim {
    query_id: Int as uint64;
    honeypots: map<Int, Honeypot>;
    forward_payload: Slice as remaining;
}

message(0xabcdef24) DeployHoneypot {
    query_id: Int as uint64;
    master: Address;
}

message(0xabcd3f13) Deposit {
    query_id: Int as uint64;
}

message(0xabcd2f13) Withdraw {
    query_id: Int as uint64;
    amount: Int as coins;
}

message(0xabcd1f13) WithdrawAll {
    query_id: Int as uint64;
}

message(0xabcd0f13) WithdrawTokens {
    query_id: Int as uint64;
    amount: Int as coins;
    token_wallet: Address;
    forward_payload: Slice as remaining;
}