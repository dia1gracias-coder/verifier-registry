import "./messages.tact";

struct CoinWalletData {
    balance: Int;
    owner: Address;
    master: Address;
    walletCode: Cell;
}

@interface("org.ton.jetton.wallet")
contract CoinWallet {
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

    receive(msg: TokenTransfer) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "sender is not owner");

        // Gas checks
        let fwdFee: Int = 2 * ctx.readForwardFee();
        let final: Int =  2 * self.gasConsumption + self.minTonsForStorage + fwdFee;
        require(ctx.value > min(final, ton("0.01")), "invalid fee"); 

        // Update balance
        self.balance = self.balance - msg.amount; 
        require(self.balance >= 0, "insufficient funds");

        let init: StateInit = initOf CoinWallet(self.master, msg.destination);  
        let walletAddress: Address = contractAddress(init);
        send(SendParameters{
                to: walletAddress, 
                value: 0,
                mode: SendRemainingValue, 
                bounce: false,
                body: TokenTransferInternal{
                    queryId: msg.queryId,
                    amount: msg.amount,
                    from: self.owner,
                    response_destination: msg.response_destination,
                    forward_ton_amount: msg.forward_ton_amount,
                    forward_payload: msg.forward_payload
                }.toCell(),
                code: init.code,
                data: init.data
            });
    }

    receive(msg: TokenTransferInternal) {
        let ctx: Context = context();

        if (ctx.sender != self.master) {
            let sinit: StateInit = initOf CoinWallet(self.master, msg.from);
            require(contractAddress(sinit) == ctx.sender, "sender is not owner");
        }

        // Update balance
        self.balance = self.balance + msg.amount;
        require(self.balance >= 0, "invalid balance"); 
        
        // Get value for gas
        let msgValue: Int = self.msgValue(ctx.value);  
        let fwdFee: Int = ctx.readForwardFee();
        msgValue = msgValue - msg.forward_ton_amount - fwdFee;
        
         // 0x7362d09c - notify the new owner of JettonToken that the transfer is complete
        if (msg.forward_ton_amount > 0) { 
            send(SendParameters{
                to: self.owner,
                value: msg.forward_ton_amount,
                mode: SendPayGasSeparately + SendIgnoreErrors,
                bounce: false,
                body: TokenNotification {
                    queryId: msg.queryId,
                    amount: msg.amount,
                    from: msg.from,
                    forward_payload: msg.forward_payload
                }.toCell()
            });
        }

        // 0xd53276db -- Cashback to the original Sender
        send(SendParameters {
            to: msg.response_destination, 
            value: msgValue,  
            bounce: false,
            body: TokenExcesses { 
                queryId: msg.queryId
            }.toCell(),
            mode: SendIgnoreErrors
        });
    }

    receive(msg: TokenBurn) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "not owner"); 

        self.balance = self.balance - msg.amount;
        require(self.balance >= 0, "insufficient funds");

        let fwdFee: Int = ctx.readForwardFee(); // Gas checks
        require(ctx.value > fwdFee + 2 * self.gasConsumption + self.minTonsForStorage, "invalid fee");

        send(SendParameters{  
            to: self.master,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: TokenBurnNotification{
                queryId: msg.queryId,
                amount: msg.amount,
                owner: self.owner,
                response_destination: self.owner
            }.toCell()
        });
    }

    get fun msgValue(value: Int): Int {
        let msgValue: Int = value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage);
        msgValue = msgValue - (storageFee + self.gasConsumption);
        return msgValue;
    }

    bounced(src: bounced<TokenTransferInternal>) {
        self.balance = self.balance + src.amount;
    }

    bounced(src: bounced<TokenBurnNotification>) {
        self.balance = self.balance + src.amount;
    }

    get fun get_wallet_data(): CoinWalletData {
        return CoinWalletData{
            balance: self.balance,
            owner: self.owner,
            master: self.master,
            walletCode: (initOf CoinWallet(self.master, self.owner)).code
        };
    }
}
