message PromoteToGuard {
    address: Address;
}

message RevokeGuard {
    address: Address;
}

message SetRoundReward {
    amount: Int as coins;
}
