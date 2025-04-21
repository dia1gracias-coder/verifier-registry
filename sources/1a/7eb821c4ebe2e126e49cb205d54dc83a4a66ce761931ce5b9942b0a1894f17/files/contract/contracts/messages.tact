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

struct VestingSchedule {
    amount: Int;
    cliffMonths: Int;
    totalMonths: Int;
    claimed: Int;
    address: Address;
    tgeUnlock: Int;
}

struct UnlockInfo {
    name: String;
    totalAmount: Int;
    claimedAmount: Int;
    cliffEnds: Int;
    nextUnlock: Int;
    monthlyUnlock: Int;
    unlockEnds: Int;
    unlockedAmount: Int;
    tgeUnlock: Int;
}


struct UnlockDateAmount {
    time: Int;
    amount: Int;
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
    send_excess: Bool;
}

message(0xd53276db) TokenExcesses {
    query_id: Int as uint64;
}

message(0x2c76b973) ProvideWalletAddress {
    query_id: Int as uint64;
    owner_address: Address;
    include_address: Bool;
}

message(0xd1735400) TakeWalletAddress {
    query_id: Int as uint64;
    wallet_address: Address;
    owner_address: Slice as remaining;
}

message Mint {
    amount: Int;
    receiver: Address;
}

message SetTGEStartTime {
    time: Int;
}

message GetUnlockInfo {
    time: Int;
}

message UnlockSchedule {
    team: UnlockInfo;
    roundA: UnlockInfo;
    projectDev: UnlockInfo;
    marketing: UnlockInfo;
    advisors: UnlockInfo;
    marketMakers: UnlockInfo;
    kol: UnlockInfo;
}

message GetUnlockDates {
    category: String;
}
