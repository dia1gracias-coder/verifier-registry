// TEP-62 Messages
message(0x5fcc3d14) Transfer {
    queryId: Int as uint64;
    newOwner: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardAmount: Int as coins;
    forwardPayload: Cell as remaining;
}

message(0x05138d91) OwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Cell as remaining;
}
message(0xd53276db) Excesses {
    queryId: Int as uint64;
}

message(0x2fcb26a2) GetStaticData {
    queryId: Int as uint64;
}

message(0x8b771735) ReportStaticData {
    queryId: Int as uint64;
    index: Int as uint256;
    collection: Address;
}

// TEP-66 Messages
message(0x693d3950) GetRoyaltyParams {
    queryId: Int as uint64;
}

message(0xa8cb00ad) ReportRoyaltyParams {
    queryId: Int as uint64;
    numerator: Int as uint16;
    denominator: Int as uint16;
    destination: Address;
}

message(0xeda77b6b) InitializeNftItem {
    owner: Address;
    baseUrl: String;
}

message(0x73a786d) MintNftItem {

}

message(0x524499e) MintNftItemAdmin {
    destination: Address;
}

message(0x4e85b663) Withdraw {
    amount: Int as coins;
    destination: Address;
}

message(0x352b00aa) SetRoyaltyParams {
    royaltyParams: RoyaltyParams;
}

message(0xdbbb64e2) SetMintPrice {
    mintPrice: Int as coins;
}

message(0x741c37fb) InitializeCollection {
    baseUrl: String;
}

message(0x5279fb19) SetBaseUrl {
    baseUrl: String;
}


struct RoyaltyParams {
    numerator: Int as uint16;
    denominator: Int as uint16;
    destination: Address;
}

struct CollectionData {
    nextItemIndex: Int as uint64;
    content: Cell;
    owner: Address;
}

struct NftData {
    initialized: Bool;
    index: Int as uint64;
    collectionAddress: Address;
    owner: Address;
    individualContent: Cell;
}