message Transfer{
    query_id: Int as uint64;
    new_owner: Address;
}

message CreateCollection{
    id: Int;
    name: String;
    supply: Int;
}

message Mint{
    query_id: Int as uint64;
    mintAddress: Address;
}

struct CollectionData{
    next_item_index: Int;
    collection_content: Cell;
    owner_address: Address;
}

struct ItemData{
    owner: Address;
    collection_address: Address;
    item_index: Int;
    individual_content: Cell;
}

// struct CollectionMetaData {
//    image: String;
//    name: String;
//    description: String;
//    social_links: String [];
// }