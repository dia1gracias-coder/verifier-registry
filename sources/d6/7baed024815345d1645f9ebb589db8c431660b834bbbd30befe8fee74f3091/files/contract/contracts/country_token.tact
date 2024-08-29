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

    receive(msg: Mint){
        // 0xfc708bd2
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        require(self.mintable, "Not mintable");
        self.mint(msg.receiver, msg.amount, self.owner);
    }

    receive(msg: SellTokenInternal){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        let sellerWalletInit: StateInit = self.getJettonWalletInit(msg.seller);
        send(SendParameters{
                to: contractAddress(sellerWalletInit),
                value: ton("0.02"),
                bounce: true,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: TokenBurn{query_id: 0, amount: msg.amount, response_destination: self.owner}.toCell()
            }
        );
        send(SendParameters{
                to: msg.seller,
                value: 0,
                bounce: true,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: TokenBurn{query_id: 0, amount: msg.amount, response_destination: ctx.sender}.toCell()
            }
        );
    }

    get fun balance(): Int {
        return myBalance(); // in nano-tons (like cents, just with 9 decimals)
    }

    // get fun calculate_price (tokens_to_mint: Int): Int {
    //     dump(fixed248Pow(self.total_supply + tokens_to_mint, 0.2));
    //     return 0;
    // }
}