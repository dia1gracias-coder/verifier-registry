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

struct TransferLimits {
    minAmount: Int as coins;
    maxAmount: Int as coins;
    canTransfer: Bool;
}

const JettonTransferOpcode: Int = 0xf8a7ea5;
message(JettonTransferOpcode) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

const JettonBurnOpcode: Int = 0x595f07bc;
message(JettonBurnOpcode) JettonBurn {
    queryId: Int as uint64;
    amount: Int as coins;
    responseDestination: Address?;
    customPayload: Cell?;
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

const JettonTransferInternalOpcode: Int = 0x178d4519;
message(JettonTransferInternalOpcode) JettonTransferInternal {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    responseDestination: Address?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0x7bdd97de) JettonBurnNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    responseDestination: Address?;
}

message(0x7bdd97df) JettonBurnNotificationWithSale {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    responseDestination: Address?;
    sellerAddress: Address;
    tonToPayOut: Int as coins;
    finalDestination: Address?;
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
    ownerAddress: Cell?;
}

message(0xd372158c) TopUp {
    queryId: Int as uint64;
}

const SetStatusOpcode: Int = 0xeed236d3;
message(SetStatusOpcode) SetStatus {
    queryId: Int as uint64;
    status: Int as uint4;
}

message(0x642b7d07) Mint {
    queryId: Int as uint64;
    toAddress: Address;
    tonAmount: Int as coins;
    masterMsg: JettonTransferInternal;
}

message(0x6501f354) ChangeAdmin {
    queryId: Int as uint64;
    newAdminAddress: Address;
}

message(0xfb88e119) ClaimAdmin {
    queryId: Int as uint64;
}

message(0x235caf52) CallTo {
    queryId: Int as uint64;
    toAddress: Address;
    tonAmount: Int as coins;
    masterMsg: Cell;
}

message(0x2508d66a) Upgrade {
    queryId: Int as uint64;
    newData: Cell;
    newCode: Cell;
}

message(0xcb862902) ChangeMetadataUri {
    queryId: Int as uint64;
    metadata: Slice as remaining;
}

message(0x7ac8d559) ProvideWalletBalance {
    receiver: Address;
    includeVerifyInfo: Bool;
}

struct VerifyInfo {
    owner: Address;
    minter: Address;
    code: Cell;
}

message(0xca77fdc2) TakeWalletBalance {
    balance: Int as coins;
    verifyInfo: VerifyInfo?;
}

message(0x4c608e7d) TokensMinted {
    to: Address;
    amount: Int as coins;
    by: Address;
}

message(0x895ec36b) TokensBurned {
    from: Address;
    amount: Int as coins;
    by: Address;
}

message(0xb95ba313) AdminChanged {
    oldAdmin: Address;
    newAdmin: Address;
}

message(0xc588313c) StatusChanged {
    wallet: Address;
    oldStatus: Int as uint4;
    newStatus: Int as uint4;
}

message(0x011138ea) PauseContract {
    pause: Bool;
}

message(0xa7c9f123) SetFee {
    queryId: Int as uint64;
    newFee: Int as uint16;
}

message(0xb1a4c5e7) SetMaxTotalSupply {
    queryId: Int as uint64;
    newMaxTotalSupply: Int as coins;
}

message(0xc2b6d8f9) SetBasePrice {
    queryId: Int as uint64;
    newBasePrice: Int as coins;
}

const SetMinTransferAmountOpcode: Int = 0xa7f8d3c1;
message(SetMinTransferAmountOpcode) SetMinTransferAmount {
    queryId: Int as uint64;
    newMinAmount: Int as coins;
}

const TransferAllTonOpcode: Int = 0x3b2f1a4e;
message(TransferAllTonOpcode) TransferAllTon {
    queryId: Int as uint64;
    responseDestination: Address?;
}

const WithdrawAllTonOpcode: Int = 0x4e2a5c6d;
message(WithdrawAllTonOpcode) WithdrawAllTon {
    queryId: Int as uint64;
    destination: Address?;
}

const BuyTokensOpcode: Int = 0x7b8e48e2;
message(BuyTokensOpcode) BuyTokens {
    queryId: Int as uint64;
    buyerAddress: Address;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

const SellTokensOpcode: Int = 0x4f2a8c3d;
message(SellTokensOpcode) SellTokens {
    queryId: Int as uint64;
    sellerAddress: Address;
    tokensAmount: Int as coins;
    responseDestination: Address?;
}

const SetSellEnabledOpcode: Int = 0x9a4b5c2e;
message(SetSellEnabledOpcode) SetSellEnabled {
    queryId: Int as uint64;
    enabled: Bool;
}

const MintTokenForTonOpcode: Int = 0x642b7d08;
message(MintTokenForTonOpcode) MintTokenForTon {
    queryId: Int as uint64;
    tokenRate: Int as coins;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0x8f5a3c2d) SetMintTokenForTonEnabled {
    queryId: Int as uint64;
    enabled: Bool;
}

const MintTokenForTonSuccessOpcode: Int = 0x7c3e9f2a;
message(MintTokenForTonSuccessOpcode) MintTokenForTonSuccess {
    queryId: Int as uint64;
    buyer: Address;
    tonAmount: Int as coins;
    tokenRate: Int as coins;
    tokensReceived: Int as coins;
    timestamp: Int as uint32;
}