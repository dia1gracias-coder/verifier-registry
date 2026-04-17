tolk 1.3

// ─── Storage ────────────────────────────────────────────────────────────────

struct Storage {
    id: uint32
}

fun Storage.load() {
    return Storage.fromCell(contract.getData())
}

// ─── Constants ──────────────────────────────────────────────────────────────

const PARI_OP = 0xaabbccef;                    
const PARI_OP_WITH_REF = 0xaabbccf0;           
const WIN_AMOUNT_PER_TICKET = 100000000;       // 0.1 TON
const PARI_EXECUTION_FEE = 100000000;          // 0.1 TON covers Pari contract gas
const FALLBACK_ADDR = address("UQAMBcOMQ2TundT4ZIv9S0rag4l9GmSLYU_aYUethISN7lvM");
const CONTRACT_RESERVE = 10000000;              // 0.01 TON kept on contract

// ─── Message types ──────────────────────────────────────────────────────────

// Direct mode: body starts with this opcode
struct (0x50415249) ProxyForward {
    pariAddress: address
    pariCell: cell                              // ref → Pari payload
}

// Wrapped mode: pTON ton_transfer from DEX
struct (0x01f3835d) PtonTonTransfer {
    queryId: uint64
    tonAmount: coins
    refundAddress: address
    forwardPayload: RemainingBitsAndRefs       // Either bit + payload
}

type ProxyMessage = ProxyForward | PtonTonTransfer

// ─── Refund helper ──────────────────────────────────────────────────────────
// Sends (msgValue - 0.01 TON) to dest, keeping 0.01 on contract for storage.
// If msgValue <= 0.01 TON — dust, keep everything.

fun sendRefund(dest: address, msgValue: int) {
    val toSend = msgValue - CONTRACT_RESERVE;
    if (toSend <= 0) { return; }
    createMessage({
        bounce: BounceMode.NoBounce,
        dest: dest,
        value: toSend,
    }).send(SEND_MODE_REGULAR);
}

// ─── Payload processing ─────────────────────────────────────────────────────
//
// batchCell ref layout:
//   opcode:      uint32 (must be 0xaabbccef)
//   beneficiary: address
//   isYes:       bool
//   entries:     map<uint8, cell{yesOdds: uint7, ticketsCount: uint32}>
//
// Validates payload, calculates cost, forwards to Pari or refunds.
// On parse error → refunds to refundDest.

fun processForward(pariAddress: address, pariCell: cell, msgValue: int, refundDest: address) {
    try {
        var bpb = pariCell.beginParse();
        val bpbOpcode = bpb.loadUint(32);
        assert(bpbOpcode == PARI_OP || bpbOpcode == PARI_OP_WITH_REF) throw 0xFFFE;
        val beneficiary = bpb.loadAddress();
        val isYes = bpb.loadBool();
        val entriesDict = bpb.loadDict();
        val entriesMap = createMapFromLowLevelDict<uint8, cell>(entriesDict);

        var totalCost = 0;
        var r = entriesMap.findFirst();
        while (r.isFound) {
            var entrySlice = r.loadValue().beginParse();
            val yesOdds = entrySlice.loadUint(7);
            val ticketsCount = entrySlice.loadUint(32);

            var ticketCost = 0;
            if (isYes) {
                ticketCost = WIN_AMOUNT_PER_TICKET * yesOdds / 100;
            } else {
                ticketCost = WIN_AMOUNT_PER_TICKET * (100 - yesOdds) / 100;
            }

            totalCost += PARI_EXECUTION_FEE + ticketCost * ticketsCount;
            r = entriesMap.iterateNext(r);
        }

        if (msgValue >= totalCost + CONTRACT_RESERVE) {
            // Forward exactly totalCost to Pari; forward fee paid from contract balance
            createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                dest: pariAddress,
                value: totalCost,
                body: pariCell,
            }).send(SEND_MODE_PAY_FEES_SEPARATELY);

            // Return change to refundDest; forward fee deducted from change
            val change = msgValue - totalCost - CONTRACT_RESERVE;
            if (change > 0) {
                createMessage({
                    bounce: BounceMode.NoBounce,
                    dest: refundDest,
                    value: change,
                }).send(SEND_MODE_REGULAR | SEND_MODE_IGNORE_ERRORS);
            }
        } else {
            sendRefund(refundDest, msgValue);
        }
    } catch (excNo) {
        sendRefund(refundDest, msgValue);
    }
}

// ─── Main entrypoint ────────────────────────────────────────────────────────
//
// Two opcodes supported:
//   0x50415249 (ProxyForward)  — direct mode, payload in body
//   0x01f3835d (PtonTonTransfer) — DEX wrapper, payload in forward_payload
// Any other opcode or empty body → FALLBACK_ADDR

fun onInternalMessage(in: InMessage) {
    try {
        val msg = lazy ProxyMessage.fromSlice(in.body);
        match (msg) {
            ProxyForward => {
                processForward(msg.pariAddress, msg.pariCell, in.valueCoins, in.senderAddress);
            }
            PtonTonTransfer => {
                // Extract forward_payload from Either encoding (bit=1 → ref, bit=0 → inline)
                var fp: slice = msg.forwardPayload;
                val isRight = fp.loadBool();
                var fwdSlice: slice;
                if (isRight) {
                    fwdSlice = fp.loadRef().beginParse();
                } else {
                    fwdSlice = fp;
                }

                val fwdOpcode = fwdSlice.loadUint(32);
                if (fwdOpcode != 0x50415249) {
                    sendRefund(msg.refundAddress, in.valueCoins);
                    return;
                }

                val pariAddr = fwdSlice.loadAddress();
                val pariCell = fwdSlice.loadRef();
                processForward(pariAddr, pariCell, in.valueCoins, msg.refundAddress);
            }
            else => {
                sendRefund(FALLBACK_ADDR, in.valueCoins);
            }
        }
    } catch (excNo) {
        sendRefund(FALLBACK_ADDR, in.valueCoins);
    }
}

fun onBouncedMessage(in: InMessageBounced) {
    sendRefund(FALLBACK_ADDR, in.valueCoins);
}

get fun initialId(): int {
    val storage = lazy Storage.load();
    return storage.id;
}
