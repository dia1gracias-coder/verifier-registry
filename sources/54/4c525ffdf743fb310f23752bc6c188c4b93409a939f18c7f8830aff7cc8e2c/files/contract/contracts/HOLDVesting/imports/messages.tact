message(0x9a17330a) AllocateJettons {
    queryId: Int as uint64; // query id
    configId: Int as uint8; // config id
    amount: Int as coins;   // jetton amount
}

message(0x9c781df9) WithdrawJettons {
    queryId: Int as uint64; // query id
    receiver: Address;      // receiver wallet address
    amount: Int as coins;   // jetton amount
}

message(0x958c1f43) WithdrawDebtJettons {
    queryId: Int as uint64; // query id
    receiver: Address;      // receiver wallet address
    amount: Int as coins;   // jetton amount
}

message(0xa17c679d) SetConfig {
    queryId: Int as uint64;              // query id
    configId: Int as uint8;              // config id
    amount: Int as coins;                // jetton amount
    receiver: Address;                   // receiver wallet address
    cliffDuration: Int as uint64;        // cliff duration (in seconds)
    cycleReleaseDuration: Int as uint64; // cycle release duration (in seconds)
    cycleReleasePercent: Int as uint64;  // cycle release percent (with decimals PERCENT_DECIMALS)
}

message(0x93ec1abf) SetFreeze {
    newFrozenAt: Int as uint64; // frozen at in the future (in seconds)
}

message(0x0f8a7ea5) JettonTransfer {
    queryId: Int as uint64;             // query id
    amount: Int as coins;               // jetton amount
    destination: Address;               // destination wallet address
    responseDestination: Address;       // response destination wallet address
    customPayload: Cell?;               // custom payload
    forwardTonAmount: Int as coins;     // forward ton amount
    forwardPayload: Slice as remaining; // forward payload
}
