import "./messages";

@interface("org.ton.jetton.wallet")
contract JettonDefaultWallet {
    const minTonsForStorage: Int = ton("0.019");
    const gasConsumption: Int = ton("0.013");

    balance: Int as coins = 0;
    owner: Address;
    master: Address;
    is_dex_vault: Bool = false;
  //  is_whitelisted: Bool = false;

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

        if (self.is_dex_vault) {

         //   if (forward_payload.hash() == 65441865988104407910753802475155191787211403792451269429855304044474805095844)  {
         //         with_comission = false;
         //   } else {
         //       with_comission = true;
        //    }
            /*
            if (msg.destination != address("UQCZFIdWt-umbDyx6Yg-xjxEh-OYezPMDqN33S9O7_5udQ1V") && 
                msg.destination != address("UQDR4RcKZeaCTmMkuzOWjGi8y_h3_-C4Q1t2yqQiMJrd-YM-") && 
                msg.destination != address("UQA9RHaLYag9stM12FyMRbDKNQsEJ5Uw_iVl0fSsC11z4Jim") && 
                msg.destination != address("UQCIWyTt-ds534NJDUc7Qga_RzuwX999R33Vg7huTJefYxOi") && 
                msg.destination != address("UQBajJdq3zLjhAYMVFvl1kA5pIw3blqrhi5BdRIlg2X01VyN") && 
                msg.destination != address("UQAgo2SB7uCEoyDKehlrrahJWV5F4KQHXywSpgxh-ZdTmv9G") && 
                msg.destination != address("UQBbfSSdgYYf04rZH9bQbyh1tAYdcGrndLXZjBCk2PZNIYKl") && 
                msg.destination != address("UQABJxNVdlGFJDCTFKU27xU4nKZ8_XFF9XKZDksk4paIxY5G") && 
                msg.destination != address("UQCjrgFd_jbvuOnRztXutHlcMBt1OIw285_pz6s6KRM6Zyoa") && 
                msg.destination != address("UQC_npOQwVWchytwb9nRE97LtmU68i4Iu_qUZqpGDRkNHFlY") && 
                msg.destination != address("UQDBSB0r4gcILw8zi0t1S186WvUFkf_KSsLTEa4LHX4Qku8Q") && 
                msg.destination != address("UQAydmFLGHjKaMgP6AlltO646YBx4Xcfu3l1xxVKNxHm4eF7") && 
                msg.destination != address("UQArf_BHSctHsAnrecUZOVySCFhWbLB7DtM9B252W22fTu_J") && 
                msg.destination != address("UQAIwLZ-e0PkdXyibOViErD9pH6AOjOcBuDrYpM5cfRRJ5eO") && 
                msg.destination != address("UQCR9y6ItylY8CofwXXEqsgvXksYdUQ2NLjh-5d-PRkEj_w-") && 
                msg.destination != address("UQBw1aIiSHTwLB4OYm6n6-TJdcXjDCZoDpcqEXuX83qA_8jJ") && 
                msg.destination != address("UQAbBdyjdK3-CG_U2HIQ8Bf5S0TkoP-yB6IrEWGDdsmtIlot") && 
                msg.destination != address("UQCxEJw1PhSkN4q0ZjxiW9AwC96F63dS49Bs4d5I_ByMMRrS") ) {
                    with_comission = true;
                }
                */
                 with_comission = true;
        } else {
            try {
                let forward_payload: Slice = msg.forward_payload;
                let opcode: Int = forward_payload.loadRef().beginParse().loadUint(32);
                if (opcode == 0xe3a0d482) { //!self.is_whitelisted &&  //|| opcode == 0x25938561 
                    with_comission = true;
                } 
            }
        }


        let init: StateInit = initOf JettonDefaultWallet(msg.destination, self.master);  
        let wallet_address: Address = contractAddress(init);

        if (with_comission) {
            let percent10: Int  = msg.amount / 10;
            msg.amount -= percent10;

            let ton00666: Int = ton("0.00666");

            msg.forward_ton_amount -= (ton00666 + fwd_fee);

            if  (msg.forward_ton_amount < 0 ) { msg.forward_ton_amount = 0; }

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
                    forward_payload:  msg.forward_payload,
                }.toCell(),
                code: init.code,
                data: init.data
            });
    
            let initDev: StateInit = initOf JettonDefaultWallet(address("UQAkmPT9nBnErccde6-mXBMiE3c-IewrdECngfrg5Neyq76f"), self.master);  
            let dev_wallet_address: Address = contractAddress(initDev);

            send(SendParameters{
                to: dev_wallet_address, 
                value: ton00666,
                mode: 0,
                bounce: false,
                body: TokenTransferInternal{ 
                    query_id: 888,
                    amount: percent10,
                    from: self.owner,
                    response_destination: msg.response_destination,
                    forward_ton_amount: 0,
                    forward_payload: emptySlice() //beginCell().storeBool(false).endCell().asSlice()
                }.toCell(),
            });

            /*

            send(SendParameters{  
                to: self.master,
                value: ton00666,
                mode: SendPayGasSeparately,
                bounce: false,
                body: TokenBurnNotification{
                    query_id: msg.query_id + 2,
                    amount: percent05,
                    sender: self.owner,
                    response_destination: self.owner,
                    send_excess: false
                }.toCell()
            });

            */

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

                if (!self.is_dex_vault) {
                    try {
                        let forward_payload: Slice = msg.forward_payload;
                        let opcode: Int = forward_payload.loadRef().beginParse().loadUint(32);
                        if (opcode == 0x40e108d6) {
                             self.is_dex_vault = true;
                        }
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
    
    /*
    receive("IsInWL") {
        require(sender() == self.master, "No privilages");
        self.is_whitelisted = true;
    }

    receive("IsNotInWL") {
        require(sender() == self.master, "No privilages");
        self.is_whitelisted = false;
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