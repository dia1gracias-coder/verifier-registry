import "./jetton/jetton";
message Deploy {
    amount: Int as coins;
}

contract XBlastToken with Jetton {
    total_supply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    init(content: Cell, owner: Address){
        self.total_supply = 0;
        self.content = content;
        self.mintable = true;
        self.owner = owner;
    }

    receive(msg: Deploy){
        require(self.mintable, "Already Initialized");
        require(sender() == self.owner, "Not owner");
        self.mint(self.owner, msg.amount, self.owner);
        self.mintable = false;
    }
}