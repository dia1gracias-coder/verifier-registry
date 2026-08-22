import "@stdlib/deploy";

message UpdateJettonMasterAddress {
    queryId: Int as uint64;
    address: Address;
}

// Redeploy migration: mint the old network's balances directly to their
// holders (owner-only, until sealed). The first batch also deploys the
// jetton master. Replaces the former one-shot 100M owner premint.
struct SnapshotMintEntry {
    receiver: Address;
    amount: Int as coins;
}

message MintSnapshotBatch {
    queryId: Int as uint64;
    count: Int as uint8;
    entries: map<Int, SnapshotMintEntry>;
}

message SealSnapshotMint {
    queryId: Int as uint64;
}

// Gift lottery tickets to the owner of a numeric invite key. Works like a
// normal buy for the GIFTER's referral chain (commissions + registration),
// while the tickets and the PRMD mint go to the key's wallet. If the key was
// never issued (or never bound), the tickets go to the gifter instead.
// `refKey` is the invite key of the GIFTER's own referrer (first-touch, used
// only if the gifter is not registered yet); 0 = the ecosystem owner key,
// same as a buy without a comment.
message(0x50524650) GiftTickets {
    queryId: Int as uint64;
    key: Int as uint64;
    refKey: Int as uint64;
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

// The jetton master's own rent reserve fell below the alert horizon: it asks
// its minter (the game contract holding the lottery bank) to top it back up
// to the full target horizon. `deficit` is the TON needed to get there.
message(0x52454e54) RequestRentRefill {
    queryId: Int as uint64;
    deficit: Int as coins;
}

// Rent top-up carried as the message value. Accepted from anyone — a donation
// can only help; the master just keeps the value on its balance.
message(0x52454e46) RentRefill {
    queryId: Int as uint64;
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

message(0x5a4d0020) SetMinter {
    queryId: Int as uint64;
    minter: Address;
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

