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

// Canonical server-signature messages (shared between proxy and logic)
inline fun buildCreateSigMessage(player: Address, betAmount: Int, hashCommitment: Cell, expectedServerNonce: Int, serverTimestamp: Int): Cell {
  return beginCell()
    .storeAddress(player)
    .storeCoins(betAmount)
    .storeRef(hashCommitment)
    .storeUint(expectedServerNonce, 64)
    .storeUint(serverTimestamp, 32)
    .endCell();
}

inline fun buildCashoutSigMessage(gameId: Int, payoutAmount: Int, multiplier: Int, moves: Cell, expectedServerNonce: Int): Cell {
  return beginCell()
    .storeUint(gameId, 64)
    .storeCoins(payoutAmount)
    .storeUint(multiplier, 16)
    .storeRef(moves)
    .storeUint(expectedServerNonce, 64)
    .endCell();
}

inline fun buildMarkLostSigMessage(gameId: Int, gameSeed: Cell, gameSalt: Cell, expectedServerNonce: Int): Cell {
  return beginCell()
    .storeUint(gameId, 64)
    .storeRef(gameSeed)
    .storeRef(gameSalt)
    .storeUint(expectedServerNonce, 64)
    .endCell();
}

// Refund signature message (backend-authorized, no moves assumed on-chain)
inline fun buildRefundSigMessage(gameId: Int, expectedServerNonce: Int, serverTimestamp: Int): Cell {
  return beginCell()
    .storeUint(gameId, 64)
    .storeUint(expectedServerNonce, 64)
    .storeUint(serverTimestamp, 32)
    .endCell();
}

// Removed execute-cashout message; cashouts are immediate

// Merkle helpers (shared protocol)
inline fun hashPair(left: Int, right: Int): Int {
  return beginCell().storeUint(left, 256).storeUint(right, 256).endCell().hash();
}

inline fun verifyMerkle(leafHash: Int, root: Int, proof: Cell): Bool {
  if (root == 0) { return false; }
  let s: Slice = proof.asSlice();
  let steps: Int = s.loadUint(16);
  let acc: Int = leafHash;
  let i: Int = 0;
  while (i < steps) {
    let dir: Int = s.loadUint(1); // 0 = left, 1 = right
    let sib: Int = s.loadUint(256);
    if (dir == 0) { acc = hashPair(acc, sib); } else { acc = hashPair(sib, acc); }
    i += 1;
  }
  return acc == root;
}

inline fun buildAffiliateRegistryLeafHash(codeHash: Int, addr: Address, pubKey: Int, bannedBit: Int, index: Int): Int {
  let leaf: Cell = beginCell()
    .storeUint(codeHash, 256)
    .storeAddress(addr)
    .storeUint(pubKey, 256)
    .storeUint(bannedBit, 1)
    .storeUint(index, 32)
    .endCell();
  return leaf.hash();
}

inline fun buildAffiliateEarningsLeafHash(epoch: Int, index: Int, addr: Address, amount: Int): Int {
  let leaf: Cell = beginCell()
    .storeUint(epoch, 32)
    .storeUint(index, 32)
    .storeAddress(addr)
    .storeCoins(amount)
    .endCell();
  return leaf.hash();
}

inline fun buildClaimNullifier(epoch: Int, index: Int, addr: Address): Int {
  return beginCell().storeUint(epoch, 32).storeUint(index, 32).storeAddress(addr).endCell().hash();
}

inline fun buildGameLeafHash(epoch: Int, gameId: Int, player: Address, bet: Int, createdAt: Int, maxPayout: Int, hashCommitment: Int): Int {
  let leaf: Cell = beginCell()
    .storeUint(epoch, 32)
    .storeUint(gameId, 64)
    .storeAddress(player)
    .storeCoins(bet)
    .storeUint(createdAt, 32)
    .storeCoins(maxPayout)
    .storeUint(hashCommitment, 256)
    .endCell();
  return leaf.hash();
}