message CurveInit {
    jetton_wallet_address: Address;
    jetton_balance: Int as coins;
    initial_buy: Int as coins;
    creator_address: Address;
}

message Buy {
    ton_amount: Int as coins;
}

message Sell {
    jetton_amount: Int as coins;
    to: Address;
}


message PayJettonTo {
    amount: Int as coins;
    keep: Int as coins;
    destination: Address;
    jetton_wallet_address: Address;
}

message PayTonTo {
    amount: Int as coins;
    destination: Address;
    jetton_wallet_address: Address;
}

struct CurveInformation {
    jetton_balance: Int as coins;
    jetton_wallet_address: Address;
}

contract Curve {

    router_address: Address;
    jetton_wallet_address: Address;
    jetton_balance: Int as coins;

    init(router_address: Address, jetton_wallet_address: Address) {
        self.router_address = router_address;
        self.jetton_wallet_address = jetton_wallet_address;
        self.jetton_balance = 0;
    }

    receive(msg: Buy) {
        require(self.jetton_balance > 0, "No tokens to sell");
        self.jetton_balance -= ton("1000");
        send(SendParameters{
            to: self.router_address,
            value: 0,
            mode: SendRemainingValue,
            body: PayJettonTo {
                amount: ton("1000"),
                keep: msg.ton_amount,
                destination: sender(),
                jetton_wallet_address: self.jetton_wallet_address
            }.toCell()
        });
    }

    receive(msg:Sell) {
        require(sender() == self.router_address, "Not Router");
        self.jetton_balance += msg.jetton_amount;
        send(SendParameters{
            to: msg.to,
            value: 0,
            mode: SendRemainingValue,
            body: PayTonTo {
                amount: ton("0.3"),
                destination: sender(),
                jetton_wallet_address: self.jetton_wallet_address
            }.toCell()
        });
    }

    receive(msg: CurveInit) {
        require(context().sender == self.router_address, "Not Router");
        require(self.jetton_balance == 0, "Already initialized");
        self.jetton_balance = msg.jetton_balance;
        send(SendParameters{
            to: msg.creator_address,
            value: 0,
            mode: SendRemainingValue,
            body : "Excess".asComment()
        });
    }

    get fun token_balance(): CurveInformation {
        return CurveInformation {
            jetton_balance: self.jetton_balance,
            jetton_wallet_address: self.jetton_wallet_address
        };
    }
}