// Запрос на предоставление адреса кошелька Jetton
message(0x2c76b973) ProvideWalletAddress {
    query_id: Int as uint64;
    owner_address: Address;
    include_address: Bool;
}

// Ответ с адресом кошелька Jetton
message(0xd1735400) TakeWalletAddress {
    query_id: Int as uint64;
    wallet_address: Address;
    owner_address: Address?;
}

// Уведомление о переводе Jetton
message(0x7362d09c) TransferNotification {
    query_id: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forward_payload: Slice as remaining;
}

// Сообщение о переводе Jetton
message(0x0f817ea5) Transfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

// Сообщение для возврата Jetton в случае ошибки
message(0xdeadbeef) RefundTransfer {
    query_id: Int as uint64;
    amount: Int as coins;
    sender: Address;
    response_destination: Address;
    error_message: Cell?;
}

// Сообщение для завершения сделки
message(0x9abc1234) FinalizeSale {
    query_id: Int as uint64;
    nft_address: Address;
    buyer_address: Address;
    sale_price: Int as coins;
    service_fee: Int as coins;
    royalty_fee: Int as coins;
    seller_address: Address;
    forward_payload: Slice as remaining;
}
