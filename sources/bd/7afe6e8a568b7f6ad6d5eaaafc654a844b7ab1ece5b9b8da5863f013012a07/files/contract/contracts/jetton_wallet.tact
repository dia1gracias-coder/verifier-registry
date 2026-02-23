import "@stdlib/deploy";

message JettonTransferInternal {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    responseDestination: Address;
    forwardAmount: Int as coins;
}

message JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address;
    forwardAmount: Int as coins;
}

message JettonBurn {
    queryId: Int as uint64;
    amount: Int as coins;
    responseDestination: Address;
}

contract JettonWallet {
    balance: Int as coins;
    owner: Address;
    minter: Address;

    init(owner: Address, minter: Address) {
        self.balance = 0;
        self.owner = owner;
        self.minter = minter;
    }

    receive(msg: JettonTransferInternal) {
        require(sender() == self.minter, "Only minter can mint");
        self.balance = self.balance + msg.amount;
    }

    receive(msg: JettonTransfer) {
        require(sender() == self.owner, "Only owner can transfer");
        require(self.balance >= msg.amount, "Insufficient balance");
        self.balance = self.balance - msg.amount;

        let init: StateInit = initOf JettonWallet(msg.destination, self.minter);
        send(SendParameters{
            to: contractAddress(init),
            value: msg.forwardAmount,
            bounce: false,
            mode: SendIgnoreErrors,
            code: init.code,
            data: init.data,
            body: JettonTransferInternal{
                queryId: msg.queryId,
                amount: msg.amount,
                from: self.owner,
                responseDestination: msg.responseDestination,
                forwardAmount: msg.forwardAmount,
            }.toCell()
        });
    }

    receive(msg: JettonBurn) {
        require(sender() == self.owner, "Only owner can burn");
        require(self.balance >= msg.amount, "Insufficient balance");
        self.balance = self.balance - msg.amount;
    }

    get fun balance(): Int {
        return self.balance;
    }

    get fun owner(): Address {
        return self.owner;
    }
}
