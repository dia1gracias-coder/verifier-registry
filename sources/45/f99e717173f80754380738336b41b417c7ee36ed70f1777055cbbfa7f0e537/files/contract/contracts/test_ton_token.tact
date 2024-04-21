import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages.tact";
import "./jetton.tact";

// message Mint {
//     amount: Int;
//     receiver: Address;
// }

contract TestTonToken with Deployable, Jetton {
    totalSupply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    max_supply: Int as coins;

    init(owner: Address, content: Cell, max_supply: Int) {
        self.totalSupply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;

        self.max_supply = max_supply;
        self.mint(self.owner, self.max_supply, self.owner);
        self.mintable = false;
        self.owner = address("0:0000000000000000000000000000000000000000000000000000000000000000");
    }

    // receive(msg: Mint) {
    //     let ctx: Context = context();
    //     require(ctx.sender == self.owner, "Not Owner");
    //     require(self.mintable, "Can't Mint Anymore");
    //     self.mint(msg.receiver, msg.amount, self.owner);
    // }

    // receive("Owner: MintClose") {
    //     let ctx: Context = context();
    //     require(ctx.sender == self.owner, "Not Owner");
    //     self.mintable = false;
    // }

    // receive(msg: Revoke) {
    //     let ctx: Context = context();
    //     require(ctx.sender == self.owner, "Not Owner");
    //     self.owner = address("0:0000000000000000000000000000000000000000000000000000000000000000");
    // }
}
