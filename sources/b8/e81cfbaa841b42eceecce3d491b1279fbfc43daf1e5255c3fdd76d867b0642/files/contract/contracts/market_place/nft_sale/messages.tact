message BuyWithTon {
    query_id: Int as uint64;
}
message BuyWithAnotherJetton {
    query_id: Int as uint64;
    buyer_address: Address;
    purchase_price: Int as coins;
}
message CancelSaleNft {
}
message(0x5fcc3d14) Transfer {
    query_id: Int as uint64;
    new_owner: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_amount: Int as coins;
    forward_payload: Slice as remaining;
}