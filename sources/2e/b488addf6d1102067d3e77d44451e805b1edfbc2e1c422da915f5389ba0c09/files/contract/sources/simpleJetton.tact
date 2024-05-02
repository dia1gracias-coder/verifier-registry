import "@stdlib/deploy";

struct JettonData{
    totalSupply: Int;
    content: Cell;
}

message Transfer {
    amount: Int as coins;
    to: Address;
}

message InternalAdd{
    amount: Int as coins;
    origin: Address;
}

contract JettonMaster with Deployable {

    totalSupply: Int as coins;
    content: Cell;

    init(content: Cell) {
        self.totalSupply = 0;
        self.content = content;
    }

    receive("Mint") {
        let ctx: Context = context();
        self.mint(ton("10"), ctx.sender);
    }

    fun mint(amount: Int, to: Address) {
        let init: StateInit = initOf JettonWallet(myAddress(), to);
        send(SendParameters{
            to: contractAddress(init),
            body: InternalAdd{amount: amount, origin: myAddress()}.toCell(),
            value: ton("0.03"),
            mode: SendIgnoreErrors,
            code: init.code,
            data: init.data
        });
        self.totalSupply = self.totalSupply + amount;
    }

    get fun walletAddress(owner: Address): Address{
        let init: StateInit = initOf JettonWallet(myAddress(), owner);
        return contractAddress(init);
    }

    get fun get_jetton_data(): JettonData{
        return JettonData{totalSupply: self.totalSupply, content: self.content};
    }
}

contract JettonWallet with Deployable {

    parent: Address;
    owner: Address;
    balance: Int as coins;

    init(parent: Address, owner: Address) {
        self.parent = parent;
        self.owner = owner;
        self.balance = 0;
    }

    // step 2
    receive(msg: InternalAdd) {
        if(msg.origin == self.parent){
            require(sender() == self.parent, "Parent only");
        } else {
            let init: StateInit = initOf JettonWallet(self.parent, msg.origin);
            require(sender() == contractAddress(init), "JettonWallet only");
        }
        self.balance = self.balance + msg.amount;
    }


    // step 1
    receive(msg: Transfer) {
        require(sender()==self.owner, "Access denied");
        require(self.balance >= msg.amount, "Insufficient balance");
        self.balance = self.balance - msg.amount;
        let init: StateInit = initOf JettonWallet(self.parent, msg.to);
        send(SendParameters{
            to: contractAddress(init),
            body: InternalAdd{amount: msg.amount, origin: self.owner}.toCell(),
            value: ton("0.03"),
            mode: SendIgnoreErrors,
            code: init.code,
            data: init.data
        });
        self.reply("transferred".asComment());
    }
}