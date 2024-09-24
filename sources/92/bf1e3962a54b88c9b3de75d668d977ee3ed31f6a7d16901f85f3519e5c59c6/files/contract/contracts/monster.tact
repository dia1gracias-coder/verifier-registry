import "@stdlib/deploy";
import "./jetton";
 
 
message InitialMint{ 
    receiver: Address;
}

contract Monster with Jetton, Deployable {
    total_supply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    max_supply: Int as coins;  

    init(owner: Address, content: Cell, max_supply: Int ) {
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
        self.max_supply = max_supply;
    }
    
    receive(msg: InitialMint){     
        require(self.mintable, "Can't Mint Anymore");
        self.mint(msg.receiver, self.max_supply, self.owner); 
        self.mintable = false; 
    }
}
 