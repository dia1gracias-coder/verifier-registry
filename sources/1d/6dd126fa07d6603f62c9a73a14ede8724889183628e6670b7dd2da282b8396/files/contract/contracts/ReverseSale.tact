import "@stdlib/deploy";

const ECONOMIC_VERSION: Int = 2;

const SALE_STATUS_WAITING_NFT: Int = 0;
const SALE_STATUS_ACTIVE: Int = 1;
const SALE_STATUS_SOLD: Int = 2;
const SALE_STATUS_CANCELLED: Int = 3;
const SALE_STATUS_SETTLING: Int = 4;

const ROUTE_NONE: Int = 0;
const ROUTE_BUYER: Int = 1;
const ROUTE_SELLER: Int = 2;

const SALE_REJECT_WRONG_NFT: Int = 1;
const SALE_REJECT_WRONG_SELLER: Int = 2;
const SALE_REJECT_NOT_ACTIVE: Int = 3;

message(0x5253434e) CancelSale { queryId: Int as uint64; }
message(0x5253524e) RescueHeldNft { queryId: Int as uint64; }

// Seller starts a sale into an existing ReverseBuy. The buyer's bid is the price.
message(0x52534642) FillBuyOffer {
    queryId: Int as uint64;
    buyContract: Address;
    settlementPrice: Int as coins;
    acceptPayload: Cell;
}

// ReverseBuy starts a purchase from this sale. This sale's ask is the price.
message(0x52534242) BuyForReverseBuy {
    queryId: Int as uint64;
    acceptPayload: Cell;
}

message(0x5242524a) ClaimRejectedNft { nft: Address; }

message(0x05138d91) OwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Slice as remaining;
}

struct SaleState {
    economicVersion: Int as uint16;
    status: Int as uint8;
    seller: Address;
    nft: Address;
    price: Int as coins;
    feeBps: Int as uint16;
    feeReceiver: Address;
    nftDeposited: Bool;
    pendingMode: Int as uint8;
    pendingUntil: Int as uint32;
}

struct SaleRejectedItem {
    prevOwner: Address;
    reasonCode: Int as uint8;
    createdAt: Int as uint32;
}

contract ReverseSale {
    seller: Address;
    nft: Address;
    price: Int as coins;
    feeReceiver: Address;
    feeBps: Int as uint16;
    minContractReserve: Int as coins;
    minDepositValue: Int as coins;
    minBuyValue: Int as coins;
    nftTransferValue: Int as coins;
    minRejectStorageValue: Int as coins;
    status: Int as uint8;
    nftDeposited: Bool;
    pendingMode: Int as uint8;
    pendingBuy: Address?;
    pendingPayment: Int as coins;
    pendingDealId: Int as uint64;
    rejectedItems: map<Address, SaleRejectedItem>;

    init(config: Cell) {
        let data: Slice = config.beginParse();
        require(data.loadUint(16) == ECONOMIC_VERSION, "invalid config");
        self.seller = data.loadAddress();
        self.nft = data.loadAddress();
        self.feeReceiver = data.loadAddress();
        self.price = data.loadCoins();
        self.feeBps = data.loadUint(16);

        let gas: Slice = data.loadRef().beginParse();
        self.minContractReserve = gas.loadCoins();
        self.minDepositValue = gas.loadCoins();
        self.minBuyValue = gas.loadCoins();
        self.nftTransferValue = gas.loadCoins();
        self.minRejectStorageValue = gas.loadCoins();

        require(self.price > 0, "invalid price");
        require(self.feeBps <= 1000, "fee too high");
        self.status = SALE_STATUS_WAITING_NFT;
        self.nftDeposited = false;
        self.pendingMode = ROUTE_NONE;
        self.pendingBuy = null;
        self.pendingPayment = 0;
        self.pendingDealId = 0;
        self.rejectedItems = emptyMap();
    }

    receive(deploy: Deploy) {
        let ctx: Context = context();
        require(ctx.sender == self.seller, "not seller");
        require(ctx.value >= self.minContractReserve, "insufficient deploy");
        // Excess stays in the seller-owned reserve and is returned on cancel/sale.
    }

    // Net settlement for a seller-initiated route. ReverseBuy validates the
    // NFT and bid and deducts the seller fee before sending the proceeds.
    receive() {
        let ctx: Context = context();
        let fee: Int = self.marketplaceFee(self.pendingPayment);
        let sellerNet: Int = self.pendingPayment - fee;
        if (self.status != SALE_STATUS_SETTLING || self.pendingMode != ROUTE_SELLER || self.pendingBuy == null || ctx.sender != self.pendingBuy!! || ctx.value < sellerNet) {
            self.refundInbound(ctx.sender);
            return;
        }

        self.status = SALE_STATUS_SOLD;
        self.nftDeposited = false;
        self.clearPending();
        self.sendTon(self.seller, sellerNet);
        self.sendRemainingTon(self.seller);
    }

    receive(msg: OwnershipAssigned) {
        let ctx: Context = context();
        if (ctx.sender != self.nft) {
            self.rememberRejected(ctx.sender, msg.prevOwner, SALE_REJECT_WRONG_NFT, ctx.value);
            return;
        }

        if (self.status == SALE_STATUS_WAITING_NFT) {
            if (msg.prevOwner != self.seller) {
                self.rememberRejected(ctx.sender, msg.prevOwner, SALE_REJECT_WRONG_SELLER, ctx.value);
                return;
            }
            self.nftDeposited = true;
            self.status = SALE_STATUS_ACTIVE;
            return;
        }

        // If ReverseBuy became unavailable during routing, its existing
        // auto-return sends the NFT back here. Restore the sale without ACKs.
        if (self.status == SALE_STATUS_SETTLING && self.pendingMode == ROUTE_SELLER && self.pendingBuy != null && msg.prevOwner == self.pendingBuy!!) {
            self.status = SALE_STATUS_ACTIVE;
            self.nftDeposited = true;
            self.clearPending();
            return;
        }

        self.rememberRejected(ctx.sender, msg.prevOwner, SALE_REJECT_NOT_ACTIVE, ctx.value);
    }

    receive(msg: FillBuyOffer) {
        let ctx: Context = context();
        require(ctx.sender == self.seller, "not seller");
        if (self.status != SALE_STATUS_ACTIVE || !self.nftDeposited || self.pendingMode != ROUTE_NONE || msg.queryId == 0 || msg.settlementPrice < self.price) {
            self.refundInbound(ctx.sender);
            return;
        }
        if (!self.validateRoutePayload(msg.acceptPayload, ROUTE_SELLER, msg.queryId, msg.settlementPrice)) {
            self.refundInbound(ctx.sender);
            return;
        }

        self.status = SALE_STATUS_SETTLING;
        self.nftDeposited = false;
        self.pendingMode = ROUTE_SELLER;
        self.pendingBuy = msg.buyContract;
        self.pendingPayment = msg.settlementPrice;
        self.pendingDealId = msg.queryId;
        self.transferNftWithPayload(self.nft, msg.buyContract, self.seller, self.nftTransferValue, self.minBuyValue, msg.acceptPayload);
    }

    receive(msg: BuyForReverseBuy) {
        let ctx: Context = context();
        if (self.status != SALE_STATUS_ACTIVE || !self.nftDeposited || msg.queryId == 0 || ctx.value < self.price) {
            self.refundInbound(ctx.sender);
            return;
        }
        if (!self.validateRoutePayload(msg.acceptPayload, ROUTE_BUYER, msg.queryId, self.price)) {
            self.refundInbound(ctx.sender);
            return;
        }

        let fee: Int = self.marketplaceFee(self.price);
        self.status = SALE_STATUS_SOLD;
        self.nftDeposited = false;
        self.sendTon(self.seller, self.price - fee);
        if (fee > 0) {
            self.sendTon(self.feeReceiver, fee);
        }
        // ReverseSale pays NFT routing from the seller's reserve.
        self.transferNftWithPayload(self.nft, ctx.sender, self.seller, self.nftTransferValue, self.minBuyValue, msg.acceptPayload);
        self.sendRemainingTon(self.seller);
    }

    receive(msg: CancelSale) {
        let ctx: Context = context();
        require(ctx.sender == self.seller, "not seller");
        if (self.status != SALE_STATUS_WAITING_NFT && self.status != SALE_STATUS_ACTIVE && self.status != SALE_STATUS_CANCELLED) {
            self.refundInbound(ctx.sender);
            return;
        }
        self.status = SALE_STATUS_CANCELLED;
        if (self.nftDeposited) {
            self.nftDeposited = false;
            self.transferNft(self.nft, self.seller, self.nftTransferValue);
        }
        self.sendRemainingTon(self.seller);
    }

    receive(msg: RescueHeldNft) {
        let ctx: Context = context();
        require(ctx.sender == self.seller, "not seller");
        if (self.status == SALE_STATUS_SOLD || self.status == SALE_STATUS_SETTLING) {
            self.refundInbound(ctx.sender);
            return;
        }
        self.status = SALE_STATUS_CANCELLED;
        self.nftDeposited = false;
        self.transferNft(self.nft, self.seller, self.nftTransferValue);
        self.sendRemainingTon(self.seller);
    }

    receive(msg: ClaimRejectedNft) {
        let ctx: Context = context();
        let item: SaleRejectedItem? = self.rejectedItems.get(msg.nft);
        require(item != null, "not rejected");
        let rejected: SaleRejectedItem = item!!;
        require(ctx.sender == rejected.prevOwner, "not previous owner");
        require(ctx.value >= self.nftTransferValue, "insufficient return value");
        self.rejectedItems.del(msg.nft);
        self.transferNft(msg.nft, rejected.prevOwner, self.nftTransferValue);
    }

    get fun get_sale_state(): SaleState {
        return SaleState{
            economicVersion: ECONOMIC_VERSION,
            status: self.status,
            seller: self.seller,
            nft: self.nft,
            price: self.price,
            feeBps: self.feeBps,
            feeReceiver: self.feeReceiver,
            nftDeposited: self.nftDeposited,
            pendingMode: self.pendingMode,
            pendingUntil: 0
        };
    }

    get fun get_rejected_item(nft: Address): SaleRejectedItem? { return self.rejectedItems.get(nft); }

    fun marketplaceFee(value: Int): Int {
        if (value <= 0 || self.feeBps <= 0) { return 0; }
        return value * self.feeBps / 10000;
    }

    fun validateRoutePayload(payloadCell: Cell, mode: Int, dealId: Int, executionPrice: Int): Bool {
        let payload: Slice = payloadCell.beginParse();
        if (payload.bits() < 32 || payload.refs() < 1 || payload.loadUint(32) != 0x52424143) { return false; }
        let proof: Cell = payload.loadRef();
        if (payload.bits() < 72 || payload.loadUint(8) != mode || payload.loadUint(64) != dealId) { return false; }
        if (payload.bits() == 0 || payload.loadCoins() != executionPrice) { return false; }
        if (payload.bits() < 32 || payload.loadUint(16) != ECONOMIC_VERSION || payload.loadUint(16) != self.feeBps) { return false; }
        return payload.loadAddress() == self.feeReceiver;
    }

    fun clearPending() {
        self.pendingMode = ROUTE_NONE;
        self.pendingBuy = null;
        self.pendingPayment = 0;
        self.pendingDealId = 0;
    }

    fun rememberRejected(nft: Address, prevOwner: Address, reason: Int, attached: Int) {
        if (attached >= self.minRejectStorageValue) {
            self.rejectedItems.set(nft, SaleRejectedItem{ prevOwner: prevOwner, reasonCode: reason, createdAt: now() });
        }
    }

    fun refundInbound(to: Address) {
        send(SendParameters{ to: to, value: 0, bounce: false, mode: SendRemainingValue | SendIgnoreErrors });
    }

    fun sendTon(to: Address, amount: Int) {
        if (amount > 0) {
            send(SendParameters{ to: to, value: amount, bounce: false, mode: SendPayGasSeparately });
        }
    }

    fun sendRemainingTon(to: Address) {
        send(SendParameters{ to: to, value: 0, bounce: false, mode: SendRemainingBalance | SendIgnoreErrors });
    }

    fun transferNft(nft: Address, newOwner: Address, value: Int) {
        let body: Cell = beginCell().storeUint(0x5fcc3d14, 32).storeUint(0, 64).storeAddress(newOwner).storeAddress(newOwner).storeBit(false).storeCoins(0).storeBit(false).endCell();
        send(SendParameters{ to: nft, value: value, bounce: true, mode: SendPayGasSeparately, body: body });
    }

    fun transferNftWithPayload(nft: Address, newOwner: Address, responseDestination: Address, value: Int, forwardAmount: Int, forwardPayload: Cell) {
        let body: Cell = beginCell().storeUint(0x5fcc3d14, 32).storeUint(0, 64).storeAddress(newOwner).storeAddress(responseDestination).storeBit(false).storeCoins(forwardAmount).storeBit(true).storeRef(forwardPayload).endCell();
        send(SendParameters{ to: nft, value: value, bounce: true, mode: SendPayGasSeparately, body: body });
    }
}
