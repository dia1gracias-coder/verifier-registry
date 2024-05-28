import "./HeroTokenMessages.tact";

struct JettonWalletData {
    balance: Int;
    owner: Address;
    master: Address;
    walletCode: Cell;
}

@interface("org.ton.jetton.wallet")
contract HeroTokenWallet {
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

    receive(msg: Transfer) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Token transfer: Invalid sender");

        let fwdFee: Int = ctx.readForwardFee() + ctx.readForwardFee();  
        let finalValue: Int =  2 * self.gasConsumption + self.minTonsForStorage + fwdFee;
        require(ctx.value > min(finalValue, ton("0.01")), "Token transfer: Insufficient value"); 

        self.balance = self.balance - msg.amount; 
        require(self.balance >= 0, "Token transfer: Insufficient balance");

        let stateInit: StateInit = initOf HeroTokenWallet(self.master, msg.destination);  
        let walletAddress: Address = contractAddress(stateInit);

        send(SendParameters{
            to: walletAddress, 
            value: 0,
            mode: SendRemainingValue, 
            bounce: false,
            body: InternalTransfer{
                query_id: msg.query_id,
                amount: msg.amount,
                from: self.owner,
                response_destination: msg.response_destination,
                forward_ton_amount: msg.forward_ton_amount,
                forward_payload: msg.forward_payload
            }.toCell(),
            code: stateInit.code,
            data: stateInit.data
        });
    }

    receive(msg: InternalTransfer) {
        let ctx: Context = context();

        if (ctx.sender != self.master) {
            let stateInit: StateInit = initOf HeroTokenWallet(self.master, msg.from);
            require(contractAddress(stateInit) == ctx.sender, "Token transfer internal: Invalid sender");
        }

        self.balance = self.balance + msg.amount;
        require(self.balance >= 0, "Token transfer internal: Insufficient balance"); 
        
        let msgValue: Int = self.calculateMessageValue(ctx.value);  
        let fwdFee: Int = ctx.readForwardFee();
        msgValue = msgValue - msg.forward_ton_amount - fwdFee;
        
        if (msg.forward_ton_amount > 0) { 
            send(SendParameters{
                to: self.owner,
                value: msg.forward_ton_amount,
                mode: SendPayGasSeparately + SendIgnoreErrors,
                bounce: false,
                body: TransferNotification {
                    query_id: msg.query_id,
                    amount: msg.amount,
                    from: msg.from,
                    forward_payload: msg.forward_payload
                }.toCell()
            });
        }

        if (msg.response_destination != null) { 
            send(SendParameters {
                to: msg.response_destination, 
                value: msgValue,  
                mode: SendIgnoreErrors,
                bounce: false,
                body: Excesses { 
                    query_id: msg.query_id
                }.toCell()
            });
        }
    }

    receive(msg: Burn) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Token burn: Invalid sender");

        let fwdFee: Int = ctx.readForwardFee();
        require(ctx.value > fwdFee + 2 * self.gasConsumption + self.minTonsForStorage, "Token burn: Insufficient value");

        self.balance = self.balance - msg.amount;
        require(self.balance >= 0, "Token burn: Invalid balance");

        send(SendParameters{  
            to: self.master,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: BurnNotification{
                query_id: msg.query_id,
                amount: msg.amount,
                owner: self.owner,
                response_destination: self.owner
            }.toCell()
        });
    }

    get fun calculateMessageValue(value: Int): Int {
        let msgValue: Int = value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage);

        msgValue = msgValue - (storageFee + self.gasConsumption);
        return msgValue;
    }

    bounced(src: bounced<InternalTransfer>) {
        self.balance = self.balance + src.amount;
    }

    bounced(src: bounced<BurnNotification>) {
        self.balance = self.balance + src.amount;
    }

    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData{
            balance: self.balance,
            owner: self.owner,
            master: self.master,
            walletCode: (initOf HeroTokenWallet(self.master, self.owner)).code
        };
    }
}
