// NOTIFICATIONS: BEGIN

// Notifications are sent from childs to the master contract 
// to make token ops or emit logs 

message ToggleAsset {
    asset: Address;
    wallet: Address;
}

message WithdrawNotification {
    queryId: Int as uint64;
    claimId: Int as uint128;
    amount: Int as coins;
    claimableAfter: Int as int32;
    user: Address;
    asset: Address;
}

message ClaimNotification {
    queryId: Int as uint64;
    claimId: Int as uint128;
    user: Address;
    asset: Address;
    amount: Int as coins;
    // transfer part
    response_destination: Address?;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message CancelClaimNotification {
    queryId: Int as uint64;
    claimId: Int as uint128;
    user: Address;
}

// NOTIFICATIONS: END

// USERDATA: BEGIN
// Messages sent to the usersData contract

message Deposit {
    queryId: Int as uint64;
    asset: Address;
    amount: Int as coins;
}

message Withdraw {
    queryId: Int as uint64;
    claimId: Int as uint128;
    asset: Address;
    amount: Int as coins;
}

message Claim {
    queryId: Int as uint64;
    claimId: Int as uint128;
    response_destination: Address;
    forward_payload: Slice as remaining; 
    forward_ton_amount: Int as coins;
}

message CancelWithdraw {
    queryId: Int as uint64;
    claimId: Int as uint128;
}

// USERDATA: END

// EVENTS: BEGIN

message DepositEvent {
    queryId: Int as uint64;
    amount: Int as coins;
    user: Address;
    asset: Address;
}

message WithdrawEvent {
    queryId: Int as uint64;
    claimId: Int as uint128;
    amount: Int as coins;
    user: Address;
    asset: Address;
}

message ClaimEvent {
    queryId: Int as uint64;
    claimId: Int as uint128;
    isCancelled: Bool;
}

// EVENTS: END
