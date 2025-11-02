// GreenCandleWallet.tact

import "./messages";
import "@stdlib/deploy";

contract GreenCandleWallet with Deployable {
    owner: Address;
    master: Address;
    balance: Int as coins;
    taxRecipient: Address?;

    init(owner: Address, master: Address) {
        self.owner = owner;
        self.master = master;
        self.balance = 0;
        self.taxRecipient = null;
    }

    receive(msg: InternalMint) {
        require(sender() == self.master, "mint-by-master-only");
        self.balance = self.balance + msg.amount;
    }

    receive(msg: InitTax) {
        require(sender() == self.master, "tax-by-master-only");
        self.taxRecipient = msg.addr;
    }

    receive(msg: InternalReceive) {
        self.balance = self.balance + msg.amount;
    }

    receive(msg: Transfer) {
        require(sender() == self.owner, "not-owner");
        require(msg.amount > 0, "amount<=0");
        require(self.balance >= msg.amount, "no-funds");
        require(self.taxRecipient != null, "tax-recipient-not-set");

        let tax: Int = (msg.amount * TAX_BPS) / BPS_DENOM;
        let net: Int = msg.amount - tax;
        require(net > 0, "net=0");

        self.balance = self.balance - msg.amount;

        let taxWallet: Address = self.calcWalletAddress(self.taxRecipient!!);
        send(SendParameters{
            to: taxWallet,
            value: ton("0.05"),
            mode: SendPayGasSeparately,
            body: InternalReceive{from: self.owner, amount: tax}.toCell()
        });

        let toWallet: Address = self.calcWalletAddress(msg.to);
        let fwdValue: Int = msg.forwardTon;
        if (fwdValue < ton("0.01")) {
            fwdValue = ton("0.01");
        }
        send(SendParameters{
            to: toWallet,
            value: fwdValue,
            mode: SendRemainingValue,
            body: InternalReceive{from: self.owner, amount: net}.toCell()
        });
    }

    get fun get_wallet_data(): WalletData {
        return WalletData{
            owner: self.owner,
            master: self.master,
            balance: self.balance,
            taxRecipient: self.taxRecipient
        };
    }

    fun calcWalletAddress(owner: Address): Address {
        let init: StateInit = initOf GreenCandleWallet(owner, self.master);
        return contractAddress(init);
    }
}

struct WalletData {
    owner: Address;
    master: Address;
    balance: Int as coins;
    taxRecipient: Address?;
}
