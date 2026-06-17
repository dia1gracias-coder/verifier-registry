// ════════════════════════════════════════════════════════════
//  Shared message definitions — kgGRM Vault System
// ════════════════════════════════════════════════════════════

// ─── TEP-74 Jetton ──────────────────────────────────────────

// JettonWallet → Vault after tokens arrive (wrap trigger)
message(0x7362d09c) JettonTransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;                    // original user who sent tokens
    forwardPayload: Slice as remaining;
}

// Vault → its own JettonWallet to send tokens back to user (unwrap)
message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

// ─── TEP-62 NFT ─────────────────────────────────────────────

// User → NFT Item: transfer to new owner (standard TEP-62)
message(0x5fcc3d14) NFTTransfer {
    queryId: Int as uint64;
    newOwner: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

// NFT Item → new owner (Vault) after transfer
// IMPORTANT: forwardPayload must contain itemIndex (uint64) so Vault can verify
message(0x05138d91) NFTOwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;                 // original user (gets GRM back)
    forwardPayload: Slice as remaining;
}

// ─── Bootstrap ──────────────────────────────────────────────

// Owner → Vault: one-time configuration of Vault's own JettonWallet.
// Required because the wallet address can only be computed AFTER
// the Vault contract is deployed (chicken-and-egg: wallet address
// depends on vault address, which depends on init data).
message SetJettonWallet {
    jettonWallet: Address;
}

// Owner → Vault: one-time configuration of the Collection address.
// Same chicken-and-egg reason as SetJettonWallet: Vault and Collection
// each want the other's address in their init data, which is circular.
// Fix: deploy Vault first (collection = null), deploy Collection with
// the now-known Vault address, then lock Vault's collection field.
message SetCollection {
    collection: Address;
}

// ─── Internal ────────────────────────────────────────────────

// Vault → Collection: mint new kgGRM NFT for user
message Mint {
    queryId: Int as uint64;
    to: Address;
}

// Vault → Collection: burn NFT at itemIndex
message CollectionBurn {
    queryId: Int as uint64;
    itemIndex: Int as uint64;
    responseDestination: Address?;
}

// Collection → NFT Item: destroy this item
message NFTBurn {
    queryId: Int as uint64;
    responseDestination: Address?;
}

// ─── Emergency rescue (owner-only) ─────────────────────────────
//
// Safety nets for funds that end up stuck due to an edge case the
// normal wrap/unwrap flow doesn't auto-recover from (e.g. a downstream
// send failing for an unforeseen reason). These do NOT let the owner
// mint or burn arbitrarily — only move GRM/NFTs that are already
// sitting in the Vault's own balance/ownership.
message RescueJetton {
    queryId: Int as uint64;
    amount: Int as coins;
    to: Address;
}

message RescueNFT {
    queryId: Int as uint64;
    itemIndex: Int as uint64;
    to: Address;
}
