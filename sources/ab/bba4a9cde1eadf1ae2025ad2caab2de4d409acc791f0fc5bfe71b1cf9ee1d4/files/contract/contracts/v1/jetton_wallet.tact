import "@stdlib/deploy";
import "./messages/jetton_messages.tact";

contract JettonWallet with Deployable {
    // @minTonsForStorage Minimum TONs required for storage costs
    const minTonsForStorage: Int = ton("0.019");
    // @gasConsumption TONs required for gas consumption
    const gasConsumption: Int = ton("0.013");

    balance: Int as coins = 0;
    owner: Address;
    master: Address;

    // @owner The address of the wallet owner
    // @master The address of the master (Jetton contract)
    init(owner: Address, master: Address) {
        self.balance = 0;
        self.owner = owner;
        self.master = master;
    }

    // @msg The TokenTransfer message to handle transfer of tokens from wallet
    // @destination The recipient address for the token transfer
    // @forward_ton_amount The amount of TONs forwarded with the transfer
    receive(msg: TokenTransfer) { // 0xf8a7ea5
        let ctx: Context = context(); // Check sender
        require(ctx.sender == self.owner, "Invalid sender");

        let final: Int = ctx.readForwardFee() * 2 + 
                            2 * self.gasConsumption + 
                                self.minTonsForStorage + 
                                    msg.forward_ton_amount;   // Gas checks
        require(ctx.value > final, "Invalid value"); 

        // Update balance
        self.balance = self.balance - msg.amount; 
        require(self.balance >= 0, "Invalid balance");

        let init: StateInit = initOf JettonWallet(msg.destination, self.master);  
        let wallet_address: Address = contractAddress(init);
        send(SendParameters{
            to: wallet_address, 
            value: 0,
            mode: SendRemainingValue, 
            bounce: false,
            body: TokenTransferInternal{ // 0x178d4519
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

    // @msg The TokenTransferInternal message to handle incoming token transfers
    // @from The address from which tokens are received
    // @amount The amount of tokens received
    receive(msg: TokenTransferInternal) { // 0x178d4519
        let ctx: Context = context();
        if (ctx.sender != self.master) {
            let sinit: StateInit = initOf JettonWallet(msg.from, self.master);
            require(contractAddress(sinit) == ctx.sender, "Invalid sender!");
        }

        // Update balance
        self.balance = self.balance + msg.amount;
        require(self.balance >= 0, "Invalid balance"); 
        
        // Get value for gas
        let msg_value: Int = self.msg_value(ctx.value);  
        let fwd_fee: Int = ctx.readForwardFee();
        if (msg.forward_ton_amount > 0) { 
                msg_value = msg_value - msg.forward_ton_amount - fwd_fee;
                send(SendParameters{
                    to: self.owner,
                    value: msg.forward_ton_amount,
                    mode: SendPayGasSeparately,
                    bounce: false,
                    body: TokenNotification { // 0x7362d09c -- Remind the new Owner
                        query_id: msg.query_id,
                        amount: msg.amount,
                        sender: msg.from,
                        forward_payload: msg.forward_payload
                    }.toCell()
                });
        }

        // 0xd53276db -- Cashback to the original Sender
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

    // @msg The TokenBurn message to handle burning of tokens
    // @amount The amount of tokens to burn
    // @response_destination The address to notify after burn
    receive(msg: TokenBurn) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");  // Check sender

        self.balance = self.balance - msg.amount; // Update balance
        require(self.balance >= 0, "Invalid balance");

        let fwd_fee: Int = ctx.readForwardFee(); // Gas checks
        require(ctx.value > fwd_fee + 2 * self.gasConsumption + self.minTonsForStorage, "Invalid value - Burn");

        // Send burn notification to master
        send(SendParameters{  
            to: self.master,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: TokenBurnNotification{
                query_id: msg.query_id,
                amount: msg.amount,
                sender: self.owner,
                response_destination: msg.response_destination!!
            }.toCell()
        });
    }

    // @value The value of the message
    // @returns Adjusted message value after accounting for gas and storage fees
    fun msg_value(value: Int): Int {
        let msg_value_temp: Int = value;
        let ton_balance_before_msg: Int = myBalance() - msg_value_temp;
        let storage_fee: Int = self.minTonsForStorage - min(ton_balance_before_msg, self.minTonsForStorage);
        msg_value_temp = msg_value_temp - (storage_fee + self.gasConsumption);
        return msg_value_temp;
    }

    // @msg The bounced TokenTransferInternal message that failed to send
    bounced(msg: bounced<TokenTransferInternal>) {
        self.balance = self.balance + msg.amount;   // Revert balance for failed transfer
    }

    // @msg The bounced TokenBurnNotification message that failed to send
    bounced(msg: bounced<TokenBurnNotification>) {
        self.balance = self.balance + msg.amount;  // Revert balance for failed burn notification
    }

    // @returns JettonWalletData containing the wallet’s balance, owner, master, and code
    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData{
            balance: self.balance,
            owner: self.owner,
            master: self.master,
            code: (initOf JettonWallet(self.owner, self.master)).code
        };
    }
}
