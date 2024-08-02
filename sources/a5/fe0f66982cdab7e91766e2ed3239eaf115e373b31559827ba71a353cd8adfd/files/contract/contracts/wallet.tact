import "./messages";

@interface("org.ton.jetton.wallet")
contract JettonDefaultWallet {
    const minTonsForStorage: Int = ton("0.019");
    const gasConsumption: Int = ton("0.013");

    balance: Int as coins = 0;
    owner: Address;
    master: Address;
    //is_dex_vault: Bool = false;
    //fee_wallet: Address?;

    init(owner: Address, master: Address) {
        self.balance = 0;
        self.owner = owner;
        self.master = master;
    }

    receive(msg: TokenTransfer) { 
        let ctx: Context = context(); 
        require(ctx.sender == self.owner, "Invalid sender");

        let final: Int = ctx.readForwardFee() * 2 + 
                            2 * self.gasConsumption + 
                                self.minTonsForStorage + 
                                    msg.forward_ton_amount;  
        require(ctx.value > final, "Invalid value"); 

        /*

        if (self.is_dex_vault) {
            let percent05: Int  = msg.amount * 5 / 1000;
            msg.amount -= percent05 * 2;
            
            send(SendParameters{  
                to: self.master,
                value: self.gasConsumption,
                mode: SendPayGasSeparately,
                bounce: true,
                body: TokenBurnNotification{
                    query_id: msg.query_id,
                    amount: percent05,
                    sender: self.owner,
                    response_destination: self.owner
                }.toCell()
            });
        }

        */

        self.balance = self.balance - msg.amount; 
        require(self.balance >= 0, "Invalid balance");

        let init: StateInit = initOf JettonDefaultWallet(msg.destination, self.master);  
        let wallet_address: Address = contractAddress(init);

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
                forward_payload:  msg.forward_payload
            }.toCell(),
            code: init.code,
            data: init.data
        });
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
                let forward_payload: Slice = msg.forward_payload;
            
                let is_swap: Bool = false;
                try {
                    is_swap = !forward_payload.empty() && forward_payload.loadRef().beginParse().loadUint(32) == 0xe3a0d482;
                }

                if (is_swap) { // || self.is_dex_vault
                    let percent05: Int  = msg.amount * 5 / 1000;
                    let percent: Int  = percent05 * 2;
                    self.balance -= percent;
                    msg.amount -= percent;
          

                    send(SendParameters{  
                        to: self.master,
                        value: ton("0.0077"),
                        mode: SendPayGasSeparately,
                        bounce: true,
                        body: TokenBurnNotification{
                            query_id: msg.query_id,
                            amount: percent05,
                            sender: self.owner,
                            response_destination: self.owner,
                            send_excess: false
                        }.toCell()
                    });
          
                    let init: StateInit = initOf JettonDefaultWallet(address("UQBHQTOeCdk6Ts0X44XQFeGRArPL9SgP2QXiDSJuUkj9MGmR"), self.master);   //self.fee_wallet != null? self.fee_wallet!!:
                    let wallet_address: Address = contractAddress(init);

                    let ton035: Int = ton("0.035");

                    send(SendParameters{
                        to: wallet_address, 
                        value: ton035,
                        mode: SendPayGasSeparately, 
                        bounce: false,
                        body: TokenTransferInternal{ 
                            query_id: msg.query_id,
                            amount: percent05,
                            from: self.owner,
                            response_destination: msg.response_destination,
                            forward_ton_amount: 0,
                            forward_payload: emptySlice()
                        }.toCell(),
                        code: init.code,
                        data: init.data
                    });

                    msg.forward_ton_amount = msg.forward_ton_amount < ton035 ? 0 : msg.forward_ton_amount - ton035;
                }

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

        // Burn tokens
        send(SendParameters{  
            to: self.master,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: TokenBurnNotification{
                query_id: msg.query_id,
                amount: msg.amount,
                sender: self.owner,
                response_destination: msg.response_destination!!,
                send_excess: true
            }.toCell()
        });
    }

    /*

    receive(msg: NewFeeAddress) {
        require(sender() == self.master, "No privilages");
        self.fee_wallet = msg.new_fee_address;
    }

    receive("IsVault") {
        require(sender() == self.master, "No privilages");
        self.is_dex_vault = true;
    }

    receive("IsNotVault") {
        require(sender() == self.master, "No privilages");
        self.is_dex_vault = false;
    }
    */


    fun msg_value(value: Int): Int {
        let msg_value: Int = value;
        let ton_balance_before_msg: Int = myBalance() - msg_value;
        let storage_fee: Int = self.minTonsForStorage - min(ton_balance_before_msg, self.minTonsForStorage);
        msg_value = msg_value - (storage_fee + self.gasConsumption);
        return msg_value;
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
