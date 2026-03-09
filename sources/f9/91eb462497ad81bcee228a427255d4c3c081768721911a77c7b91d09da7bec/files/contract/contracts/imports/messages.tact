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

message Excesses { 
    queryId: Int as uint64;
}

message Deploy { }

message SetJettonWallet {
    jettonWallet : Address
}


message TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}


message TokenTransferInternal {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}

message TokenNotification {
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

message TokenBurnNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    response_destination: Address?;
}
message TokenExcesses {
    queryId: Int as uint64;
}

message TokenUpdateContent {
    content: Cell;
}

// ==== TEP89: Jetton Wallet Discovery ====
message ProvideWalletAddress {
    query_id: Int as uint64;
    owner_address: Address;
    include_address: Bool;
}

// take_wallet_address#d1735400 
// query_id:uint64 wallet_address:MsgAddress owner_address:(Maybe ^MsgAddress) = InternalMsgBody;
message TakeWalletAddress {
    query_id: Int as uint64;
    wallet_address: Address;
    owner_address: Slice as remaining;
}

message Mint {
    amount: Int;
}

message Claim {
    rewardId: String?;
    amount: Int as uint64;
    nonce: Int as uint64;
    deadline: Int as uint64;
    signature: Slice;
}

message ClaimRes {
    sender :Address;
    amount: Int as uint64;
    nonce: Int as uint64;
    deadline: Int as uint64;
    signature: Slice;
    signerPubKey: Int as uint256;
    payloadHash:Int
}

message BatchClaimItem {
    amount: Int as uint64;
    nonce: Int as uint64;
    deadline: Int as uint64;
    signature: Slice;
}

message BatchClaim {
    count: Int as uint16;
    payload: Slice;
}

message Upgrade {
    newCode: Cell;
}

message Pause {
}

message Unpause {
}

message SetMaxClaim {
    newMax: Int as uint64;
}

message RotateSigner {
    newKey: Int as uint256;
}

message AdminWithdraw {
    amount: Int as uint64;
}

message Withdraw {
    to: Address;
    amount: Int as uint64;
}


message JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Cell;
}