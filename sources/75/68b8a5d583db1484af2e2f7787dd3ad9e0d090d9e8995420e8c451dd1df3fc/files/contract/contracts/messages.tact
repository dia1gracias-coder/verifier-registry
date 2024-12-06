import "./common/messages.tact";
message MakePayment {
    queryId: Int as uint64;
    payeeAddress: Address;
    payeeJettonWalletAddress: Address;
    masterJettonWalletCode: Cell;
    jettonMasterAddress: Address;
    amount: Int as coins;
    forwardPayload: Cell
}
message Deposit {
    queryId: Int as uint64;
    amount: Int as coins;
}
message ChangeMaster {
    queryId: Int as uint64;
    newMaster: Address;
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
message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}
message(0x595f07bc) TokenBurn {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    responseAddress: Address?;
}
message TokenBurnConfirmation {
    queryId: Int as uint64;
    amount: Int as coins;
}
message SafeTokenBurn {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    responseAddress: Address?;
}
message(0xd53276db) TokenExcesses {
    queryId: Int as uint64;
}
message TokenUpdateContent {
    content: Cell?;
}
// =====================================
// Project specific messages
// =====================================
// MintJetton is a message that allows the owner to mint new tokens
// and send them to a specified walletOwner.
message(0xa593886f) MintJetton {
    queryId: Int as uint64;
    amount: Int;
    receiver: Address;
    responseDestination: Address;
    forwardAmount: Int as coins;
    forwardPayload: Cell?;
}
// MultiMint is a message that allows the owner to mint new tokens for
// multiple receivers and send them to their wallets at once.
message(0xe78d9033) MultiMint {
    queryId: Int as uint64;
    receivers: map<Int as uint32, MultiMintReceiver>;
    receiverCount: Int as uint32;
}
message UpdateJettonContent {
    queryId: Int as uint64;
    content: Tep64TokenData;
}
// =====================================
// Structs
// =====================================
struct JettonWalletData {
    balance: Int;
    owner: Address;
    master: Address;
    walletCode: Cell;
}
struct JettonMasterData {
    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell;
    walletCode: Cell;
}
struct MultiMintReceiver {
    receiver: Address;
    // Amount of Jettokens to mint
    amount: Int;
    // Amount of TON to forward
    tonAmount: Int as coins;
    responseDestination: Address;
    forwardAmount: Int as coins;
    forwardPayload: Cell?;
}
// struct
// struct JettonWalletData {
//     status: Int as uint4;
//     balance: Int as coins;
//     ownerAddress: Address;
//     jettonMasterAddress: Address;
// }

struct ReceivedJettonInfo {
    jettonAmount: Int as coins;
}


