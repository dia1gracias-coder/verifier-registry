// Events
message(0xa3877d65) LogEventMintRecord {
    minter: Address;
    itemId: Int;
    generateNumber: Int;
}

// Methods
message(0x88bdee97) Mint {
    queryId: Int as uint64;
    owner: Address;
    signature: Slice;
    collectorPoints: Int as uint16;
    tokenIndex: Int as uint64;
}

message(0x1f2f145e) ChangeOwner {
    queryId: Int as uint64;
    newOwner: Address;
}

message(0x4e73744b) ChangePaymentKey {
    queryId: Int as uint64;
    newPaymentPublicKey: Int as uint256;
}

struct CollectionData {
    nextItemIndex: Int;
    collectionContent: Cell;
    ownerAddress: Address;
}