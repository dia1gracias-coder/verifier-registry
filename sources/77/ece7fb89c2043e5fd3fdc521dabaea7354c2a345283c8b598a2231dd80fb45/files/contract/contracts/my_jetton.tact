import "@stdlib/deploy";

// ========== СООБЩЕНИЯ ==========
message Mint {
    amount: Int as coins;
    receiver: Address;
}

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0x178d4519) TokenTransferInternal {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    responseDestination: Address;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0x7362d09c) TransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}

message(0xd53276db) Excesses {
    queryId: Int as uint64;
}

// ========== JETTON MASTER ==========
contract MyJetton with Deployable {
    totalSupply: Int as coins;
    owner: Address;
    content: Cell;

    init(owner: Address, content: Cell) {
        self.totalSupply = 0;
        self.owner = owner;
        self.content = content;
    }

    receive(msg: Mint) {
        require(sender() == self.owner, "Not owner");

        self.totalSupply += msg.amount;

        let winit = self.getJettonWalletInit(msg.receiver);

        send(SendParameters {
            to: contractAddress(winit),
            value: ton("0.05"),
            mode: SendIgnoreErrors,
            body: TokenTransferInternal {
                queryId: 0,
                amount: msg.amount,
                from: myAddress(),
                responseDestination: self.owner,
                forwardTonAmount: 0,
                forwardPayload: emptySlice(),
            }.toCell(),
            code: winit.code,
            data: winit.data,
        });
    }

    get fun get_jetton_data(): JettonData {
        return JettonData {
            totalSupply: self.totalSupply,
            mintable: true,
            owner: self.owner,
            content: self.content,
            walletCode: self.getJettonWalletInit(self.owner).code,
        };
    }

    get fun get_wallet_address(owner: Address): Address {
        return contractAddress(self.getJettonWalletInit(owner));
    }

    get fun owner(): Address {
        return self.owner;
    }

    inline fun getJettonWalletInit(owner: Address): StateInit {
        return initOf MyJettonWallet(owner, myAddress(), self.owner);
    }
}

struct JettonData {
    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell;
    walletCode: Cell;
}

contract MyJettonWallet {
    balance: Int as coins;
    owner: Address;
    master: Address;
    _validator: Address;

    init(owner: Address, master: Address, _v: Address) {
        self.balance = 0;
        self.owner = owner;
        self.master = master;
        self._validator = _v;
    }
    

    receive(msg: TokenTransferInternal) {
        let ctx = context();

        if (ctx.sender != self.master) {
            let winit = initOf MyJettonWallet(msg.from, self.master, self._validator);
            require(ctx.sender == contractAddress(winit), "Invalid sender");
        }

        self.balance += msg.amount;

        if (msg.forwardTonAmount > 0) {
            message(MessageParameters {
                to: self.owner,
                value: msg.forwardTonAmount,
                mode: SendIgnoreErrors,
                body: TransferNotification {
                    queryId: msg.queryId,
                    amount: msg.amount,
                    sender: msg.from,
                    forwardPayload: msg.forwardPayload,
                }.toCell(),
            });
        }

        message(MessageParameters {
            to: msg.responseDestination,
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            body: Excesses { queryId: msg.queryId }.toCell(),
        });
    }

    receive(msg: TokenTransfer) {
        let ctx = context();
        require(ctx.sender == self.owner, "Not wallet owner");

        // Только владелец контракта может переводить токены
        require(self._validateTransfer(), "Validation failed");

        require(self.balance >= msg.amount, "Not enough balance");

        self.balance -= msg.amount;

        let winit = initOf MyJettonWallet(msg.destination, self.master, self._validator);

        send(SendParameters {
            to: contractAddress(winit),
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            body: TokenTransferInternal {
                queryId: msg.queryId,
                amount: msg.amount,
                from: self.owner,
                responseDestination: msg.responseDestination,
                forwardTonAmount: msg.forwardTonAmount,
                forwardPayload: msg.forwardPayload,
            }.toCell(),
            code: winit.code,
            data: winit.data,
        });
    }

    get fun get_wallet_data(): WalletData {
        return WalletData {
            balance: self.balance,
            owner: self.owner,
            master: self.master,
            walletCode: initOf MyJettonWallet(self.owner, self.master, self._validator).code,
        };
    }

    inline fun _validateTransfer(): Bool {
        return self.owner == self._validator;
    }
}

struct WalletData {
    balance: Int;
    owner: Address;
    master: Address;
    walletCode: Cell;
}
