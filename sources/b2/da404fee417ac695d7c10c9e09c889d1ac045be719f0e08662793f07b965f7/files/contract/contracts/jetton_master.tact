import "@stdlib/deploy";
import "./master";

message Mint {
    to: Address;
    amount: Int;
    responseAddress: Address?;
}

contract JettonMaster with Deployable, Jetton  {

    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell?;
    
    init() {
        self.totalSupply = 0;
        self.mintable = true;
        self.owner = sender();
    }

    receive(msg: Mint) {
        self.requireOwner();
        self.mint(msg.to, msg.amount, msg.responseAddress);
    }
}
