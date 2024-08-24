import "../lib/nft/collection/messages.tact";

message Register {
    query_id: Int as uint64;
}

message MintDBlog {
    query_id: Int as uint64;
    blog_data: NftCollectionMetadata;
    d_user: Address;
}
