message TokenDeploy {
    name: String;
    description: String;
    symbol: String;
    image: String;
}
message(0x7362d09c) TransferNotification {
    // query_id: Int as uint64;
    jetton_amount: Int as coins;
    from_user: Address;
    ref_msg_data: Cell;
}