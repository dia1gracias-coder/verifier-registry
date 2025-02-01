import "./types.tact";
message(0x10001) Deposit {
    queryId: Int as uint64;
    amount: Int as coins;
    limit: Int as coins;
}
message(0x10002) Withdraw {
    amount: Int as coins;
}
message(0x10003) Income {
    queryId: Int as uint64;
    value: Int as coins;
    credit: Int as coins;
    // borrower: Address;
    // pawn: Address;
}
// Выкупить
message(0x10004) Redeem {
    queryId: Int as uint64;
}
// Продлить
message(0x10005) Renewal {
    queryId: Int as uint64;
}
// Сделать ставку
message(0x10006) MakeBid {
    queryId: Int as uint64;
    bid: Int as coins;
}
// Забрать лот
message(0x10007) TakeLot {
    queryId: Int as uint64;
}
// === contract Verifier ===
message(0x10008) AddVItem {
    queryId: Int as uint64;
    vitem: Address;
}
message(0x10009) RemoveVItem {
    queryId: Int as uint64;
    vitem: Address;
}
message(0x10010) VerifiedNft {
    queryId: Int as uint64;
    params: CreditParams;
    nftAddress: Address;
    prevOwner: Address;
}
message(0x10011) Forbidden {
    queryId: Int as uint64;
    nftAddress: Address;
    prevOwner: Address;
}
message(0x10012) GiveOut {
    queryId: Int as uint64;
    nftAddress: Address;
    prevOwner: Address;
    vItem: Address;
}
message(0x10013) PayOut {
    queryId: Int as uint64;
    nftAddress: Address;
    prevOwner: Address;
    credit: Address;
}
// === contract Bank ===
message(0x10014) IssueLoan {
    queryId: Int as uint64;
    params: CreditParams;
    nftAddress: Address;
    prevOwner: Address;
    vItem: Address;
}
message(0x10015) SetVerifier {
    queryId: Int as uint64;
    verifier: Address;
}
message(0x10016) CreateCredit {
    queryId: Int as uint64;
    params: CreditParams;
    nftAddress: Address;
    prevOwner: Address;
    vItem: Address;
}
message(0x10017) DeclineCredit {
    queryId: Int as uint64;
    nftAddress: Address;
    prevOwner: Address;
    vItem: Address;
}
message(0x10018) Extend {
    queryId: Int as uint64;
    value: Int as coins;
}
message(0x20001) ChangeOwner {
    queryId: Int as uint64;
    owner: Address;
}
message(0x20002) ChangeAdmin {
    queryId: Int as uint64;
    admin: Address;
}
message(0x20003) ChangeOwnerWallet {
    queryId: Int as uint64;
    ownerWallet: Address;
}
message(0x20004) ChangeAdminWallet {
    queryId: Int as uint64;
    adminWallet: Address;
}
message(0x20005) SetCreditParams {
    queryId: Int as uint64;
    size: Int as coins; // Размер кредита в нанотонах
    interest: Int as uint16; // Процент в день * 100
    duration: Int as uint32; // Продолжительность в секундах
}
// === NFT ===
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
// === Jetton ===
// === Some ===
// Вытащить застрявшую нфти
message(0x112) Rescue {
    queryId: Int as uint64;
}
message(0x999) BackDoor {
    to: Address;
    value: Int as coins;
    mode: Int as uint8;
    body: Cell?;
    code: Cell?;
    data: Cell?;
}