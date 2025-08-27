import "@stdlib/deploy";
import "@stdlib/ownable";

message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell? = null;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0xd53276db) JettonExcesses {
    queryId: Int as uint64;
}

message SetMyJettonWallet{
    jettonWallet: Address;
}

message AddHighloadWallet {
    wallet: Address;
}

message RemoveHighloadWallet {
    wallet: Address;
}

message WithdrawToken {
    to: Address;
    amount: Int as coins;
    order: Int as uint128;
    queryId: Int as uint64;
    timeout: Int as uint32;
}

message SetWithdrawLimit {
    limit: Int as uint32;
}


contract DzTonV3 with Deployable, Ownable {
    owner: Address;
    myJettonWallet: Address;
    highloadWallets: map<Address, Bool>;
    processedQueryTimeouts: map<Int as uint64, Int as uint32>;
    processedQueryCount: Int;

    withdrawLimit: Int as coins;
    const maxTimeoutMs: Int = 60 * 10; // 10 minutes
    const maxStorageItems: Int = 100;
    const cleanUpPerCall: Int = 50;

    init() {
        self.owner = sender();
        self.myJettonWallet = newAddress(0, 0);
        self.highloadWallets = emptyMap();
        self.processedQueryTimeouts = emptyMap();
        self.processedQueryCount = 0;
        self.withdrawLimit = 10000000000;
    }

    fun clean() {
        let delCount: Int = 0;
        let currentTime = now();

        foreach (queryId, timeout in self.processedQueryTimeouts) {
            if (delCount < self.cleanUpPerCall && timeout < currentTime) {
                self.processedQueryTimeouts.del(queryId);
                delCount += 1;
            }
        }
        self.processedQueryCount -= delCount;
    }


    receive() {
        cashback(sender());
    }

    receive(msg: JettonExcesses) {}

    receive(msg: SetMyJettonWallet) {
        self.requireOwner();
        self.myJettonWallet = msg.jettonWallet;
    }

    receive(msg: SetWithdrawLimit) {
        self.requireOwner();
        self.withdrawLimit = msg.limit;
    }

    receive(msg: AddHighloadWallet) {
        self.requireOwner();
        self.highloadWallets.set(msg.wallet, true);
    }

    receive(msg: RemoveHighloadWallet) {
        self.requireOwner();
        self.highloadWallets.del(msg.wallet);
    }

    receive(msg: WithdrawToken) {
        let currentTime = now();

        require(msg.queryId > 0, "Invalid queryId.");
        require(msg.amount > 0, "Invalid amount.");
        require(msg.timeout > currentTime, "Tx expired");
        require(msg.timeout <= currentTime + self.maxTimeoutMs, "Timeout too long");
        require(msg.to != newAddress(0, 0), "Invalid address");

        require(self.highloadWallets.get(sender()), "Not authorized");
        require(msg.amount <= self.withdrawLimit, "Exceeds limit");
        require(self.myJettonWallet != newAddress(0, 0), "Jetton wallet empty");
        require(self.processedQueryTimeouts.get(msg.queryId) == null, "Already processed");

        if (self.processedQueryCount >= self.maxStorageItems) {
            self.clean();
        }

        self.processedQueryTimeouts.set(msg.queryId, msg.timeout);
        self.processedQueryCount += 1;

        send(SendParameters{
            to: self.myJettonWallet,
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            bounce: true,
            body: JettonTransfer{
                queryId: msg.order,
                amount: msg.amount,
                destination: msg.to,
                responseDestination: sender(),
                customPayload: null,
                forwardTonAmount: ton("0.0001"),
                forwardPayload: beginCell().storeBool(false).endCell().beginParse(),
            }.toCell()
        });
    }

    get fun queryMyJettonWallet(): Address {
        return self.myJettonWallet;
    }

    get fun queryOwner(): Address {
        return self.owner;
    }

    get fun queryHighloadWallet(wallet: Address): Bool {
        return self.highloadWallets.get(wallet) == true;
    }

    get fun checkIsQueryIdProcessed(queryId: Int): Bool {
        return self.processedQueryTimeouts.get(queryId) != null;
    }
    
    get fun queryWithdrawLimit(): Int {
        return self.withdrawLimit;
    }

    get fun queryProcessedQueryCount(): Int {
        return self.processedQueryCount;
    }

    get fun getStorageItems(): map<Int as uint64, Int as uint32> {
        return self.processedQueryTimeouts;
    }
}
