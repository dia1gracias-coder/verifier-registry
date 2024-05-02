import "@stdlib/deploy";
import "@stdlib/ownable";

// ======================== Messages ========================
message CreateOffer {
    queryId: Int as uint64;
    seller: Address;
    exTokenWallet: Address; // Jetton wallet
    value: Int as coins;
    collateral: Int as coins;
}

message FillOffer {
    queryId: Int as uint64;
    buyer: Address;
    transferValue: Int as coins;
}

message SettleOffer {
    queryId: Int as uint64;
    caller: Address;
}

message ConfirmOffer {
    queryId: Int as uint64;
    caller: Address;
    isCallerOperator: Bool;
}

// ======================== Data Structures ========================
// offer data
struct Offer {
    offerId: Int as uint64;
    seller: Address;
    buyer: Address;
    exTokenWallet: Address; // Jetton wallet
    value: Int as coins;
    collateral: Int as coins;
    status: Int as uint8;
}

// ======================== Constants ========================
// Offer status
const OfferOpen: Int = 0;
const OfferFilled: Int = 1;
const OfferSettled: Int = 2;
const OfferClosed: Int = 3;

const minTonsForStorage: Int = ton("0.01");

contract EscrowOffer {
    escrow: Address;
    offer: Offer;
    init(escrow: Address, offerId: Int){
        self.escrow = escrow;
        self.offer = Offer{
            offerId: offerId,
            seller: newAddress(0, 0),
            buyer: newAddress(0, 0),
            exTokenWallet: newAddress(0, 0),
            value: 0,
            collateral: 0,
            status: OfferOpen
        };
    }

    receive(msg: CreateOffer){
        require(sender() == self.escrow, "Only escrow contract");
        self.offer.seller = msg.seller;
        self.offer.exTokenWallet = msg.exTokenWallet;
        self.offer.value = msg.value;
        self.offer.collateral = msg.collateral;
    }

    receive(msg: FillOffer){
        require(sender() == self.escrow, "Only escrow contract");
        if (msg.transferValue != self.offer.value || self.offer.status != OfferOpen) {
            // refund jettons
            send(SendParameters{
                to: self.escrow,
                value: 0,
                body: PayTo{
                    offerId: self.offer.offerId,
                    queryId: msg.queryId,
                    fromWallet: self.offer.exTokenWallet,
                    amount: msg.transferValue,
                    destination: msg.buyer,
                    responseDestination: msg.buyer
                }.toCell()
            });
            return;
        }
        self.offer.buyer = msg.buyer;
        self.offer.status = OfferFilled;
    }

    receive(msg: SettleOffer){
        require(sender() == self.escrow, "Only escrow contract");
        require(self.offer.status == OfferFilled, "Invalid offer status");
        self.offer.status = OfferSettled;
        // transfer collateral + value to buyer
        send(SendParameters{
                to: self.escrow,
                value: 0,
                body: PayTo{
                    offerId: self.offer.offerId,
                    queryId: msg.queryId,
                    fromWallet: self.offer.exTokenWallet,
                    amount: self.offer.collateral + self.offer.value,
                    destination: self.offer.buyer,
                    responseDestination: msg.caller
                }.toCell()
            });
    }

    receive(msg: ConfirmOffer){
        require(sender() == self.escrow, "Only escrow contract");
        require(self.offer.status == OfferFilled, "Invalid offer status");
        require(msg.isCallerOperator || msg.caller == self.offer.buyer, "Invalid caller");
        self.offer.status = OfferClosed;
        // transfer collateral + value to seller
        send(SendParameters{
                to: self.escrow,
                value: 0,
                body: PayTo{
                    offerId: self.offer.offerId,
                    queryId: msg.queryId,
                    fromWallet: self.offer.exTokenWallet,
                    amount: self.offer.collateral + self.offer.value,
                    destination: self.offer.seller,
                    responseDestination: msg.caller
                }.toCell()
            });
    }

    get fun get_offer_data(): Offer {
        return self.offer;
    }
}

// ======================== Messages ========================
message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}

message SetOperator {
    operator: Address;
}

message UpdatePledgeRate {
    pledgeRate: Int as uint64;
}

message PayTo {
    offerId: Int? as uint64;
    queryId: Int as uint64;
    fromWallet: Address; // Jetton wallet
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
}

message CallSettleOffer {
    queryId: Int as uint64;
    offerId: Int as uint64;
}

message CallConfirmOffer {
    queryId: Int as uint64;
    offerId: Int as uint64;
}

// ======================== Constants ========================
const OpCreateOffer: Int = 1000;
const OpFillOffer: Int = 1001;
const OpSettleOffer: Int = 1002;
const OpConfirmOffer: Int = 1003;
const WEI6: Int = 1000000;

contract Escrow with Deployable, OwnableTransferable {
    owner: Address;
    operator: Address;
    pledgeRate: Int as uint64;
    lastOfferId: Int as uint256;
    init(){
        self.owner = sender();
        self.operator = newAddress(0, 0);
        self.pledgeRate = WEI6 / 20; // 5%
        self.lastOfferId = 0;
    }

    receive(msg: SetOperator){
        self.requireOwner();
        self.operator = msg.operator;
    }

    receive(msg: UpdatePledgeRate){
        self.requireOwner();
        require(msg.pledgeRate > 0 && msg.pledgeRate < WEI6, "Invalid pledgeRate");
        self.pledgeRate = msg.pledgeRate;
    }

    receive(msg: PayTo){
        require(msg.offerId != null, "Invalid offerId");
        require(msg.amount > 0, "Invalid amount");
        require(sender() == self.get_offer_address(msg.offerId!!), "Only offer contract");
        self.send_transfer_message(msg);
    }

    receive(msg: TokenNotification){
        let ctx: Context = context();
        let fwdFee: Int = ctx.readForwardFee();

        require(msg.amount > 0, "Invalid amount");
        let op: Int = msg.forwardPayload.loadUint(32);
        // create offer
        if (op == OpCreateOffer) {
            let value: Int = msg.forwardPayload.loadCoins();

            if (msg.amount != value * self.pledgeRate / WEI6 || ctx.value < fwdFee + minTonsForStorage) {
                // refund jettons
                self.send_transfer_message(PayTo{
                        offerId: null,
                        queryId: msg.queryId,
                        fromWallet: ctx.sender,
                        amount: msg.amount,
                        destination: msg.from,
                        responseDestination: msg.from
                    }
                );
                return;
            }
            self.lastOfferId += 1;
            let offerId: Int = self.lastOfferId;
            let offerInit: StateInit = self.getOfferInit(offerId);
            send(SendParameters{
                    to: self.get_offer_address(offerId),
                    value: 0,
                    mode: SendRemainingValue,
                    body: CreateOffer{
                        queryId: msg.queryId,
                        seller: msg.from,
                        exTokenWallet: ctx.sender,
                        value: value,
                        collateral: msg.amount
                    }.toCell(),
                    code: offerInit.code,
                    data: offerInit.data
                }
            );
            return;
        }
        // fill offer
        if (op == OpFillOffer) {
            if (ctx.value < fwdFee * 2) {
                // refund jettons
                self.send_transfer_message(PayTo{
                        offerId: null,
                        queryId: msg.queryId,
                        fromWallet: ctx.sender,
                        amount: msg.amount,
                        destination: msg.from,
                        responseDestination: msg.from
                    }
                );
                return;
            }

            let offerId: Int = msg.forwardPayload.loadUint(64);
            let offerInit: StateInit = self.getOfferInit(offerId);
            send(SendParameters{
                    to: self.get_offer_address(offerId),
                    value: 0,
                    mode: SendRemainingValue,
                    body: FillOffer{
                        queryId: msg.queryId,
                        buyer: msg.from,
                        transferValue: msg.amount
                    }.toCell(),
                    code: offerInit.code,
                    data: offerInit.data
                }
            );
            return;
        }
    }

    receive(msg: CallSettleOffer){
        let ctx: Context = context();
        let fwdFee: Int = ctx.readForwardFee();

        require(ctx.value >= fwdFee * 5, "Insufficient fee");
        require(ctx.sender == self.operator, "Only accept call from operator");

        let offerInit: StateInit = self.getOfferInit(msg.offerId);
        send(SendParameters{
                to: self.get_offer_address(msg.offerId),
                value: 0,
                mode: SendRemainingValue,
                body: SettleOffer{
                    queryId: msg.queryId,
                    caller: ctx.sender
                }.toCell(),
                code: offerInit.code,
                data: offerInit.data
            }
        );
    }

    receive(msg: CallConfirmOffer){
        let ctx: Context = context();

        let fwdFee: Int = ctx.readForwardFee();
        require(ctx.value >= fwdFee * 5, "Insufficient fee");

        let offerInit: StateInit = self.getOfferInit(msg.offerId);
        send(SendParameters{
                to: self.get_offer_address(msg.offerId),
                value: 0,
                mode: SendRemainingValue,
                body: ConfirmOffer{
                    queryId: msg.queryId,
                    caller: sender(),
                    isCallerOperator: sender() == self.operator
                }.toCell(),
                code: offerInit.code,
                data: offerInit.data
            }
        );
    }

    // bounced(msg: Slice){}

    inline fun send_transfer_message(msg: PayTo) {
        send(SendParameters{
                to: msg.fromWallet,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: TokenTransfer{
                    queryId: msg.queryId,
                    amount: msg.amount,
                    destination: msg.destination,
                    responseDestination: msg.responseDestination,
                    customPayload: emptyCell(),
                    forwardTonAmount: 0,
                    forwardPayload: emptySlice()
                }.toCell()
            }
        );
    }

    inline fun getOfferInit(offerId: Int): StateInit {
        return initOf EscrowOffer(myAddress(), offerId);
    }

    // @dev get_offer_address call get_offer_address and return address of offer

    get fun get_offer_address(offerId: Int): Address {
        let initCode: StateInit = self.getOfferInit(offerId);
        return contractAddress(initCode);
    }

    get fun get_last_offer_id(): Int {
        return self.lastOfferId;
    }

    get fun get_pledge_rate(): Int {
        return self.pledgeRate;
    }

    get fun get_operator(): Address {
        return self.operator;
    }
}