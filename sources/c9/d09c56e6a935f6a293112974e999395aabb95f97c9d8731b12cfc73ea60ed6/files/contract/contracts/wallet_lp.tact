import "./tep74/messages";

@interface("org.ton.jetton.wallet")
contract LPWallet
{
    const minTonsForStorage: Int = ton("0.019");
    const gasConsumption: Int = ton("0.013");
    const updateAmount: Int = ton("0.02");

    balance: Int as coins = 0;
    owner: Address;
    master: Address;
    init(owner: Address, master: Address){
        self.balance = 0;
        self.owner = owner;
        self.master = master;
    }

    receive(){}

    /// @dev Triggered by the wallet Owner
    receive(msg: TokenTransfer){
        // 0xf8a7ea5
        let ctx: Context = context(); // Check sender
        require(ctx.sender == self.owner, "Invalid sender");
        // Update balance
        self.balance -= msg.amount;
        require(self.balance >= 0, "TokenTransfer: Invalid balance");

        let init: StateInit = initOf LPWallet(msg.sender, self.master);
        let wallet_address: Address = contractAddress(init);
        send(SendParameters{
                to:                         wallet_address,
                value:                      self.minTonsForStorage,
                mode:                       SendRemainingValue,
                bounce:                     true,
                body: TokenTransferInternal{ // 0x178d4519
                    query_id:               msg.query_id,
                    amount:                 msg.amount,
                    from:                   self.owner,
                    response_destination:   msg.response_destination,
                    forward_ton_amount:     msg.forward_ton_amount,
                    forward_payload:        msg.forward_payload
                }.toCell(),
                code:                       init.code,
                data:                       init.data
            }
        );
        
    }

    /// @dev Triggered by the sender's wallet
    receive(msg: TokenTransferInternal){
        // 0x178d4519
        let ctx: Context = context();
        if (ctx.sender != self.master) {
            let sinit: StateInit = initOf LPWallet(msg.from, self.master);
            require(contractAddress(sinit) == ctx.sender, "Invalid sender!");
        }
        // Update balance
        self.balance += msg.amount;
        require(self.balance >= 0, "TokenTransferInternal: Invalid balance");

        // Get value for gas
        let _msg_value: Int = self.msg_value(ctx.value);
        let fwd_fee: Int = ctx.readForwardFee();
        if (msg.forward_ton_amount > 0) {
            _msg_value = ((_msg_value - msg.forward_ton_amount) - fwd_fee);
            send(SendParameters{
                    to:                     self.owner,
                    value:                  msg.forward_ton_amount,
                    mode:                   SendPayGasSeparately,
                    bounce:                 true,
                    body: TokenNotification{ // 0x7362d09c -- Remind the new Owner
                        query_id:           msg.query_id,
                        amount:             msg.amount,
                        from:               msg.from,
                        forward_payload:    msg.forward_payload
                    }.toCell()
                }
            );
        }

        // Notofication to the JettonMaster to update the sender's & receiver's positions
        send(SendParameters{
                to:                         self.master,
                value:                      self.updateAmount,
                mode:                       SendPayGasSeparately,
                bounce:                     true,
                body: UpdateDeposits{
                    amount:                 msg.amount,
                    sender:                 msg.from,
                    receiver:               self.owner,
                }.toCell()
            }
        );

        // 0xd53276db -- Cashback to the original Sender
        if (msg.response_destination != null && _msg_value > 0) {
            send(SendParameters{
                    to: msg.response_destination!!,
                    value: _msg_value - self.updateAmount,
                    bounce: false,
                    body: TokenExcesses{query_id: msg.query_id}.toCell(),
                    mode: SendPayGasSeparately
                }
            );
        }
    }

    receive(msg: TokenBurn){
        let ctx: Context = context();
        require(
            ctx.sender == self.owner || ctx.sender == self.master, 
            "Invalid sender"
        ); // Check sender

        self.balance = (self.balance - msg.amount); // Update balance
        require(self.balance >= 0, "TokenBurn: Invalid balance");
        // let fwd_fee: Int = ctx.readForwardFee(); // Gas checks
        // require(ctx.value > ((fwd_fee + 2 * self.gasConsumption) + self.minTonsForStorage), "Invalid value - Burn");
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
                    response_destination: msg.response_destination
                }.toCell()
            }
        );
    }

    fun msg_value(value: Int): Int {
        let _value: Int = value;
        let ton_balance_before_msg: Int = (myBalance() - _value);
        let storage_fee: Int = (self.minTonsForStorage - min(ton_balance_before_msg, self.minTonsForStorage));
        _value = (_value - (storage_fee + self.gasConsumption));
        return _value;
    }

    bounced(msg: bounced<TokenTransferInternal>){
        self.balance = (self.balance + msg.amount);
    }

    bounced(msg: bounced<TokenBurnNotification>){
        self.balance = (self.balance + msg.amount);
    }

    get fun get_wallet_data(): JettonWalletData {
        return
            JettonWalletData{
                balance: self.balance,
                owner: self.owner,
                master: self.master,
                code: initOf LPWallet(self.owner, self.master).code
            };
    }
}