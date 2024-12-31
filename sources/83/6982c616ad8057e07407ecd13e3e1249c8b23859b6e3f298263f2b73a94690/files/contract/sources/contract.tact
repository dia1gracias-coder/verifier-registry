import "./jetton";
import "@stdlib/deploy";

message ChangeContent {
    content: Cell;
}
 
contract DuckJetton with Jetton,Deployable {
    total_supply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;

    init(owner: Address, content: Cell, max_supply: Int) {
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
        self.mint(owner, max_supply, self.owner); 
        self.mintable = false;
    }
    receive(msg: ChangeContent) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        self.content = msg.content;
    }
} 