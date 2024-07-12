message ReigsterTokenTick {
    symbol: Cell;
    name: Cell;
    image: Cell;
    description: Cell;
    minting_info: Cell;
}

message AdminAddSymbol {
    symbol: Cell;
    theoryItemIndex: Int as uint32;
}

message AdminRemoveSymbol {
    symbol: Cell;
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
    response_destination: Address;
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

// ------
message TreasuryChangeAddress {
    new_address: Address;
}


message ClaimRevenue {
    treasury: Address;
}

message EventMintRecord {
    minter: Address;
    mintAmount: Int as coins;
    lastMintTimestamp: Int as uint32;
    mintRate: Int as uint32;
}

struct TokenData {
    ownerOfNftItemAddress: Address;
    costPerMint: Int as coins;
    startTime: Int as uint32;
    maxSupply: Int as coins;
    totalDuration: Int as uint16;
    lastMintTimestamp: Int as uint32;
    currentMintRate: Int as uint32;
    acutalMintTimes: Int as uint32;
    contractBalance: Int as coins;
    is_owenr_claimed: Bool;
}

struct AddressList {
    nftItemAddress: Address;
    jettonRootAddress: Address;
    jettonContent: Cell;
}


message(0x0000017) ClaimReward {
    query_id: Int as uint64;
    receiver: Address;
}

message(0x0000016) JettonInitial {
    query_id: Int as uint64;
    minting_info: Cell;
}