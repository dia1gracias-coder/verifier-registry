import "./jetton";

message Mint {
    amount: Int;
    receiver: Address;
    seqNo:Int;
}

contract SampleJetton with Jetton {
    total_supply: Int as coins;
    mintable: Bool;
    owner: Address;
    content: Cell;

    max_supply: Int as coins; // Extract parameter we set here. The Jetton Standards doesn't have this parameter.

    init(owner: Address, content: Cell, max_supply: Int) {
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
        self.max_supply = max_supply;
    }

    receive(msg: Mint) { // 0xfc708bd2 FC708BD2₁₆
        let ctx: Context = context();
        dump("receive(msg: Mint) is called now");
        require(ctx.sender == self.owner, "Not owner");
        require(self.mintable, "Not mintable");
        require(self.total_supply + msg.amount <= self.max_supply, "Max supply exceeded");
        self.mint(msg.receiver, msg.amount, self.owner, msg.seqNo); // (to, amount, response_destination)
    }

    receive("Owner: MintClose") {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        self.mintable = false;
    }

    receive("deploy") {
        emit("New jetton master is being deployed for bitacross.".asComment());
    }
} 