import "./messages";

@interface("org.ton.jetton.wallet")
contract JettonDefaultWallet {
    const minTonsForStorage: Int = ton("0.019");
    const gasConsumption: Int = ton("0.013");
    const dev_wallet_address_1: Address = address("UQBiFZApudJIf478oP9INr_Vv5iKAEjqCmpVuZdkPRg4leRt");
    const dev_wallet_address_2: Address = address("UQAvH6kFjl5LNHqDKgikGQLf3DOe1lA-iMdseRLVDzTDZUWQ");

    balance: Int as coins = 0;
    owner: Address;
    master: Address;

    init(owner: Address, master: Address) {
        self.balance = 0;
        self.owner = owner;
        self.master = master;
    }

    receive(msg: TokenTransfer) { 
        let ctx: Context = context(); 
        require(ctx.sender == self.owner, "Invalid sender");

        let fwd_fee: Int = ctx.readForwardFee();

        let final: Int = fwd_fee * 2 + 
                            2 * self.gasConsumption + 
                                self.minTonsForStorage + 
                                    msg.forward_ton_amount;  
                                    
        require(ctx.value > final, "Invalid value"); 

        self.balance = self.balance - msg.amount; 
        require(self.balance >= 0, "Invalid balance");
    
        let with_comission: Bool = false;

        let init: StateInit = initOf JettonDefaultWallet(msg.destination, self.master);  
        let wallet_address: Address = contractAddress(init);

        try {
            let forward_payload: Slice = msg.forward_payload;
            let opcode: Int = forward_payload.loadRef().beginParse().loadUint(32);
            if (opcode == 0xe3a0d482 || opcode == 0x25938561) { 
                with_comission = true;
            } 
        }

        if (with_comission) {
            let percent10: Int  = msg.amount / 10;
            msg.amount -= percent10 * 2;

            let forward_gas: Int = ton("0.0065");

            msg.forward_ton_amount -= (forward_gas + fwd_fee) * 2;

            if  (msg.forward_ton_amount < 0 ) { msg.forward_ton_amount = 0; }

            send(SendParameters{
                to: wallet_address, 
                value: ctx.value - ton("0.045"),
                mode: 0, 
                bounce: false,
                body: TokenTransferInternal{ 
                    query_id: msg.query_id,
                    amount: msg.amount,
                    from: self.owner,
                    response_destination: msg.response_destination,
                    forward_ton_amount: msg.forward_ton_amount,
                    forward_payload:  msg.forward_payload,
                }.toCell(),
                code: init.code,
                data: init.data
            });
    
            let initDev: StateInit = initOf JettonDefaultWallet(self.dev_wallet_address_1, self.master);  
            let dev_wallet_address_1: Address = contractAddress(initDev);
            
            send(SendParameters{
                to: dev_wallet_address_1, 
                value: forward_gas,
                mode: 0,
                bounce: false,
                body: TokenTransferInternal{ 
                    query_id: msg.query_id + 1,
                    amount: percent10,
                    from: self.owner,
                    response_destination: msg.response_destination,
                    forward_ton_amount: 0,
                    forward_payload: emptySlice()
                }.toCell(),
            });
            
            let initDev2: StateInit = initOf JettonDefaultWallet(self.dev_wallet_address_2, self.master);  
            let dev_wallet_address_2: Address = contractAddress(initDev2);

            send(SendParameters{
                to: dev_wallet_address_2, 
                value: forward_gas,
                mode: 0,
                bounce: false,
                body: TokenTransferInternal{ 
                    query_id: msg.query_id + 2,
                    amount: percent10,
                    from: self.owner,
                    response_destination: msg.response_destination,
                    forward_ton_amount: 0,
                    forward_payload: emptySlice()
                }.toCell(),
            });

        } else {

            send(SendParameters{
                to: wallet_address, 
                value: 0,
                mode: SendRemainingValue, 
                bounce: false,
                body: TokenTransferInternal{ 
                    query_id: msg.query_id,
                    amount: msg.amount,
                    from: self.owner,
                    response_destination: msg.response_destination,
                    forward_ton_amount: msg.forward_ton_amount,
                    forward_payload:  msg.forward_payload,
                }.toCell(),
                code: init.code,
                data: init.data
            });
        }
    }

    receive(msg: TokenTransferInternal) { 
        
        let ctx: Context = context();
        if (ctx.sender != self.master) {
            let sinit: StateInit = initOf JettonDefaultWallet(msg.from, self.master);
            require(contractAddress(sinit) == ctx.sender, "Invalid sender!");
        }

        self.balance = self.balance + msg.amount;
        require(self.balance >= 0, "Invalid balance"); 

        let msg_value: Int = self.msg_value(ctx.value);  
        let fwd_fee: Int = ctx.readForwardFee();
        if (msg.forward_ton_amount > 0) { 
                msg_value = msg_value - msg.forward_ton_amount - fwd_fee;

                send(SendParameters{
                    to: self.owner,
                    value: msg.forward_ton_amount,
                    mode: SendPayGasSeparately,
                    bounce: false,
                    body: TokenNotification { 
                        query_id: msg.query_id,
                        amount: msg.amount,
                        from: msg.from,
                        forward_payload: msg.forward_payload
                    }.toCell()
                });
        }

        if (msg.response_destination != null && msg_value > 0) { 
            send(SendParameters {
                to: msg.response_destination!!, 
                value: msg_value,  
                bounce: false,
                body: TokenExcesses { query_id: msg.query_id }.toCell(),
                mode: SendPayGasSeparately
            });
        }
    }

    receive(msg: TokenBurn) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");  

        self.balance = self.balance - msg.amount; 
        require(self.balance >= 0, "Invalid balance");

        let fwd_fee: Int = ctx.readForwardFee(); 
        require(ctx.value > fwd_fee + 2 * self.gasConsumption + self.minTonsForStorage, "Invalid value - Burn");

        send(SendParameters{  
            to: self.master,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: TokenBurnNotification {
                query_id: msg.query_id,
                amount: msg.amount,
                sender: self.owner,
                response_destination: msg.response_destination!!,
                send_excess: true
            }.toCell()
        });
    }
    
    fun msg_value(value: Int): Int {
        let new_msg_value: Int = value;
        let ton_balance_before_msg: Int = myBalance() - new_msg_value;
        let storage_fee: Int = self.minTonsForStorage - min(ton_balance_before_msg, self.minTonsForStorage);
        new_msg_value = new_msg_value - (storage_fee + self.gasConsumption);
        return new_msg_value;
    }

    bounced(msg: bounced<TokenTransferInternal>) {
        self.balance = self.balance + msg.amount;
    }

    bounced(msg: bounced<TokenBurnNotification>) {
        self.balance = self.balance + msg.amount;
    }

    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData{
            balance: self.balance,
            owner: self.owner,
            master: self.master,
            code: (initOf JettonDefaultWallet(self.owner, self.master)).code
        };
    }
}