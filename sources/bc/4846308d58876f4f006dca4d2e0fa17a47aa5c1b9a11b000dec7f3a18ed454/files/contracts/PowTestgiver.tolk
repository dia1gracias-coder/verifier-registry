import "@stdlib/gas-payments"
import "@stdlib/tvm-lowlevel"
// Advanced TestGiver smart contract with Proof-of-Work verification

fun ufits(x: int, bits: int): int
    asm "UFITSX";

fun onInternalMessage(_inMsg: slice) {
  // do nothing for internal messages
}

@inline_ref
fun checkProofOfWork(cs: slice) {
  var hash = cs.hash();
  var ds = contract.getData().beginParse();
  var (storedSeqnoSw, publicKey, seed, powComplexity) = (ds.loadUint(64), ds.loadUint(256), ds.loadUint(128), ds.loadUint(256));
  assert(hash < powComplexity) throw 24;
  var (op, flags, expire, whom, rdata1, rseed, rdata2) = (cs.loadUint(32), cs.loadInt(8), cs.loadUint(32), cs.loadUint(256), cs.loadUint(256), cs.loadUint(128), cs.loadUint(256));
  cs.assertEnd();
  ufits(expire - blockchain.now(), 10);
  assert((rseed == seed) & (rdata1 == rdata2)) throw 25;
  acceptExternalMessage();
  random.initialize();
  random.initializeBy(rdata1);
  var (lastSuccess, xdata) = (ds.loadUint(32), ds.loadRef());
  ds.assertEnd();
  ds = xdata.beginParse();
  var (amount, targetDelta, minCpl, maxCpl) = (ds.loadCoins(), ds.loadUint(32), ds.loadUint(8), ds.loadUint(8));
  ds.assertEnd();
  var delta: int = blockchain.now() - lastSuccess;
  if (delta > 0) {
    var factor: int = mulDivRound(delta, 1 << 128, targetDelta);
    factor = min(max(factor, 7 << 125), 9 << 125);
    powComplexity = mulDivRound(powComplexity, factor, 1 << 128);
    powComplexity = min(max(powComplexity, 1 << minCpl), 1 << maxCpl);
  }
  contract.setData(beginCell()
    .storeUint(storedSeqnoSw, 64)
    .storeUint(publicKey, 256)
    .storeUint(random.uint256() >> 128, 128)
    .storeUint(powComplexity, 256)
    .storeUint(blockchain.now(), 32)
    .storeRef(xdata)
    .endCell());
  commitContractDataAndActions();
  sendRawMessage(beginCell()
    .storeUint(((flags & 1) << 6) | 0x84, 9)
    .storeInt(flags >> 2, 8)
    .storeUint(whom, 256)
    .storeCoins(amount)
    .storeUint(0, 1 + 4 + 4 + 64 + 32 + 1 + 1)
  .endCell(), 3);
}

@inline_ref
fun rescaleComplexity(cs: slice) {
  var (op, expire) = (cs.loadUint(32), cs.loadUint(32));
  cs.assertEnd();
  var time: int = blockchain.now();
  assert(time > expire) throw 28;
  var ds = contract.getData().beginParse();
  var (skippedData, powComplexity, lastSuccess, xdata) = (ds.loadBits(64 + 256 + 128), ds.loadUint(256), ds.loadUint(32), ds.loadRef());
  ds.assertEnd();
  assert(expire > lastSuccess) throw 29;
  ds = xdata.beginParse();
  var (amount, targetDelta) = (ds.loadCoins(), ds.loadUint(32));
  var delta: int = time - lastSuccess;
  assert(delta >= targetDelta * 16) throw 30;
  acceptExternalMessage();
  var (minCpl, maxCpl) = (ds.loadUint(8), ds.loadUint(8));
  ds.assertEnd();
  var factor: int = mulDivRound(delta, 1 << 128, targetDelta);
  var maxComplexity: int = (1 << maxCpl);
  var maxFactor: int = mulDivFloor(maxComplexity, 1 << 128, powComplexity);
  powComplexity = (maxFactor < factor ? maxComplexity : mulDivRound(powComplexity, factor, 1 << 128));
  lastSuccess = time - targetDelta;
  contract.setData(beginCell()
    .storeSlice(skippedData)
    .storeUint(powComplexity, 256)
    .storeUint(lastSuccess, 32)
    .storeRef(xdata)
    .endCell());
}

@inline_ref
fun slice.updateParams(mutate self, pref: cell): void {
  var cs = pref.beginParse();
  var resetCpl = cs.loadUint(8);
  var (seed, powComplexity, lastSuccess) = (self.loadUint(128), self.loadUint(256), self.loadUint(32));
  if (resetCpl != 0) {
    random.initializeBy(seed);
    powComplexity = (1 << resetCpl);
    seed = (random.uint256() >> 128);
  }
  var c = beginCell()
    .storeUint(seed, 128)
    .storeUint(powComplexity, 256)
    .storeUint(blockchain.now(), 32)
    .storeRef(beginCell().storeSlice(cs).endCell())
    .endCell();
  self = c.beginParse();
  return;
}

fun onExternalMessage(inMsg: slice) {
  var op = inMsg.preloadUint(32);
  if (op == 0x4d696e65) { return checkProofOfWork(inMsg); }
  if (op == 0x5253636c) { return rescaleComplexity(inMsg); }
  var signature = inMsg.loadBits(512);
  var cs = inMsg;
  var (subwalletId, validUntil, msgSeqno) = (cs.loadUint(32), cs.loadUint(32), cs.loadUint(32));
  assert(!(validUntil <= blockchain.now())) throw 35;
  var ds = contract.getData().beginParse();
  var (storedSeqno, storedSubwallet, publicKey) = (ds.loadUint(32), ds.loadUint(32), ds.loadUint(256));
  assert(msgSeqno == storedSeqno) throw 33;
  assert((subwalletId == storedSubwallet) | (subwalletId == 0)) throw 34;
  assert(isSignatureValid(inMsg.hash(), signature, publicKey)) throw 35;
  acceptExternalMessage();
  cs.stackMoveToTop();
  while (cs.remainingRefsCount() != 0) {
    var ref = cs.loadRef();
    var mode = cs.loadUint(8);
    if (mode < 0xff) { sendRawMessage(ref, mode); }
    else { ds.updateParams(ref); }
  }
  contract.setData(beginCell()
    .storeUint(storedSeqno + 1, 32)
    .storeUint(storedSubwallet, 32)
    .storeUint(publicKey, 256)
    .storeSlice(ds)
    .endCell());
}

get fun seqno(): int {
  return contract.getData().beginParse().preloadUint(32);
}

get fun get_pow_params(): (int, int, int, int) {
  var ds = contract.getData().beginParse().skipBits(32 + 32 + 256);
  var (seed, powComplexity, xdata) = (ds.loadUint(128), ds.loadUint(256), ds.preloadRef());
  ds = xdata.beginParse();
  return (seed, powComplexity, ds.loadCoins(), ds.preloadUint(32));
}

get fun get_public_key(): int {
  var ds = contract.getData().beginParse();
  ds.loadUint(32 + 32);
  return ds.preloadUint(256);
}
