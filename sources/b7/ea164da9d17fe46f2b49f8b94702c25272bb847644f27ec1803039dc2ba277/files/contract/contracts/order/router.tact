import "./order";
import "./router_base";

contract Router with RouterBase {
    owner: Address;
    fee: Int;
    status: Bool = true;

    init(owner: Address, fee: Int, time: Int) {
        self.owner = owner;
        self.fee = fee;
    }

    // @notice Receive Jetton Transfer Notification message, validate and send deploy and jettons
    receive(notify: JettonTransferNotification) {
        let seller = notify.sender;

        if (!SmartThrow(router_not_open, self.status, seller, notify.amount)){return;}

        let forward_payload = notify.forward_payload;
        let requestCell = forward_payload.loadRef().beginParse();
        if (!SmartThrow(invalid_op, requestCell.loadUint(32) == 2659197548, seller, notify.amount)){return;}

        let order_jetton_sell_wallet = requestCell.loadAddress();
        let order_jetton_buy_wallet = requestCell.loadAddress();
        let jetton_sell_master = requestCell.loadAddress();
        requestCell = requestCell.loadRef().beginParse();
        let jetton_buy_master = requestCell.loadAddress();
        let amount_sell = requestCell.loadCoins();
        let amount_buy = requestCell.loadCoins();
        let expiration_time = requestCell.loadUint(64);

        let request = Request{
            order_jetton_sell_wallet: order_jetton_sell_wallet,
            order_jetton_buy_wallet: order_jetton_buy_wallet,
            jetton_sell_master: jetton_sell_master,
            jetton_buy_master: jetton_buy_master,
            amount_sell: amount_sell,
            amount_buy: amount_buy,

            expiration_time: expiration_time
        };
        if (!SmartThrow(invalid_expiration_time, request.expiration_time > now(), seller, notify.amount)){return;}

        let initCell = forward_payload.loadRef().beginParse();
        let init_seller = initCell.loadAddress();
        let init_nonce = initCell.loadInt(257);

        let expectedValue = deploy_fee + jetton_transfer_fee + self.fee + ton("0.01");
        if (!SmartThrow(not_enough_ton, context().value > expectedValue, seller, notify.amount)){return;}

        let orderInit = initOf Order(init_seller, init_nonce);
        let orderAddress = self.calculate_order(init_seller, init_nonce);

        send(SendParameters{
            to: orderAddress,
            value: context().value - expectedValue,
            mode: SendIgnoreErrors,
            body: request.toCell(),
            code: orderInit.code,
            data: orderInit.data
        });

        basicJettonTransfer(context().sender, orderAddress, notify.amount, ton("0.01"));
    }

    override get fun calculate_order(seller: Address, nonce: Int): Address {
        let orderInit = initOf Order(seller, nonce);
        return contractAddressExt(0, orderInit.code, orderInit.data);
    }
}
