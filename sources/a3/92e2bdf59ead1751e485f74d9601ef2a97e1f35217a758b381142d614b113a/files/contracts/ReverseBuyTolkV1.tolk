tolk 1.4.2

const ECONOMIC_VERSION = 2

const BUY_STATUS_ACTIVE = 0
const BUY_STATUS_FILLED = 1
const BUY_STATUS_CANCELLED = 2

const ROUTE_NONE = 0
const ROUTE_BUYER = 1
const ROUTE_SELLER = 2

const CONDITION_NONE = 0
const CONDITION_AND = 1
const CONDITION_OR = 2
const MAX_CONDITIONS = 16

const FILL_GAS_MARGIN = 10000000

// Public exit codes inherited from ReverseBuy Tact economic v2.
const ERROR_INVALID_CONDITION_MODE = 7197
const ERROR_NOT_BUYER = 7643
const ERROR_INVALID_PRICE = 12537
const ERROR_TOO_MANY_CONDITIONS = 19235
const ERROR_MISSING_ROOT = 20989
const ERROR_INSUFFICIENT_RESCUE_VALUE = 30731
const ERROR_ALREADY_FUNDED = 33704
const ERROR_ORDER_STILL_ACTIVE = 44257
const ERROR_FEE_TOO_HIGH = 52892
const ERROR_INVALID_CONDITION = 55104
const ERROR_INVALID_CONFIG = 59253
const ERROR_INVALID_CONDITION_DATA = 63623
const ERROR_INSUFFICIENT_DEPOSIT = 63847
const ERROR_INVALID_INCOMING_MESSAGE = 130

struct (0b0) ReverseBuyStorageAtDeployment {
    config: cell
}

struct ReverseBuyGasConfig {
    minContractReserve: coins
    minAcceptValue: coins
    nftTransferValue: coins
    minRejectStorageValue: coins
}

struct ReverseBuyEligibilityConfig {
    eligibilityRoot: uint256
    conditions: cell
}

struct ReverseBuyInitialConfig {
    economicVersion: uint16
    salt: uint64
    buyer: address
    collection: address
    feeReceiver: address
    price: coins
    feeBps: uint16
    eligibility: Cell<ReverseBuyEligibilityConfig>
    gas: Cell<ReverseBuyGasConfig>
}

struct ReverseBuyCore {
    buyer: address
    collection: address
    feeReceiver: address
    price: coins
    feeBps: uint16
}

struct ReverseBuyEligibility {
    conditionMode: uint8
    conditionCount: uint8
    conditionsHash: uint256
    eligibilityRoot: uint256
}

struct ReverseBuyRuntime {
    status: uint8
    reservedBalance: coins
    funded: bool
    pendingSale: address?
    pendingNft: address?
    pendingSalePrice: coins
    pendingDealId: uint64
}

// The working state is split into refs so every valid coin encoding fits.
struct (0b1) ReverseBuyStorage {
    core: Cell<ReverseBuyCore>
    eligibility: Cell<ReverseBuyEligibility>
    gas: Cell<ReverseBuyGasConfig>
    runtime: Cell<ReverseBuyRuntime>
}

// Runtime-only decoded view. Returning it avoids serializing and parsing the
// freshly initialized refs twice during the deployment transaction.
struct ReverseBuyLoaded {
    storage: ReverseBuyStorage
    core: ReverseBuyCore
    eligibility: ReverseBuyEligibility
    gas: ReverseBuyGasConfig
    runtime: ReverseBuyRuntime
}

struct BuyState {
    economicVersion: uint16
    status: uint8
    buyer: address
    collection: address
    price: coins
    reservedBalance: coins
    feeBps: uint16
    feeReceiver: address
    conditionMode: uint8
    conditionCount: uint8
    conditionsHash: uint256
    eligibilityRoot: uint256
    funded: bool
    pendingMode: uint8
    pendingUntil: uint32
}

struct (0x946a98b6) Deploy {
    queryId: uint64
}

struct (0x5242434e) CancelBuyOffer {
    queryId: uint64
}

struct (0x5242524e) RescueStrandedNft {
    queryId: uint64
    nft: address
    recipient: address
}

struct (0x52425342) BuySaleOffer {
    queryId: uint64
    saleContract: address
    nft: address
    salePrice: coins
    acceptPayload: cell
}

struct (0x05138d91) OwnershipAssigned {
    queryId: uint64
    prevOwner: address
    forwardPayload: RemainingBitsAndRefs
}

type ReverseBuyIncomingMessage =
    | Deploy
    | CancelBuyOffer
    | RescueStrandedNft
    | BuySaleOffer
    | OwnershipAssigned

contract ReverseBuyTolkV1 {
    author: "Reverse NFT Marketplace"
    version: "1.0"
    description: "ReverseBuy economic v2 implemented in Tolk 1.4.2"
    incomingMessages: ReverseBuyIncomingMessage
    storage: ReverseBuyStorage
    storageAtDeployment: ReverseBuyStorageAtDeployment
}

fun loadReverseBuy(): ReverseBuyLoaded {
    val data = contract.getData();
    val dataSlice = data.beginParse();
    if (dataSlice.preloadUint(1) == 0) {
        val deployment = ReverseBuyStorageAtDeployment.fromCell(data);
        val config = ReverseBuyInitialConfig.fromCell(deployment.config);
        val eligibilityConfig = config.eligibility.load();
        val conditions = eligibilityConfig.conditions;
        var conditionsSlice = conditions.beginParse();
        val conditionMode = conditionsSlice.loadUint(8);
        val conditionCount = conditionsSlice.loadUint(8);

        assert (config.economicVersion == ECONOMIC_VERSION) throw ERROR_INVALID_CONFIG;
        assert (config.price > 0) throw ERROR_INVALID_PRICE;
        assert (config.feeBps <= 1000) throw ERROR_FEE_TOO_HIGH;
        assert (eligibilityConfig.eligibilityRoot != 0) throw ERROR_MISSING_ROOT;
        validateConditions(conditions);

        val core: ReverseBuyCore = {
            buyer: config.buyer,
            collection: config.collection,
            feeReceiver: config.feeReceiver,
            price: config.price,
            feeBps: config.feeBps,
        };
        val eligibility: ReverseBuyEligibility = {
            conditionMode,
            conditionCount,
            conditionsHash: conditions.hash(),
            eligibilityRoot: eligibilityConfig.eligibilityRoot,
        };
        val runtime: ReverseBuyRuntime = {
            status: BUY_STATUS_ACTIVE,
            reservedBalance: config.price,
            funded: false,
            pendingSale: null,
            pendingNft: null,
            pendingSalePrice: 0,
            pendingDealId: 0,
        };
        val storage: ReverseBuyStorage = {
            core: core.toCell(),
            eligibility: eligibility.toCell(),
            gas: config.gas,
            runtime: runtime.toCell(),
        };
        return { storage, core, eligibility, gas: config.gas.load(), runtime };
    }
    val storage = ReverseBuyStorage.fromCell(data);
    return {
        storage,
        core: storage.core.load(),
        eligibility: storage.eligibility.load(),
        gas: storage.gas.load(),
        runtime: storage.runtime.load(),
    };
}

fun ReverseBuyStorage.save(self) {
    contract.setData(self.toCell());
}

fun ReverseBuyStorage.saveRuntime(mutate self, runtime: ReverseBuyRuntime) {
    self.runtime = runtime.toCell();
    self.save();
}

fun onInternalMessage(in: InMessage) {
    val loaded = loadReverseBuy();
    var storage = loaded.storage;
    val core = loaded.core;
    val eligibility = loaded.eligibility;
    val gas = loaded.gas;
    var runtime = loaded.runtime;

    // ReverseSale refunds a failed buyer-initiated purchase with an empty body.
    if (in.body.isEmpty()) {
        if (runtime.pendingSale != null && in.senderAddress == runtime.pendingSale! && runtime.status == BUY_STATUS_ACTIVE) {
            runtime.clearPending();
            runtime.reservedBalance = core.price;
            storage.saveRuntime(runtime);
        }
        refundAttached(core.buyer, in.valueCoins);
        return;
    }

    val msg = lazy ReverseBuyIncomingMessage.fromSlice(in.body);
    match (msg) {
        Deploy => {
            assert (in.senderAddress == core.buyer) throw ERROR_NOT_BUYER;
            val required = core.price + gas.minContractReserve;
            assert (in.valueCoins >= required) throw ERROR_INSUFFICIENT_DEPOSIT;
            assert (!runtime.funded) throw ERROR_ALREADY_FUNDED;
            runtime.funded = true;
            storage.saveRuntime(runtime);
            refundAttached(core.buyer, in.valueCoins - required);
        }
        CancelBuyOffer => {
            assert (in.senderAddress == core.buyer) throw ERROR_NOT_BUYER;
            if (runtime.status != BUY_STATUS_ACTIVE || runtime.pendingSale != null) {
                refundInbound(in.senderAddress);
                return;
            }
            runtime.status = BUY_STATUS_CANCELLED;
            runtime.reservedBalance = 0;
            storage.saveRuntime(runtime);
            sendRemainingTon(core.buyer);
        }
        BuySaleOffer => {
            assert (in.senderAddress == core.buyer) throw ERROR_NOT_BUYER;
            if (
                !runtime.funded ||
                runtime.status != BUY_STATUS_ACTIVE ||
                runtime.pendingSale != null ||
                msg.queryId == 0 ||
                msg.salePrice == 0 ||
                msg.salePrice > core.price
            ) {
                refundInbound(in.senderAddress);
                return;
            }
            if (!validateAcceptPayload(core, eligibility, msg.nft, msg.acceptPayload, ROUTE_BUYER, msg.queryId, msg.salePrice)) {
                refundInbound(in.senderAddress);
                return;
            }
            runtime.pendingSale = msg.saleContract;
            runtime.pendingNft = msg.nft;
            runtime.pendingSalePrice = msg.salePrice;
            runtime.pendingDealId = msg.queryId;
            runtime.reservedBalance = core.price - msg.salePrice;
            storage.saveRuntime(runtime);
            buyReverseSale(msg.saleContract, msg.salePrice, msg.queryId, msg.acceptPayload);
            refundAttached(core.buyer, in.valueCoins);
        }
        OwnershipAssigned => {
            runtime.handleOwnershipAssigned(
                mutate storage,
                core,
                eligibility,
                gas,
                in.senderAddress,
                in.valueCoins,
                msg.prevOwner,
                msg.forwardPayload,
            );
        }
        RescueStrandedNft => {
            assert (in.senderAddress == core.buyer) throw ERROR_NOT_BUYER;
            assert (runtime.status != BUY_STATUS_ACTIVE) throw ERROR_ORDER_STILL_ACTIVE;
            assert (in.valueCoins >= gas.nftTransferValue) throw ERROR_INSUFFICIENT_RESCUE_VALUE;
            returnInboundNft(msg.nft, msg.recipient);
        }
        else => {
            throw ERROR_INVALID_INCOMING_MESSAGE;
        }
    }
}

// Tact ignores bounced messages unless a bounced receiver is declared.
fun onBouncedMessage(in: InMessageBounced) {
}

fun ReverseBuyRuntime.handleOwnershipAssigned(
    mutate self,
    mutate storage: ReverseBuyStorage,
    core: ReverseBuyCore,
    eligibility: ReverseBuyEligibility,
    gas: ReverseBuyGasConfig,
    nft: address,
    inboundValue: coins,
    prevOwner: address,
    forwardPayload: slice,
) {
    if (!self.funded || self.status != BUY_STATUS_ACTIVE) {
        returnInboundNft(nft, prevOwner);
        return;
    }

    var payload = unwrapForwardPayload(forwardPayload);
    if (payload.remainingBitsCount() < 32 || payload.remainingRefsCount() < 1 || payload.loadUint(32) != 0x52424143) {
        returnInboundNft(nft, prevOwner);
        return;
    }
    var proof = payload.loadRef().beginParse();
    var routeMode = ROUTE_NONE;
    var dealId = 0;
    var executionPrice: coins = 0;
    if (payload.remainingBitsCount() >= 72) {
        routeMode = payload.loadUint(8);
        dealId = payload.loadUint(64);
        if (payload.remainingBitsCount() > 0) {
            executionPrice = payload.loadCoins();
        }
    }
    if (!verifyEligibilityProof(core, eligibility, nft, proof)) {
        returnInboundNft(nft, prevOwner);
        return;
    }

    if (routeMode == ROUTE_BUYER) {
        if (
            self.pendingSale == null ||
            self.pendingNft == null ||
            prevOwner != self.pendingSale! ||
            nft != self.pendingNft! ||
            dealId != self.pendingDealId ||
            executionPrice != self.pendingSalePrice
        ) {
            returnInboundNft(nft, prevOwner);
            return;
        }
        self.status = BUY_STATUS_FILLED;
        self.reservedBalance = 0;
        self.clearPending();
        storage.saveRuntime(self);
        if (!canAffordFillSends(gas, 0)) {
            returnInboundNft(nft, core.buyer);
            return;
        }
        transferNft(nft, core.buyer, gas.nftTransferValue);
        sendRemainingTon(core.buyer);
        return;
    }

    if (routeMode == ROUTE_SELLER) {
        if (executionPrice != core.price) {
            returnInboundNft(nft, prevOwner);
            return;
        }
        if (!canAffordFillSends(gas, core.price + inboundValue)) {
            returnInboundNft(nft, prevOwner);
            return;
        }
        val fee = marketplaceFee(core, core.price);
        self.status = BUY_STATUS_FILLED;
        self.reservedBalance = 0;
        storage.saveRuntime(self);
        sendTon(prevOwner, core.price - fee + inboundValue);
        if (fee > 0) {
            sendTon(core.feeReceiver, fee);
        }
        transferNft(nft, core.buyer, gas.nftTransferValue);
        sendRemainingTon(core.buyer);
        return;
    }

    if (routeMode != ROUTE_NONE || executionPrice != 0) {
        returnInboundNft(nft, prevOwner);
        return;
    }
    if (!canAffordFillSends(gas, core.price + inboundValue)) {
        returnInboundNft(nft, prevOwner);
        return;
    }
    val fee = marketplaceFee(core, core.price);
    self.status = BUY_STATUS_FILLED;
    self.reservedBalance = 0;
    storage.saveRuntime(self);
    sendTon(prevOwner, core.price - fee + inboundValue);
    if (fee > 0) {
        sendTon(core.feeReceiver, fee);
    }
    transferNft(nft, core.buyer, gas.nftTransferValue);
    sendRemainingTon(core.buyer);
}

fun marketplaceFee(core: ReverseBuyCore, value: coins): coins {
    if (value == 0 || core.feeBps == 0) {
        return 0;
    }
    return value * core.feeBps / 10000;
}

fun canAffordFillSends(gas: ReverseBuyGasConfig, payoutTotal: coins): bool {
    return contract.getOriginalBalance() >= payoutTotal + gas.nftTransferValue + FILL_GAS_MARGIN;
}

fun ReverseBuyRuntime.clearPending(mutate self) {
    self.pendingSale = null;
    self.pendingNft = null;
    self.pendingSalePrice = 0;
    self.pendingDealId = 0;
}

fun validateAcceptPayload(
    core: ReverseBuyCore,
    eligibility: ReverseBuyEligibility,
    nft: address,
    payloadCell: cell,
    mode: int,
    dealId: int,
    executionPrice: coins,
): bool {
    var payload = payloadCell.beginParse();
    if (payload.remainingBitsCount() < 32 || payload.remainingRefsCount() < 1 || payload.loadUint(32) != 0x52424143) {
        return false;
    }
    var proof = payload.loadRef().beginParse();
    if (payload.remainingBitsCount() < 72 || payload.loadUint(8) != mode || payload.loadUint(64) != dealId) {
        return false;
    }
    if (payload.remainingBitsCount() == 0 || payload.loadCoins() != executionPrice) {
        return false;
    }
    if (payload.remainingBitsCount() < 32 || payload.loadUint(16) != ECONOMIC_VERSION || payload.loadUint(16) != core.feeBps) {
        return false;
    }
    if (payload.loadAddress() != core.feeReceiver) {
        return false;
    }
    return verifyEligibilityProof(core, eligibility, nft, proof);
}

fun validateConditions(conditions: cell) {
    var data = conditions.beginParse();
    val mode = data.loadUint(8);
    val count = data.loadUint(8);
    assert (count <= MAX_CONDITIONS) throw ERROR_TOO_MANY_CONDITIONS;
    if (count == 0) {
        assert (mode == CONDITION_NONE) throw ERROR_INVALID_CONDITION_MODE;
        return;
    }
    assert (mode == CONDITION_AND || mode == CONDITION_OR) throw ERROR_INVALID_CONDITION_MODE;
    var index = 0;
    var previousKey = 0;
    while (index < count) {
        assert (data.remainingBitsCount() >= 512) throw ERROR_INVALID_CONDITION_DATA;
        val key = data.loadUint(256);
        val value = data.loadUint(256);
        assert (key > previousKey && value != 0) throw ERROR_INVALID_CONDITION;
        previousKey = key;
        index += 1;
    }
}

fun verifyEligibilityProof(
    core: ReverseBuyCore,
    eligibility: ReverseBuyEligibility,
    nft: address,
    proof: slice,
): bool {
    var current = beginCell()
        .storeAddress(core.collection)
        .storeAddress(nft)
        .storeUint(eligibility.conditionsHash, 256)
        .endCell()
        .hash();
    var cursor = proof;
    while (true) {
        while (cursor.remainingBitsCount() >= 257) {
            val siblingOnLeft = cursor.loadBool();
            val sibling = cursor.loadUint(256);
            if (siblingOnLeft) {
                current = beginCell().storeUint(sibling, 256).storeUint(current, 256).endCell().hash();
            } else {
                current = beginCell().storeUint(current, 256).storeUint(sibling, 256).endCell().hash();
            }
        }
        if (cursor.remainingRefsCount() == 0) {
            return current == eligibility.eligibilityRoot;
        }
        cursor = cursor.loadRef().beginParse();
    }
}

fun unwrapForwardPayload(payload: slice): slice {
    var result = payload;
    if (result.remainingBitsCount() == 1 && result.remainingRefsCount() > 0) {
        result.loadBool();
        return result.loadRef().beginParse();
    }
    return result;
}

fun buyReverseSale(sale: address, value: coins, dealId: int, acceptPayload: cell) {
    val body = beginCell()
        .storeUint(0x52534242, 32)
        .storeUint(dealId, 64)
        .storeRef(acceptPayload)
        .endCell();
    val msg = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: sale,
        value,
        body,
    });
    msg.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun refundAttached(to: address, amount: coins) {
    if (amount > 0) {
        sendTon(to, amount);
    }
}

fun refundInbound(to: address) {
    val msg = createMessage({
        bounce: BounceMode.NoBounce,
        dest: to,
        value: 0,
    });
    msg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS);
}

fun sendTon(to: address, amount: coins) {
    if (amount > 0) {
        val msg = createMessage({
            bounce: BounceMode.NoBounce,
            dest: to,
            value: amount,
        });
        msg.send(SEND_MODE_PAY_FEES_SEPARATELY);
    }
}

fun sendRemainingTon(to: address) {
    val msg = createMessage({
        bounce: BounceMode.NoBounce,
        dest: to,
        value: 0,
    });
    msg.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
}

fun transferNft(nft: address, newOwner: address, value: coins) {
    val body = beginCell()
        .storeUint(0x5fcc3d14, 32)
        .storeUint(0, 64)
        .storeAddress(newOwner)
        .storeAddress(newOwner)
        .storeBool(false)
        .storeCoins(0)
        .storeBool(false)
        .endCell();
    val msg = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: nft,
        value,
        body,
    });
    msg.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun returnInboundNft(nft: address, newOwner: address) {
    val body = beginCell()
        .storeUint(0x5fcc3d14, 32)
        .storeUint(0, 64)
        .storeAddress(newOwner)
        .storeAddress(newOwner)
        .storeBool(false)
        .storeCoins(10000000)
        .storeBool(false)
        .endCell();
    val msg = createMessage({
        bounce: BounceMode.NoBounce,
        dest: nft,
        value: 0,
        body,
    });
    msg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_IGNORE_ERRORS);
}

get fun get_buy_state(): BuyState {
    val loaded = loadReverseBuy();
    val core = loaded.core;
    val eligibility = loaded.eligibility;
    val runtime = loaded.runtime;
    var pendingMode = ROUTE_NONE;
    if (runtime.pendingSale != null) {
        pendingMode = ROUTE_BUYER;
    }
    return {
        economicVersion: ECONOMIC_VERSION,
        status: runtime.status,
        buyer: core.buyer,
        collection: core.collection,
        price: core.price,
        reservedBalance: runtime.reservedBalance,
        feeBps: core.feeBps,
        feeReceiver: core.feeReceiver,
        conditionMode: eligibility.conditionMode,
        conditionCount: eligibility.conditionCount,
        conditionsHash: eligibility.conditionsHash,
        eligibilityRoot: eligibility.eligibilityRoot,
        funded: runtime.funded,
        pendingMode,
        pendingUntil: 0,
    };
}
