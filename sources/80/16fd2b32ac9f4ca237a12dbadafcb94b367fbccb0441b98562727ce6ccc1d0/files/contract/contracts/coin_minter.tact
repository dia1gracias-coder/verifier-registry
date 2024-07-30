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
        require(ctx.sender == self.owner, "Not Owner");
        require(self.mintable, "Can't Mint Anymore");
        self.mint(msg.receiver, msg.amount, self.owner);
    }

    receive("Mint: 100") {
        let ctx: Context = context();
        require(self.mintable, "Can't Mint Anymore");
        self.mint(ctx.sender, 100 * self.multiplier, self.owner);
    }

    receive("Owner: MintClose") {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not Owner");
        self.mintable = false;
    }
}
