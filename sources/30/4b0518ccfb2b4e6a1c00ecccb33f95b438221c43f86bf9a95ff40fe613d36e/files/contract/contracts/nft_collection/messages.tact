message(0x693d3950) GetRoyaltyParams {
    query_id: Int as uint64;
}

message(0x693d3951)  GetBeneficiary {
    query_id: Int as uint64;
}

message(0x693d3952)  Beneficiary {
    query_id: Int as uint64;
    beneficiary: Address;
}

message GetPricePerMint {
    query_id: Int as uint64;
}

message Mint {
    query_id: Int as uint64;
    referer: Address?;
}

message BuilkMint {
    query_id: Int as uint64;
    receiver: Address;
    amount: Int as uint32;
}

message(0xa8cb00ad) ReportRoyaltyParams {
    query_id: Int as uint64;
    numerator:  Int as uint16;
    denominator: Int as uint16;
    destination: Address;
}

message AssignBeneficiary {
    query_id: Int as uint64;
    beneficiary: Address;
}

message AssignRefererReward {
    query_id: Int as uint64;
    referer_reward: Int;
}

message AssignPricePerMint {
    query_id: Int as uint64;
    price_per_mint: Int;
}