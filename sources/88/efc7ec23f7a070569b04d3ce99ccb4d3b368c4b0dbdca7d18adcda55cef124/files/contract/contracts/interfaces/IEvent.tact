message BuyTickets {
    ticketTypes: Array;
}

message WithdrawRoyalty {
    //amount: Int;
}

message WithdrawRoyaltyFor {
    collector: Address;
    //amount: Int; 
}

message FillOrder {
    queryId: Int as uint64;
    signedOrder: Cell;
    signature: Cell;
    publicKey: Int;
    firstOwner: Address;
}

message CancelOrder {
    queryId: Int as uint64;
    signedOrder: Cell;
    signature: Cell;
    publicKey: Int;
}