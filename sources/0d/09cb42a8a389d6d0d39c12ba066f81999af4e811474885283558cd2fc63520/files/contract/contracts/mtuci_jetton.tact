import "./jetton";

message Mint {
    amount: Int;
}

contract MtuciJetton with Jetton {
    
    totalSupply: Int as coins;
    owner: Address;
    content: Cell?;
    mintable: Bool;

    init(owner: Address, content: Cell?) {
        self.totalSupply = 0;
        self.owner = owner;
        self.mintable = false;
        self.content = content;
    }

    receive("Mint!") {
        let ctx: Context = context();
        self.mint(ctx.sender, ton("19041881"), ctx.sender);
    }
}
