// Events 
message LogEventMintRecord {
    minter: Address;
    new_owner: Address;
    item_id: Int;
}

message LogEventBurnRecord {
    owner: Address;
    anima_collection: String;
}

// Collection messages
message Mint {
    new_owner: Address;
    anima_collection: String;
}

message Burn {
    owner: Address;
    anima_collection: String;
    response_destination: Address;
}

message AddAdmin {
	admin_to_add: Address;
}

message RemoveAdmin {
	admin_to_remove: Address;
}

// Soulbound messages

message InitSoulbound {
    item_index: Int;
    response_destination: Address;
    custom_payload: Cell;
}

struct GetNftData {
    index: Int;
    collection_address: Address;
    owner_address: Address;
    anima_collection: String;
    individual_content: Cell;
}