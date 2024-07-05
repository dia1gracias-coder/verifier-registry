struct NFTData {
    isComplete: Bool;
    startAt: Int as uint32;
    finishAt: Int as uint32;
    marketAddress: Address; // aka admin address
    nftAddress: Address;
    nftOwnerAddress: Address;
    fullPrice: Int as coins;
    jettonAddress: Address;
    // fees:Royalty;
}

struct Royalty {
    marketplaceFeeAddress: Address;
    marketplaceFee: Int as uint32;
    royaltyAddress: Address;
    royaltyAmount: Int as uint32;
}