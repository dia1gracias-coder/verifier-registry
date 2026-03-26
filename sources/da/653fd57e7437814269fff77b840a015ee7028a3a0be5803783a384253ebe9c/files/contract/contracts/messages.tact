// ─── Platform messages ────────────────────────────────────────────────────────

/// Sent by user to JettonFactory to request a new jetton deployment.
message(0x1a2b3c4d) DeployJetton {
    tierPro:     Bool;           // false = Base (1.5 TON), true = Pro (3 TON)
    name:        String;
    symbol:      String;
    decimals:    Int as uint8;
    maxSupply:   Int as coins;
    mintable:    Bool;
    burnable:    Bool;
    pausable:    Bool;           // owner can pause/resume all transfers
    freezable:   Bool;           // owner can freeze specific wallets
    metadataUri: String;         // ipfs://... TEP-64 metadata JSON
}

/// Emitted back to user after successful deploy.
message(0x2b3c4d5e) JettonDeployed {
    minterAddress: Address;
    queryId:       Int as uint64;
}

// ─── TEP-74 standard messages ─────────────────────────────────────────────────

message(0x0f8a7ea5) TokenTransfer {
    queryId:             Int as uint64;
    amount:              Int as coins;
    destination:         Address;
    responseDestination: Address?;
    customPayload:       Cell?;
    forwardTonAmount:    Int as coins;
    forwardPayload:      Slice as remaining;
}

message(0x178d4519) TokenTransferInternal {
    queryId:             Int as uint64;
    amount:              Int as coins;
    from:                Address;
    responseDestination: Address?;
    forwardTonAmount:    Int as coins;
    forwardPayload:      Slice as remaining;
}

message(0x7362d09c) TokenNotification {
    queryId:        Int as uint64;
    amount:         Int as coins;
    from:           Address;
    forwardPayload: Slice as remaining;
}

message(0x595f07bc) TokenBurn {
    queryId:             Int as uint64;
    amount:              Int as coins;
    responseDestination: Address?;
    customPayload:       Cell?;
}

message(0x7bdd97de) TokenBurnNotification {
    queryId:             Int as uint64;
    amount:              Int as coins;
    sender:              Address;
    responseDestination: Address?;
}

message(0xd53276db) TokenExcesses {
    queryId: Int as uint64;
}

message(0x642b7d07) TokenUpdateContent {
    content: Cell;
}

// ─── Mint messages ────────────────────────────────────────────────────────────

message(0x00000001) Mint {
    queryId:  Int as uint64;
    amount:   Int as coins;
    receiver: Address;
}

// ─── Admin messages (owner only) ──────────────────────────────────────────────

/// Freeze or unfreeze a specific wallet address.
/// frozen = true → wallet cannot send or receive tokens.
message(0x4a6f7e8f) FreezeWallet {
    target: Address;
    frozen: Bool;
}

/// Step 1 of 2-step ownership transfer: propose a new owner.
/// The new owner must call AcceptOwnership to complete the transfer.
message(0x5b7c8d9e) ProposeOwner {
    newOwner: Address;
}

/// Step 2 of 2-step ownership transfer: accept ownership.
/// Must be called by the pending owner address set in ProposeOwner.
message(0x6c8d9eaf) AcceptOwnership {
    queryId: Int as uint64;
}

/// Query sent from JettonWallet to JettonMinter to check if a wallet is frozen.
/// Used internally to validate transfers.
message(0x7d9eafb0) CheckFrozen {
    queryId:  Int as uint64;
    target:   Address;
    callback: Address;  // wallet that asked (receives the response)
}
