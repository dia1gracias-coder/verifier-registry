import "../lib/nft/collection/messages.tact";

message InitializeDProfile {
    query_id: Int as uint64;
    d_user: Address;
}

message CreateDBlog {
    query_id: Int as uint64;
    blog_data: NftCollectionMetadata;
}

message SetCreatedDBlog {
    query_id: Int as uint64;
    blog_seq_no: Int;
}

message ChangeUsername {
    query_id: Int as uint64;
    new_username: String?;
}

message GetSubscribed {
    query_id: Int as uint64;
    d_blog: Address;
}

message GetUnsubscribed {
    query_id: Int as uint64;
    d_blog: Address;
}
