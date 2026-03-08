struct JettonData {
    totalSupply: Int as coins;
    mintable: Bool;
    owner: Address;
    content: Cell;
    walletCode: Cell;
}


struct ContractStatus {
    owner: Address;
    jettonWallet: Address;
    paused: Bool;
    maxClaimAmount: Int as uint64;
}

struct JettonWalletData {
    balance: Int;
    owner: Address;
    master: Address;
    walletCode: Cell;
}

struct JettonWalletDataRes {
    balance: Int;
    owner: Address;
    master: Address;
}

message(0xd53276db) Excesses { 
    queryId: Int as uint64;
}

message(0x97d59ca3) Deploy { }


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
    response_destination: Address?;
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

message(0xaf1ca26a) TokenUpdateContent {
    content: Cell;
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

message(0xfc708bd2) Mint {
    amount: Int;
}

message(0xe7c9c931) Claim {
    rewardId: String?;
    amount: Int as uint64;
    nonce: Int as uint64;
    deadline: Int as uint64;
    signature: Slice;
}

message(0xc53b0777) ClaimRes {
    sender :Address;
    amount: Int as uint64;
    nonce: Int as uint64;
    deadline: Int as uint64;
    signature: Slice;
    signerPubKey: Int as uint256;
    payloadHash:Int
}

message(0x58abd82f) BatchClaimItem {
    amount: Int as uint64;
    nonce: Int as uint64;
    deadline: Int as uint64;
    signature: Slice;
}

message(0x77777777) BatchClaim {
    count: Int as uint16;
    payload: Slice;
}

message(0x99999999) Upgrade {
    newCode: Cell;
}

message(0xdf88109b) Pause {
}

message(0xc7b06d35) Unpause {
}

message(0x5c491c58) SetMaxClaim {
    newMax: Int as uint64;
}

message(0xb0dd5436) RotateSigner {
    newKey: Int as uint256;
}

message(0xe1c8017c) AdminWithdraw {
    amount: Int as uint64;
}

message(0xd859dbd6) Withdraw {
    to: Address;
    amount: Int as uint64;
}


message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Cell;
}