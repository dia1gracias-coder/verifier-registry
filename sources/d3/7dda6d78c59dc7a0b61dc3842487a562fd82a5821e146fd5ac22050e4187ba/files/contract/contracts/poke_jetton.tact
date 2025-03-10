import "@stdlib/ownable";
import "@stdlib/deploy";
import "./jetton";

contract PokeJetton with Jetton, Deployable {
    totalSupply: Int as coins;
    mintable: Bool;
    owner: Address;
    content: Cell;
    max_supply: Int as coins;

    init(owner: Address, content: Cell, max_supply: Int) {
        self.totalSupply = max_supply;
        self.mintable = true;
        self.owner = owner;
        self.content = content;
        self.max_supply = max_supply;
        self.mint(owner, max_supply, myAddress());
    }

    receive(msg: Mint) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not Owner");
        require(self.mintable, "Can't Mint Anymore");
        self.mint(ctx.sender, msg.amount, myAddress());
    }

    receive("Owner: MintClose") {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not Owner");
        self.mintable = false;
    }
}
