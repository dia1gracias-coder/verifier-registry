struct GetNftData { 
    is_initialized: Bool;
    index: Int;
    collection_address: Address; 
    owner_address: Address;
    individual_content: Cell;
}

// Define new message for refueling
message(0xabcdef12) Refuel {
    query_id: Int as uint64;
}