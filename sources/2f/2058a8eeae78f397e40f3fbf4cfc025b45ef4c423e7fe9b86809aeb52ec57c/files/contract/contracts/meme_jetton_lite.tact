import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages.tact";
import "./jetton.tact";


contract MemeJettonLite with Jetton, Deployable {
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
}
