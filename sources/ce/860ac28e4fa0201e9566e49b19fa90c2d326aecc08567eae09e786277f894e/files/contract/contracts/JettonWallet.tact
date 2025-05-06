// Define WalletData struct
struct WalletData {
    balance: Int;
    owner: Address;
    master: Address;
}

// Messages
message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x178d4519) TokenTransferInternal {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x595f07bc) TokenBurn {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    response_destination: Address;
}

// Wallet Contract
contract JeddonWallet {
    balance: Int;
    owner: Address;
    master: Address;

    init(master: Address, owner: Address) {
        self.master = master;
        self.owner = owner;
        self.balance = 0;
    }

    receive(msg: TokenTransfer) {
        let ctx = context();
        require(ctx.sender == self.owner, "Only owner can transfer");

        self.balance = self.balance - msg.amount;
        require(self.balance >= 0, "Insufficient balance");

        let walletInit = initOf JeddonWallet(self.master, msg.destination);
        send(SendParameters {
            to: contractAddress(walletInit),
            value: 0,
            bounce: false,
            mode: SendRemainingValue,
            body: TokenTransferInternal {
                queryId: msg.queryId,
                amount: msg.amount,
                from: self.owner,
                response_destination: msg.response_destination,
                forward_ton_amount: msg.forward_ton_amount,
                forward_payload: msg.forward_payload,
            }.toCell(),
            code: walletInit.code,
            data: walletInit.data,
        });
    }

    receive(msg: TokenTransferInternal) {
        let ctx = context();
        require(
            ctx.sender == self.master ||
            contractAddress(initOf JeddonWallet(self.master, msg.from)) == ctx.sender,
            "Invalid sender",
        );

        self.balance = self.balance + msg.amount;
        require(self.balance >= 0, "Overflow");

        if (msg.forward_ton_amount > 0) {
            send(SendParameters {
                to: self.owner,
                value: msg.forward_ton_amount,
                bounce: false,
                mode: SendIgnoreErrors,
                body: msg.forward_payload.asCell(),
            });
        }
    }

    receive(msg: TokenBurn) {
        let ctx = context();
        require(ctx.sender == self.owner, "Only owner can burn");

        self.balance = self.balance - msg.amount;
        require(self.balance >= 0, "Insufficient balance");

        send(SendParameters {
            to: self.master,
            value: 0,
            bounce: true,
            mode: SendRemainingValue,
            body: TokenBurn {
                queryId: msg.queryId,
                amount: msg.amount,
                owner: self.owner,
                response_destination: msg.response_destination,
            }.toCell(),
        });
    }

    get fun get_wallet_data(): WalletData {
        return WalletData {
            balance: self.balance,
            owner: self.owner,
            master: self.master,
        };
    }
}
