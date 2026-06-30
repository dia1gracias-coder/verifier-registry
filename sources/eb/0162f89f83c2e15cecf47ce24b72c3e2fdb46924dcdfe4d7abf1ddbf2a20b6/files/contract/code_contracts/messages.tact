import "@stdlib/deploy";

message UpdateJettonMasterAddress {
    queryId: Int as uint64;
    address: Address;
}

message MintInitJettonsToOwner {
    queryId: Int as uint64;
    mint: Bool;
}

message(0x888bbb88) ChangePyramidaOwner {
    queryId: Int as uint64;
    owner: Address;
}

message(0xd2a7c100) DrawLottery {
    queryId: Int as uint64;
}

message JettonsBurned {
    queryId: Int as uint64;
    amount: Int as coins;
    totalSupply: Int as coins;
}

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0x178d4519) TokenTransferInternal {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    responseDestination: Address?;
    forwardAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0x7362d09c) TransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}

message(0x595f07bc) Burn {
    queryId: Int as uint64;
    amount: Int as coins;
    responseDestination: Address?;
    customPayload: Cell?;
}

message(0x7bdd97de) TokenBurnNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    responseDestination: Address?;
}

message(0xd53276db) Excesses {
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
    ownerAddress: Slice as remaining;
}

message(0xa593886f) MintJetton {
    queryId: Int as uint64;
    amount: Int as coins;
    receiver: Address;
    responseDestination: Address;
    forwardAmount: Int as coins;
    forwardPayload: Cell?;
}

message(0xe78d9033) MultiMint {
    queryId: Int as uint64;
    receivers: map<Int as uint32, MultiMintReceiver>;
    receiverCount: Int as uint32;
}

message ChangeJettonMasterOwner {
    queryId: Int as uint64;
    owner: Address;
}

message StopMinting {
    queryId: Int as uint64;
}

message UpdateJettonContent {
    queryId: Int as uint64;
    content: Cell;
}
