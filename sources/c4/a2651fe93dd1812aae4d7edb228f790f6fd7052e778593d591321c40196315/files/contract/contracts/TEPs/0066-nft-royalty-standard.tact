message(0x693d3950) NFTGetRoyaltyParams {
    query_id: Int as uint64;
}

struct NFTRoyaltyParams {
    numerator: Int as uint16;
    denominator: Int as uint16;
    royalty_destination: Address;
}

message(0xa8cb00ad) NFTReportRoyaltyParams {
    query_id: Int as uint64;
    numerator: Int as uint16;
    denominator: Int as uint16;
    destination: Address;
}
