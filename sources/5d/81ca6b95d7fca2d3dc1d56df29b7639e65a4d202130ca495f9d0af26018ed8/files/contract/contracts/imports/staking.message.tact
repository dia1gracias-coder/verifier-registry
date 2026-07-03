// ============================================================
// StakingVault — messages & structs (self-contained)
// ------------------------------------------------------------
// Re-declares the TEP-74 subset locally (like vesting.message.tact) so the
// standard transfer_notification opcode 0x7362d09c does NOT clash with
// MiningNotification in imports/messages.tact.
//
// Design = "thin vault" (data off-chain, trust backend):
//   - The vault only custodies $1 (principal pool + reward treasury) and a few counters.
//   - Every payout (unstake-flexible / execute-unstake / claim-matured / claim-rewards)
//     is authorized by a backend Ed25519 signature (StakingWithdraw).
//   - Positions, plan snapshot, lock/maturity, 24h early-unstake, accrual & auto-compound
//     all live OFF-CHAIN (backend DB + immutable on-chain tx history via the indexer).
// ============================================================

// TEP-74 jetton transfer (0x0f8a7ea5) — the vault PAYS OUT via its jetton wallet.
message(0x0f8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

// TEP-74 transfer_notification (0x7362d09c) — the vault RECEIVES $1 here.
// forward_payload op: 1 = stake (+ planId uint32), 2 = fund treasury (owner only).
message(0x7362d09c) StakeNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining;
}

// TEP-74 excesses (0xd53276db) — leftover TON returned after a transfer.
message(0xd53276db) TokenExcesses {
    queryId: Int as uint64;
}

// -------------------- admin --------------------
message SetStakingJettonWallet { jettonWallet: Address; }
message SetRewardSigner { publicKey: Int as uint256; } // backend Ed25519 pubkey (0 = withdrawals blocked)
message SetStakeSigner  { publicKey: Int as uint256; } // backend Ed25519 pubkey for stake vouchers (0 = stakes blocked)
message SetMinStake { amount: Int as coins; }
message SetMaxWithdrawPerTx { amount: Int as coins; } // 0 = unlimited; owner should set a real cap (C6)
message StakingPause {}
message StakingUnpause {}
message DefundTreasury { amount: Int as coins; to: Address; }      // owner reclaims UNUSED reward pool only (never principal) (C5)
message WithdrawStakingTon { amount: Int as coins; }               // stuck TON, keeps a reserve
message PrunePayout { id: Int as uint64; }                          // owner cleanup for a stale pending record (C9)

// -------------------- backend-signed payout --------------------
// One entry point for ALL withdrawals; the backend only signs when its off-chain rules
// (lock/maturity/24h timelock/forfeit/accrual) allow. `principal`/`reward` may be 0 independently:
//   flexible unstake -> principal + reward   |  execute-unstake (post 24h) -> principal only
//   matured claim    -> principal + reward   |  flexible claim rewards     -> reward only
message StakingWithdraw {
    user: Address;           // recipient; the signature is bound to this address
    principal: Int as coins; // principal released (decrements totalStakedPrincipal)
    reward: Int as coins;    // reward released from treasury (decrements rewardTreasury)
    nonce: Int as uint64;    // per-user monotonic replay guard; must == lastNonce + 1
    deadline: Int as uint64; // unix seconds; rejected once now() > deadline
    signature: Slice as remaining; // 64-byte Ed25519 over the payload hash (see StakingVault)
}

// Kept per in-flight payout so a bounced TokenTransfer can roll the counters back.
struct PayoutRecord {
    user: Address;
    principal: Int as coins;
    reward: Int as coins;
}

// Full vault snapshot — one getter call returns everything the backend/monitor needs.
struct VaultState {
    owner: Address;
    jettonWallet: Address?;
    rewardSigner: Int as uint256;
    stakeSigner: Int as uint256;
    paused: Bool;
    minStake: Int as coins;
    totalStakedPrincipal: Int as coins; // total principal held (obligation)
    rewardTreasury: Int as coins;       // reward pool remaining
    tonBalance: Int as coins;           // TON left to pay gas for payouts
}
