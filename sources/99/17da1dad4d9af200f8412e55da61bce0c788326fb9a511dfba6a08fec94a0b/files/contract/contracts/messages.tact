message(1) MintNft {
    query_id: Int as uint64;
    item_index: Int as uint64;
    amount: Int as coins;
    content: Cell;
}

message(3) ChangeCollectionOwner {
    query_id: Int as uint64;
    new_owner: Address;
}
