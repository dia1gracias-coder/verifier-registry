const minTonsForStorage: Int = ton("0.02");
const gasConsumption: Int = ton("0.02");
message LogEventMintRecord {
    minter: Address;
    item_id: Int;
    generate_number: Int;
}
message InitDeployed {
    query_id: Int;
    nft_address: Address;
    sender: Address;
    individual_content: Cell;
}
message InitDeployedTrue {
    query_id: Int;
    nft_address: Address;
    sender: Address;
    individual_content: Cell;
}
message(0x693d3950) GetRoyaltyParams {
    query_id: Int as uint64;
}
message(0xa8cb00ad) ReportRoyaltyParams {
    query_id: Int as uint64;
    numerator: Int as uint16;
    denominator: Int as uint16;
    destination: Address;
}
message(0x5fcc3d14) Transfer {
    query_id: Int as uint64;
    new_owner: Address;
    response_destination: Address?;
    custom_payload: Cell;
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
message(0x2fcb26a2) Get_static_data { 
    query_id: Int as uint64;
}
message(0x8b771735) ReportStaticData {
    query_id: Int as uint64;
    index_id: Int as uint256;
    collection: Address;
}
message UpdateGameAttributes {
    query_id: Int;
    attributes: GameAttributes;
}
message(0x1) Mint {
    query_id: Int as uint64;
    custom_payload: Cell;
}
message UpdateContent {
    query_id: Int;
    content: Cell;     
}
message(0x54cbf19b) UpdateMeta {
    query_id: Int;
    content: Cell;     
}

//Описание структур****************************************
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
struct GetNftData {
    init: Int;
    index: Int;
    collection_address: Address;
    owner_address: Address;
    individual_content: Cell;
}


struct GameAttributes {
    
    distans: Int as uint16;
}
message SetGameAttributes {    
    query_id: Int as uint16;
    distans: Int as uint16;
    nonce: Int as uint32;
    signature: Slice;
    public_key: Int as uint256; 
}


struct GetState {
    collection_address: Address;
    item_index: Int; 
    is_init: Bool;
    owner: Address;
    game_attributes_distans: Int as uint16;
    individual_content: Cell; 
    royalty_destination: Address;
    numerator: Int as uint16;
    denominator: Int as uint16;
   }