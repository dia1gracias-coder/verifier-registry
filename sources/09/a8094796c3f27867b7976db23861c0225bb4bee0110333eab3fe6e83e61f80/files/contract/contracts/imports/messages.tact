// [Collection Contract] -> Transfer -> OwnershipAssigned -> NFTExcesses
message(0x5fcc3d14) Transfer { 
    query_id: Int as uint64;            
    new_owner: Address; 
    response_destination: Address; 
    custom_payload: Cell?; 
    forward_amount: Int as coins; 
    forward_payload: Slice as remaining; 
    nft_offchain_id: String?;
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

message TransferEditorship { 
    query_id: Int as uint64;            
    new_editor: Address; 
    response_destination: Address;
    forward_amount: Int as coins; 
    forward_payload: Slice as remaining;
}

message MintWithContent { 
    query_id: Int as uint64;
    nftOffchainId: String;
}

message EditorshipAssigned{
    query_id: Int as uint64;
    prev_editor: Address;
    forward_payload: Slice as remaining; 
}

message UpdateNftContent { 
    query_id: Int as uint64;
    new_content: Cell;
}

message UpdateCollectionContent { 
    query_id: Int as uint64;
    new_content: Cell;
    numerator:  Int as uint16;
    denominator: Int as uint16;
    destination: Address;
    collectionContentUrl: Cell;
    commonContentUrl: Cell;
}

message UpdateSingleNftContent {
    owner_address: Address;  
    editor_address: Address; 
    content: Cell;
    royalty_factor: Int as uint16 ;
    royalty_base: Int as uint16;
    royalty_address: Address;
}

message(0x8b771735) ReportStaticData{
    query_id: Int as uint64;
    index_id: Int as uint32;
    collection: Address;
}

message(0x693d3950) GetRoyaltyParams {
    query_id: Int as uint64;
}

message(0x693d3950) GetRoyaltyParamsOfSingleNft {
    query_id: Int as uint64;
}

message(0xa8cb00ad) ReportRoyaltyParams {
    query_id: Int as uint64;
    numerator:  Int as uint16;
    denominator: Int as uint16;
    destination: Address;
}

message(0xa8cb00ad) ReportRoyaltyParamsOfSingleNft {
    query_id: Int as uint64;
    royalty_factor: Int as uint16 ;
    royalty_base: Int as uint16;
    royalty_address: Address;
}