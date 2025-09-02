message RewardRequest {
    signature: Cell;
    contract: Address;
    recipient: Address;
    amount: Int as coins;
    nonce: Int as uint64;
    validUntil: Int as uint32;
}

// ===== Admin (owner-only) =====
message SetBackendKey {
    pubkey: Int as uint256;
}
message SetMaxPayout {
    amount: Int as coins;
}
message SetMinPayout {
    amount: Int as coins;
}
message SetTreasuryWallet {
    addr: Address;
}

// ===== Events =====
struct PayoutExecutedEvent {
    recipient: Address;
    amount: Int as coins;
    nonce: Int as uint64;
}

struct BackendKeyRotatedEvent {
    keyHash: Int as uint256;
}