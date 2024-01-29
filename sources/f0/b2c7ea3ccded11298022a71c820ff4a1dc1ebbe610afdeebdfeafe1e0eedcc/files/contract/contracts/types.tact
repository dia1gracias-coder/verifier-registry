const PERCENT_BASE: Int = 100;
const GAS_INSURANCE: Int = ton("0.1");
const STORAGE: Int = ton("0.01"); // enough for 1 KB of storage for 2.5 years

struct CreditAgents {
    borrower: Address; // Заёмщик
    lender: Address; // Займодавец
}
struct CreditService {
    pawn: Address; // Залог
}
struct CreditAddresses {
    agents: CreditAgents;
    service: CreditService;
}
struct CreditData {
    size: Int as coins; // Размер кредита в нанотонах
    interest: Int as uint16; // Процент в день * 100
    duration: Int as uint32; // Продолжительность в секундах
    addresses: Cell;
}
message(0x05138d91) OwnershipAssignedWithCredit {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: CreditData; // Slice as remaining
}
message(0x05138d91) OwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Slice as remaining;
}
message(0x5fcc3d14) Transfer {
    queryId: Int as uint64;
    newOwner: Address;
    responseDestination: Address;
    customPayload: Cell?;
    forwardAmount: Int as coins;
    forwardPayload: Slice as remaining;
}
// Выдать (Private)
message(0x110) Issue {
    premium: Int as coins;
    proportion: Int as uint8;
}
// Выкупить
message(0x111) Redeem {
}
// Ликвидировать (Private)
message(0x112) Dispose {
    owner: Address; // Ликвидатор
}
// Отменить
message(0x113) Cancel {
}
// Отказаться
message(0x114) Refuse {
}
// Счет - Депозит
message(0x210) Deposit {
    queryId: Int as uint8;
}
// Счет - Вывести
message(0x211) Withdraw {
    amount: Int as coins;
}
// Счет - Выдать кредит
message(0x212) AccountIssue {
    size: Int as coins; // Размер кредита в нанотонах
    interest: Int as uint16; // Процент в день * 100
    duration: Int as uint32; // Продолжительность в секундах
    borrower: Address; // Заёмщик
    pawn: Address; // Залог
}
// Счет - Ликвидировать кредит
message(0x213) AccountDispose {
    credit: Address; // Контракт Кредита
}
// Private
message(0x214) AccountProportion {
    proportion: Int as uint8; // Доля в процентах
}
// Банк - создать аккаунт
message(0x310) CreateAccount {
}
// Private
message(0x311) BankIssueCredit {
    size: Int as coins; // Размер кредита в нанотонах
    address: Address; // Контракт Кредита
    premium: Int as coins; // Размер надбавки в нанотонах
}
// Банк/Аккаунт - забрать NFT
message(0x312) GetNft {
    nft: Address; // Адрес NFT
    forward: Int as coins; // Размер forward в нанотонах
    payload: Slice as remaining;
}
// Банк - установить пропоцию клиенту
message(0x313) SetProportion {
    user: Address; // Адрес ювелира
    proportion: Int as uint8; // Доля в процентах
}
// Банк - Выплата
message(0x314) Payout {
    contract: Address; // Адрес кошелька дивидендов
}
// Банк - Профит (Private)
message(0x315) Income {
    queryId: Int as uint8;
}
// Банк - Настройки
message(0x316) Settings {
    bot: Address; // Адрес бота
    premium: Int as uint8; // Размер надбавки в процентах
}
message(0x404) Destroy {
}