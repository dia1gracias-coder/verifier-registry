import "./library/jetton";
import "./library/jetton_wallet";
import "./library/messages";


contract CountryToken with Jetton {
    total_supply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;

    init(owner: Address, content: Cell){
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
    }

    receive(){}

    receive(msg: Mint) { // 0xfc708bd2
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        require(self.mintable, "Not mintable");
        // require(self.total_supply + msg.amount <= self.max_supply, "Max supply exceeded");
        self.mint(msg.receiver, msg.amount, self.owner); // (to, amount, response_destination)
    }

    get fun balance(): Int {
        return myBalance(); // in nano-tons (like cents, just with 9 decimals)
    }

    // get fun calculate_price (tokens_to_mint: Int): Int {
    //     dump(fixed248Pow(self.total_supply + tokens_to_mint, 0.2));
    //     return 0;
    // }
}