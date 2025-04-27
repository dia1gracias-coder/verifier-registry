import "@stdlib/deploy";

message(0xba69751) Withdraw {
    amount: Int as coins;
    to: Address;
}

message(0x7bdd97de) WithdrawCallback {
    amount: Int as coins;
    to: Address;
    success: Bool;
}

contract WithdrawTon with Deployable {

    const MinTonForStorage: Int = ton("0.01"); 
    const CallbackValue: Int = ton("0.000001");
    deployer: Address;

    init() {
        self.deployer = sender();
    }

    receive() {
        dump("Received funds");
    }

    receive(msg: Withdraw) {
        require(sender() == self.deployer, "Only deployer is allowed to withdraw");

        let availableBalance = myBalance() - context().value - self.MinTonForStorage;
        require(availableBalance > 0, "Insufficient balance");

        let amountToSend: Int = min(msg.amount, availableBalance);
        require(amountToSend > 0, "Withdraw amount must be positive");

        send(SendParameters{
            to: msg.to,
            bounce: true,
            value: amountToSend,
            mode: 0,
        });

        self.send_withdraw_callback(msg.amount, msg.to, true);
    }

    fun send_withdraw_callback(requestedAmount: Int, to: Address, success: Bool) {
        let balance = myBalance();

        if (balance > self.CallbackValue + self.MinTonForStorage) {
            send(SendParameters{
                to: self.deployer,
                value: self.CallbackValue,
                mode: 0,
                body: WithdrawCallback{
                    amount: requestedAmount,
                    to: to,
                    success: success,
                }.toCell()
            });
        } else {
            dump("Not enough balance to send WithdrawCallback");
        }
    }

    get fun balance(): String {
        return myBalance().toCoinsString();
    }
}