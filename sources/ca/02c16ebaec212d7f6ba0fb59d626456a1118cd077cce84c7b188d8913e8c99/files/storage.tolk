// Common message structures for all Cocoon contracts

import "errors"
import "messages"

// === Constants ===

const COMMISSION_ESTIMATE = ton("0.1")
const STORAGE_ESTIMATE = ton("0.01")
const CLIENT_STAKE = ton("1.0")

// Send modes are already in stdlib:
// SEND_MODE_PAY_FEES_SEPARATELY = 1
// SEND_MODE_IGNORE_ERRORS = 2  
// SEND_MODE_CARRY_ALL_BALANCE = 128

// === State Constants ===

// Client states
enum ClientState : uint2 {
    Normal = 0,
    Closing = 1,
    Closed = 2
}

// Proxy states
enum ProxyState : uint2 {
    Normal = 0,
    Closing = 1,
    Closed = 2
}

// Worker states
enum WorkerState : uint2 {
    Normal = 0,
    Closed = 2
}

// === CocoonParams Structure ===

struct CocoonParams {
    structVersion: uint8
    paramsVersion: uint32
    uniqueId: uint32
    isTest: bool
    pricePerToken: coins
    workerFeePerToken: coins
    promptTokensPriceMultiplier: uint32
    cachedTokensPriceMultiplier: uint32
    completionTokensPriceMultiplier: uint32
    reasoningTokensPriceMultiplier: uint32
    proxyDelayBeforeClose: uint32
    clientDelayBeforeClose: uint32
    minProxyStake: coins
    minClientStake: coins
    proxyScCode: cell?
    workerScCode: cell?
    clientScCode: cell?
}

// Helper method for calculating earnings split
fun CocoonParams.calculateEarnings(self, tokensDelta: int): (coins, coins) {
    val workerPart = tokensDelta * self.workerFeePerToken;
    val proxyPart = tokensDelta * (self.pricePerToken - self.workerFeePerToken);
    return (workerPart, proxyPart);
}

// Helper method to create params without code cells (for address calculation)
fun CocoonParams.withoutCode(self): CocoonParams {
    var result = self;
    result.proxyScCode = null;
    result.workerScCode = null;
    result.clientScCode = null;
    return result;
}

// === Root Storage ===

struct RootData {
    proxyHashes: map<uint256, ()>
    registeredProxies: map<uint32, slice>
    lastProxySeqno: uint32
    workerHashes: map<uint256, ()>
    modelHashes: map<uint256, ()>
}

struct RootStorage {
    ownerAddress: address
    version: uint32
    data: Cell<RootData>
    params: Cell<CocoonParams>
}

fun RootStorage.load() {
    return RootStorage.fromCell(contract.getData());
}

fun RootStorage.save(self) {
    contract.setData(self.toCell());
}

// === Proxy Storage ===

// SAFETY: Fixed fields take 824 bits, leaving 199 bits for balance + stake (coins).
// Overflow requires both fields to encode >~1B TON each, which exceeds total TON supply (~5B).
@overflow1023_policy("suppress")
struct ProxyStorage {
    ownerAddress: address
    proxyPublicKey: uint256
    rootAddress: address
    state: ProxyState
    balance: coins
    stake: coins
    unlockTs: uint32
    params: Cell<CocoonParams>
}

fun ProxyStorage.load(): ProxyStorage {
    return ProxyStorage.fromCell(contract.getData());
}

fun ProxyStorage.save(self) {
    contract.setData(self.toCell());
}

// === Worker Storage ===

struct WorkerStorage {
    ownerAddress: address
    proxyAddress: address
    proxyPublicKey: uint256
    state: WorkerState
    tokens: uint64
    params: Cell<CocoonParams>  // Cell reference (CocoonParams is too large to inline)
}

fun WorkerStorage.load() {
    return WorkerStorage.fromCell(contract.getData());
}

fun WorkerStorage.save(self) {
    contract.setData(self.toCell());
}

// === Client Storage ===

struct ClientConstData {
    ownerAddress: address
    proxyAddress: address
    proxyPublicKey: uint256
}

struct ClientStorage {
    state: ClientState
    balance: coins
    stake: coins
    tokensUsed: uint64
    unlockTs: uint32
    secretHash: uint256
    constDataRef: Cell<ClientConstData>
    params: Cell<CocoonParams>
}

fun ClientStorage.load() {
    return ClientStorage.fromCell(contract.getData());
}

fun ClientStorage.save(self) {
    contract.setData(self.toCell());
}

fun ClientStorage.toStateData(self): ClientStateData {
    return ClientStateData {
        state: self.state,
        balance: self.balance,
        stake: self.stake,
        tokensUsed: self.tokensUsed,
        secretHash: self.secretHash
    };
}

fun ClientStorage.updateBalance(mutate self, newTokensUsed: uint64) {
    if (newTokensUsed <= self.tokensUsed) {
        return;
    }

    val p = self.params.load();
    val tokens = newTokensUsed - self.tokensUsed;
    val balanceUpdate = tokens * p.pricePerToken;

    self.tokensUsed = newTokensUsed;
    self.balance = max(self.balance - balanceUpdate, 0);
}


// === Wallet Storage ===

struct WalletStorage {
    seqno: uint32
    subwalletId: uint32
    publicKey: uint256
    status: uint32
    ownerAddress: address
}

fun WalletStorage.load() {
    return WalletStorage.fromCell(contract.getData());
}

fun WalletStorage.save(self) {
    contract.setData(self.toCell());
}

// === Helper Functions ===

fun calculateContractAddress(codeCell: cell, dataCell: cell): address {
    val addrHash = StateInit.calcHashCodeData(codeCell, dataCell);
    return address.fromWorkchainAndHash(BASECHAIN, addrHash);
}

