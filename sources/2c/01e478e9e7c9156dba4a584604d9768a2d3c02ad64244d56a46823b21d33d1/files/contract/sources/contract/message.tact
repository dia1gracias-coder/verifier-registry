
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

message DepositTokens {
    _amount : Int as uint256;
    _depositToken: Address;
}

message WithdrawToken {
    _tokenAmount: Int as uint256;
    _token: Address;
}

message AddToken {
    tokenAmount: Int as uint256;
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

