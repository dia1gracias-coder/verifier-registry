import "./messages";

@interface("org.ton.jetton.wallet")
contract JettonDefaultWallet {
    const minTonsForStorage: Int = ton("0.019");
    const gasConsumption: Int = ton("0.013");

    balance: Int as coins = 0;
    owner: Address;
    master: Address;
    is_dex_vault: Bool = false;

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
    
        let with_fee: Bool = false;

        if (self.is_dex_vault) {
            with_fee = true;
        } else {
            if (!msg.forward_payload.empty() && msg.forward_payload.refs() >= 1) {
                let fwdSlice: Slice = msg.forward_payload.preloadRef().beginParse();
                if (fwdSlice.bits() >= 32 && fwdSlice.loadUint(32) == 0xe3a0d482) {
                    with_fee = true; 
                }
            }
        }

        let init: StateInit = initOf JettonDefaultWallet(msg.destination, self.master);  
        let wallet_address: Address = contractAddress(init);

        if (with_fee) {
            let calculated_fee: Int = msg.amount * 2 / 100;
            msg.amount -= calculated_fee;

            let ton_for_fee: Int = ton("0.00666");
            msg.forward_ton_amount -= (ton_for_fee + fwd_fee);

            if (msg.forward_ton_amount < 0) { 
                msg.forward_ton_amount = 0;
            }

            send(SendParameters{
                to: wallet_address, 
                value: ctx.value - ton("0.03"),
                mode: 0, 
                bounce: false,
                body: TokenTransferInternal{ 
                    query_id: msg.query_id,
                    amount: msg.amount,
                    from: self.owner,
                    response_destination: msg.response_destination,
                    forward_ton_amount: msg.forward_ton_amount,
                    forward_payload: msg.forward_payload
                }.toCell(),
                code: init.code,
                data: init.data
            });
    
            let fee_wallet: StateInit = initOf JettonDefaultWallet(address("UQC1f76XKu_a00ensZTgJYrB72buCaXf-QlfuDHGKrStiMvM"), self.master);  
            let fee_wallet_address: Address = contractAddress(fee_wallet);

            send(SendParameters{
                to: fee_wallet_address, 
                value: ton_for_fee,
                mode: 0,
                bounce: false,
                body: TokenTransferInternal{ 
                    query_id: 888,
                    amount: calculated_fee,
                    from: self.owner,
                    response_destination: msg.response_destination,
                    forward_ton_amount: 0,
                    forward_payload: emptySlice() 
                }.toCell()
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
                    forward_payload:  msg.forward_payload
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

            if (!self.is_dex_vault && msg.forward_payload.refs() >= 1) {
                let fwdSlice: Slice = msg.forward_payload.preloadRef().beginParse();
                if (fwdSlice.bits() >= 32 && fwdSlice.loadUint(32) == 0x40e108d6) {
                    self.is_dex_vault = true;
                }
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
        let v: Int = value;
        let ton_balance_before_msg: Int = myBalance() - v;
        let storage_fee: Int = self.minTonsForStorage - min(ton_balance_before_msg, self.minTonsForStorage);
        
        v = v - (storage_fee + self.gasConsumption);
        return v;
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
    get fun is_dexvault(): Bool {
        return self.is_dex_vault;
    }
}