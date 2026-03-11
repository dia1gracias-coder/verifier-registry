const min_balance: Int = ton("0.03");
const gas_consumption: Int = ton("0.03");

message(0xd53276db) NftExcesses {
    query_id: Int as uint64;
}

message(0x05138d91) NftOwnershipAssigned {
    query_id: Int as uint64;
    previous_owner: Address;
    forward_payload: Slice as remaining;
}

message(0x5fcc3d14) NftTransfer {
    query_id: Int as uint64;
    new_owner: Address;
    response_destination: Address;
    custom_payload: Cell? = null;
    forward_amount: Int as coins;
    forward_payload: Slice as remaining;
}

struct NftData {
    init: Bool?;
    index: Int as uint256;
    collection_address: Address;
    owner_address: Address;
    individual_content: Cell;
}

message(0x2fcb26a2) NftGetStaticData {
    query_id: Int as uint64;
}

message(0x8b771735) NftReportStaticData {
    query_id: Int as uint64;
    index: Int as uint256;
    collection: Address;
}

struct NftCollectionData {
    next_item_index: Int as uint256;
    collection_content: Cell;
    owner_address: Address;
}
