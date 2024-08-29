// 1. Transfer + Ownership event //
message(0x5fcc3d14) Transfer {
    query_id: Int as uint64;                    // arbitrary request number
    new_owner: Address;                         // new owner of the NFT item
    response_destination: Address;              // address where to send a response with confirmation of a successful transfer and the rest of the incoming message coins if not empty address
    custom_payload: Cell?;                      // optional custom data
    forward_amount: Int as coins;               // the amount of nanotons to be sent to the new owner
    forward_payload: Slice as remaining;        // optional custom data that should be sent to the new owner
}
message(0x05138d91) OwnershipAssigned {
    query_id: Int as uint64;
    prev_owner: Address;
    forward_payload: Slice as remaining;
}
message(0xd53276db) Excesses {
    query_id: Int as uint64;
}
///////////////////////////////////

/////// 2. Static NFT Data ////////
message(0x2fcb26a2) GetStaticData {
    query_id: Int as uint64;
}
message(0x8b771735) ReportStaticData {
    query_id: Int as uint64;
    index: Int as uint64;
    collection: Address;
}
///////////////////////////////////
