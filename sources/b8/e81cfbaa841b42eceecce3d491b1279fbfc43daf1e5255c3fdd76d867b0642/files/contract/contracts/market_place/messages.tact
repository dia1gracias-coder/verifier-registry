import "./nft_sale/structs.tact";
message(0x05138d91) OwnershipAssigned {
    query_id: Int as uint64;
    prev_owner: Address;
    forward_payload: Slice as remaining;
}
message(0x0fe0ede) SaleNft {
    stateInit: NFTData;
}
message AddExchangeJetton {
    jetton_address: Address;
}
message RemoveExchangeJetton {
    jetton_address: Address;
}