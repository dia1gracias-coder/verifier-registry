struct JettonWalletData {
    owner: Address;
    jettonWallet: Address;
    jettonWalletCode: Cell;
    balance: Int;
}

struct JettonMasterData {
    totalSupply: Int;
    mintable: Bool;
    adminAddress: Address;
    jettonContent: Cell;
    jettonWalletCode: Cell;
}

// Standard jetton transfer message (from owner)
message(0x0f8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

// Internal jetton transfer message (between wallets)
message(0x178d4519) JettonTransferInternal {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    responseDestination: Address?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

// Jetton transfer notification (to recipient)
message(0x7362d09c) JettonTransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}

// Jetton excess gas return message
message(0xd53276db) JettonExcesses {
    queryId: Int as uint64;
}

// TODO: implement it in wallet
// Cancel a pending transfer that's stuck
message(0x9a8b7c6d) CancelPendingTransfer {
    // Empty message, just a signal from owner
}
