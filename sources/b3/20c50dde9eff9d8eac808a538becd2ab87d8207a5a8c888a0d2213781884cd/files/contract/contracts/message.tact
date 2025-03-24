struct CollectionData {
    next_item_index: Int;
    collection_content: Cell;
    owner_address: Address;
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
    forward_payload: Slice as remaining;
}
message(0xd53276db) Excesses {
    query_id: Int as uint64;
}
struct GetNftData {
    index: Int;
    collection_address: Address;
    owner_address: Address;
    individual_content: Cell;
}


message SetCollectionContent {
    collection_content: Cell;
}
message CertificateIssue {
    student: Address;
}
message CertificateIssueRecord {
    item_id: Int;
    student: Address;
}
message Enrollment {
    student_id: Cell;
    student_gmail: Cell; 
}
message SetCost {
    cost: Int as coins;
}
message Quiz {
    quizNumber: Int as uint32;
    answers: Cell;
}