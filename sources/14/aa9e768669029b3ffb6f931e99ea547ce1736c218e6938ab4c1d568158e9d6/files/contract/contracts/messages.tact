// structs
struct NftData {
    is_initialized: Bool;
    index: Int as uint64;
    collection_address: Address;
    owner_address: Address?;
    individual_content: Cell?; // nft item content uri
}
struct NftCollectionData {
    next_item_index: Int as uint64;
    content: Cell;
    owner_address: Address;
}
struct RoyaltyParams {
    numerator: Int as uint16;
    denominator: Int as uint16;
    destination: Address;
}
struct NftContent {
    offchain_tag: Int as uint8;
    common_content: Slice; // Base url for NFT items metadata
    individual_nft_content: Cell; // nft item content uri
}

struct SpecialData
{
    nft_basic: Int;//0 - category
    nft_silver: Int;//1 - category
    nft_gold: Int;//2 - category
    nft_platinum: Int;//3 - category

    next_basic_index: Int as uint64;
    next_silver_index: Int as uint64;
    next_gold_index: Int as uint64;
    next_platinum_index: Int as uint64;

    coin_minial: Int as coins;
    
    address_check: Bool;//Делать проверку кому можно минтить или нет
    address_mint: map<Address, Int>;//Кому разрешено минтить и сколько раз
}


message(0x5fcc3d14) Transfer {
    query_id: Int as uint64;
    new_owner_address: Address;
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
    index: Int as uint256;
    collection_address: Address;
}
message(0x693d3950) GetRoyaltyParams {
    query_id: Int as uint64;
}
message(0xa8cb00ad) ReportRoyaltyParams {
    query_id: Int as uint64;
    royalty_params: RoyaltyParams;
}

//NFT Item
message(0x00010000) InteralChangeIndividualContent {
    query_id: Int as uint64;
    individual_content: Cell;
}



// NFT Collection specified
message(0x00000001) NftCollectionDeployNewNft {
    query_id: Int as uint64;
    new_owner: Address?;
    nft_content: Cell;
}
message(0x00000002) NftCollectionBatchDeployNewNft {
    query_id: Int as uint64;
    deploy_list: Cell;
    use_next_item_index: Bool?;
}
message(0x00000003) NftCollectionChangeOwner {
    query_id: Int as uint64;
    new_owner: Address;
}
message(0x00000004) NftCollectionReturnBalance {
    query_id: Int as uint64;
}
message(0x00000005) NftCollectionChangeSecondOwner {
    query_id: Int as uint64;
    new_second_owner: Address;
}
message(0x00000006) NftCollectionChangeContent {
    query_id: Int as uint64;
    content: Cell;
    nft_item_content_common: Cell;
}
message(0x00000007) NftCollectionChangeItemContent {
    query_id: Int as uint64;
    item_index: Int as uint64;
    individual_content: Cell;
}
message(0x00000008) NftCollectionChangeSpecialDataItem {
    query_id: Int as uint64;
    nft_basic: Int as uint64;
    nft_silver: Int as uint64;
    nft_gold: Int as uint64;
    nft_platinum: Int as uint64;
}
message(0x00000009) NftCollectionChangeSpecialDataTonMin {
    query_id: Int as uint64;
    value: Int as coins;
}
message(0x0000000A) NftCollectionChangeSpecialDataAddAddress {
    query_id: Int as uint64;
    length_list: Int as uint64;
    count_list: map<Int, Int>;
    address_list: map<Int, Address>;
}
message(0x0000000B) NftCollectionChangeSpecialDataClearAddress {
    query_id: Int as uint64;
}
message(0x0000000C) NftCollectionChangeSpecialDataCheckAddress {
    query_id: Int as uint64;
    address_check: Bool;
}



//TODO: SBT
message(0xd0c3bfea) RequestOwner {
}
message(0x0dd607e3) OwnerInfo {
}
message(0x04ded148) ProveOwnership {
}
message(0x0524c7ae) OwnershipProof {
}
message(0xc18e86d2) OwnershipProofBounced {
}
message(0x1f04537a) Destroy {
}
message(0x6f89f5e3) Revoke {
}
message(0xd136d3b3) TakeExcess {
}