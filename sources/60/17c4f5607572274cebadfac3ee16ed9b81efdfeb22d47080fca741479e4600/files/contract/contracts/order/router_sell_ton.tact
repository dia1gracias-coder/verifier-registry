import "./order_sell_ton";
import "./router_base";

message(3810013679) TonTransferNotification {
    request: Request;
    seller: Address;
    nonce: Int
}

contract RouterSellTon with RouterBase {
    owner: Address;
    fee: Int;
    status: Bool = true;

    init(owner: Address, fee: Int, time: Int) {
        self.owner = owner;
        self.fee = fee;
    }

    // @notice Receive Ton Transfer Notification message, validate and send deploy (with seller toncoins)
    receive (notify: TonTransferNotification) {
        let seller = context().sender;

        if (notify.request.expiration_time < now() || !self.status) {
            send(SendParameters{
                to: context().sender,
                value: context().value - context().readForwardFee() - ton("0.01"),
                bounce: true,
                mode: SendIgnoreErrors,
            });
            return;
        }

        let orderInit = initOf OrderSellTon(notify.seller, notify.nonce);
        let orderAddress = contractAddressExt(0, orderInit.code, orderInit.data);

        send(SendParameters{
            to: orderAddress,
            value: context().value - self.fee - ton("0.01"),
            mode: SendIgnoreErrors,
            body: notify.request.toCell(),
            code: orderInit.code,
            data: orderInit.data
        });
    }

    override get fun calculate_order(seller: Address, nonce: Int): Address {
        let orderInit = initOf OrderSellTon(seller, nonce);
        return contractAddressExt(0, orderInit.code, orderInit.data);
    }
}
