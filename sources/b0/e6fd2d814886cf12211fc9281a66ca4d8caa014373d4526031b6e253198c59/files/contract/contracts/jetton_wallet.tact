import "./imports/messages";

message LockWallet {
    amount: Int as coins;
    unlockAt: Int as uint64;
}

message LockInfo {
    lockedAmount: Int as coins;
    unlockTime: Int as uint64;
}

@interface("org.ton.jetton.wallet")
contract JettonDefaultWallet {

    const minTonsForStorage: Int = ton("0.01");
    const gasConsumption: Int = ton("0.01");

    balance: Int;
    owner: Address;
    master: Address;

    // 🔒 LOCK STATE
    lockedAmount: Int;
    unlockTime: Int;

    init(master: Address, owner: Address) {
        self.balance = 0;
        self.owner = owner;
        self.master = master;

        self.lockedAmount = 0;
        self.unlockTime = 0;
    }

    // ================= LOCK MESSAGE =================


    // 🔒 Receive lock from master
    receive(msg: LockWallet) {
        require(sender() == self.master, "only master");

        self.lockedAmount = msg.amount;
        self.unlockTime = msg.unlockAt;
    }

    // ================= TRANSFER =================
    receive(msg: TokenTransfer) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");

        // 🔥 LOCK CHECK
        let nowTime = now();

        let locked = 0;
        if (nowTime < self.unlockTime) {
            locked = self.lockedAmount;
        }

        let available = self.balance - locked;

        require(available >= msg.amount, "Jetton locked");

        // Gas checks
        let fwdFee: Int = ctx.readForwardFee() + ctx.readForwardFee();  
        let final: Int =  2 * self.gasConsumption + self.minTonsForStorage + fwdFee;
        require(ctx.value > min(final, ton("0.01")), "Invalid value!!"); 

        // Update balance
        self.balance = self.balance - msg.amount; 
        require(self.balance >= 0, "Invalid balance");

        let init: StateInit = initOf JettonDefaultWallet(self.master, msg.destination);  
        let walletAddress: Address = contractAddress(init);

        send(SendParameters{
            to: walletAddress, 
            value: 0,
            mode: SendRemainingValue, 
            bounce: false,
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

    // ================= RECEIVE TOKEN =================
    receive(msg: TokenTransferInternal) {
        let ctx: Context = context();

        if (ctx.sender != self.master) {
            let sinit: StateInit = initOf JettonDefaultWallet(self.master, msg.from);
            require(contractAddress(sinit) == ctx.sender, "Invalid sender!");
        }

        self.balance = self.balance + msg.amount;
        require(self.balance >= 0, "Invalid balance"); 
        
        let msgValue: Int = self.msgValue(ctx.value);  
        let fwdFee: Int = ctx.readForwardFee();
        msgValue = msgValue - msg.forward_ton_amount - fwdFee;

        if (msg.forward_ton_amount > 0) { 
            send(SendParameters{
                to: self.owner,
                value: msg.forward_ton_amount,
                mode: SendPayGasSeparately + SendIgnoreErrors,
                bounce: false,
                body: TokenNotification {
                    queryId: msg.queryId,
                    amount: msg.amount,
                    from: msg.from,
                    forward_payload: msg.forward_payload
                }.toCell()
            });
        }

        if (msg.response_destination != null) { 
            send(SendParameters {
                to: msg.response_destination!!, 
                value: msgValue,  
                bounce: false,
                body: TokenExcesses { 
                    queryId: msg.queryId
                }.toCell(),
                mode: SendIgnoreErrors
            });
        }
    }

    // ================= BURN =================
    receive(msg: TokenBurn) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");

        // 🔥 LOCK CHECK (không cho burn phần bị lock)
        let nowTime = now();
        let locked = 0;

        if (nowTime < self.unlockTime) {
            locked = self.lockedAmount;
        }

        let available = self.balance - locked;
        require(available >= msg.amount, "Jetton locked");

        self.balance = self.balance - msg.amount;
        require(self.balance >= 0, "Invalid balance");

        let fwdFee: Int = ctx.readForwardFee();
        require(ctx.value > fwdFee + 2 * self.gasConsumption + self.minTonsForStorage, "Invalid value - Burn");

        send(SendParameters{  
            to: self.master,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: TokenBurnNotification{
                queryId: msg.queryId,
                amount: msg.amount,
                owner: self.owner,
                response_destination: self.owner
            }.toCell()
        });
    }

    // ================= INTERNAL =================
    get fun msgValue(value: Int): Int {
        let _msgValue: Int = value;
        let tonBalanceBeforeMsg: Int = myBalance() - _msgValue;
        let storageFee: Int = self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage);
        _msgValue = _msgValue - (storageFee + self.gasConsumption);
        return _msgValue;
    }

    bounced(src: bounced<TokenTransferInternal>) {
        self.balance = self.balance + src.amount;
    }

    bounced(src: bounced<TokenBurnNotification>) {
        self.balance = self.balance + src.amount;
    }

    // ================= GETTER =================
    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData{
            balance: self.balance,
            owner: self.owner,
            master: self.master,
            walletCode: (initOf JettonDefaultWallet(self.master, self.owner)).code
        };
    }

    get fun get_locked_info(): LockInfo {
        return LockInfo {
            lockedAmount : self.lockedAmount,
            unlockTime : self.unlockTime
        };
    }
}