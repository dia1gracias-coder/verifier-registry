import "./jetton";
import "./messages.tact";
import "@stdlib/deploy";

contract SharkJetton with Jetton, Deployable {
    totalSupply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    max_supply: Int as coins;
    init(owner: Address, content: Cell, max_supply: Int, initial_supply: Int){
        self.totalSupply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
        self.max_supply = max_supply; // Initial Setting for max_supply\
        self.mint(owner, initial_supply, owner);
    }

    receive(msg: Mint){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not Owner");
        require(self.mintable, "Can't Mint Anymore");
        self.mint(msg.receiver, msg.amount, self.owner); // (to, amount, response_destination)
        self.reply("Mint refund".asComment());
    }

    // receive("Owner: MintClose"){
    //     let ctx: Context = context();
    //     require(ctx.sender == self.owner, "Not Owner");
    //     self.mintable = false;
    //     self.reply("MintClose refund".asComment());
    // }
}