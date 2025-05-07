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
message(0x2fcb26a2) GetStaticData {
    query_id: Int as uint64;
}
message(0x8b771735) ReportStaticData {
    query_id: Int as uint64;
    index_id: Int;
    collection: Address;
}
struct GetNftData {
    is_initialized: Bool;
    index: Int;
    collection_address: Address;
    owner_address: Address;
    individual_content: Cell;
}

message UpdateCourse {
    content: Cell;
    cost: Int as coins;
}
message CertificateIssue {
    student: Address;
    certificate_content: Cell;
}
message CertificateIssueRecord {
    item_id: Int;
    student: Address;
}
message(0xe5443d9f) Enrollment {
    student_id: Cell;
    student_gmail: Cell;
}
message Quiz {
    quizNumber: Int as uint32;
    answers: Cell;
}
message(0x9b0285f7) QuizRecord {
    quizNumber: Int as uint32;
    answers: Cell;
    student: Address;
}
struct CourseData {
    next_item_index: Int;
    collection_content: Cell;
    owner_address: Address;
    cost: Int as coins;
}