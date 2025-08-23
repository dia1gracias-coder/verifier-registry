// Since v1.6.0, Tact has a contract parameters syntax that can supersede
// lazy initialization by init() for all contracts that do not require specific on-chain
// deployment logic that must be run only once in the `init()` function.
//
// Note that the empty parameter list above is still a parameter list,
// meaning that the contract won't have an implicit or explicit `init(){:tact}` function
// and will enjoy storage write optimizations and use less gas overall.
//
// See: https://docs.tact-lang.org/book/contracts/#parameters

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


    receive() {
        cashback(sender());
    }

    receive(msg: JettonExcesses) {}

    receive(msg: SetMyJettonWallet) {
        self.requireOwner();
        self.myJettonWallet = msg.jettonWallet;
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

        require(msg.queryId > 0, "Invalid queryId!");
        require(msg.amount > 0, "Invalid amount");
        require(msg.timeout > currentTime, "Tx expired");
        require(msg.timeout <= currentTime + self.maxTimeoutMs, "Timeout too long");
        require(msg.to != newAddress(0, 0), "Invalid address");

        require(self.highloadWallets.get(sender()), "Not authorized");
        require(msg.amount <= self.withdrawLimit, "Exceeds limit");
        require(self.myJettonWallet != newAddress(0, 0), "Jetton wallet empty");
        require(self.processedQueryTimeouts.get(msg.queryId) == null, "Already processed");

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
    
    get fun getWithdrawLimit(): Int {
        return self.withdrawLimit;
    }
}
