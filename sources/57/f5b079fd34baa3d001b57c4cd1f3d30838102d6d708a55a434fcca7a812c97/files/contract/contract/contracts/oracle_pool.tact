import "@stdlib/deploy";

message TransferOwnership {
    new_owner: Address;
}

message SetReferrer {
    new_referrer: Address;
    rate_bps: Int; 
}

message ProcessServiceFee {
    service_wallet: Address;
}

message DepositReferral {
    referrer: Address;
}

contract OraclePool with Deployable {
    chat_id: Int as int64;
    creator: Address;
    master: Address; // Адрес нашей фабрики
    owner: Address; // Владелец хаба
    referrer: Address?; // Активный партнер
    referrer_rate_bps: Int = 0; // Его доля
    balances: map<Address, Int>;

    init(chat_id: Int, creator: Address, master: Address, referrer: Address?, referrer_rate_bps: Int) {
        self.chat_id = chat_id;
        self.creator = creator;
        self.owner = creator; 
        self.master = master;
        self.referrer = referrer;
        self.referrer_rate_bps = referrer_rate_bps;
    }

    receive() {}

    receive(msg: TransferOwnership) {
        require(sender() == self.owner, "Only owner can transfer ownership");
        self.owner = msg.new_owner;
    }

    // Изменить реферала может ТОЛЬКО Мастер по криптографическому билету
    receive(msg: SetReferrer) {
        require(sender() == self.master, "Only MasterFactory can change referrer settings");
        require(msg.rate_bps <= 10000, "Max partner share is 100%"); 
        self.referrer = msg.new_referrer;
        self.referrer_rate_bps = msg.rate_bps;
    }

    receive(msg: ProcessServiceFee) {
        let total_service_fee: Int = context().value;

        if (self.referrer != null && self.referrer_rate_bps > 0) {
            let referrer_share: Int = (total_service_fee * self.referrer_rate_bps) / 10000;
            let platform_share: Int = total_service_fee - referrer_share;

            let ref_addr: Address = self.referrer!!;
            let val: Int? = self.balances.get(ref_addr);
            let current_bal: Int = 0;
            if (val != null) {
                current_bal = val!!;
            }
            self.balances.set(ref_addr, current_bal + referrer_share);

            if (platform_share > 0) {
                send(SendParameters{
                    to: msg.service_wallet,
                    value: platform_share,
                    mode: 1
                });
            }
        } else {
            send(SendParameters{
                to: msg.service_wallet,
                value: total_service_fee,
                mode: 1
            });
        }
    }

    receive(msg: DepositReferral) {
        let amount: Int = context().value;
        let val: Int? = self.balances.get(msg.referrer);
        let current_bal: Int = 0;
        if (val != null) {
            current_bal = val!!;
        }
        self.balances.set(msg.referrer, current_bal + amount);
    }

    receive("withdraw") {
        let val: Int? = self.balances.get(sender());
        let amount_to_send: Int = 0;
        if (val != null) {
            amount_to_send = val!!;
        }
        require(amount_to_send > 0, "Nothing to withdraw");
        self.balances.set(sender(), 0); 

        send(SendParameters{
            to: sender(),
            value: amount_to_send,
            mode: 64 
        });
    }

    // Геттеры
    get fun owner(): Address { return self.owner; }
    get fun master(): Address { return self.master; }
    get fun referrer(): Address? { return self.referrer; }
    get fun referrer_rate_bps(): Int { return self.referrer_rate_bps; }
    get fun balance_of(user: Address): Int {
        let val: Int? = self.balances.get(user);
        if (val != null) {
            return val!!;
        }
        return 0;
    }
}