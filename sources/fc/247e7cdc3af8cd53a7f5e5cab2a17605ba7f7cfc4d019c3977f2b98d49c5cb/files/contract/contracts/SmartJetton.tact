import "@stdlib/ownable";
import "./messages.tact";
import "./Jetton.tact";

contract SmartJetton with Jetton {
    totalSupply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;

    init(owner: Address, content: Cell) {
        self.totalSupply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
    }

    receive(msg: Mint) {
        self.requireOwner();
        require(self.mintable, "Can't Mint Anymore");
        self.mint(msg.receiver, msg.amount, self.owner);
    }

    receive("Owner: MintClose") {
        self.requireOwner();
        self.mintable = false;
    }
}