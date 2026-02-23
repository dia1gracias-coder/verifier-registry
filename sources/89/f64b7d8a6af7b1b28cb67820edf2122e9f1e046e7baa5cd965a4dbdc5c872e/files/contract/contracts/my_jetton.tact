import "@stdlib/deploy";

message Mint {
    amount: Int as coins;
    to: Address;
}

message Burn {
    amount: Int as coins;
}

contract MyJetton with Deployable {
    owner: Address;
    totalSupply: Int as coins;
    name: String;
    symbol: String;
    balances: map<Address, Int>;

    init(owner: Address) {
        self.owner = owner;
        self.totalSupply = 0;
        self.name = "MyToken";
        self.symbol = "MTK";
        self.balances = emptyMap();
    }

    receive(msg: Mint) {
        require(sender() == self.owner, "Only owner can mint");
        require(msg.amount > 0, "Amount must be positive");

        let currentBalance: Int = self.balances.get(msg.to) == null ? 0 : self.balances.get(msg.to)!!;
        self.balances.set(msg.to, currentBalance + msg.amount);
        self.totalSupply = self.totalSupply + msg.amount;
    }

    receive(msg: Burn) {
        let currentBalance: Int = self.balances.get(sender()) == null ? 0 : self.balances.get(sender())!!;
        require(currentBalance >= msg.amount, "Insufficient balance");
        require(msg.amount > 0, "Amount must be positive");

        self.balances.set(sender(), currentBalance - msg.amount);
        self.totalSupply = self.totalSupply - msg.amount;
    }

    get fun totalSupply(): Int {
        return self.totalSupply;
    }

    get fun owner(): Address {
        return self.owner;
    }

    get fun name(): String {
        return self.name;
    }

    get fun symbol(): String {
        return self.symbol;
    }

    get fun balanceOf(addr: Address): Int {
        return self.balances.get(addr) == null ? 0 : self.balances.get(addr)!!;
    }
}
