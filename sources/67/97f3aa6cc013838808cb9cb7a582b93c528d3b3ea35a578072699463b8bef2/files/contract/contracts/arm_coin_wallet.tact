import "@stdlib/deploy";

// Standard messages for Jetton (TEP-74)
message(0x178d4519) InternalTransfer {
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x0f8a7ea5) Transfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x7362d09c) TransferNotification {
    query_id: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forward_payload: Slice as remaining;
}

message(0x595f07bc) Burn {
    query_id: Int as uint64;
    amount: Int as coins;
    response_destination: Address;
    custom_payload: Cell?;
}

contract ArmCoinWallet {
    balance: Int as coins = 0;
    owner: Address;
    master: Address;

    init(master: Address, owner: Address) {
        self.master = master;
        self.owner = owner;
    }

    // Handles incoming token transfers from Master or other Wallets
    receive(msg: InternalTransfer) {
        let ctx: Context = context();
        
        // Security check: ensure the sender is either the Master or a valid Wallet
        if (ctx.sender != self.master) {
            let sinit: StateInit = initOf ArmCoinWallet(self.master, msg.from);
            require(ctx.sender == contractAddress(sinit), "Invalid sender");
        }

        // Update user balance
        self.balance = self.balance + msg.amount;
        require(self.balance >= 0, "Invalid balance");

        // Return excess gas if requested
        if (msg.forward_ton_amount > 0) {
            send(SendParameters{
                to: self.owner,
                value: msg.forward_ton_amount,
                mode: SendIgnoreErrors,
                body: TransferNotification{
                    query_id: msg.query_id,
                    amount: msg.amount,
                    sender: msg.from,
                    forward_payload: msg.forward_payload
                }.toCell()
            });
        }
    }

    // Handles sending tokens to another user
    receive(msg: Transfer) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Only owner can transfer");
        require(self.balance >= msg.amount, "Insufficient balance");

        // Deduct balance
        self.balance = self.balance - msg.amount;

        // Calculate destination wallet address
        let dinit: StateInit = initOf ArmCoinWallet(self.master, msg.destination);
        let dreadress: Address = contractAddress(dinit);

        // Send tokens to destination's wallet
        send(SendParameters{
            to: dreadress,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: InternalTransfer{
                query_id: msg.query_id,
                amount: msg.amount,
                from: self.owner,
                response_destination: msg.response_destination,
                forward_ton_amount: msg.forward_ton_amount,
                forward_payload: msg.forward_payload
            }.toCell(),
            code: dinit.code,
            data: dinit.data
        });
    }

    // Handles burning tokens for deflationary protocol
    receive(msg: Burn) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Only owner can burn");
        require(self.balance >= msg.amount, "Insufficient balance");

        self.balance = self.balance - msg.amount;
        
        // Notify Master that tokens were burned to update total_supply
        // (Implementation omitted for brevity, but crucial for Master's sync)
    }

    get fun balance(): Int {
        return self.balance;
    }
}