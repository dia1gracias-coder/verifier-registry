message OrderJetton {
    sponsorAddress: Address;
}

message ActivateReferralLink {
    sponsorAddress: Address;
}

message ActivateReferralLinkByOwner {
    referralAddress: Address;
    sponsorAddress: Address;
}

message Claim {
    amount: Int;
    hash: Int;    
}

message RevokeVesting {
    address: Address;
    index: Int as uint8;
}

message SetCrowdsaleStage {
    stage: Int as uint8;
}

message SetTonRate {
    rate: Int as coins;
}

message SetMinimalAmount {
    minAmount: Int as coins;
}

message AddVestingScheduleByManual {
    cliff: Int as uint32;
    start: Int as uint32;
    beneficiary: Address;
    jettonAmount: Int as uint256; // as coins ???
    durationVesting: Int as uint256;
}

message SetJettonAddress {
    jettonAddress: Address;
}

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}