struct CollectionData {
    next_item_index: Int;
    collection_content: Cell;
    owner_address: Address;
}
struct GetNftData {
    is_initialized: Bool;
    index: Int;
    collection_address: Address;
    owner_address: Address;
    individual_content: Cell;
}
struct RoyaltyParams {
    numerator: Int;
    denominator: Int;
    destination: Address;
}
struct SupplyInfo {
    current_supply : Int;
    max_supply     : Int;
} 

message Mint {
    content   : Cell;
    recipient : Address;
}

message LogEventMintRecord {
    minter: Address;
    content: Cell;
    recipient: Address;
    item_id: Int;
    generate_number: Int;
}
message UpdateCode {
    queryId : Int as uint64;
    newCode : Cell;
}
message UpdateSettings {
    queryId   : Int as uint64;
    max_supply : Int as uint32;
}
message Withdraw {
    queryId     : Int as uint64;
    amount      : Int as coins;
    destination : Address;
}
message GetRoyaltyParams {
    query_id: Int as uint64;
}
message ReportRoyaltyParams {
    query_id: Int as uint64;
    numerator: Int as uint16;
    denominator: Int as uint16;
    destination: Address;
}
message Transfer {
    query_id: Int as uint64;
    new_owner: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_amount: Int as coins;
    forward_payload: Slice as remaining;
}
message OwnershipAssigned {
    query_id: Int as uint64;
    prev_owner: Address;
    forward_payload: Slice as remaining;
}
message Excesses {
    query_id: Int as uint64;
}
message GetStaticData {
    query_id: Int as uint64;
}
message ReportStaticData {
    query_id: Int as uint64;
    index_id: Int;
    collection: Address;
}
