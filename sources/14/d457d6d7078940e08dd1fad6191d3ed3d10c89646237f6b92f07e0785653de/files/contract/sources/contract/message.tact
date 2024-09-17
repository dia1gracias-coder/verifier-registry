
message TokensDeposited {
    user: Address;
    amount: Int as uint256;
}

message TokensClaimedEvent {
    user: Address;
    amount: Int as uint256;
}

message UpdateVestingSchedules {
    _vestingStartTime: Int as uint256;
    _vestingDuration: Int as uint256;
    _vestingInterval: Int as uint256;
    _cliffDuration: Int as uint256;
    _cliffPercentage: Int as uint256;
}

message WithdrawToken {
    _tokenAmount: Int as coins;
    _token: Address;
}

message ICOJetton {
    _token: Address;
}

message Claim {
    _token: Address;
}

//ICOJetton
message AddToken {
    tokenAmount: Int as coins;
    tokenAddr: Address;
    add1: Address;
    add2: Address;
}

struct User {
    investedAmount: Int as uint256;
    claimedTokens: Int as uint256;
    investedTimestamp: Int as uint256;
    lastClaimedTimestamp: Int as uint256;
}

message TransferEvent {
    sender_address: Address;
    jetton_amount: Int as coins;
    score: Int as uint128;
}


message TokenTransfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

