// transfer#5fcc3d14 queryId:uint64 new_owner:MsgAddress response_destination:MsgAddress
// custom_payload:(Maybe ^Cell) forward_amount:(VarUInteger 16)
// forward_payload:(Either Cell ^Cell) = InternalMsgBody;
message(0x5fcc3d14) Transfer {
    queryId: Int as uint64;
    newOwner: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0x2fcb26a2) GetStaticData {
    queryId: Int as uint64;
}

message(0x693d3950) GetRoyaltyParams {
    queryId: Int as uint64;
}

message(0xa8cb00ad) ReportRoyaltyParams {
    queryId: Int as uint64;
    params: RoyaltyParams;
}

message(0x8b771735) ReportStaticDataMessage {
    queryId: Int as uint64;
    index: Int as uint256;
    collection: Address;
}

message(0x746d6f79) OpenYear {
    queryId: Int as uint64;
    year: Int as uint16;
    totalSlots: Int as uint32;
    basePrice: Int as coins;
    itemDeployAmount: Int as coins;
}

message(0x746d6379) CloseYear {
    queryId: Int as uint64;
    year: Int as uint16;
}

message(0x746d6164) ChangeAdmin {
    queryId: Int as uint64;
    newAdmin: Address;
}

message(0x746d7367) SetQuoteSigner {
    queryId: Int as uint64;
    quotePublicKey: Int as uint256;
}

message(0x746d706d) SetPaymentAddress {
    queryId: Int as uint64;
    paymentAddress: Address;
}

message(0x746d6d69) MintDate {
    queryId: Int as uint64;
    year: Int as uint16;
    minuteIndex: Int as uint32;
    price: Int as coins;
    validUntil: Int as uint32;
    owner: Address;
    rarity: Int as uint8;
    content: Cell;
    signature: Slice as bytes64;
}

struct NFTData {
    init: Int;
    itemIndex: Int as uint64;
    collectionAddress: Address;
    owner: Address?;
    content: Cell?;
}

struct InitNFTBody {
    owner: Address;
    content: Cell;
}

struct CollectionData {
    nextItemIndex: Int as uint64;
    collectionContent: Cell;
    owner: Address;
}

struct RoyaltyParams {
    nominator: Int as uint16;
    dominator: Int as uint16;
    owner: Address;
}

struct YearConfig {
    isOpen: Bool;
    totalSlots: Int as uint32;
    basePrice: Int as coins;
    itemDeployAmount: Int as coins;
    mintedCount: Int as uint32;
}

struct MintedSlot {
    owner: Address;
    itemIndex: Int as uint64;
    rarity: Int as uint8;
    price: Int as coins;
    mintedAt: Int as uint32;
}

struct DateStatus {
    year: Int as uint16;
    minuteIndex: Int as uint32;
    isYearOpen: Bool;
    minted: Bool;
    owner: Address?;
    itemIndex: Int? as uint64;
    nftAddress: Address?;
    rarity: Int? as uint8;
    price: Int? as coins;
    mintedAt: Int? as uint32;
}
