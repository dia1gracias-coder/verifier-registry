struct NftCollectionMetadata {
    image: String;
    name: String;
    description: String;
}

// https://github.com/ton-blockchain/TEPs/blob/master/text/0062-nft-standard.md#get-methods-1
struct CollectionData {
    next_item_index: Int as uint32;
    collection_content: Cell;
    owner_address: Address;
}
