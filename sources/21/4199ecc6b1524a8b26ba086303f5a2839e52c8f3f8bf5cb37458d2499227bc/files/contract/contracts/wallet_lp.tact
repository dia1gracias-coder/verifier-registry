import "./tep74/messages";

@interface("org.ton.jetton.wallet")
contract LPWallet
{
    const minTonsForStorage:    Int = ton("0.019");
    const gasConsumption:       Int = ton("0.013");
    const updateAmount:         Int = ton("0.02" );

    balance: Int as coins = 0;
    owner: Address;
    master: Address;
    init(owner: Address, master: Address){
        self.balance    = 0;
        self.owner      = owner;
        self.master     = master;
    }

    receive(){}

    receive(msg: TokenExcesses){}

    /// @dev Triggered by the wallet Owner
    receive(msg: TokenTransfer){
        // 0xf8a7ea5
        require(
            context().value >= self.minTonsForStorage + self.updateAmount, 
            "TokenTransfer: Insufficient TON value"
        );
        require(sender() == self.owner, "Invalid sender");
        // Update balance
        self.balance -= msg.amount;
        require(self.balance >= 0, "TokenTransfer: Invalid balance");

        let init: StateInit = initOf LPWallet(msg.sender, self.master);
        let wallet_address: Address = contractAddress(init);

        send(SendParameters{
                to:                         wallet_address,
                value:                      self.minTonsForStorage + self.updateAmount,
                mode:                       SendRemainingValue | SendIgnoreErrors,
                bounce:                     true,
                body: TokenTransferInternal{ // 0x178d4519
                    query_id:               msg.query_id,
                    amount:                 msg.amount,
                    from:                   self.owner,
                    response_destination:   msg.response_destination,
                    forward_ton_amount:     self.updateAmount,
                    forward_payload:        self.ensurePayload(msg.forward_payload)
                }.toCell(),
                code:                       init.code,
                data:                       init.data
            }
        );
        
    }

    /// @dev Triggered by the sender's wallet
    receive(msg: TokenTransferInternal){
        // 0x178d4519
        
        if (sender() != self.master) {
            let sinit: StateInit = initOf LPWallet(msg.from, self.master);
            require(contractAddress(sinit) == sender(), "Invalid sender!");
        }
        // Update balance
        self.balance += msg.amount;
        require(self.balance >= 0, "TokenTransferInternal: Invalid balance");

        send(SendParameters{
                to:                     self.owner,
                value:                  self.updateAmount,
                mode:                   SendPayGasSeparately,
                bounce:                 true,
                body: TokenNotification{ // 0x7362d09c -- Remind the new Owner
                    query_id:           msg.query_id,
                    amount:             msg.amount,
                    from:               msg.from,
                    forward_payload:    self.ensurePayload(msg.forward_payload)
                }.toCell()
            }
        );

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
        
    }

    receive(msg: TokenBurn){
        let ctx: Context = context();
        require(
            ctx.sender == self.owner || ctx.sender == self.master, 
            "Invalid sender"
        ); // Check sender

        self.balance = (self.balance - msg.amount); // Update balance
        require(self.balance >= 0, "TokenBurn: Invalid balance");

        // Burn tokens
        send(SendParameters{
                to: self.master,
                value: 0,
                mode: SendRemainingValue,
                bounce: true,
                body: TokenBurnNotification{
                    query_id:               msg.query_id,
                    amount:                 msg.amount,
                    sender:                 self.owner,
                    response_destination:   msg.response_destination
                }.toCell()
            }
        );
    }

    fun msg_value(value: Int): Int {
        let _value: Int = value;
        let ton_balance_before_msg: Int = (myBalance() - _value);
        let storage_fee: Int = (self.minTonsForStorage - min(ton_balance_before_msg, self.minTonsForStorage));
        _value -= storage_fee + self.gasConsumption;
        return _value;
    }

    bounced(msg: bounced<TokenTransferInternal>){
        self.balance = (self.balance + msg.amount);
    }

    bounced(msg: bounced<TokenBurnNotification>){
        self.balance = (self.balance + msg.amount);
    }

    fun ensurePayload(maybePayload: Slice?): Slice {
        let payload: Slice = beginCell().endCell().asSlice();

        if(maybePayload != null){
            payload = maybePayload!!;
        }

        return payload;
    }

    get fun get_wallet_data(): JettonWalletData {
        return
            JettonWalletData{
                balance:    self.balance,
                owner:      self.owner,
                master:     self.master,
                code:       initOf LPWallet(self.owner, self.master).code
            };
    }
}