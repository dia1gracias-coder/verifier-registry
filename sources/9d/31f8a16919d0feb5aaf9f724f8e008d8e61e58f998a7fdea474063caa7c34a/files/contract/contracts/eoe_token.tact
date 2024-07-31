import "@stdlib/deploy";
import "@stdlib/ownable";
import "./jetton/master";

message Mint {
    amount: Int;
    receiver: Address;
}

contract EoeToken with Jetton, Deployable {
    totalSupply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    max_supply: Int as coins;

    init(content: Cell, max_supply: Int) {
        self.totalSupply = 0;
        self.owner = sender();
        self.mintable = true;
        self.content = content;
        self.max_supply = max_supply; // Initial Setting for max_supply
    }

    receive(msg: Mint) {
        self.requireOwner();
        require(self.mintable, "Can't Mint Anymore");
        self.mint(msg.receiver, msg.amount, self.owner); // (to, amount, response_destination)
    }

    receive("Owner:MintClose") {
        self.requireOwner();
        self.mintable = false;
    }
}