// ── Status constants ──────────────────────────────────────────────
const STATUS_ACTIVE: Int = 0;
const STATUS_PAUSED: Int = 1;
const STATUS_CLOSED: Int = 2;

// ── Incoming messages ─────────────────────────────────────────────

// client sends TON to fund the contract (no body needed, just value)
message Fund {}

// contractor calls this to receive payment for a completed period
message Claim {}

// either party proposes a check-in with a hash of the report
message ProposeCheckin {
    reportHash: Int as uint256;
}

// the other party confirms the proposed check-in
message ConfirmCheckin {}

// either party pauses the contract
message Pause {}

// client withdraws remaining balance after grace period
message WithdrawClient {}

// mutual close: contractor sends this with client's signature over a Close payload
message Close {
    clientSignature: Slice; // 64-byte ed25519 sig of close_payload cell
}

// ── Internal / utility ────────────────────────────────────────────

// payload that both parties sign for op::close
// hash(ClosePayload) is what client signs off-chain
struct ClosePayload {
    contractAddress: Address;
    timestamp:        Int as uint32;
}
