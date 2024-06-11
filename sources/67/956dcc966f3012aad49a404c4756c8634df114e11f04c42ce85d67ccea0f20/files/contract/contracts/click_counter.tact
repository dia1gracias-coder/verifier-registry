import "@stdlib/deploy";

message Add {
    queryId: Int as uint64;
}

contract ClickCounter with Deployable {
    
    counters: map<Address, Int as uint32>;
    latestTxAt: map<Address, Int as uint32>;
    owner: Address;

    init(owner: Address) {
        self.owner = owner;
    }
    
    receive("Add") {
        let ctx: Context = context();
        self.counters.set(ctx.sender, self.nonNullInt(self.counters.get(ctx.sender)) + 1);
        self.latestTxAt.set(ctx.sender, now());
    }

    receive("Withdraw") {
        let ctx: Context = context();
        if (ctx.sender == self.owner) {
            let balanceToSend: Int = myBalance() - ton("0.05");
            send(SendParameters{
                to: self.owner,
                value: balanceToSend,
                bounce: false,
                mode: SendIgnoreErrors,
                body: emptyCell()
            });
        }
    }

    get fun counter(sender: Address): Int {
        return self.nonNullInt(self.counters.get(sender));
    }

    get fun latestTxAt(sender: Address): Int? {
        return self.latestTxAt.get(sender);
    }

    fun nonNullInt(num: Int?): Int {
        if (num == null) {
            return 0;
        }

        return num!!;
    }
}
