message CreateDeal {
    id: String;
    amount: Int as coins;
    admin: Address;
    customer: Address;
    freelancer: Address;
}
message FinishDeal {
    id: String;
}
message AdminForceEnd {
    id: String;
    receiver: Address;
}
message Deposit {
    amount: Int as coins;
}