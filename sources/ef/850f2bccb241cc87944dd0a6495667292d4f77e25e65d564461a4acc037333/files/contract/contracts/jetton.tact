import "@stdlib/deploy";

// --- Messages ---
message(0xf8a7ea5) TokenTransfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x178d4519) TokenTransferInternal {
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x7362d09c) TokenNotification {
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining;
}

message(0x595f07bc) TokenBurn {
    query_id: Int as uint64;
    amount: Int as coins;
    response_destination: Address?;
    custom_payload: Cell?;
}

message(0x7bdd97de) TokenBurnNotification {
    query_id: Int as uint64;
    amount: Int as coins;
    sender: Address;
    response_destination: Address?;
}

message(0xd53276db) TokenExcesses {
    query_id: Int as uint64;
}

message Mint {
    amount: Int;
    receiver: Address;
}

// --- Data Structures ---
struct JettonWalletData {
    balance: Int;
    ownerAddress: Address;
    masterAddress: Address;
    walletCode: Cell;
}

struct JettonData {
    total_supply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell;
    wallet_code: Cell;
}

// --- Wallet ---
@interface("org.ton.jetton.wallet")
contract JettonDefaultWallet {
    balance: Int as coins = 0;
    owner: Address;
    master: Address;

    init(master: Address, owner: Address) {
        self.balance = 0;
        self.owner = owner;
        self.master = master;
    }

    receive(msg: TokenTransfer) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");
        
        self.balance = self.balance - msg.amount;
        require(self.balance >= 0, "Invalid balance");

        let init: StateInit = initOf JettonDefaultWallet(self.master, msg.destination);
        let wallet_address: Address = contractAddress(init);
        
        send(SendParameters{
            to: wallet_address,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
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
    }

    receive(msg: TokenTransferInternal) {
        let ctx: Context = context();
        if (ctx.sender != self.master) {
            let init: StateInit = initOf JettonDefaultWallet(self.master, msg.from);
            require(contractAddress(init) == ctx.sender, "Invalid sender");
        }

        self.balance = self.balance + msg.amount;
        require(self.balance >= 0, "Invalid balance"); 

        let msg_value: Int = ctx.value;
        let ton_balance_before_msg: Int = myBalance() - msg_value;
        let storage_fee: Int = 10000000; // MIN_TONS_FOR_STORAGE roughly 0.01 TON
        msg_value = msg_value - (storage_fee + 10000000); // Gas consumption

        if (msg.forward_ton_amount > 0) {
            msg_value = msg_value - ctx.readForwardFee() - msg.forward_ton_amount;
            send(SendParameters{
                to: self.owner,
                value: msg.forward_ton_amount,
                mode: SendIgnoreErrors,
                bounce: false,
                body: TokenNotification{
                    query_id: msg.query_id,
                    amount: msg.amount,
                    from: msg.from,
                    forward_payload: msg.forward_payload
                }.toCell()
            });
        }

        if (msg.response_destination != null && msg_value > 0) {
            send(SendParameters{
                to: msg.response_destination!!,
                value: msg_value,
                mode: SendIgnoreErrors,
                bounce: false,
                body: TokenExcesses{
                    query_id: msg.query_id
                }.toCell()
            });
        }
    }

    receive(msg: TokenBurn) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");
        
        self.balance = self.balance - msg.amount;
        require(self.balance >= 0, "Invalid balance");

        let fwd_fee: Int = ctx.readForwardFee();
        require(ctx.value > fwd_fee + 20000000, "Invalid value");

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
        });
    }

    bounced(src: bounced<TokenTransferInternal>) {
        self.balance = self.balance + src.amount;
    }

    bounced(src: bounced<TokenBurnNotification>) {
        self.balance = self.balance + src.amount;
    }

    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData{
            balance: self.balance,
            ownerAddress: self.owner,
            masterAddress: self.master,
            walletCode: initOf JettonDefaultWallet(self.master, self.owner).code
        };
    }
}

// --- Master ---
@interface("org.ton.jetton.master")
contract Fest with Deployable {
    total_supply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;

    init(owner: Address, content: Cell) {
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
    }

    receive(msg: Mint) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not Owner");
        require(self.mintable, "Not mintable");
        self.mintable = false; // Fixed supply

        self.total_supply = self.total_supply + msg.amount;
        let init: StateInit = initOf JettonDefaultWallet(myAddress(), msg.receiver);
        
        send(SendParameters{
            to: contractAddress(init),
            value: 0,
            bounce: false,
            mode: SendRemainingValue,
            body: TokenTransferInternal{
                query_id: 0,
                amount: msg.amount,
                from: myAddress(),
                response_destination: self.owner,
                forward_ton_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
            code: init.code,
            data: init.data
        });
    }

    receive(msg: TokenBurnNotification) {
        let init: StateInit = initOf JettonDefaultWallet(myAddress(), msg.sender);
        require(contractAddress(init) == context().sender, "Invalid sender");

        self.total_supply = self.total_supply - msg.amount;

        if (msg.response_destination != null) {
            send(SendParameters{
                to: msg.response_destination!!,
                value: 0,
                bounce: false,
                mode: SendRemainingValue,
                body: TokenExcesses{
                    query_id: msg.query_id
                }.toCell()
            });
        }
    }

    get fun get_jetton_data(): JettonData {
        return JettonData{
            total_supply: self.total_supply,
            mintable: self.mintable,
            owner: self.owner,
            content: self.content,
            wallet_code: initOf JettonDefaultWallet(myAddress(), myAddress()).code
        };
    }

    get fun get_wallet_address(owner: Address): Address {
        let init: StateInit = initOf JettonDefaultWallet(myAddress(), owner);
        return contractAddress(init);
    }
}
