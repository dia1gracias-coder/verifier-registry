// ===============================
// Reekt.Fun — Actions & Helpers (shared)
// ===============================

// Optional typed action envelope if you prefer explicit kinds.
// Else, you can let responses carry raw message Cells (confirmation/payout).

const ACTION_SEND_MESSAGE: Int      = 0x01;
const ACTION_SEND_CONFIRMATION: Int = 0x02;

struct Action {
  kind: Int;        // ACTION_*
  to: Address;
  amount: Int;
  data: Cell;       // payload cell
}

// Tiny helper to pack a confirmation (proxy will send it)
fun buildConfirmation(op: Int, gameId: Int, amount: Int, extra: Cell): Cell {
  return beginCell()
    .storeUint(op, 32)
    .storeUint(gameId, 64)
    .storeCoins(amount)
    .storeRef(extra)
    .endCell();
}