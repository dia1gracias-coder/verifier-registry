struct NftMetadataAttribute {
    trait_type: String;
    value: String;
}

struct NftMetadata {
    name: String;
    description: String;
    image: String;
}

struct InitializeNftOptions {
    owner: Address;
    individual_content: NftMetadata;
}

message(0x5fcc3d14) Transfer {
    query_id: Int as uint64;
    new_owner: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x05138d91) OwnershipAssigned{
    query_id: Int as uint64;
    prev_owner: Address;
    forward_payload: Slice as remaining;
}

message(0xd53276db) Excesses {
    query_id: Int as uint64;
}

message(0x2fcb26a2) GetStaticData {
    query_id: Int as uint64;
}

message(0x8b771735) ReportStaticData{
    query_id: Int as uint64;
    index_id: Int;
    collection: Address;
}

struct GetNftData {
    is_initialized: Bool;
    index: Int as uint32;
    collection_address: Address;
    owner_address: Address;
    individual_content: Cell;
}
