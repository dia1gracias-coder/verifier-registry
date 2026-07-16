tolk 1.4.2

const ECONOMIC_VERSION = 2

const SALE_STATUS_WAITING_NFT = 0
const SALE_STATUS_ACTIVE = 1
const SALE_STATUS_SOLD = 2
const SALE_STATUS_CANCELLED = 3
const SALE_STATUS_SETTLING = 4

const ROUTE_NONE = 0
const ROUTE_BUYER = 1
const ROUTE_SELLER = 2

const SALE_REJECT_WRONG_NFT = 1
const SALE_REJECT_WRONG_SELLER = 2
const SALE_REJECT_NOT_ACTIVE = 3

// These codes are part of the public behavior of ReverseSaleTactV2.
const ERROR_INVALID_PRICE = 12537
const ERROR_INSUFFICIENT_DEPLOY = 25034
const ERROR_INSUFFICIENT_RETURN_VALUE = 39403
const ERROR_NOT_REJECTED = 41792
const ERROR_NOT_PREVIOUS_OWNER = 47652
const ERROR_FEE_TOO_HIGH = 52892
const ERROR_NOT_SELLER = 54672
const ERROR_INVALID_CONFIG = 59253
const ERROR_INVALID_INCOMING_MESSAGE = 130

struct (0b0) ReverseSaleStorageAtDeployment {
    config: cell
}

struct ReverseSaleGasConfig {
    minContractReserve: coins
    minDepositValue: coins
    minBuyValue: coins
    nftTransferValue: coins
    minRejectStorageValue: coins
}

struct ReverseSaleInitialConfig {
    economicVersion: uint16
    seller: address
    nft: address
    feeReceiver: address
    price: coins
    feeBps: uint16
    gas: Cell<ReverseSaleGasConfig>
}

struct SaleRejectedItem {
    prevOwner: address
    reasonCode: uint8
    createdAt: uint32
}

struct ReverseSaleRuntime {
    status: uint8
    nftDeposited: bool
    pendingMode: uint8
    pendingBuy: address?
    pendingPayment: coins
    pendingDealId: uint64
    rejectedItems: map<address, SaleRejectedItem>
}

// Prefix 1 distinguishes working storage from the lazy-deployment cell above.
// Gas settings and mutable runtime state are refs so the root always fits into
// a cell even for maximum-width coin values.
struct (0b1) ReverseSaleStorage {
    seller: address
    nft: address
    price: coins
    feeReceiver: address
    feeBps: uint16
    gas: Cell<ReverseSaleGasConfig>
    runtime: Cell<ReverseSaleRuntime>
}

struct SaleState {
    economicVersion: uint16
    status: uint8
    seller: address
    nft: address
    price: coins
    feeBps: uint16
    feeReceiver: address
    nftDeposited: bool
    pendingMode: uint8
    pendingUntil: uint32
}

struct (0x946a98b6) Deploy {
    queryId: uint64
}

struct (0x5253434e) CancelSale {
    queryId: uint64
}

struct (0x5253524e) RescueHeldNft {
    queryId: uint64
}

struct (0x52534642) FillBuyOffer {
    queryId: uint64
    buyContract: address
    settlementPrice: coins
    acceptPayload: cell
}

struct (0x52534242) BuyForReverseBuy {
    queryId: uint64
    acceptPayload: cell
}

struct (0x5242524a) ClaimRejectedNft {
    nft: address
}

struct (0x05138d91) OwnershipAssigned {
    queryId: uint64
    prevOwner: address
    forwardPayload: RemainingBitsAndRefs
}

type ReverseSaleIncomingMessage =
    | Deploy
    | CancelSale
    | RescueHeldNft
    | FillBuyOffer
    | BuyForReverseBuy
    | ClaimRejectedNft
    | OwnershipAssigned

contract ReverseSaleTolkV1 {
    author: "Reverse NFT Marketplace"
    version: "1.0"
    description: "ReverseSale economic v2 implemented in Tolk 1.4.2"
    incomingMessages: ReverseSaleIncomingMessage
    storage: ReverseSaleStorage
    storageAtDeployment: ReverseSaleStorageAtDeployment
}

fun ReverseSaleStorage.load(): ReverseSaleStorage {
    val data = contract.getData();
    val dataSlice = data.beginParse();
    if (dataSlice.preloadUint(1) == 0) {
        val deployment = ReverseSaleStorageAtDeployment.fromCell(data);
        val config = ReverseSaleInitialConfig.fromCell(deployment.config);
        val gas = config.gas.load();

        assert (config.economicVersion == ECONOMIC_VERSION) throw ERROR_INVALID_CONFIG;
        assert (config.price > 0) throw ERROR_INVALID_PRICE;
        assert (config.feeBps <= 1000) throw ERROR_FEE_TOO_HIGH;

        val runtime: ReverseSaleRuntime = {
            status: SALE_STATUS_WAITING_NFT,
            nftDeposited: false,
            pendingMode: ROUTE_NONE,
            pendingBuy: null,
            pendingPayment: 0,
            pendingDealId: 0,
            rejectedItems: [],
        };
        val storage: ReverseSaleStorage = {
            seller: config.seller,
            nft: config.nft,
            price: config.price,
            feeReceiver: config.feeReceiver,
            feeBps: config.feeBps,
            gas: config.gas,
            runtime: runtime.toCell(),
        };
        storage.save();
        return storage;
    }
    return ReverseSaleStorage.fromCell(data);
}

fun ReverseSaleStorage.save(self) {
    contract.setData(self.toCell());
}

fun ReverseSaleStorage.saveRuntime(mutate self, runtime: ReverseSaleRuntime) {
    self.runtime = runtime.toCell();
    self.save();
}

fun onInternalMessage(in: InMessage) {
    var storage = ReverseSaleStorage.load();
    val gas = storage.gas.load();
    var runtime = storage.runtime.load();

    if (in.body.isEmpty()) {
        runtime.handleEmptySettlement(mutate storage, in.senderAddress, in.valueCoins);
        return;
    }

    val msg = lazy ReverseSaleIncomingMessage.fromSlice(in.body);
    match (msg) {
        Deploy => {
            assert (in.senderAddress == storage.seller) throw ERROR_NOT_SELLER;
            assert (in.valueCoins >= gas.minContractReserve) throw ERROR_INSUFFICIENT_DEPLOY;
            storage.save();
        }
        OwnershipAssigned => {
            runtime.handleOwnershipAssigned(mutate storage, gas, in.senderAddress, in.valueCoins, msg.prevOwner);
        }
        FillBuyOffer => {
            assert (in.senderAddress == storage.seller) throw ERROR_NOT_SELLER;
            if (
                runtime.status != SALE_STATUS_ACTIVE ||
                !runtime.nftDeposited ||
                runtime.pendingMode != ROUTE_NONE ||
                msg.queryId == 0 ||
                msg.settlementPrice < storage.price
            ) {
                refundInbound(in.senderAddress);
                return;
            }
            if (!storage.validateRoutePayload(msg.acceptPayload, ROUTE_SELLER, msg.queryId, msg.settlementPrice)) {
                refundInbound(in.senderAddress);
                return;
            }

            runtime.status = SALE_STATUS_SETTLING;
            runtime.nftDeposited = false;
            runtime.pendingMode = ROUTE_SELLER;
            runtime.pendingBuy = msg.buyContract;
            runtime.pendingPayment = msg.settlementPrice;
            runtime.pendingDealId = msg.queryId;
            storage.saveRuntime(runtime);
            transferNftWithPayload(
                storage.nft,
                msg.buyContract,
                storage.seller,
                gas.nftTransferValue,
                gas.minBuyValue,
                msg.acceptPayload,
            );
        }
        BuyForReverseBuy => {
            if (
                runtime.status != SALE_STATUS_ACTIVE ||
                !runtime.nftDeposited ||
                msg.queryId == 0 ||
                in.valueCoins < storage.price
            ) {
                refundInbound(in.senderAddress);
                return;
            }
            if (!storage.validateRoutePayload(msg.acceptPayload, ROUTE_BUYER, msg.queryId, storage.price)) {
                refundInbound(in.senderAddress);
                return;
            }

            val fee = storage.marketplaceFee(storage.price);
            runtime.status = SALE_STATUS_SOLD;
            runtime.nftDeposited = false;
            storage.saveRuntime(runtime);
            sendTon(storage.seller, storage.price - fee);
            if (fee > 0) {
                sendTon(storage.feeReceiver, fee);
            }
            transferNftWithPayload(
                storage.nft,
                in.senderAddress,
                storage.seller,
                gas.nftTransferValue,
                gas.minBuyValue,
                msg.acceptPayload,
            );
            sendRemainingTon(storage.seller);
        }
        CancelSale => {
            assert (in.senderAddress == storage.seller) throw ERROR_NOT_SELLER;
            if (
                runtime.status != SALE_STATUS_WAITING_NFT &&
                runtime.status != SALE_STATUS_ACTIVE &&
                runtime.status != SALE_STATUS_CANCELLED
            ) {
                refundInbound(in.senderAddress);
                return;
            }
            runtime.status = SALE_STATUS_CANCELLED;
            val hadNft = runtime.nftDeposited;
            runtime.nftDeposited = false;
            storage.saveRuntime(runtime);
            if (hadNft) {
                transferNft(storage.nft, storage.seller, gas.nftTransferValue);
            }
            sendRemainingTon(storage.seller);
        }
        RescueHeldNft => {
            assert (in.senderAddress == storage.seller) throw ERROR_NOT_SELLER;
            if (runtime.status == SALE_STATUS_SOLD || runtime.status == SALE_STATUS_SETTLING) {
                refundInbound(in.senderAddress);
                return;
            }
            runtime.status = SALE_STATUS_CANCELLED;
            runtime.nftDeposited = false;
            storage.saveRuntime(runtime);
            transferNft(storage.nft, storage.seller, gas.nftTransferValue);
            sendRemainingTon(storage.seller);
        }
        ClaimRejectedNft => {
            val found = runtime.rejectedItems.get(msg.nft);
            assert (found.isFound) throw ERROR_NOT_REJECTED;
            val rejected = found.loadValue();
            assert (in.senderAddress == rejected.prevOwner) throw ERROR_NOT_PREVIOUS_OWNER;
            assert (in.valueCoins >= gas.nftTransferValue) throw ERROR_INSUFFICIENT_RETURN_VALUE;
            runtime.rejectedItems.delete(msg.nft);
            storage.saveRuntime(runtime);
            transferNft(msg.nft, rejected.prevOwner, gas.nftTransferValue);
        }
        else => {
            throw ERROR_INVALID_INCOMING_MESSAGE;
        }
    }
}

// Tact's default behavior is to ignore all bounced messages.
fun onBouncedMessage(in: InMessageBounced) {
}

fun ReverseSaleRuntime.handleEmptySettlement(
    mutate self,
    mutate storage: ReverseSaleStorage,
    sender: address,
    value: coins,
) {
    val fee = storage.marketplaceFee(self.pendingPayment);
    val sellerNet = self.pendingPayment - fee;
    if (
        self.status != SALE_STATUS_SETTLING ||
        self.pendingMode != ROUTE_SELLER ||
        self.pendingBuy == null ||
        sender != self.pendingBuy! ||
        value < sellerNet
    ) {
        refundInbound(sender);
        return;
    }

    self.status = SALE_STATUS_SOLD;
    self.nftDeposited = false;
    self.clearPending();
    storage.saveRuntime(self);
    sendTon(storage.seller, sellerNet);
    sendRemainingTon(storage.seller);
}

fun ReverseSaleRuntime.handleOwnershipAssigned(
    mutate self,
    mutate storage: ReverseSaleStorage,
    gas: ReverseSaleGasConfig,
    sender: address,
    value: coins,
    prevOwner: address,
) {
    if (sender != storage.nft) {
        self.rememberRejected(sender, prevOwner, SALE_REJECT_WRONG_NFT, value, gas.minRejectStorageValue);
        storage.saveRuntime(self);
        return;
    }

    if (self.status == SALE_STATUS_WAITING_NFT) {
        if (prevOwner != storage.seller) {
            self.rememberRejected(sender, prevOwner, SALE_REJECT_WRONG_SELLER, value, gas.minRejectStorageValue);
            storage.saveRuntime(self);
            return;
        }
        self.nftDeposited = true;
        self.status = SALE_STATUS_ACTIVE;
        storage.saveRuntime(self);
        return;
    }

    if (
        self.status == SALE_STATUS_SETTLING &&
        self.pendingMode == ROUTE_SELLER &&
        self.pendingBuy != null &&
        prevOwner == self.pendingBuy!
    ) {
        self.status = SALE_STATUS_ACTIVE;
        self.nftDeposited = true;
        self.clearPending();
        storage.saveRuntime(self);
        return;
    }

    self.rememberRejected(sender, prevOwner, SALE_REJECT_NOT_ACTIVE, value, gas.minRejectStorageValue);
    storage.saveRuntime(self);
}

fun ReverseSaleStorage.marketplaceFee(self, value: coins): coins {
    if (value == 0 || self.feeBps == 0) {
        return 0;
    }
    return value * self.feeBps / 10000;
}

fun ReverseSaleStorage.validateRoutePayload(
    self,
    payloadCell: cell,
    mode: int,
    dealId: int,
    executionPrice: coins,
): bool {
    var payload = payloadCell.beginParse();
    if (payload.remainingBitsCount() < 32 || payload.remainingRefsCount() < 1) {
        return false;
    }
    if (payload.loadUint(32) != 0x52424143) {
        return false;
    }
    payload.loadRef();
    if (payload.remainingBitsCount() < 72) {
        return false;
    }
    if (payload.loadUint(8) != mode || payload.loadUint(64) != dealId) {
        return false;
    }
    if (payload.remainingBitsCount() == 0 || payload.loadCoins() != executionPrice) {
        return false;
    }
    if (payload.remainingBitsCount() < 32) {
        return false;
    }
    if (payload.loadUint(16) != ECONOMIC_VERSION || payload.loadUint(16) != self.feeBps) {
        return false;
    }
    return payload.loadAddress() == self.feeReceiver;
}

fun ReverseSaleRuntime.clearPending(mutate self) {
    self.pendingMode = ROUTE_NONE;
    self.pendingBuy = null;
    self.pendingPayment = 0;
    self.pendingDealId = 0;
}

fun ReverseSaleRuntime.rememberRejected(
    mutate self,
    nft: address,
    prevOwner: address,
    reason: int,
    attached: coins,
    minRejectStorageValue: coins,
) {
    if (attached >= minRejectStorageValue) {
        self.rejectedItems.set(nft, {
            prevOwner,
            reasonCode: reason,
            createdAt: blockchain.now(),
        });
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

fun transferNftWithPayload(
    nft: address,
    newOwner: address,
    responseDestination: address,
    value: coins,
    forwardAmount: coins,
    forwardPayload: cell,
) {
    val body = beginCell()
        .storeUint(0x5fcc3d14, 32)
        .storeUint(0, 64)
        .storeAddress(newOwner)
        .storeAddress(responseDestination)
        .storeBool(false)
        .storeCoins(forwardAmount)
        .storeBool(true)
        .storeRef(forwardPayload)
        .endCell();
    val msg = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: nft,
        value,
        body,
    });
    msg.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

get fun get_sale_state(): SaleState {
    val storage = ReverseSaleStorage.load();
    val runtime = storage.runtime.load();
    return {
        economicVersion: ECONOMIC_VERSION,
        status: runtime.status,
        seller: storage.seller,
        nft: storage.nft,
        price: storage.price,
        feeBps: storage.feeBps,
        feeReceiver: storage.feeReceiver,
        nftDeposited: runtime.nftDeposited,
        pendingMode: runtime.pendingMode,
        pendingUntil: 0,
    };
}

// Keep the legacy Tact ABI: one nullable TVM tuple on the stack. Returning the
// struct directly would flatten its fields in Tolk and break existing clients
// that use TupleReader.readTupleOpt().
get fun get_rejected_item(nft: address): [address, uint8, uint32]? {
    val found = ReverseSaleStorage.load().runtime.load().rejectedItems.get(nft);
    if (!found.isFound) {
        return null;
    }
    val rejected = found.loadValue();
    return [rejected.prevOwner, rejected.reasonCode, rejected.createdAt];
}
