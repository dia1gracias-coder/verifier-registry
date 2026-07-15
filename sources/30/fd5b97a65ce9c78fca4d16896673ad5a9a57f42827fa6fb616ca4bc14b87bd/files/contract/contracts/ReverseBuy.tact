import "@stdlib/deploy";

const ECONOMIC_VERSION: Int = 2;
const BUY_STATUS_ACTIVE: Int = 0;
const BUY_STATUS_FILLED: Int = 1;
const BUY_STATUS_CANCELLED: Int = 2;

const ROUTE_NONE: Int = 0;
const ROUTE_BUYER: Int = 1;
const ROUTE_SELLER: Int = 2;

const CONDITION_NONE: Int = 0;
const CONDITION_AND: Int = 1;
const CONDITION_OR: Int = 2;
const MAX_CONDITIONS: Int = 16;

// Headroom for forward/action fees and gas between the seller payout and the NFT
// hand-off. Incident ORD-105 (2026-07-07): a fill whose payout left less than
// nftTransferValue aborted in the action phase and stranded the inbound NFT.
const FILL_GAS_MARGIN: Int = ton("0.01");

message(0x5242434e) CancelBuyOffer { queryId: Int as uint64; }

message(0x5242524e) RescueStrandedNft {
    queryId: Int as uint64;
    nft: Address;
    recipient: Address;
}

message(0x52425342) BuySaleOffer {
    queryId: Int as uint64;
    saleContract: Address;
    nft: Address;
    salePrice: Int as coins;
    acceptPayload: Cell;
}

message(0x05138d91) OwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Slice as remaining;
}

struct BuyState {
    economicVersion: Int as uint16;
    status: Int as uint8;
    buyer: Address;
    collection: Address;
    price: Int as coins;
    reservedBalance: Int as coins;
    feeBps: Int as uint16;
    feeReceiver: Address;
    conditionMode: Int as uint8;
    conditionCount: Int as uint8;
    conditionsHash: Int as uint256;
    eligibilityRoot: Int as uint256;
    funded: Bool;
    pendingMode: Int as uint8;
    pendingUntil: Int as uint32;
}

contract ReverseBuy {
    buyer: Address;
    collection: Address;
    price: Int as coins;
    feeReceiver: Address;
    feeBps: Int as uint16;
    conditionMode: Int as uint8;
    conditionCount: Int as uint8;
    conditionsHash: Int as uint256;
    eligibilityRoot: Int as uint256;
    minContractReserve: Int as coins;
    minAcceptValue: Int as coins;
    nftTransferValue: Int as coins;
    // Deployer config slot kept for layout/address compatibility. ReverseBuy no
    // longer quarantines inbound NFTs (it returns them), so this is unused here.
    minRejectStorageValue: Int as coins;
    status: Int as uint8;
    reservedBalance: Int as coins;
    funded: Bool;
    pendingSale: Address?;
    pendingNft: Address?;
    pendingSalePrice: Int as coins;
    pendingDealId: Int as uint64;

    init(config: Cell) {
        let data: Slice = config.beginParse();
        require(data.loadUint(16) == ECONOMIC_VERSION, "invalid config");
        let salt: Int = data.loadUint(64);
        self.buyer = data.loadAddress();
        self.collection = data.loadAddress();
        self.feeReceiver = data.loadAddress();
        self.price = data.loadCoins();
        self.feeBps = data.loadUint(16);
        let eligibility: Slice = data.loadRef().beginParse();
        self.eligibilityRoot = eligibility.loadUint(256);
        let conditions: Cell = eligibility.loadRef();
        self.conditionsHash = conditions.hash();
        let header: Slice = conditions.beginParse();
        self.conditionMode = header.loadUint(8);
        self.conditionCount = header.loadUint(8);

        let gas: Slice = data.loadRef().beginParse();
        self.minContractReserve = gas.loadCoins();
        self.minAcceptValue = gas.loadCoins();
        self.nftTransferValue = gas.loadCoins();
        self.minRejectStorageValue = gas.loadCoins();

        require(self.price > 0, "invalid price");
        require(self.feeBps <= 1000, "fee too high");
        require(self.eligibilityRoot != 0, "missing root");
        self.status = BUY_STATUS_ACTIVE;
        self.reservedBalance = self.price;
        self.funded = false;
        self.pendingSale = null;
        self.pendingNft = null;
        self.pendingSalePrice = 0;
        self.pendingDealId = 0;
        self.validateConditions(conditions);
    }

    receive(deploy: Deploy) {
        let ctx: Context = context();
        require(ctx.sender == self.buyer, "not buyer");
        let required: Int = self.price + self.minContractReserve;
        require(ctx.value >= required, "insufficient deposit");
        require(!self.funded, "already funded");
        self.funded = true;
        self.refundAttached(ctx.sender, ctx.value - required);
    }

    // ReverseSale refunds a failed buyer-initiated purchase with an empty body.
    receive() {
        let ctx: Context = context();
        if (self.pendingSale != null && ctx.sender == self.pendingSale!! && self.status == BUY_STATUS_ACTIVE) {
            self.clearPending();
            self.reservedBalance = self.price;
        }
        self.refundAttached(self.buyer, ctx.value);
    }

    receive(msg: CancelBuyOffer) {
        let ctx: Context = context();
        require(ctx.sender == self.buyer, "not buyer");
        if (self.status != BUY_STATUS_ACTIVE || self.pendingSale != null) {
            self.refundInbound(ctx.sender);
            return;
        }
        self.status = BUY_STATUS_CANCELLED;
        self.reservedBalance = 0;
        self.sendRemainingTon(self.buyer);
    }

    receive(msg: BuySaleOffer) {
        let ctx: Context = context();
        require(ctx.sender == self.buyer, "not buyer");
        if (!self.funded || self.status != BUY_STATUS_ACTIVE || self.pendingSale != null || msg.queryId == 0 || msg.salePrice <= 0 || msg.salePrice > self.price) {
            self.refundInbound(ctx.sender);
            return;
        }
        if (!self.validateAcceptPayload(msg.nft, msg.acceptPayload, ROUTE_BUYER, msg.queryId, msg.salePrice)) {
            self.refundInbound(ctx.sender);
            return;
        }
        self.pendingSale = msg.saleContract;
        self.pendingNft = msg.nft;
        self.pendingSalePrice = msg.salePrice;
        self.pendingDealId = msg.queryId;
        self.reservedBalance = self.price - msg.salePrice;
        self.buyReverseSale(msg.saleContract, msg.salePrice, msg.acceptPayload);
        self.refundAttached(ctx.sender, ctx.value);
    }

    receive(msg: OwnershipAssigned) {
        let ctx: Context = context();
        if (!self.funded || self.status != BUY_STATUS_ACTIVE) {
            self.returnInboundNft(ctx.sender, msg.prevOwner);
            return;
        }

        let payload: Slice = self.unwrapForwardPayload(msg.forwardPayload);
        if (payload.bits() < 32 || payload.refs() < 1 || payload.loadUint(32) != 0x52424143) {
            // Never quarantine an inbound NFT here: a seller-routed fill carries
            // prevOwner = ReverseSale, which cannot self-claim. Always bounce the
            // NFT back to its sender so a routed sale contract recovers.
            self.returnInboundNft(ctx.sender, msg.prevOwner);
            return;
        }
        let proof: Slice = payload.loadRef().beginParse();
        let routeMode: Int = ROUTE_NONE;
        let dealId: Int = 0;
        let executionPrice: Int = 0;
        if (payload.bits() >= 72) {
            routeMode = payload.loadUint(8);
            dealId = payload.loadUint(64);
            if (payload.bits() > 0) {
                executionPrice = payload.loadCoins();
            }
        }
        if (!self.verifyEligibilityProof(ctx.sender, proof)) {
            // Same rationale as the invalid-payload branch: return, never quarantine.
            self.returnInboundNft(ctx.sender, msg.prevOwner);
            return;
        }

        if (routeMode == ROUTE_BUYER) {
            if (self.pendingSale == null || self.pendingNft == null || msg.prevOwner != self.pendingSale!! || ctx.sender != self.pendingNft!! || dealId != self.pendingDealId || executionPrice != self.pendingSalePrice) {
                self.returnInboundNft(ctx.sender, msg.prevOwner);
                return;
            }
            self.status = BUY_STATUS_FILLED;
            self.reservedBalance = 0;
            self.clearPending();
            if (!self.canAffordFillSends(0)) {
                // The sale contract is already SOLD and paid out, so a return would
                // strand the NFT there. Deliver to the buyer on the inbound value.
                self.returnInboundNft(ctx.sender, self.buyer);
                return;
            }
            self.transferNft(ctx.sender, self.buyer, self.nftTransferValue);
            self.sendRemainingTon(self.buyer);
            return;
        }

        if (routeMode == ROUTE_SELLER) {
            if (executionPrice != self.price) {
                self.returnInboundNft(ctx.sender, msg.prevOwner);
                return;
            }
            // The payout below leaves the contract before the NFT hand-off. If the
            // remaining balance cannot fund the transfer, the action phase would abort
            // after the NFT already changed owner and strand it here. Return it instead.
            if (!self.canAffordFillSends(self.price + ctx.value)) {
                self.returnInboundNft(ctx.sender, msg.prevOwner);
                return;
            }
            let fee: Int = self.marketplaceFee(self.price);
            self.status = BUY_STATUS_FILLED;
            self.reservedBalance = 0;
            // Deduct here so a forged seller-route payload cannot bypass the
            // fee by naming a wallet or an unrelated contract as prevOwner.
            self.sendTon(msg.prevOwner, self.price - fee + ctx.value);
            if (fee > 0) {
                self.sendTon(self.feeReceiver, fee);
            }
            self.transferNft(ctx.sender, self.buyer, self.nftTransferValue);
            self.sendRemainingTon(self.buyer);
            return;
        }

        if (routeMode != ROUTE_NONE || executionPrice != 0) {
            self.returnInboundNft(ctx.sender, msg.prevOwner);
            return;
        }
        // Same stranding hazard as the seller route: never start the payout unless
        // the NFT hand-off is still fundable afterwards.
        if (!self.canAffordFillSends(self.price + ctx.value)) {
            self.returnInboundNft(ctx.sender, msg.prevOwner);
            return;
        }
        let fee: Int = self.marketplaceFee(self.price);
        self.status = BUY_STATUS_FILLED;
        self.reservedBalance = 0;
        self.sendTon(msg.prevOwner, self.price - fee + ctx.value);
        if (fee > 0) {
            self.sendTon(self.feeReceiver, fee);
        }
        self.transferNft(ctx.sender, self.buyer, self.nftTransferValue);
        self.sendRemainingTon(self.buyer);
    }

    // Last-resort exit for an NFT left owned by this contract after an aborted fill
    // (incident ORD-105). Only once no fill can be in flight, and funded by the
    // caller because CANCELLED already drained the balance to the buyer.
    receive(msg: RescueStrandedNft) {
        let ctx: Context = context();
        require(ctx.sender == self.buyer, "not buyer");
        require(self.status != BUY_STATUS_ACTIVE, "order still active");
        require(ctx.value >= self.nftTransferValue, "insufficient rescue value");
        self.returnInboundNft(msg.nft, msg.recipient);
    }

    get fun get_buy_state(): BuyState {
        let pendingMode: Int = ROUTE_NONE;
        if (self.pendingSale != null) {
            pendingMode = ROUTE_BUYER;
        }
        return BuyState{
            economicVersion: ECONOMIC_VERSION,
            status: self.status,
            buyer: self.buyer,
            collection: self.collection,
            price: self.price,
            reservedBalance: self.reservedBalance,
            feeBps: self.feeBps,
            feeReceiver: self.feeReceiver,
            conditionMode: self.conditionMode,
            conditionCount: self.conditionCount,
            conditionsHash: self.conditionsHash,
            eligibilityRoot: self.eligibilityRoot,
            funded: self.funded,
            pendingMode: pendingMode,
            pendingUntil: 0
        };
    }

    fun marketplaceFee(value: Int): Int {
        if (value <= 0 || self.feeBps <= 0) { return 0; }
        return value * self.feeBps / 10000;
    }

    // payoutTotal is everything a fill sends before the NFT hand-off; the balance
    // (which already includes the inbound value) must also cover the transfer itself.
    fun canAffordFillSends(payoutTotal: Int): Bool {
        return myBalance() >= payoutTotal + self.nftTransferValue + FILL_GAS_MARGIN;
    }

    fun clearPending() {
        self.pendingSale = null;
        self.pendingNft = null;
        self.pendingSalePrice = 0;
        self.pendingDealId = 0;
    }

    fun validateAcceptPayload(nft: Address, payloadCell: Cell, mode: Int, dealId: Int, executionPrice: Int): Bool {
        let payload: Slice = payloadCell.beginParse();
        if (payload.bits() < 32 || payload.refs() < 1 || payload.loadUint(32) != 0x52424143) { return false; }
        let proof: Slice = payload.loadRef().beginParse();
        if (payload.bits() < 72 || payload.loadUint(8) != mode || payload.loadUint(64) != dealId) { return false; }
        if (payload.bits() == 0 || payload.loadCoins() != executionPrice) { return false; }
        if (payload.bits() < 32 || payload.loadUint(16) != ECONOMIC_VERSION || payload.loadUint(16) != self.feeBps) { return false; }
        if (payload.loadAddress() != self.feeReceiver) { return false; }
        return self.verifyEligibilityProof(nft, proof);
    }

    fun validateConditions(cell: Cell) {
        let data: Slice = cell.beginParse();
        let mode: Int = data.loadUint(8);
        let count: Int = data.loadUint(8);
        require(count <= MAX_CONDITIONS, "too many conditions");
        if (count == 0) { require(mode == CONDITION_NONE, "invalid condition mode"); return; }
        require(mode == CONDITION_AND || mode == CONDITION_OR, "invalid condition mode");
        let index: Int = 0;
        let previousKey: Int = 0;
        while (index < count) {
            require(data.bits() >= 512, "invalid condition data");
            let key: Int = data.loadUint(256);
            let value: Int = data.loadUint(256);
            require(key > previousKey && value != 0, "invalid condition");
            previousKey = key;
            index = index + 1;
        }
    }

    fun verifyEligibilityProof(nft: Address, proof: Slice): Bool {
        let current: Int = beginCell().storeAddress(self.collection).storeAddress(nft).storeUint(self.conditionsHash, 256).endCell().hash();
        let cursor: Slice = proof;
        while (true) {
            while (cursor.bits() >= 257) {
                let left: Bool = cursor.loadBool();
                let sibling: Int = cursor.loadUint(256);
                if (left) { current = beginCell().storeUint(sibling, 256).storeUint(current, 256).endCell().hash(); }
                else { current = beginCell().storeUint(current, 256).storeUint(sibling, 256).endCell().hash(); }
            }
            if (cursor.refs() == 0) { return current == self.eligibilityRoot; }
            cursor = cursor.loadRef().beginParse();
        }
        return false;
    }

    fun unwrapForwardPayload(payload: Slice): Slice {
        if (payload.bits() == 1 && payload.refs() > 0) { payload.loadBool(); return payload.loadRef().beginParse(); }
        return payload;
    }

    fun buyReverseSale(sale: Address, value: Int, acceptPayload: Cell) {
        let body: Cell = beginCell().storeUint(0x52534242, 32).storeUint(self.pendingDealId, 64).storeRef(acceptPayload).endCell();
        send(SendParameters{ to: sale, value: value, bounce: true, mode: SendPayGasSeparately, body: body });
    }

    fun refundAttached(to: Address, amount: Int) { if (amount > 0) { self.sendTon(to, amount); } }
    fun refundInbound(to: Address) { send(SendParameters{ to: to, value: 0, bounce: false, mode: SendRemainingValue | SendIgnoreErrors }); }
    fun sendTon(to: Address, amount: Int) { if (amount > 0) { send(SendParameters{ to: to, value: amount, bounce: false, mode: SendPayGasSeparately }); } }
    fun sendRemainingTon(to: Address) { send(SendParameters{ to: to, value: 0, bounce: false, mode: SendRemainingBalance | SendIgnoreErrors }); }

    fun transferNft(nft: Address, newOwner: Address, value: Int) {
        let body: Cell = beginCell().storeUint(0x5fcc3d14, 32).storeUint(0, 64).storeAddress(newOwner).storeAddress(newOwner).storeBit(false).storeCoins(0).storeBit(false).endCell();
        send(SendParameters{ to: nft, value: value, bounce: true, mode: SendPayGasSeparately, body: body });
    }

    fun returnInboundNft(nft: Address, newOwner: Address) {
        // ReverseSale uses the standard ownership callback to restore ACTIVE
        // after an automatic return; no protocol ACK is introduced. The
        // 0.01 TON forward comes from ReverseSale's original NFT carrier.
        let body: Cell = beginCell().storeUint(0x5fcc3d14, 32).storeUint(0, 64).storeAddress(newOwner).storeAddress(newOwner).storeBit(false).storeCoins(10000000).storeBit(false).endCell();
        send(SendParameters{ to: nft, value: 0, bounce: false, mode: SendRemainingValue | SendIgnoreErrors, body: body });
    }
}
