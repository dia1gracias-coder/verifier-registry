import "@stdlib/deploy";
import "./messages";

const gasForTransfer: Int = 10500;
const minContractBalance: Int = ton("0.1");

contract TradeHubContract with Deployable {
    address: Address;
    server: Address;
    jetton_wallet: Address; 
    usdt_master: Address;

    init(server: Address) {
        self.server = server;
        self.address = myAddress();
        //EQCxE6mUtQJKFnGfaROTKOt1lZbDiiX1kCixRv7Nw2Id_sDs
        self.usdt_master = address("EQCxE6mUtQJKFnGfaROTKOt1lZbDiiX1kCixRv7Nw2Id_sDs");
        self.jetton_wallet = self.server;
        self.init_jwallet();
    }

    receive() {}

    fun init_jwallet() {
        let ctx = context();
        require(ctx.value >= ton("0.1"), "Insufficient balance");

        send(SendParameters{
            to: self.usdt_master,
            value: ton("0.1"),
            mode: SendIgnoreErrors,
            body: JettonWalletRequest{
                contract_address: self.address,
            }.toCell()
        });
    }

    receive(msg: JettonWalletResponse) {
        self.jetton_wallet = msg.wallet_address;  
        self.send_server_notification("jetton_wallet_initialized");
    }

    fun send_server_notification(event: String) {
        let ctx = context();
        require(
            ctx.value >
            ctx.readForwardFee() +
            (2 * getComputeFee(gasForTransfer, false) + minContractBalance),
            "Insufficient amount of TON attached",
        );

        send(SendParameters{
            to: self.server,
            value: ton("0.01"),
            mode: SendIgnoreErrors,
            body: EventNotification{
                event: event,
            }.toCell()
        });
    }

    receive(msg: JettonTransfer) {
        require(self.jetton_wallet != self.server, "Jetton wallet not initialized");
        require(msg.forward_payload.bits() >= 64, "Comments not contains user id.");

        let ctx = context();
        let fwdCount = 1 + sign(msg.forward_ton_amount);
        require(
            ctx.value >
            msg.forward_ton_amount +
            fwdCount * ctx.readForwardFee() +
            (2 * getComputeFee(gasForTransfer, false) + minContractBalance),
            "Insufficient amount of TON attached",
        );

        let user_id: Int = msg.forward_payload.loadUint(64);
        self.send_deposit_callback(user_id, msg.amount, true);
    }

    fun send_deposit_callback(user_id: Int, amount: Int, success: Bool) {
         let ctx = context();
        require(
            ctx.value >
            ctx.readForwardFee() +
            (2 * getComputeFee(gasForTransfer, false) + minContractBalance),
            "Insufficient amount of TON attached",
        );

        send(SendParameters {
            to: self.server,
            value: ton("0.01"),
            mode: SendIgnoreErrors,
            body: DepositCallback{
                user_id: user_id,
                amount: amount,
                success: success,
            }.toCell()
        }); 
    }

    receive(msg: InternalWithdraw) {
        let ctx: Context = context();
        require(ctx.sender == self.server, "Access denied, only server can withdraw");
        require(self.jetton_wallet != self.server, "Jetton wallet not initialized");
        require(msg.amount > 0, "Amount must be positive");
        require(
            ctx.value >
            ctx.readForwardFee() +
            (2 * getComputeFee(gasForTransfer, false) + minContractBalance),
            "Insufficient amount of TON attached",
        );

        send(SendParameters{
            to: self.jetton_wallet,
            value: ton("0.01"),
            mode: SendIgnoreErrors,
            body: WithdrawRequest {
                query_id: 0,
                amount: msg.amount,
                destination: msg.to,
                response_destination: self.address,
                custom_payload: emptyCell(),
                forward_ton_amount: ton("0.01"),
                forward_payload: (beginCell().endCell()).asSlice(),
            }.toCell()
        });
        
        self.send_withdraw_callback(msg.amount, msg.to, true);
    }

    fun send_withdraw_callback(amount: Int, to: Address, success: Bool) {
        let ctx = context();
        require(
            ctx.value >
            ctx.readForwardFee() +
            (2 * getComputeFee(gasForTransfer, false) + minContractBalance),
            "Insufficient amount of TON attached",
        );

        send(SendParameters{
            to: self.server,
            value: ton("0.01"),
            mode: SendIgnoreErrors,
            body: WithdrawCallback{
                amount: amount,
                to: to,
                success: success,
            }.toCell()
        });
    }
}