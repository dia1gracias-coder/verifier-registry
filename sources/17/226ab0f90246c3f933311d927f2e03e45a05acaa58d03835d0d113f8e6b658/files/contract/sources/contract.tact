message(0xf8a7ea5) TokenTransfer {
    query_Id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x7362d09c) TokenNotification {
    query_Id: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining;
}

message UpdateBondRate {
    usdt_bond_rate: Int as uint64;
    pro_ton_bond_rate: Int as uint64;
    pro_usdt_bond_rate: Int as uint64;
    ton_bond_rate: Int as uint64;
}

message WithdrawOwner {
    jetton_wallet: Address;
    amount: Int as coins;
    forward_payload: Slice as remaining;
}

message AddingJettonAddress {
    usdt_wallet: Address;
    pro_ton_wallet: Address;
    pro_usdt_wallet: Address;
    pro_wallet: Address;
}

message TransferOwner {
    new_owner: Address;
}

message WithdrawTON {
    amount: Int as coins;
}

message Claim {
    amount: Int as coins;
    forward_payload: Slice as remaining;
}

message BondTON {}

struct BondInfo {
    pending_amount: Int as coins;
    deposit_time: Int as uint32;
    period: Int as uint32;
}

contract BondingContract {
    // usdt jetton wallet
    usdt_wallet: Address?;
    usdt_bond_rate: Int as uint64 = 0;
    usdt_total_purchased: Int as coins = 0;

    // pro_ton_lp jetton wallet
    pro_ton_wallet: Address?;
    pro_ton_bond_rate: Int as uint64 = 0;
    pro_ton_total_purchased: Int as coins = 0;

    // pro_usdt_lp jetton wallet
    pro_usdt_wallet: Address?;
    pro_usdt_bond_rate: Int as uint64 = 0;
    pro_usdt_total_purchased: Int as coins = 0;

    // ton
    ton_bond_rate: Int as uint64 = 0;
    ton_total_purchased: Int as coins = 0;

    // pro jetton wallet
    pro_wallet: Address?;

    // owner
    owners: map<Address, Int>;
    // bond record   
    bond_info: map<Address, BondInfo>;

    // total information
    total_bond_amount: Int as coins = 0;

    init(_owner: Address){
        self.owners.set(_owner, 1);
    }

    receive(msg: AddingJettonAddress){
        let ctx: Context = context();
        require(self.owners.get(ctx.sender) == 1, "!owner");
        self.usdt_wallet = msg.usdt_wallet;
        self.pro_ton_wallet = msg.pro_ton_wallet;
        self.pro_usdt_wallet = msg.pro_usdt_wallet;
        self.pro_wallet = msg.pro_wallet;
        self.forward(ctx.sender, "Success".asComment(), false, null);
    }

    receive(msg: UpdateBondRate) {
        let ctx: Context = context();
        require(self.owners.get(ctx.sender) == 1, "!owner");
        self.usdt_bond_rate = msg.usdt_bond_rate;
        self.pro_ton_bond_rate = msg.pro_ton_bond_rate;
        self.pro_usdt_bond_rate = msg.pro_usdt_bond_rate;
        self.ton_bond_rate = msg.ton_bond_rate;
        self.forward(ctx.sender, "Success".asComment(), false, null);
    }

    receive(msg: TokenNotification){
        let ctx: Context = context();
        require(ctx.sender == self.usdt_wallet || ctx.sender == self.pro_ton_wallet || ctx.sender == self.pro_usdt_wallet, "!jetton_wallet");

        let user_info: BondInfo? = self.bond_info.get(msg.from);

        if (user_info == null) {
            self.bond_info.set(msg.from, BondInfo{pending_amount: self.bond_amount(msg.amount, ctx.sender), period: 432000, deposit_time: now()});
        } else {
            let previous_user_info: BondInfo = user_info!!;
            let pending_amount: Int = previous_user_info.pending_amount + self.bond_amount(msg.amount, ctx.sender);
            self.bond_info.set(msg.from, BondInfo{pending_amount: pending_amount, period: 432000, deposit_time: now()});
        }

        if (ctx.sender == self.usdt_wallet) {
            self.usdt_total_purchased = self.usdt_total_purchased + msg.amount;
        } else if (ctx.sender == self.pro_usdt_wallet) {
            self.pro_usdt_total_purchased = self.pro_usdt_total_purchased + msg.amount;
        } else if (ctx.sender == self.pro_ton_wallet) {
            self.pro_ton_total_purchased = self.pro_ton_total_purchased + msg.amount;
        }
        self.total_bond_amount = self.total_bond_amount + self.bond_amount(msg.amount, ctx.sender);
    }

    // Bond TON
    receive(msg: BondTON) {
        let ctx: Context = context();
        let user_info: BondInfo? = self.bond_info.get(ctx.sender);
        // decrease transaction fee
        let deposit_amount: Int = ctx.value - ton("0.012");
        if (user_info == null) {
            self.bond_info.set(ctx.sender, BondInfo{pending_amount: self.bond_amount(deposit_amount, ctx.sender), period: 432000, deposit_time: now()});
        } else {
            let previous_user_info: BondInfo = user_info!!;
            let pending_amount: Int = previous_user_info.pending_amount + self.bond_amount(deposit_amount, ctx.sender);
            self.bond_info.set(ctx.sender, BondInfo{pending_amount: pending_amount, period: 432000, deposit_time: now()});
        }

        self.ton_total_purchased = self.ton_total_purchased + deposit_amount;
        self.total_bond_amount = self.total_bond_amount + self.bond_amount(deposit_amount, ctx.sender);
    }

    fun bond_amount(jetton_amount: Int, jetton_wallet: Address?): Int {
        if (jetton_wallet == self.usdt_wallet) {
            return jetton_amount * self.usdt_bond_rate / 10000;
        }
        if (jetton_wallet == self.pro_usdt_wallet) {
            return jetton_amount * self.pro_usdt_bond_rate / 10000;
        }
        if (jetton_wallet == self.pro_ton_wallet) {
            return jetton_amount * self.pro_ton_bond_rate / 10000;
        }
        return jetton_amount * self.ton_bond_rate / 10000;
    }

    get fun get_bond_amount(jetton_amount: Int, jetton_wallet: Address): Int {
        return self.bond_amount(jetton_amount, jetton_wallet);
    }

    receive(msg: Claim) {
        let ctx: Context = context();
        let user_bond_info: BondInfo = self.bond_info.get(ctx.sender)!!;
        let claimable_amount_per_second: Int = user_bond_info.pending_amount / user_bond_info.period;
        let claimable_amount: Int = 0;
        let period: Int = 0;
        let pending_amount: Int = 0;
        if (now() - user_bond_info.deposit_time >= user_bond_info.period) {
            claimable_amount = claimable_amount_per_second * user_bond_info.period;
            period = 0;
            pending_amount = 0;            
        } else {
            claimable_amount = claimable_amount_per_second * (now() - user_bond_info.deposit_time);
            pending_amount = user_bond_info.pending_amount - claimable_amount;
            period = user_bond_info.period - (now() - user_bond_info.deposit_time);
        }
        require(claimable_amount > 0, "!claimable_amount");
        if (msg.amount != 0) {
            require(msg.amount <= claimable_amount, "!msg.amount");
            claimable_amount = msg.amount;
            pending_amount = user_bond_info.pending_amount - msg.amount;
            if (period == 0) {
                period = 10;
            }
        }
        self.bond_info.set(ctx.sender, BondInfo{pending_amount: pending_amount, deposit_time: now(), period: period});
        send(SendParameters{
                to: self.pro_wallet!!,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                bounce: false,
                body: TokenTransfer {
                    query_Id: 0,
                    amount: claimable_amount,
                    destination: ctx.sender,
                    response_destination: ctx.sender,
                    custom_payload: emptyCell(),
                    forward_ton_amount: ton("0.01"),
                    forward_payload: msg.forward_payload
                }.toCell()
            }
        );
    }

    // withdraw jettons by owner
    receive(msg: WithdrawOwner) {
        let ctx: Context = context();
        require(self.owners.get(ctx.sender) == 1, "!owner");
        send(SendParameters{
                to: msg.jetton_wallet,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                bounce: false,
                body: TokenTransfer {
                    query_Id: 0,
                    amount: msg.amount,
                    destination: ctx.sender,
                    response_destination: ctx.sender,
                    custom_payload: emptyCell(),
                    forward_ton_amount: ton("0.01"),
                    forward_payload: msg.forward_payload
                }.toCell()
            }
        );
    }

    receive(msg: WithdrawTON) {
        let ctx: Context = context();
        require(self.owners.get(ctx.sender) == 1, "!owner");
        send(SendParameters{
            to: ctx.sender,
            value: msg.amount,
            mode: SendRemainingValue + SendIgnoreErrors,
            bounce: false,
            body: null
        });
    }

    // transfer ownership
    receive(msg: TransferOwner) {
        let ctx: Context = context();
        require(self.owners.get(ctx.sender) == 1, "!owner");
        self.owners.set(msg.new_owner, 1);
    }

    get fun get_user_bond_info(): map<Address, BondInfo> {
        return self.bond_info;
    }

    get fun get_usdt_total_purchased_amount(): Int {
        return self.usdt_total_purchased;
    }

    get fun get_pro_usdt_total_purchased_amount(): Int {
        return self.pro_usdt_total_purchased;
    }

    get fun get_pro_ton_total_purchased_amount(): Int {
        return self.pro_ton_total_purchased;
    }

    get fun get_ton_total_purchased_amount(): Int {
        return self.ton_total_purchased;
    }

    get fun get_usdt_bond_rate(): Int {
        return self.usdt_bond_rate;
    }

    get fun get_pro_ton_bond_rate(): Int {
        return self.pro_ton_bond_rate;
    }

    get fun get_pro_usdt_bond_rate(): Int {
        return self.pro_usdt_bond_rate;
    }

    get fun get_ton_bond_rate(): Int {
        return self.ton_bond_rate;
    }

    get fun get_usdt_wallet(): Address? {
        return self.usdt_wallet;
    }

    get fun get_pro_ton_wallet(): Address? {
        return self.pro_ton_wallet;
    }

    get fun get_pro_usdt_wallet(): Address? {
        return self.pro_usdt_wallet;
    }

    get fun get_pro_wallet(): Address? {
        return self.pro_wallet;
    }

    get fun get_owner(address: Address): Int {
        return self.owners.get(address)!!;
    }
}