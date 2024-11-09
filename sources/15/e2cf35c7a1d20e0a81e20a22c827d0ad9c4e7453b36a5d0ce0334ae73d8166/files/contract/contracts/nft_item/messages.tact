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

// Define new message for refueling
message(0xabcdef12) Refuel {
    query_id: Int as uint64;
}

// Define the BuyBooster message
message(0x12345678) BuyBooster {
    query_id: Int as uint64;
}

// Define the BuyFuelBooster message
message(0x9abcdef0) BuyFuelBooster {
    query_id: Int as uint64;
}