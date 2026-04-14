import "./imports/messages";
import "./jetton";

contract TONX with Jetton {

    totalSupply: Int as coins = 0; // Already set initially 
    mintable: Bool = true;
    owner: Address;
    content: Cell;
    max_supply: Int as coins; // This is not in the TEP-74 interface
    // ===== INIT =====
    init(owner: Address, max_supply: Int, content: Cell) {
        self.owner = owner;
        self.content = content;
        self.max_supply = max_supply;
    }

    receive(msg: Mint) {
        self.requireOwner(); 
        require(self.mintable, "Minting is disabled");
        require(self.totalSupply + msg.amount <= self.max_supply, "Exceed supply");

        self.mint(sender(), msg.amount, self.owner);

        if (self.totalSupply >= self.max_supply) {
            self.mintable = false;
        }
    }
}