import "../lib/nft/item/messages.tact";

message InitializeDPost {
    query_id: Int as uint64;
    init_nft_options: InitializeNftOptions;
    reply_to: Address?;
}

message EditDPost {
    query_id: Int as uint64;
    new_metadata: NftMetadata;
}

message CreateDPostReplyLink {
    query_id: Int as uint64;
    reply_blog_address: Address;
    reply_index: Int as uint8;
    reply_author: Address;
}

struct DPostInfo {
    blog_address: Address;
    id: Int;
    owner: Address;
    nft_content: NftMetadata;
    created_at: Int as uint64;
    edited_at: Int? as uint64;
    replied_to: Address?;
    replies_count: Int as uint8;
}
