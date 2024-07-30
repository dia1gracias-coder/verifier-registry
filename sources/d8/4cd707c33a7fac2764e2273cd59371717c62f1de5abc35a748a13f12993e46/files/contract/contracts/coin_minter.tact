import "@stdlib/deploy";
import "@stdlib/ownable";
import "./jetton_trait.tact";

message Mint {
    amount: Int;
    receiver: Address;
}

contract CoinMinter with Deployable, Jetton {

    const multiplier: Int = pow(10, 9);

    totalSupply: Int as coins;
    owner: Address;
    mintable: Bool;
    content: Cell;

    init(owner: Address, content: Cell) {
        self.owner = owner;
        self.mintable = true;
        self.content = content;
        self.totalSupply = 0;
    }

    receive(msg: Mint) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "not owner");
        require(self.mintable, "minting is disabled");
        self.mint(msg.receiver, msg.amount, self.owner);
    }

    receive("MintClose") {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "not owner");
        self.mintable = false;
    }
}
