import "./order_base";

message(4288332758) Request {
    order_jetton_sell_wallet: Address;
    jetton_sell_master: Address;
    amount_sell: Int as coins;
    amount_buy: Int as coins;

    expiration_time: Int as uint64 = 0;
}

contract OrderBuyTon with OrderBase {
    seller: Address;
    router: Address;
    type: Int as uint8 = 1;

    request: Request = Request {
        order_jetton_sell_wallet: newAddress(0,0),
        jetton_sell_master: newAddress(0,0),
        amount_sell: 0,
        amount_buy: 0,

        expiration_time: 0,
    };

    open: Bool = false;
    filled: Bool = false;

    init(seller: Address, nonce: Int) {
        self.router = context().sender;
        self.seller = seller;
    }

    // @notice Receive request message, validate and set request data
    // @param request - request message with necessary params
    receive(request: Request) {
        nativeThrowUnless(access_denided, context().sender == self.router);
        nativeThrowUnless(order_already_filled, !self.filled);

        self.request = request;

        self.filled = true;
    }

    // @notice Receive Jetton Transfer Notification from seller, validate and set order open
    receive(notify: JettonTransferNotification) {
        if (!SmartThrow(order_not_filled, self.filled, notify.sender, notify.amount)) {return;}
        if (!SmartThrow(access_denided, notify.sender == self.router, notify.sender, notify.amount)) {return;}
        if (!SmartThrow(order_already_opened, !self.open, self.seller, notify.amount)) {return;}
        if (!SmartThrow(invalid_address, context().sender == self.request.order_jetton_sell_wallet, self.seller, notify.amount)) {return;}
        if (!SmartThrow(invalid_expiration_time, self.request.expiration_time > now(), self.seller, notify.amount)) {return;}
        if (!SmartThrow(invalid_jetton_amount, notify.amount == self.request.amount_sell, self.seller, notify.amount)) {return;}

        self.open = true;
    }

    // @notice Receive toncoin from anyone, validate and send ton and jetton to seller and buyer
    receive("transfer ton") {
        let ctx = context();

        if (!self.open || myBalance() < self.request.amount_buy + jetton_transfer_fee + ton("0.01")) {
            send(SendParameters{
                to: context().sender,
                value: ctx.value - ctx.readForwardFee() - ton("0.01"),
                bounce: true,
                mode: SendIgnoreErrors,
            });
            return;
        }

        let buyer: Address = ctx.sender;
        send(SendParameters{
            to: self.seller,
            value: self.request.amount_buy,
            bounce: true,
            mode: SendIgnoreErrors + SendPayGasSeparately,
        });

        basicJettonTransfer(self.request.order_jetton_sell_wallet, buyer, self.request.amount_sell, 0);

        self.withdraw()
    }

    // @notice Receive cancel message, validate and send jettons and withdraw to seller
    receive(cancel: Cancel) {
        nativeThrowUnless(order_closed, self.open);
        nativeThrowUnless(access_denided, context().sender == self.seller);
        nativeThrowUnless(not_enough_ton, myBalance() >= jetton_transfer_fee);

        basicJettonTransfer(self.request.order_jetton_sell_wallet, self.seller, self.request.amount_sell, 0);

        self.withdraw()
    }
}
