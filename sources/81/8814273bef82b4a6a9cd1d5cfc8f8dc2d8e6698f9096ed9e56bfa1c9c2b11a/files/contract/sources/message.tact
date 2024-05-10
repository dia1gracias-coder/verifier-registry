message(0x693d3950) GetRoyaltyParams {
    query_id: Int as uint64;
}
message(0xa8cb00ad) ReportRoyaltyParams {
    query_id: Int as uint64;
    numerator: Int as uint16;
    denominator: Int as uint16;
    destination: Address;
}
struct CollectionData {
    next_item_index: Int;
    collection_content: Cell;
    owner_address: Address;
}
struct RoyaltyParams {
    numerator: Int;
    denominator: Int;
    destination: Address;
}
message(0x5fcc3d14) Transfer {
    query_id: Int as uint64;
    new_owner: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_amount: Int as coins;
    forward_payload: Slice as remaining;
}
message(0x05138d91) OwnershipAssigned {
    query_id: Int as uint64;
    prev_owner: Address;
    index: Int;
    forward_payload: Slice as remaining;
}
message(0xd53276db) Excesses {
    query_id: Int as uint64;
}
message(0x2fcb26a2) GetStaticData {
    query_id: Int as uint64;
}

message(0x8b771736) SendEnoughJetton {
    query_id: Int as uint64;
    minter: Address;
    response_destination: Address?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x8b771735) ReportStaticData {
    query_id: Int as uint64;
    index_id: Int;
    collection: Address;
}

message(0x8b771734) ChangeJetton {
    query_id: Int as uint64;
    jetton: Address;
}

message(0x8b771733) ChangeNFT {
    query_id: Int as uint64;
    nft: Address;
}

message(0x8b771732) ChangeDuration {
    query_id: Int as uint64;
    duration: Int;
}

message(0x8b771731) Recharge {
    query_id: Int as uint64;
    amount: Int;
}


struct GetNftData {
    is_initialized: Bool;
    index: Int;
    collection_address: Address;
    owner_address: Address;
    individual_content: Cell;
}

// message(0x7362d09c) TokenNotification {
//     query_id: Int as uint64;
//     amount: Int as coins;
//     from: Address;
//     forward_payload: Slice as remaining;
// }

// message(0xf8a7ea5) TokenTransfer {
//     query_id: Int as uint64;
//     amount: Int as coins;
//     sender: Address;
//     response_destination: Address?;
//     custom_payload: Cell?;
//     forward_ton_amount: Int as coins;
//     forward_payload: Slice as remaining; 
// }

message(0x7362d09d) Withdraw {
    query_id: Int as uint64;
    item_address: Address;
}
