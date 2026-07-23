message(1) MintNft {
    query_id: Int as uint64;
    item_index: Int as uint64;
    content: Cell;
}

message(2) ChangeCollectionOwner {
    query_id: Int as uint64;
    owner: Address;
}

message(3) ChangeRoyaltyDestination {
    query_id: Int as uint64;
    royalty_destination: Address;
}

message(4) UpdateCollectionContent {
    query_id: Int as uint64;
    collection_meta_content: Cell;
    common_content: Cell;
}

message(5) CollectionUpdateItemContent {
    query_id: Int as uint64;
    item_index: Int as uint64;
    individual_content: Cell;
}

message(6) ItemUpdateContent {
    query_id: Int as uint64;
    individual_content: Cell;
}
