message(0xb803b08d) IncrementSuccessfulTx {
    wallet: Address;
}
// Регистрация/обновление партнёра
message(0x50525247) RegisterPartnerShare {  // "PPRG"
    wallet: Address;
    shareBps: Int?;
}

// Удаление партнёра
message(0x5052554E) UnregisterPartnerShare { // "PPUN"
    wallet: Address;
}