message DealDetails {
    admin: Address;
    customer: Address;
    freelancer: Address;
    amount: Int as coins;
}
message Info {
    id: Int as uint32;
    admin: Address;
    customer: Address;
    freelancer: Address;
    amount: Int as coins;
}

message AddAdditionalValue {
    amount: Int as coins;
}
message FinishDeal {
    dealId: Int as uint32;
}
message AdminForceEnd {
    dealId: Int as uint32;
    receiver: Address;
}
message Deposit {
    amount: Int as coins;
}