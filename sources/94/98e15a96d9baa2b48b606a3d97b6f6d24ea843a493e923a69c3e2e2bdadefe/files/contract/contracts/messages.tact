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

const TakeWalletAddressOpcode: Int = 0xd1735400;
message(TakeWalletAddressOpcode) TakeWalletAddress {
    queryId: Int as uint64;
    walletAddress: Address;
    ownerAddress: Cell?; //It is Maybe ^Address, just encoded it like this
}

message(21) Mint {
    queryId: Int as uint64;
    destination: Address;
    tonAmount: Int as coins;
    mintMessage: JettonTransferInternal;
}

message(22) CloseMinting {}

message(23) MintForReward {
    queryId: Int as uint64;
    destination: Address;
    tonAmount: Int as coins;
    mintMessage: JettonTransferInternal;
}

message(24) MintForOperation {
    queryId: Int as uint64;
    destination: Address;
    tonAmount: Int as coins;
    mintMessage: JettonTransferInternal;
}

message(25) MintForMarinaProtocol {
    queryId: Int as uint64;
    destination: Address;
    tonAmount: Int as coins;
    mintMessage: JettonTransferInternal;
}

message(26) MintForCocozNft {
    queryId: Int as uint64;
    destination: Address;
    tonAmount: Int as coins;
    mintMessage: JettonTransferInternal;
}

message(27) MintForOpenNetwork {
    queryId: Int as uint64;
    destination: Address;
    tonAmount: Int as coins;
    mintMessage: JettonTransferInternal;
}

message(3) ChangeOwner {
    queryId: Int as uint64;
    newOwner: Address;
}

// provide_wallet_balance#7ac8d559 destination:MsgAddress include_verify_info:Bool = InternalMsgBody
message(0x7ac8d559) ProvideWalletBalance {
    destination: Address;
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

// claim_ton#0393b1ce destination:MsgAddress = InternalMsgBody
message(0x0393b1ce) ClaimTON {
    destination: Address;
}

// ===== Reward Claim Messages =====
message(0xaaaa0001) AllocateRewardClaim {
    queryId: Int as uint64;
    destinations: map<Address, Int as coins>;
}

message(0xaaaa0002) RewardClaimJetton {
    queryId: Int as uint64;
}

// ===== Operation Claim Messages =====
message(0xaaaa0003) AllocateOperationClaim {
    queryId: Int as uint64;
    destinations: map<Address, Int as coins>;
}

message(0xaaaa0004) OperationClaimJetton {
    queryId: Int as uint64;
}

// ===== Marina Protocol Claim Messages =====
message(0xaaaa0005) AllocateMarinaProtocolClaim {
    queryId: Int as uint64;
    destinations: map<Address, Int as coins>;
}

message(0xaaaa0006) MarinaProtocolClaimJetton {
    queryId: Int as uint64;
}

// ===== Cocoz NFT Claim Messages =====
message(0xaaaa0007) AllocateCocozNftClaim {
    queryId: Int as uint64;
    destinations: map<Address, Int as coins>;
}

message(0xaaaa0008) CocozNftClaimJetton {
    queryId: Int as uint64;
}

// ===== The Open Network Claim Messages =====
message(0xaaaa0009) AllocateOpenNetworkClaim {
    queryId: Int as uint64;
    destinations: map<Address, Int as coins>;
}

message(0xaaaa000a) OpenNetworkClaimJetton {
    queryId: Int as uint64;
}

message(0xaaaa000b) WithdrawAll {
}
