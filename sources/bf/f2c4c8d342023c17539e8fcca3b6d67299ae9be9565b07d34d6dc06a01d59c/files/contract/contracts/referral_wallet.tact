import "@stdlib/deploy";
message CreateWallet {
    owner: Address;
}
message Move {
    target: Address;
}

contract ReferralWallet {
    factory: Address;
    owner: Address;
    amount: Int;
    seqno: Int;
    const MinTonForStorage: Int = ton("0.01");
    
    init(factory: Address, seqno: Int){
        self.factory = factory;
        self.owner = newAddress(0, 0);
        self.seqno = seqno;
        self.amount = 0;
    }

    receive(msg: CreateWallet){
        self.owner = msg.owner;
    }

    receive("accept"){
        self.amount = self.amount + context().value;
    }

    receive("withdraw"){
        require(sender() == self.factory, "Access is denied");
        require(self.amount > 0, "Invalid balance");
        send(SendParameters{
                to: self.owner,
                bounce: true,
                value: myBalance() - self.MinTonForStorage,
                mode: SendIgnoreErrors,
            }
        );
        self.amount = 0;
    }

    receive(msg: Move) {
        require(sender() == self.factory, "Access is denied");
        send(SendParameters{
                to: msg.target,
                bounce: true,
                value: myBalance() - self.MinTonForStorage,
                mode: SendIgnoreErrors,
                body: "addFunds".asComment()
            }
        );
    }

    get fun balance():Int {
        return self.amount;
    }
}