import "./jetton";
import "./messages";

message Mint {
    amount: Int;
    receiver: Address;
}

message BatchMint {
    amount: Int;
    receivers: map<Int as uint16, Address>;
    length: Int;
}

contract SampleJetton with Jetton {
    total_supply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;

    init(owner: Address, content: Cell) {
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
    }

    receive(msg: Mint) { // 0xfc708bd2
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        require(self.mintable, "Not mintable");
        self.mint(msg.receiver, msg.amount, self.owner); // (to, amount, response_destination)
    }

    receive(msg: BatchMint) { // 0xf2479593
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        self.batch_mint(msg.receivers, msg.amount, msg.length, self.owner);
    }
} 