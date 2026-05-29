// Shared TEP-74 jetton interop for the Sooth TON fund-holding contracts (AMM / order engine /
// launchpad). The outgoing JettonTransfer body (opcode 0x0f8a7ea5) and the attached-value helper
// are byte-identical across all three, so they live here as a single source of truth.
//
// NOTE: JettonTransferNotification (0x7362d09c) is intentionally NOT shared. Its forwardPayload
// field type has diverged by design — the launchpad declares it `cell?` so it can re-parse the
// creation/yield payload as a standalone cell, while the AMM and order engine read the tail
// inline as RemainingBitsAndRefs. Each contract therefore keeps its own notification struct.
//
// The opcode is wire-significant; do NOT change it.

struct (0x0f8a7ea5) JettonTransfer {
    queryId: uint64
    amount: coins
    destination: address
    responseDestination: address
    customPayload: cell?
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

// Minimum TON to attach to a message that will emit one outgoing JettonTransfer: the transfer's
// own carried value plus a fixed overhead for the sending contract's compute/storage. The
// forwardTonAmount is contained inside jettonTransferValue, so it is not added again here.
fun requiredJettonSendValue(jettonTransferValue: coins, _forwardTonAmount: coins) {
    return jettonTransferValue + ton("0.005");
}
