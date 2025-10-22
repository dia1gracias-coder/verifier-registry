message TransferTicket {
    queryId: Int as uint64;
    receiver: Address;
}

message RedeemTicket {
    queryId: Int as uint64;
}

message MarketplaceTransfer {
    queryId: Int as uint64;
    previousOwner: Address;
    newOwner: Address;
}