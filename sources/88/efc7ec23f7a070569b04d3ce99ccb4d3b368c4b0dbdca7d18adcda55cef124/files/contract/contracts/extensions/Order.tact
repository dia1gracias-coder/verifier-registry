struct Order {
    maker: Address;
    eventAddress: Address;
    ticketId: Int as uint32;
    ticketType: Int as uint8;
    ticketPrice: Int as uint64;
    salt: Int as uint128;
    listingTime: Int as uint64;
    expirationTime: Int as uint64;
}

struct SignedOrder {
    prefix: Int as uint32;
    schemaHash: Int as uint32;
    timestamp: Int as uint64;
    userAddress: Address;
    domain: Cell;
    order: Cell;
}