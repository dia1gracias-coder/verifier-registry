import "@stdlib/deploy";

// ==============================================
// 1. MESSAGES (Protokol Standar Transfer)
// ==============================================

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x178d4519) TokenTransferInternal {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining;
}

message(0x595f07bc) TokenBurn {
    queryId: Int as uint64;
    amount: Int as coins;
    response_destination: Address?;
    custom_payload: Cell?;
}

message(0x7bdd97de) TokenBurnNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    response_destination: Address?;
}

message(0xd53276db) TokenExcesses {
    queryId: Int as uint64;
}

message TokenUpdateContent {
    content: Cell;
}

message Mint {
    amount: Int;
    receiver: Address; // Ke dompet siapa koin akan dikirim
}

// ==============================================
// 2. JETTON WALLET (Dompet untuk setiap pengguna)
// ==============================================

contract JettonWallet {
    master: Address;
    owner: Address;
    balance: Int as coins;

    init(master: Address, owner: Address) {
        self.master = master;
        self.owner = owner;
        self.balance = 0;
    }

    receive(msg: TokenTransfer) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Bukan pemilik dompet");
        require(self.balance >= msg.amount, "Saldo tidak cukup");

        self.balance = self.balance - msg.amount;
        
        let init: StateInit = initOf JettonWallet(self.master, msg.destination);
        let walletAddress: Address = contractAddress(init);

        send(SendParameters{
            to: walletAddress,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: TokenTransferInternal{
                queryId: msg.queryId,
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
            let init: StateInit = initOf JettonWallet(self.master, msg.from);
            require(contractAddress(init) == ctx.sender, "Pengirim tidak valid");
        }

        self.balance = self.balance + msg.amount;

        if (msg.forward_ton_amount > 0) {
            send(SendParameters{
                to: self.owner,
                value: msg.forward_ton_amount,
                mode: SendIgnoreErrors,
                bounce: false,
                body: TokenNotification{
                    queryId: msg.queryId,
                    amount: msg.amount,
                    from: msg.from,
                    forward_payload: msg.forward_payload
                }.toCell()
            });
        }

        if (msg.response_destination != null) {
            send(SendParameters{
                to: msg.response_destination!!,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                bounce: false,
                body: TokenExcesses{
                    queryId: msg.queryId
                }.toCell()
            });
        }
    }

    receive(msg: TokenBurn) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Bukan pemilik dompet");
        require(self.balance >= msg.amount, "Saldo tidak cukup");

        self.balance = self.balance - msg.amount;

        send(SendParameters{
            to: self.master,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: TokenBurnNotification{
                queryId: msg.queryId,
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
            owner: self.owner,
            master: self.master,
            walletCode: (initOf JettonWallet(self.master, self.owner)).code
        };
    }
}

struct JettonWalletData {
    balance: Int;
    owner: Address;
    master: Address;
    walletCode: Cell;
}

// ==============================================
// 3. JETTON MASTER (Pabrik Utama Koin)
// ==============================================

contract Funny with Deployable {
    total_supply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;

    // Saat diciptakan, butuh alamat owner dan link KTP koin (content)
    init(owner: Address, content: Cell) {
        self.total_supply = 0;
        self.owner = owner;
        self.content = content;
        self.mintable = true;
    }

    receive(msg: Mint) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Hanya owner yang bisa cetak koin!");
        require(self.mintable, "Token sudah tidak bisa dicetak (Renounced)");

        self.total_supply = self.total_supply + msg.amount;

        // Bikin dompet untuk penerima dan transfer koinnya
        let init: StateInit = initOf JettonWallet(myAddress(), msg.receiver);
        send(SendParameters{
            to: contractAddress(init),
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: TokenTransferInternal{
                queryId: 0,
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

    receive("Stop Minting") {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Hanya owner");
        self.mintable = false; // Ini untuk mengunci koin biar tidak bisa dicetak lagi (bikin investor percaya)
    }

    receive(msg: TokenBurnNotification) {
        let init: StateInit = initOf JettonWallet(myAddress(), msg.sender);
        require(contractAddress(init) == sender(), "Hanya dompet resmi yang bisa burn");

        self.total_supply = self.total_supply - msg.amount;

        if (msg.response_destination != null) {
            send(SendParameters{
                to: msg.response_destination!!,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                bounce: false,
                body: TokenExcesses{
                    queryId: msg.queryId
                }.toCell()
            });
        }
    }

    get fun get_jetton_data(): JettonData {
        return JettonData{
            totalSupply: self.total_supply,
            mintable: self.mintable,
            owner: self.owner,
            content: self.content,
            walletCode: (initOf JettonWallet(myAddress(), self.owner)).code
        };
    }

    get fun get_wallet_address(owner: Address): Address {
        let init: StateInit = initOf JettonWallet(myAddress(), owner);
        return contractAddress(init);
    }
}

struct JettonData {
    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell;
    walletCode: Cell;
}