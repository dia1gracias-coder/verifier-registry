// Shared messages & server-signed vouchers for the LRS auction contracts.
// Design: api/onchain-contracts-spec.md. Every releasing action is authorised by an
// ed25519 voucher the server signs over a canonical struct that INCLUDES the target
// escrow address and a strictly-increasing nonce (replay- and cross-contract-proof).
//
// Signature convention: server signs `<Payload>.toCell().hash()`; the contract calls
// checkSignature(hash, signature, serverPubKey). Signatures are raw 64-byte ed25519.

// --- Settlement (Split payout terms; also the escrow->Split PayWin trigger) --------
// One server signature over these terms authorises BOTH the winner's escrow to release
// `price` to Split AND Split to divide it 95/5 for `seller`. Bond is credited: the
// winner tops up (price - bond); the escrow already holds the bond, so its balance
// covers `price` (onchain-contracts-spec §5, §7 flow C).
struct SettleTerms {
    escrow: Address;        // which BondEscrow releases the funds
    listingId: Int as uint64;
    seller: Address;        // 95% recipient
    price: Int as coins;    // total distributed by Split
    expiry: Int as uint32;  // unix; voucher void after this
    nonce: Int as uint64;   // per-escrow settle nonce, strictly increasing
}

message(0x5e771e01) Settle {
    terms: SettleTerms;
    signature: Slice as bytes64;  // server ed25519 over terms.toCell().hash()
}

// --- Hold attestation (server tells the escrow how much is currently bonded) -------
struct HoldTerms {
    escrow: Address;
    held: Int as coins;     // TON reserved as bonds right now
    expiry: Int as uint32;  // THIS is the griefing timeout T: once past, held -> 0
    nonce: Int as uint64;
}

message(0x40bd0001) UpdateHold {
    terms: HoldTerms;
    signature: Slice as bytes64;
}

// --- Withdrawal fast path (server voucher attests the free balance) ----------------
struct WithdrawTerms {
    escrow: Address;
    maxWithdrawable: Int as coins;
    expiry: Int as uint32;
    nonce: Int as uint64;
}

message(0x77d40001) WithdrawSigned {
    amount: Int as coins;          // player-chosen, <= maxWithdrawable
    terms: WithdrawTerms;
    signature: Slice as bytes64;
}

// --- Withdrawal timeout path (no server voucher; bounded by the stored HoldTerms) --
// Owner-only. Available = balance - reserve - (unexpired stored held). After the
// stored hold's expiry lapses, held is treated as 0 -> player withdraws everything.
message(0x77d40002) Withdraw {
    amount: Int as coins;
}

// --- Forfeit (server-authorised: bond -> seller only, on proven post-win default) --
struct ForfeitTerms {
    escrow: Address;
    seller: Address;        // the ONLY allowed recipient
    amount: Int as coins;   // the bond amount
    expiry: Int as uint32;
    nonce: Int as uint64;
}

message(0xf0f0e001) Forfeit {
    terms: ForfeitTerms;
    signature: Slice as bytes64;
}
