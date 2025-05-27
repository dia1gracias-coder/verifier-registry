message(0x85dc9ff2) W2GStartGame {
    bet: Int as uint256;
    referrer: Address?;
}

message(0x34776b1a) W2GStopGame {}

message(0xa3dfe41c) W2GRedGame {
    bet: Int as uint256;
    referrer: Address?;
}

message(0xc6326144) G2PStartPlayer {
    bet: Int as uint256;
    useBalance: Bool;
    player: Address;
    referrer: Address?;
    streakState: Int as uint64;
    greenCount: Int as uint64;
    redCount: Int as uint64;
}

message(0x37439d3) G2PStopPlayer {
    player: Address;
    streakState: Int as uint64;
    greenCount: Int as uint64;
    redCount: Int as uint64;
}

message(0x1b8b6864) G2PRedPlayer {
    price: Int as uint256;
    player: Address;
    referrer: Address?;
    streakState: Int as uint64;
    greenCount: Int as uint64;
    redCount: Int as uint64;
}

message(0x33057504) P2GTokenWithdraw {
    destination: Address;
    amount: Int as uint256;
}

message(0xc18d3b01) P2PAffRewardInternal {
    cpaReward: Int as coins;
    refShareReward: Int as coins;
    cashback: Address;
    isRed: Bool = false;
}

message(0xbc142c27) G2PTokenDeposit {
    sender: Address;
    amount: Int as uint256;
}

message(0xb99218e1) W2GTokenWithdraw {
    player: Address;
    amount: Int as uint256;
}

message(0x80f3eebc) G2PTokenWithdraw {
    player: Address;
    amount: Int as uint256;
}

message(101) InitialMint {}

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
    tonAmount: Int as coins;
    mintMessage: JettonTransferInternal;
}

message(22) CloseMinting {}

message(3) ChangeTokenOwner {
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
