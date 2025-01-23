import "@stdlib/deploy";
import "@stdlib/ownable";
import "../../jetton/messages";
import "../../jetton/jetton_master";
import "../../jetton/jetton_wallet";

message Mint {
    amount: Int;
}

contract UsdtJetton with Deployable, JettonMaster {

    totalSupply: Int as coins;
    owner: Address;
    content: Cell?;
    mintable: Bool;

    init(owner: Address, content: Cell?) {
        self.totalSupply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
    }

    receive(msg: Mint) {
        let ctx: Context = context();
        self.mint(ctx.sender, msg.amount, ctx.sender);
    }
}