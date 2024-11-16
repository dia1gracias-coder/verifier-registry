import "@stdlib/ownable";
import "./messages";

@interface("org.ton.jetton.wallet")
contract JettonDefaultWallet {

    const minTonsForStorage: Int = ton("0.01");
    const gasConsumption: Int = ton("0.01");

    balance: Int;
    owner: Address;
    master: Address;

    init(master: Address, owner: Address) {
        self.balance = 0;
        self.owner = owner;
        self.master = master;
    }

    // 0xf8a7ea5
    receive(msg: TokenTransfer) {

        // Check sender
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");

        // Gas checks
        let fwdFee: Int = ctx.readForwardFee() * 2;  
        let final: Int =  2 * (self.gasConsumption + self.minTonsForStorage + fwdFee);
        require(ctx.value > min(final, ton("0.01")), "Invalid value!!"); 

        // Update balance
        self.balance = self.balance - msg.amount; 
        require(self.balance >= 0, "Invalid balance");

        // Send tokens
        let init: StateInit = initOf JettonDefaultWallet(self.master, msg.destination);
        let walletAddress: Address = contractAddress(init);
        send(SendParameters{
            to: walletAddress, 
            value: 0,
            mode: 0 | SendRemainingValue, 
            bounce: false,
            body: TokenTransferInternal{
                queryId: msg.queryId,
                amount: msg.amount,
                from: self.owner,
                responseAddress: msg.responseDestination,
                forwardTonAmount: msg.forwardTonAmount,
                forwardPayload: msg.forwardPayload
            }.toCell(),
            code: init.code,
            data: init.data
        });
    }

    receive(msg: TokenTransferInternal) {

        // Check sender
        let ctx: Context = context();

        if (ctx.sender != self.master) {
            let sinit: StateInit = initOf JettonDefaultWallet(self.master, msg.from);
            require(contractAddress(sinit) == ctx.sender, "Invalid sender");
        }

        // Update balance
        self.balance = self.balance + msg.amount;
        require(self.balance >= 0, "Invalid balance");

        // Adjust value for gas
        let msgValue: Int = self.get_msg_Value(ctx.value);   

        let fwdFee: Int = ctx.readForwardFee();  
        msgValue = msgValue - msg.forwardTonAmount - fwdFee;

         // 0x7362d09c - notify the new owner of JettonToken that the transfer is complete
        if (msg.forwardTonAmount > 0) {

            send(SendParameters{
                to: self.owner,
                value: msg.forwardTonAmount,
                mode: SendPayGasSeparately | SendIgnoreErrors,
                bounce: false,
                body: TokenNotification{
                    queryId: msg.queryId,
                    amount: msg.amount,
                    from: msg.from,
                    forwardPayload: msg.forwardPayload
                }.toCell()
            });
        }


        // 0xd53276db -- Cashback to the original Sender
        if (msg.responseAddress != null && msgValue > 0) {

            send(SendParameters{
                to: msg.responseAddress!!,
                value: msgValue,
                bounce: false,
                body: TokenExcesses{
                    queryId: msg.queryId
                }.toCell(),
                mode: SendIgnoreErrors
            });
        }
    }

    receive(msg: TokenBurn) {

        // Check sender
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");

        // Update balance
        self.balance = self.balance - msg.amount;
        require(self.balance >= 0, "Invalid balance");

        // Gas checks
        let fwdFee: Int = ctx.readForwardFee();
        require(ctx.value > fwdFee + 2 * self.gasConsumption + self.minTonsForStorage, "Invalid value");

        // Burn tokens
        send(SendParameters{
            to: self.master,
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
            bounce: true,
            body: TokenBurnNotification{
                queryId: msg.queryId,
                amount: msg.amount,
                owner: self.owner,
                responseAddress: self.owner
            }.toCell()
        });
    }

    bounced(msg: Slice) {

        // Parse bounced message
        msg.skipBits(32); // 0xFFFFFFFF
        let op: Int = msg.loadUint(32);
        let queryId: Int = msg.loadUint(64);
        let jettonAmount: Int = msg.loadCoins();
        require(op == 0x178d4519 || op == 0x7bdd97de, "Invalid bounced message");

        // Update balance
        self.balance = self.balance + jettonAmount;
    }

    fun get_msg_Value(value: Int): Int {
        let msgValue: Int = value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage);
        msgValue = msgValue - (storageFee + self.gasConsumption);
        return msgValue;
    }

    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData{
            balance: self.balance,
            owner: self.owner,
            master: self.master,
            walletCode: (initOf JettonDefaultWallet(self.master, self.owner)).code
        };
    }

    get fun balance(): Int {
        return myBalance();
    }
}