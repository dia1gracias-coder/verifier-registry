message(0x7362d09c) JettonTransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}

message(0x9a1b2c3d) UnlockSTON {
    user: Address;
    amount: Int as coins;
    fee: Int as coins;
}

message(0x807bb095) Spend {
    user: Address;
    amount: Int as coins;
    nonce: Int;
    expiry: Int;
    signature: Slice as bytes64;
}

message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell? = null;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

struct BatchEntry {
    to: Address;
    tonAmount: Int;
    stonAmount: Int;
}

struct JettonWalletData {
    balance: Int as coins;
    ownerAddress: Address;
    jettonMasterAddress: Address;
    jettonWalletCode: Cell;
}

message(0xf3893193) BatchTransferTON {
    entries: map<Int as uint8, BatchEntry>;
    count: Int;
}
message(0x1e18a375) WithdrawSTON {
    amount: Int as coins;
    destination: Address;
}

message(0x2e18a376) WithdrawTON {
    amount: Int as coins;
}

message(0x8f3a9d2b) SetJettonWallet {
    jettonWallet: Address;
}

message(0x5a9c2f10) SetStipendAmount {
    amount: Int as coins;
}
