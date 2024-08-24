import "../lib/nft/item/messages.tact";
import "../lib/nft/collection/messages.tact";



message InitializeDBlog {
    query_id: Int as uint64;
    metadata: NftCollectionMetadata;
    treasury_address: Address;
    owner_address: Address;
    d_profile: Address;
}

message EditBlogMetadata {
    query_id: Int as uint64;
    new_metadata: NftCollectionMetadata;
}

message MintDPost {
    query_id: Int as uint64;
    post_data: NftMetadata;
    reply_to: Address?;
}

struct BlogInfo {
    id: Int as uint32;
    master_contract: Address;
    owner: Address;
    collection_content: NftCollectionMetadata;
    is_initialized: Bool;
    created_at: Int as uint64;
}

message GetNotifiedAboutNewSubscription {
    query_id: Int as uint64;
    d_user: Address;
}

message GetNotifiedAboutLostSubscription {
    query_id: Int as uint64;
    d_user: Address;
}
