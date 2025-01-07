message Staked {
    amount:                 Int;
    staker:                 Address;
}

message LPTransfer {
    amount:                 Int;
    to:                     Address;
}

message RewardsPaid {
    user:                   Address;
    amount:                 Int;
}

message Withdrawn {
    stake:                 Int;     // Amount of tokens withdrawn
    rewards:               Int;     // Amount of rewards withdrawn
    user:                  Address; // Address of the withdrawing user
}