import "./structs_trinity.tact";

// ------------------ FtTrinityProgramUser ------------------ //

message(0x4d057345) ActivateContract {
    owner: Address;
    invitedId: Int as uint64;
    recipientExcesses: Address;
}

message(0xe57610de) ActivateOneLevel {
    levelNumber: Int as uint8;
    levelPrice: Int as coins;
    nextLevelPrice: Int as coins;
    autoFee: Int as coins;
    autoWithdrawMinFee: Int as coins;
    recipientExcesses: Address;
}

message(0x8eca7980) ActivateManyLevels {
    startLevelNumber: Int as uint8;
    finishLevelNumber: Int as uint8;
    levels: map<Int as uint8, Int as coins>;
    fees: map<Int as uint8, Int as coins>;
    nextLevelPrice: map<Int as uint8, Int as coins>;
    autoWithdrawMinFee: Int as coins;
    recipientExcesses: Address;
}

message(0x3009f7f1) FinishActivation {
    fromId: Int as uint64;
    wasActivatedLevel: Int as uint8;
    autoWithdrawMinFee: Int as coins;
    recipientExcesses: Address;
}

message(0x6caae5dc) CancelActivation {
    fromId: Int as uint64;
    levelNumber: Int as uint8;
    levelPrice: Int as coins;
    nextLevelPrice: Int as coins;
    autoWithdrawMinFee: Int as coins;
    recipientExcesses: Address;
}

message(0x7ab8ca87) UpdateTrinityMatrix {
    id: Int as uint64;
    fromId: Int as uint64;
    levelNumber: Int as uint8;
    levelPrice: Int as coins;
    nextLevelPrice: Int as coins;
    autoWithdrawMinFee: Int as coins;
    recipientExcesses: Address; 
}

message(0x90e412e3) ManualRecycle {
    id: Int as uint64;
    levelNumber: Int as uint8;
    nextLevelPrice: Int as coins;
    autoWithdrawMinFee: Int as coins;
    recipientExcesses: Address;
}

message(0xcd9e33f) OverflowFromTop {
    id: Int as uint64;
    fromId: Int as uint64;

    levelNumber: Int as uint8;
    levelPrice: Int as coins;
    nextLevelPrice: Int as coins;

    upperId: Int as uint64;
    userLine: Int as uint8;
    userBranch: Int as uint8;

    countOverflow: Int as uint8;
    autoWithdrawMinFee: Int as coins;

    recipientExcesses: Address;
}

message(0xbd5bd4a4) OverflowFromBottom {
    id: Int as uint64;
    fromId: Int as uint64;

    levelNumber: Int as uint8;
    levelPrice: Int as coins;
    nextLevelPrice: Int as coins;

    upperId: Int as uint64;
    userLine: Int as uint8;
    userBranch: Int as uint8;

    countOverflow: Int as uint8;
    autoWithdrawMinFee: Int as coins;

    recipientExcesses: Address;
}

message(0x30a1d58d) GiftTrinity {
    fromId: Int as uint64;
    value: Int as coins;
    autoWithdrawMinFee: Int as coins;
    recipientExcesses: Address;
}

message(0x9e2cc7b) SwitchAutoUpgrade {}

message(0x9e2cc7c) SwitchAutoWithdraw {}

message(0x1adc789) ClaimMatrixProfit {}

message(0xafe72100) ClaimLineBonus {
    levelNumber: Int as uint8;
    lineNumber: Int as uint8;
    recipientExcesses: Address;
}

message(0xfc5b7cc1) ReturnTon {}

message(0xab05820) SetupProgramUser {
    id: Int as uint64;
    owner: Address;
    invitedId: Int as uint64;
    invitedAddress: Address;
    canClaim: Int as coins;
    lastLevel: Int as uint8;
    overtakeInfo: map<Int as uint8, Int as uint16>;
    levelInfo: map<Int as uint8, TrinityInfo>;
    spentForActivate: Int as coins;
}

message(0xeb225d2) SetupProgramUserInternal {
    id: Int as uint64;
    owner: Address;
    invitedId: Int as uint64;
    invitedAddress: Address;
    canClaim: Int as coins;
    lastLevel: Int as uint8;
    overtakeInfo: map<Int as uint8, Int as uint16>;
    levelInfo: map<Int as uint8, TrinityInfo>;
    spentForActivate: Int as coins;
    recipientExcesses: Address;
}

message(0xab67517e) ChangeActivation {
    id: Int as uint64;
    activating: Bool;
    lastLevel: Int as uint8;
    recipientExcesses: Address;
}


// ------------------ FtTrinityProgramUser Emit ------------------ //

message(0x78d0b3b6) FinishTrinityCycle {
    levelNumber: Int as uint8;
    reinvestNumber: Int as uint16;
    matrix: map<Int as uint8, Place>;
}

// ------------------ FtTrinityProgramMain ----------------------- //

message(0x95ab4bd6) SetupTrinityPrice {
    newLevelPrice: map<Int as uint8, Int as coins>;
    newLevelPriceAutoFee: map<Int as uint8, Int as coins>;
}

message(0x968898a9) SetupTrinityFee {
    newLevelFee: map<Int as uint8, Int as coins>;
}

message(0x6fe57a02) SetupJettonWallet {
    wallet: Address;
}

message(0xbdd5f8f8) SetupTrinityStart {
    startTrinity: Int as uint32;
}

message(0x5cb522cd) SetupMinValueForActivate {
    newMinValue: Int as coins;
}

message(0x2593ba97) SetupAutoWithdrawMinFee {
    value: Int as coins;
}

message(0x7afb1b33) SetupAutoWithdrawPercent {
    value: Int as uint8;
}

message(0x26e869b0) SetupStartParam {
    totalFrtInProgram: Int as coins;
    passiveVault: Int as coins;
}

message(0xd07d62b1) ChangeUOwner {
    id: Int as uint64;
    newOwner: Address;
    recipientExcesses: Address;
}

message(0xc2ccdad9) ChangeInfo {
    id: Int as uint64;
    levelNumber: Int as uint8;
    newInfo: TrinityInfo;
    recipientExcesses: Address;
}

message(0x530b2f70) TryActivateOneLevel {
    userId: Int as uint64;
    levelNumber: Int as uint8;
    isEarly: Bool;
}

message(0x530b2f71) TryActivateManyLevels {
    userId: Int as uint64;
    startLevelNumber: Int as uint8;
    finishLevelNumber: Int as uint8;
    isEarly: Bool;
}

message(0x7b0dbcbf) ReturnJetton {
    userId: Int as uint64;
    recipient: Address;
    autoFee: Int as coins;
    amount: Int as coins;
}

message(0x6ddf63) ClaimJetton {
    userId: Int as uint64;
    recipient: Address;
    amount: Int as coins;
    isAuto: Bool;
    recipientExcesses: Address;
}

message(0xf933be53) ClaimTon {
    amount: Int as coins;
}

message(0x6490dc2a) GetPassiveBank {}

message(0xd456c178) GetProtocolFees {}

message(0x835e82d2) GetPassiveBankFull {}

message(0x2d9ae3fe) GetJetton {
    value: Int as coins;
    recipient: Address;
    recipientExcesses: Address;
}

message(0x1c9e5b8) ChangeEditable {}

message(0xc867352c) ChangeRelaunch {}

message(0x7887435) AutoActivation {
    userId: Int as uint64;
    levelNumber: Int as uint8;
    value: Int as coins;
    recipientExcesses: Address;
}

message(0xb9c0af05) FailAutoActivate {
    levelNumber: Int as uint8;
    value: Int as coins;
    recipientExcesses: Address;
}

message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0x7362d09c) JettonNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}

message(0xd53276db) JettonExcesses {
    queryId: Int as uint64;
}
