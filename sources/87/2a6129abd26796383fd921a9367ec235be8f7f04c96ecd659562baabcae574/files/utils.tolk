import "./constants";

// ─────────────────────────────────────────────────────────────────────────────
//// Address helpers
// ─────────────────────────────────────────────────────────────────────────────

fun addrNone(): address {
    // addr_none = two zero bits ($00)
    return beginCell().storeUint(0, 2).endCell().beginParse() as address;
}

fun isNoneAddress(a: address): int {
    // serialize then peek the first two tag bits: 00 -> none
    var s = beginCell().storeAddress(a).endCell().beginParse();
    return (s.preloadUint(2) == 0) ? 1 : 0;
}

fun calculateForwardFee(): int {
    // Approximation of forward fee calculation like reference's ctx.readForwardFee()
    // In TON, forward fees depend on message size and network load
    // Using conservative estimate similar to reference constants
    return ton("0.005"); // Conservative estimate for forward fee
}

fun refundExcess(to: address, queryId: int) {
    // Build internal message to `to` with proper excess opcode
    val info = beginCell()
        .storeUint(0, 1)          // internal
        .storeUint(1, 1)          // ihr_disabled
        .storeUint(1, 1)          // bounce
        .storeUint(0, 1)          // not bounced
        .storeAddress(contract.getAddress())
        .storeAddress(to)
        .storeCoins(0)            // value: 0 (mode 64 will add remaining inbound value)
        .storeDict(null)
        .storeCoins(0)
        .storeCoins(0)
        .storeUint(0, 64)
        .storeUint(0, 32)
        .endCell();

    // Build excess message body per TEP-74
    val body = beginCell()
        .storeUint(OpCode.EXCESSES as int, 32)
        .storeUint(queryId, 64)
        .endCell();

    val msg = beginCell()
        .storeSlice(info.beginParse())
        .storeUint(0, 1)          // no init
        .storeUint(1, 1)          // body by ref
        .storeRef(body)
        .endCell();

    // Carry all remaining inbound message value back to the sender
    sendRawMessage(msg, SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE); // 64
}