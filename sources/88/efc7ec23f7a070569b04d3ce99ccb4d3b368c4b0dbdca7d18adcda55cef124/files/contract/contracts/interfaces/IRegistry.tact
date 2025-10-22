message CreateEvent {
    eventName: String;
    eventUri: String;
    ticketAmounts: Array;
    ticketPrices: Array;
    endTimestamp: Int as uint64;
    sellRoyaltyCollectors: RoyaltyCollectorArray;
    resellRoyaltyCollectors: RoyaltyCollectorArray;
}