// Standard NFT messages and data structures

// ===== Storage Structures ===== //

struct RoyaltyParams {
    royalty_factor: Int as uint16;
    royalty_base: Int as uint16;
    royalty_address: Address;
}

struct CollectionData {
    next_item_index: Int;
    collection_content: Cell;
    owner_address: Address;
}

struct NftData {
    is_initialized: Bool;
    index: Int;
    collection_address: Address;
    owner_address: Address;
    individual_content: Cell;
}

// ===== Messages ===== //

// Standard NFT Transfer (op=0x5fcc3d14)
message(0x5fcc3d14) Transfer {
    query_id: Int as uint64;
    new_owner: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_amount: Int as coins;
    forward_payload: Slice as remaining;
}

// Ownership assigned notification (op=0x05138d91)
message(0x05138d91) OwnershipAssigned {
    query_id: Int as uint64;
    prev_owner: Address;
    forward_payload: Slice as remaining;
}

// Excesses message (op=0xd53276db)
message(0xd53276db) Excesses {
    query_id: Int as uint64;
}

// Get static data (op=0x2fcb26a2)
message(0x2fcb26a2) GetStaticData {
    query_id: Int as uint64;
}

// Report static data (op=0x8b771735)
message(0x8b771735) ReportStaticData {
    query_id: Int as uint64;
    index: Int as uint256;
    collection: Address;
}

// ===== Custom Messages for Collection ===== //

// Mint NFT request
message MintNft {
    query_id: Int as uint64;
    individual_content: Cell?;
}

// Mint NFT request V2 - for authorized minter
message MintNftV2 {
    query_id: Int as uint64;
    individual_content: Cell?;
}

// Update authorized minter message
message UpdateAuthorizedMinter {
    query_id: Int as uint64;
    new_minter: Address;
}

// Public mint message - anyone can use this
message PublicMint {
    query_id: Int as uint64;
    individual_content: Cell?;
}

// Batch mint NFTs
message BatchMint {
    query_id: Int as uint64;
    recipients: map<Int, Address>;
}

// Update collection content
message UpdateCollectionContent {
    query_id: Int as uint64;
    collection_content: Cell;
}

// Update NFT price
message UpdateNftPrice {
    query_id: Int as uint64;
    price: Int as coins;
}

// Withdraw collected funds
message WithdrawFunds {
    query_id: Int as uint64;
}

// ===== Custom Messages for NFT Item ===== //

// Update NFT content
message UpdateNftContent {
    query_id: Int as uint64;
    individual_content: Cell;
}

// Burn NFT
message BurnNft {
    query_id: Int as uint64;
}

// ===== Admin Control Messages ===== //

message BurnById {
    query_id: Int as uint64;
    index: Int;
}

// Update an NFT's individual content by index (collection -> item)

// NFT Burned confirmation
message NftBurned {
    query_id: Int as uint64;
}

// ===== Utility Functions ===== //

// Helper to create off-chain content with URL
fun buildOffChainContent(url: String): Cell {
    // 0x01 prefix for off-chain content
    let b: StringBuilder = beginString();
    b.append(url);
    return beginCell()
        .storeUint(1, 8)
        .storeRef(b.toCell())
        .endCell();
}

