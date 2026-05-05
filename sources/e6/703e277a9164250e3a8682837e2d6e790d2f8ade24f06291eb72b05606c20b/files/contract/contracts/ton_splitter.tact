const TIME_LOCK: Int = 30;
const CONTRACT_GAS_COSTS: Int = 10000000; // 0.01 TON

message Pause {}
message Unpause {}
message Withdraw {
    amount: Int;
}
message UpdateParams {
    total: Int;
    amount1: Int;
    amount2: Int;
    wallet1: Address;
    wallet2: Address;
}

struct State {
    owner: Address;
    wallet1: Address;
    wallet2: Address;
    total: Int;
    amount1: Int;
    amount2: Int;
    paused: Bool;
}

contract TonSplitter {
    owner: Address;
    total: Int;
    amount1: Int;
    amount2: Int;
    wallet1: Address;
    wallet2: Address;

    paused: Bool;
    lastUser: Address?;
    lastUserCallTime: Int;
    lastOwnerCallTime: Int;

    init(
        owner: Address,
        total: Int,
        amount1: Int,
        amount2: Int,
        wallet1: Address,
        wallet2: Address,
    ) {
        require(total > 0, "Total positive");
        require(amount1 > 0, "Amount1 positive");
        require(amount2 > 0, "Amount2 positive");
        require(amount1 + amount2 + CONTRACT_GAS_COSTS <= total, "Too large amounts");
        require(wallet1 != wallet2, "Same Wallets");
        require(wallet1 != myAddress(), "Wallet1 invalid");
        require(wallet2 != myAddress(), "Wallet2 invalid");
        require(wallet1 != owner, "Wallet1 is owner");
        require(wallet2 != owner, "Wallet2 is owner");
        require(owner != myAddress(), "Owner invalid");

        self.owner = owner;
        self.total = total;
        self.amount1 = amount1;
        self.amount2 = amount2;
        self.wallet1 = wallet1;
        self.wallet2 = wallet2;

        self.paused = false;
        self.lastUserCallTime = 0;
        self.lastOwnerCallTime = 0;
    }

    receive() {
        if (sender() != self.owner) {
            self.handleSplit(sender(), context().value);
        }
    }

    receive(_: String) {
        if (sender() != self.owner) {
            self.handleSplit(sender(), context().value);
        }
    }

    receive(_: Pause) {
        require(sender() == self.owner, "Only owner");
        self.checkOwnerTimeLock();
        self.paused = true;
    }

    receive(_: Unpause) {
        require(sender() == self.owner, "Only owner");
        self.checkOwnerTimeLock();
        self.paused = false;
    }

    receive(msg: Withdraw) {
        require(sender() == self.owner, "Only owner");
        self.checkOwnerTimeLock();
        require(msg.amount > 0, "Amount positive");
        require(msg.amount <= (myBalance() - CONTRACT_GAS_COSTS), "Low Balance");

        send(SendParameters {
            to: sender(),
            value: msg.amount,
        });
    }

    receive(msg: UpdateParams) {
        require(sender() == self.owner, "Only owner");
        self.checkOwnerTimeLock();
        require(self.paused, "Not Paused");
        require(msg.total > 0, "Total positive");
        require(msg.amount1 > 0, "Amount1 positive");
        require(msg.amount2 > 0, "Amount2 positive");
        require(msg.amount1 + msg.amount2 + CONTRACT_GAS_COSTS <= msg.total, "Too large amounts");
        require(msg.wallet1 != msg.wallet2, "Same Wallets");
        require(msg.wallet1 != myAddress(), "Wallet1 invalid");
        require(msg.wallet2 != myAddress(), "Wallet2 invalid");
        require(msg.wallet1 != self.owner, "Wallet1 is owner");
        require(msg.wallet2 != self.owner, "Wallet2 is owner");

        self.total = msg.total;
        self.amount1 = msg.amount1;
        self.amount2 = msg.amount2;
        self.wallet1 = msg.wallet1;
        self.wallet2 = msg.wallet2;
    }

    bounced(msg: Slice) {
        return;
    }

    get fun state(): State {
        return State {
            owner: self.owner,
            wallet1: self.wallet1,
            wallet2: self.wallet2,
            total: self.total,
            amount1: self.amount1,
            amount2: self.amount2,
            paused: self.paused,
        };
    }

    inline fun checkUserTimeLock(sender: Address) {
        let currentTime = now();

        if (self.lastUser != null) {
            let sameUser = self.lastUser!! == sender;
            let tooSoon = currentTime < self.lastUserCallTime + TIME_LOCK;
            require(!(sameUser && tooSoon), "User timelock");
        }

        self.lastUser = sender;
        self.lastUserCallTime = currentTime;
    }

    fun checkOwnerTimeLock() {
        let currentTime = now();
        require(currentTime >= self.lastOwnerCallTime + TIME_LOCK, "Owner timelock");
        self.lastOwnerCallTime = currentTime;
    }

    fun handleSplit(sender: Address, value: Int) {
        require(!self.paused, "Paused");
        require(value >= self.total, "Low value");

        self.checkUserTimeLock(sender);

        send(SendParameters {
            to: self.wallet1,
            value: self.amount1,
            mode: SendPayFwdFeesSeparately | SendBounceIfActionFail,
        });

        send(SendParameters {
            to: self.wallet2,
            value: self.amount2,
            mode: SendPayFwdFeesSeparately | SendBounceIfActionFail,
        });
    }
}
