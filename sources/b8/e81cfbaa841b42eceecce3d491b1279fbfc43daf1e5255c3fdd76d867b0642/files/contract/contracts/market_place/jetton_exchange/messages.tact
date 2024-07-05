message EnableExchangeJetton {
}
message DisableExchangeJetton {
}
message(0x7362d09c) TokenTransferNotification {
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining; // contain type, nftSaleAddress
}