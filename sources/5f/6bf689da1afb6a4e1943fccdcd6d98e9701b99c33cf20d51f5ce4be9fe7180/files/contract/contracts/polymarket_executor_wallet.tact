import "@stdlib/ownable";

import "./traits/jetton/IJetton.tact";
import "./traits/polymarket/IPolymarket.tact";

//// Deployments
message(0xed53c0fc) ExecutorWalletDeployed {}
message(0xa47e29b4) InitializeExecutorWallet {}

message(0x72ed59dc) ConfirmSellOrder {
    user: Address;
    usd_amount: Int as coins;
    fee: Int as uint16;
}

message(0x56e31497) WithdrawUSDT {
    amount: Int as uint64;
}

contract PolymarketExecutorWallet with Ownable {
    master: Address; // NOTE: to verify the validity of the contract.
    get fun master(): Address {
        return self.master;
    }
    owner: Address;
    usdt_wallet: Address;
    get fun usdt_wallet(): Address {
        return self.usdt_wallet;
    }
    init(master: Address, owner: Address, usdt_master: Address, usdt_wallet_code: Cell) {
        self.master = master;
        self.owner = owner;
        self.usdt_wallet = calculate_jetton_wallet_address(myAddress(), usdt_master, usdt_wallet_code)
    }

    receive(msg: InitializeExecutorWallet) {
        // Return excess amount, then notify deployment status (in case user is some smart contract)
        self.forward(self.owner, ExecutorWalletDeployed{}.toCell(), false, null);
    }

    receive(msg: WithdrawTON) {
        self.requireOwner();
        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance,
        })
    }

    receive(msg: JettonExcesses) {
        // NOTE: receive TON and do nothing, be explicit instead of `receive()`
    }

    const TRANSFER_USDT_COST: Int = ton("0.009");
    inline fun send_usdt(amount: Int, to: Address, response: Address, mode: Int) {
        let transfer_usdt_msg = beginCell()
            .storeUint(OP_JettonTransfer, 32) // opcode
            .storeUint(0, 64) // queryId
            .storeCoins(amount) // usd amount
            .storeAddress(to) // to address
            .storeAddress(response) // response address
            .storeUint(0, 1) // custom payload
            .storeCoins(0) // forward_amount
            .storeUint(0, 1) // forward_payload
            .endCell();

        send(SendParameters{
            to: self.usdt_wallet,
            value: self.TRANSFER_USDT_COST,
            mode: mode,
            body: transfer_usdt_msg
        });
    }

    // NOTE: Executor will manage this balance.
    receive(msg: WithdrawUSDT) {
        self.requireOwner();
        self.send_usdt(msg.amount, self.owner, self.owner, SendRemainingValue | SendBounceIfActionFail);
    }

    inline fun only_master() {
        nativeThrowUnless(132, sender() == self.master);
    }

    // NOTE: Flow 2.2 - Return money to user after SELL is confirmed on kernel.
    //  0.1 Executor must fund this wallet with enough
    //  0.2 Executor call gateway which call this handler
    //  1. This return settlement USDT amount to user.
    //  2. This perform callback to polymarket master
    //  3. Polymarket master log event and take fees
    receive(msg: ConfirmSellOrder) {
        // 1. Access control
        self.only_master();

        // 2. Send amount after fee to user
        let amount_after_fee = msg.usd_amount - msg.usd_amount / 10_000 * msg.fee;
        self.send_usdt(amount_after_fee, msg.user, msg.user, SendBounceIfActionFail);
    }
}

