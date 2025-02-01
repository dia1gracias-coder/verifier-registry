const PERCENT_BASE: Int = 100;
const GAS_INSURANCE: Int = ton("0.19");
const STORAGE: Int = ton("0.01"); // enough for 1 KB of storage for 2.5 years

// TODO: Разделить на разные файлы (для банка)
struct BankRateBalance {
    balance: Int as coins; // Баланс
    rate: Int; // Курс
}
struct CreditAddresses {
    borrower: Address; // Заёмщик
    pawn: Address; // Залог
}
struct CreditCell {
    size: Int as coins; // Размер кредита в нанотонах
    interest: Int as uint16; // Процент в день * 100
    duration: Int as uint32; // Продолжительность в секундах
    addresses: Cell;
}
struct CreditParams {
    size: Int as coins; // Размер кредита в нанотонах
    interest: Int as uint16; // Процент в день * 100
    duration: Int as uint32; // Продолжительность в секундах
}
struct AuctonParams {
    bid: Int as coins; // Текущая ставка
    bidder: Address; // Претендент
    finish: Int as uint32; // Окончание
}
struct CreditGetData {
    status: Int as uint8; // Статус залога
    params: CreditParams;
    verifier: Address;
    addresses: CreditAddresses;
    start: Int as uint32; // Время начала unixtime
    debt: Int as coins; // Задолженность
    auction: AuctonParams?;
}
struct GetNftData {
    is_initialized: Bool;
    index: Int;
    collection_address: Address;
    owner_address: Address;
    individual_content: Cell;
}
struct RoyaltyParams {
    numerator: Int;
    denominator: Int;
    destination: Address;
}
struct CollectionData {
    next_item_index: Int;
    collection_content: Cell;
    owner_address: Address;
}
struct GetAddresses {
    bank: Address;  
    owner: Address;
    ownerComissionWallet: Address;
    admin: Address;
    adminComissionWallet: Address;
    vItems: map<Address, Bool>;
}