message(0x85dc9ff2) W2SJoin {
    queryId: Int as uint64;
    bet: Int as coins;
    referrer: Address?;
}

message(0x34776b1a) W2SLeave {
    queryId: Int as uint64;
    forwardFee: Int as coins;
}

message(0xa3dfe41c) W2SBreak {
    queryId: Int as uint64;
    forwardFee: Int as coins;
    referrer: Address?;
}

message(0xc6326144) S2UJoin {
    bet: Int as coins;
    useBalance: Bool;
    owner: Address;
    referrer: Address?;
    streakCount: Int as uint64;
    joinCount: Int as uint64;
    breakCount: Int as uint64;
}

message(0x37439d3) S2ULeave {
    owner: Address;
    cpaRewardBase: Int as coins;
    forwardFee: Int as coins;
    refShareRewardRatio: Int as uint8;
    streakRewardRatio: Int as uint8;
    streakCount: Int as uint64;
    joinCount: Int as uint64;
    breakCount: Int as uint64;
}

message(0x1b8b6864) S2UBreak {
    price: Int as coins;
    cpaRewardBase: Int as coins;
    forwardFee: Int as coins;
    refShareRewardRatio: Int as uint8;
    breakRewardRatio: Int as uint8;
    owner: Address;
    referrer: Address?;
    streakCount: Int as uint64;
    joinCount: Int as uint64;
    breakCount: Int as uint64;
}

message(0x33057504) U2STokenWithdraw {
    amount: Int as coins;
    destination: Address;
}

message(0xc18d3b01) U2UAffRewardInternal {
    cpaReward: Int as coins;
    refShareReward: Int as coins;
    tonRefShareReward: Int as coins;
    forwardFee: Int as coins;
    referee: Address;
    cashback: Address;
}

message(0xbc142c27) S2UTokenDeposit {
    amount: Int as coins;
    sender: Address;
}

message(0xb99218e1) W2STokenWithdraw {
    queryId: Int as uint64;
    amount: Int as coins;
}

message(0x80f3eebc) S2UTokenWithdraw {
    amount: Int as coins;
    owner: Address;
}

message(0xcaac34cf) W2SChangeStreaksPrice {
    queryId: Int as uint64;
    newPrice: Int as uint256;
}

message(0x568359c2) W2SBuyStreaks {
    queryId: Int as uint64;
    telegram: String;
    email: String;
}

message(0x56d8b9c8) S2WChangeStreaksOwnerOk {
    queryId: Int as uint64;
    newOwner: Address;
}

struct JettonData {
    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell;
    jettonWalletCode: Cell;
}

struct JettonWalletData {
    balance: Int;
    owner: Address;
    minter: Address;
    code: Cell;
}

struct MaybeAddress {
    address: Address?;
}

message(4) JettonUpdateContent {
    queryId: Int as uint64;
    content: Cell;
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

message(0x178d4519) JettonTransferInternal {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    responseDestination: Address?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0x7362d09c) JettonNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}

message(0x595f07bc) JettonBurn {
    queryId: Int as uint64;
    amount: Int as coins;
    responseDestination: Address?;
    customPayload: Cell?;
}

message(0x7bdd97de) JettonBurnNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    responseDestination: Address?;
}

message(0xd53276db) JettonExcesses {
    queryId: Int as uint64;
}

message(0x2c76b973) ProvideWalletAddress {
    queryId: Int as uint64;
    ownerAddress: Address;
    includeAddress: Bool;
}

message(0xd1735400) TakeWalletAddress {
    queryId: Int as uint64;
    walletAddress: Address;
    ownerAddress: Cell?; //It is Maybe ^Address, just encoded it like this
}

message(0x642b7d07) Mint {
    queryId: Int as uint64;
    receiver: Address;
    mintMessage: JettonTransferInternal;
}

message(22) CloseMinting {}

message(3) ChangeOwner {
    queryId: Int as uint64;
    newOwner: Address;
}

// provide_wallet_balance#7ac8d559 receiver:MsgAddress include_verify_info:Bool = InternalMsgBody
message(0x7ac8d559) ProvideWalletBalance {
    receiver: Address;
    includeVerifyInfo: Bool;
}

struct VerifyInfo {
    owner: Address;
    minter: Address;
    code: Cell;
}

// verify_info$_ owner:MsgAddress minter:MsgAddress code:^Cell = VerifyInfo
// take_wallet_balance#ca77fdc2 balance:Coins verify_info:(Maybe VerifyInfo) = InternalMsgBody
message(0xca77fdc2) TakeWalletBalance {
    balance: Int as coins;
    verifyInfo: VerifyInfo?;
}

// claim_ton#0393b1ce receiver:MsgAddress = InternalMsgBody
message(0x0393b1ce) ClaimTON {
    receiver: Address;
}

// Binary messages
message(0xcfd88fae) ClaimTonJettonWallet {}
message(0xba97d26a) Excesses {}
message(0xf6d488f4) ExtendChangeInterval {}
message(0xccc2cd58) ReduceChangeInterval {}
message(0xecb7a380) ExtendMaxBet {}
message(0xafc0584) ReduceMaxBet {}
message(0xc034083d) ExtendMinBet {}
message(0x8b2956f3) ReduceMinBet {}
message(0x65215ed7) ExtendStreakRewardRatio {}
message(0x52c13721) ReduceStreakRewardRatio {}
message(0x464cc487) ExtendJoinPrice {}
message(0x36ce804) ReduceJoinPrice {}
message(0x6f9065c9) ExtendBreakPriceBase {}
message(0xabb7aedd) ReduceBreakPriceBase {}
message(0xe612b50a) ExtendBreakRewardRatio {}
message(0x19bbacc9) ReduceBreakRewardRatio {}
message(0xdc4e8748) ExtendBreakPriceChangeInterval {}
message(0x45aff5ca) ReduceBreakPriceChangeInterval {}
message(0xbae277e) ClaimTonAsOwner {}
message(0x2d9995ff) InitialMint {}
message(0x55cd6216) CloseMint {}
