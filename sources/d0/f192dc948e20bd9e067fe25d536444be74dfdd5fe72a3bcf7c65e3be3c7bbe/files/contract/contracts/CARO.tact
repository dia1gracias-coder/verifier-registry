import "@stdlib/ownable";
import "@stdlib/deploy";
import "./Jetton";

message Init {
    to: Address;
    content: Cell;
}

contract CARO with Jetton, OwnableTransferable {
    total_supply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    to: Address;

    init(msg: Init) {
        self.total_supply = 0;
        self.owner = sender();
        self.content = msg.content;
        self.mintable = true;
        self.to = msg.to;
    }

    receive(msg: Deploy) {
        require(sender() == self.owner, "Not owner");
        self.mint(self.to, ton("1000000000"), sender()); // (to, amount, response_destination)
        self.mintable = false;
    }
    
} 
