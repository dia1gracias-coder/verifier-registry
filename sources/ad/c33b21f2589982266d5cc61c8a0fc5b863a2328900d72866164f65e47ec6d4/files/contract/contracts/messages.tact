// ─── JettonMaker V4 — messages.tact ──────────────────────────────────────────

// ─── Platform messages ────────────────────────────────────────────────────────

/// Sent by user to JettonFactory to request a new jetton deployment.
message(0x1a2b3c4d) DeployJetton {
    tierPro:     Bool;           // false = Base (0.6 TON), true = Pro (0.7 TON)
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
/// frozen = true → wallet cannot send or burn tokens (sender check); cannot receive (dest check).
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

// ─── V4: Transfer routing through minter (pause/freeze enforcement) ───────────
//
// V4 transfer flow (synchronous pause + freeze enforcement):
//
//   1. User → TokenTransfer → JettonWallet
//      Wallet: checks owner, checks balance, deducts balance,
//              sends TokenTransferViaRouter to JettonMinter with SendRemainingValue.
//
//   2. JettonWallet → TokenTransferViaRouter → JettonMinter
//      Minter: verifies sender is the legitimate source wallet (initOf check),
//              checks transfersPaused (if pausable),
//              checks frozen[msg.from] (if freezable),
//              checks frozen[msg.destination] (if freezable),
//              sends TokenTransferInternal to destination wallet (fixed gas).
//
//   Rejection path — minter require() fails → message bounces:
//      bounced<TokenTransferViaRouter> → JettonWallet → self.balance += src.amount  ✅
//
//   Dest-wallet bounce path — destination wallet rejects TokenTransferInternal:
//      bounced<TokenTransferInternal> → JettonMinter
//      Minter distinguishes mint vs transfer by checking src.from == myAddress():
//        - Mint bounce  → self.totalSupply -= src.amount
//        - Transfer bounce → send TokenTransferInternal to source wallet (restores balance)
//
// NOTE: `from` carries the wallet owner address (not the wallet contract address).
//       The minter uses it to verify the source wallet via initOf and to look up frozen map.
//       `destination` is also a wallet owner address (not wallet contract address).

/// Sent by minter to destination wallet to credit tokens during a routed transfer.
/// Separate from TokenTransferInternal (used for mints) so the minter can
/// distinguish the two in bounce handlers without needing to read fields
/// beyond the 224-bit bounced-message limit.
/// Fields: queryId(64) + amount(coins≤124) = ≤188 bits — safely within bounce limit.
message(0x22334455) TokenTransferCredit {
    queryId:             Int as uint64;
    amount:              Int as coins;
    from:                Address;        // source wallet owner (for TokenNotification)
    responseDestination: Address?;
    forwardTonAmount:    Int as coins;
    forwardPayload:      Slice as remaining;
}

message(0x11223344) TokenTransferViaRouter {
    queryId:             Int as uint64;
    amount:              Int as coins;
    from:                Address;        // source wallet owner address
    destination:         Address;        // destination wallet owner address
    responseDestination: Address?;
    customPayload:       Cell?;
    forwardTonAmount:    Int as coins;
    forwardPayload:      Slice as remaining;
}
