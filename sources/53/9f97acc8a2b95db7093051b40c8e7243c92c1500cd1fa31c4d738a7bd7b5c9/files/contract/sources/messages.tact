message(0x0a7344a4) JettonWalletResponse {
    wallet_address: Address;            
}

message(0x2d5f0fbc) JettonWalletRequest {
    contract_address: Address;
}

message(0x6789abcd) EventNotification {
    event: String;
}

message(0x0f817ea5) JettonTransfer {
    query_id: Int as uint64;            // query id сообщения
    amount: Int as coins;               // количество монет которые переводим
    destination: Address;               // адресс получаеля
    response_destination: Address;      // куда перевести остаток тон(на контракт)
    custom_payload: Cell?;              // комменарий к отправке
    forward_ton_amount: Int as coins;   // количество ТОН которые надо оправить владельцу жетттон воллет за выполнение логики
    forward_payload: Slice as remaining;// тело которое перешлется за выполнение другим кошельком
}

message(0x1a2b3c4d) DepositCallback {
    user_id: Int as int64;
    amount: Int as coins;
    success: Bool;
}

message(0x5e6f7a8b) InternalWithdraw {
    amount: Int as coins;               
    to: Address;  
}

message(0x0f8a7ea5) WithdrawRequest {
    query_id: Int as uint64;            // query id сообщения
    amount: Int as coins;               // количество монет которые переводим
    destination: Address;               // адресс получаеля
    response_destination: Address;      // куда перевести остаток тон(на контракт)
    custom_payload: Cell?;              // комменарий к отправке
    forward_ton_amount: Int as coins;   // количество ТОН которые надо оправить владельцу жетттон воллет за выполнение логики
    forward_payload: Slice as remaining;// тело которое перешлется за выполнение другим кошельком
}

message(0x7bdd97de) WithdrawCallback {
    amount: Int as coins;
    to: Address; 
    success: Bool;
}