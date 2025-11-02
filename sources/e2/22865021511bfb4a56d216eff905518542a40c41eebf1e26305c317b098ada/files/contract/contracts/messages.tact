message(0x5fcc3d14) NFTTransfer {
    queryId: Int as uint64;
    newOwner: Address; 
    responseDestination: Address;
    customPayload: Cell? = null;
    forwardAmount: Int as coins; 
    forwardPayload: Slice as remaining;
}

message(0x05138d91) NftOwnershipAssigned {
  queryId: Int as uint64;
  prev_owner: Address;
  forward_payload: Slice as remaining;
}

message(0x01) StartCredit {
  creditAmount: Int as coins;
  lender: Address;
  originalOwner: Address;
  nft: Address;
}

message(0x2fcb26a2) NFTGetStaticData {
    queryId: Int as uint64;
}

message(0x8b771735) NFTReportStaticData {
  queryId: Int as uint64;
  index: Int as uint256;
  collection: Address;
}

struct NFTItemInitData {
  index: Int as uint256;
  collectionAddress: Address;
}
