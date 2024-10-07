import "./order_base";

message(3907800561) Request {
    order_jetton_buy_wallet: Address;
    jetton_buy_master: Address;
    amount_sell: Int as coins;
    amount_buy: Int as coins;

    expiration_time: Int as uint64 = 0;
}

contract OrderSellTon with OrderBase {
    seller: Address;
    router: Address;
    type: Int as uint8 = 2;

    request: Request = Request {
        order_jetton_buy_wallet: newAddress(0,0),
        jetton_buy_master: newAddress(0,0),
        amount_sell: 0,
        amount_buy: 0,

        expiration_time: 0,
    };

    open: Bool = false;

    init(seller: Address, nonce: Int) {
        self.router = context().sender;
        self.seller = seller;
    }

    // @notice Receive request message, validate and set request data
    // @param request - request message with necessary params
    receive(request: Request) {
        let ctx = context();
        nativeThrowUnless(access_denided, ctx.sender == self.router);
        nativeThrowUnless(order_already_opened, !self.open);
        nativeThrowUnless(not_enough_ton, ctx.value >= request.amount_sell);

        self.request = request;

        self.open = true;
    }

    // @notice Receive Jetton Transfer Notification from anyone, validate and send ton and jetton to seller and buyer
    receive(notify: JettonTransferNotification) {
        if (!SmartThrow(not_enough_ton, myBalance() > jetton_transfer_fee + ton("0.01"), notify.sender, notify.amount)) {return;}
        if (!SmartThrow(order_not_opened, self.open, notify.sender, notify.amount)) {return;}
        if (!SmartThrow(invalid_address, context().sender == self.request.order_jetton_buy_wallet, notify.sender, notify.amount)) {return;}
        if (!SmartThrow(invalid_expiration_time, self.request.expiration_time > now(), notify.sender, notify.amount)) {return;}
        if (!SmartThrow(invalid_jetton_amount, notify.amount == self.request.amount_buy, notify.sender, notify.amount)) {return;}
        let buyer: Address = notify.sender;

        basicJettonTransfer(self.request.order_jetton_buy_wallet, self.seller, self.request.amount_buy, 0);

        send(SendParameters{
            to: buyer,
            value: self.request.amount_sell,
            bounce: true,
            mode: SendIgnoreErrors + SendPayGasSeparately,
        });

        self.withdraw()
    }

    // @notice Receive cancel message, validate and send jettons and withdraw to seller
    receive(cancel: Cancel) {
        nativeThrowUnless(order_closed, self.open);
        nativeThrowUnless(access_denided, context().sender == self.seller);
        nativeThrowUnless(not_enough_ton, myBalance() >= jetton_transfer_fee);

        self.withdraw()
    }
}
