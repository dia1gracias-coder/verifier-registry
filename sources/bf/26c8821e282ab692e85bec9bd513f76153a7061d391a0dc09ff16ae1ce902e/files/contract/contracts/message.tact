message LogEventMintRecord {
    minter: Address;
    item_id: Int;
    generate_number: Int;
}
struct CollectionData {
    next_item_index: Int;
    collection_content: Cell;
    owner_address: Address;
}
message Mint {
    recipient: Address;
    individual_content: Cell;
}
message(0x5fcc3d14) Transfer {
    query_id: Int as uint64;
    new_owner: Address;
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
struct NftData {
    is_initialized: Bool;
    index: Int;
    collection_address: Address;
    owner_address: Address;
    individual_content: Cell;
}
message(0x04ded148) ProveOwnership {
    query_id: Int as uint64;
    dest: Address;
    forward_payload: Cell;
    with_content: Bool;
}
message(0xd0c3bfea) RequestOwner {
    query_id: Int as uint64;
    dest: Address;
    forward_payload: Cell;
    with_content: Bool;
}
message(0x0524c7ae) OwnershipProof {
    query_id: Int as uint64;
    item_id: Int as uint256;
    owner: Address;
    data: Cell;
    revoked_at: Int as uint64;
    content: Cell?;
}
message(0x0dd607e3) OwnerInfo {
    query_id: Int as uint64;
    item_id: Int as uint256;
    initiator: Address;
    owner: Address;
    data: Cell;
    revoked_at: Int as uint64;
    content: Cell?;
}
message(0x6f89f5e3) Revoke {
    query_id: Int as uint64;
}
struct Job {
    id: Int;
    title: String;
    description: String;
    compensation: Int? as coins;
    skills: map<Int, Cell>;
    numberOfSkills: Int;
    employer: Address;
    isAcceptingApplicants: Bool;
    worker: Address?;
    worker_rating: Int?;
    worker_review: String?;
    isCompleted: Bool?;
    applicants: map<Int, Address>;
    numberOfApplicants: Int;
    createdAt: Int;
    completedAt: Int?;
}
struct Post {
    id: Int;
    title: String;
    content: String;
    author: Address;
    comments: map<Int, Comment>;
    numberOfComments: Int;
    upvotes: Int;
    downvotes: Int;
    createdAt: Int;
    archivedAt: Int?;
}
struct Comment {
    id: Int;
    author: Address;
    content: String;
    upvotes: Int;
    downvotes: Int;
}
struct User {
    address: Address;
    name: String;
    email: String;
    skills: map<Int, Cell>;
    isEmployer: Bool;
    reputations: map<Int, Reputation>;
    numberOfReputations: Int;
}
struct Reputation {
    rating: Int;
    review: Cell;
}
message CreateUser {
    address: Address;
    name: String;
    email: String;
    skills: map<Int, Cell>;
    isEmployer: Bool;
}
message UpdateUserName {
    address: Address;
    name: String;
}
message UpdateUserEmail {
    address: Address;
    email: String;
}
message UpdateUserRole {
    address: Address;
    isEmployer: Bool;
}
message UpdateUserSkills {
    address: Address;
    skills: map<Int, Cell>;
}
message CreateJob {
    title: String;
    description: String;
    compensation: Int as coins;
    skills: map<Int, Cell>;
    numberOfSkills: Int;
}
message ApplyForJob {
    job_id: Int;
}
message AcceptApplicant {
    job_id: Int;
    applicant: Address;
}
message CompleteJob {
    job_id: Int;
    employer_rating: Int;
    employer_review: String;
}
message MarkJobCompleted {
    job_id: Int;
    worker_rating: Int;
    worker_review: String;
    nft_metadata: Cell;
}
message CreatePost {
    title: String;
    content: String;
}
message CreateComment {
    post_id: Int;
    content: String;
}
message UpvotePost {
    post_id: Int;
}
message DownvotePost {
    post_id: Int;
}
message UpvoteComment {
    post_id: Int;
    comment_id: Int;
}
message DownvoteComment {
    post_id: Int;
    comment_id: Int;
}
message ArchivePost {
    post_id: Int;
}
