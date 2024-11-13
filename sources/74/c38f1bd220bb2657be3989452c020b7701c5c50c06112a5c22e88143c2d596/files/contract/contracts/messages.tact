message ChangeClaimData {
    claimStartTime: Int as uint32;
    claimEndTime: Int as uint32;
    claimable: Bool;
}
message ChangeSaleData {
    startTime: Int as uint32;
    endTime: Int as uint32;
    price: Int as coins;
    minBuyToken: Int as coins;
    maxBuyToken: Int as coins;
}
message Mint {
    amount: Int;
    receiver: Address;
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
message(0x178d4519) TokenTransferInternal {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}
message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}
message(0x595f07bc) TokenBurn {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    response_destination: Address;
}
message(0x7bdd97de) TokenBurnNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    response_destination: Address?;
}
message(0xd53276db) TokenExcesses {
    queryId: Int as uint64;
}
message TokenUpdateContent {
    content: Cell;
}
message MintPrivateSale {
    totalSupply: Int;
}
message BuyTokenInternal {
    amount: Int as uint256;
    sender: Address;
}
message BuyTokenNotification {
    amount: Int as uint256;
    sender: Address;
}
message TransferPrivateSaleInternal {
    totalSupply: Int;
}
message TransferPrivateSaleInternalCallBack {
    totalSupply: Int;
}
message ClaimTokensInternal {
    sender: Address;
    jetton: Address;
}