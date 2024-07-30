import "@stdlib/deploy";
import "./interface";
message Mint {
    amount: Int;
    receiver: Address;
}
message MintPublic {
    amount: Int;
}

contract MaritonToken with Jetton, Deployable {
    totalSupply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    max_supply: Int as coins;
    const STORAGE_GAS_RESERVE: Int = ton("0.1");
    init(owner: Address, content: Cell, max_supply: Int){
        self.totalSupply = 0;
        self.owner = owner;
        self.mintable = false;
        self.content = content;
        self.max_supply = max_supply;
        self.mint(self.owner, max_supply, self.owner);
    }

    receive("withdraw"){
        self.requireOwner();
        send_ton_with_ramaining(self.owner,
            (myBalance() - self.STORAGE_GAS_RESERVE),
            false,
            "Owner Withdraw Fee".asComment()
        );
    }
}