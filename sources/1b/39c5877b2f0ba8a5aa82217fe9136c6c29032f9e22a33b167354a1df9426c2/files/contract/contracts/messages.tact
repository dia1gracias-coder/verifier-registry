message DealDetails {
    id: Int as uint32;
    amount: Int as coins;
    admin: Address;
    customer: Address;
    freelancer: Address;
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