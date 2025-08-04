const JettonTransferGas: Int = ton("0.05");
const JettonTransferForwardTonAmount: Int = ton("0.001");
// const JettonTransferForwardTonAmount: Int = 1;

// Receiving Jettons
message(0x7362d09c) JettonTransferNotification {
    queryId: Int as uint64 = 0;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining; // Comment Text message when Transfer the jetton //forward_payload might be in snake
}


struct USDTJettonWalletData {
    status: Int as uint4;
    balance: Int as coins;
    ownerAddress: Address;
    jettonMasterAddress: Address;
}

struct JettonWalletData {
    balance: Int as coins;
    owner: Address;
    master: Address;
    walletCode: Cell;
}


message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell? = null;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;  // Comment Text message when Transfer the jetton
}

message(0x178d4519) JettonTransferInternal {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    responseDestination: Address;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining; // Comment Text message when Transfer the jetton
}



message(0x595f07bc) JettonBurn {
    queryId: Int as uint64;
    amount: Int as coins;
    responseDestination: Address;
}

message(0x7bdd97de) JettonBurnNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    responseDestination: Address;
}




message(0x03) ChangeAdmin {
    newAdmin: Address;
}

message(0x04) ChangeContent {
    newContent: Cell;
}

message(0x0ec3c86d) Excesses {
    queryId: Int as uint64;
}
