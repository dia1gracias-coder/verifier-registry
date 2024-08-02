import "@stdlib/deploy";
import "./imports/jetton";
import "./imports/messages";

contract MemJetton with Jetton, Deployable {
    const buyGasConsumption: Int = ton("0.08");
    total_supply: Int as coins;
    TON_min: Int as coins;
    TON_liquidity: Int as coins;
    Token_liquidity: Int as coins;
    Token_treshold: Int as coins;
    cp: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    is_init: Bool = false;

    max_supply: Int as coins;

    init(owner: Address, content: Cell, max_supply: Int, initialLiquidity: Int, TON_min: Int, supply_treshold: Int) {
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
        self.max_supply = max_supply;
        self.cp = initialLiquidity * TON_min;
        self.TON_liquidity = TON_min;
        self.Token_liquidity = initialLiquidity;
        self.TON_min = TON_min;
        self.Token_treshold = supply_treshold;
    }

    receive("Init liquidity") {
        require(context().sender == self.owner, "Not owner");
        require(!self.is_init, "Liquidity already initialized");
        self.mint(myAddress(), self.Token_liquidity, self.owner);
        self.is_init = true;
    }

    receive(msg: Mint) { // 0xfc708bd2
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        require(self.mintable, "Not mintable");
        require(self.total_supply + msg.amount <= self.max_supply, "Max supply exceeded");
        self.mint(msg.receiver, msg.amount, self.owner); // (to, amount, response_destination)
    }

    receive(msg: Buy) {
        let ctx: Context = context();
        let myWallet = self.get_wallet_address(myAddress());
        let value = ctx.value;
        let amount_in = self.cp / (self.Token_liquidity - msg.amount_buy) - self.TON_liquidity;
        require(ctx.value >= amount_in + self.buyGasConsumption , "Insufficient value");
        require(amount_in <= msg.max_payment, "Payment amount exceeds allowed");
        self.Token_liquidity = self.Token_liquidity - msg.amount_buy;
        self.TON_liquidity = self.TON_liquidity + amount_in;
        send(SendParameters{
                to: myWallet,
                value: ton("0.015") + ton("0.013") * 2 + ton("0.019"),
                mode: SendBounceIfActionFail,
                body: TokenTransfer{ // 0x178d4519
                    query_id: 0,
                    amount: msg.amount_buy,
                    sender: ctx.sender,
                    response_destination: ctx.sender,
                    forward_ton_amount: 0,
                    custom_payload: null,
                    forward_payload:  beginCell().endCell().asSlice()
                }.toCell(),
            });
        emit(BuyEvent{token_amount: msg.amount_buy, ton_amount: amount_in, user: ctx.sender}.toCell());
    }

    receive(msg: Sell) {
        let ctx: Context = context();
        let wallet = self.get_wallet_address(ctx.sender);
        let value = ctx.value;
        let amount_out = self.TON_liquidity - self.cp / (self.Token_liquidity + msg.amount_sell);
        require(amount_out >= msg.min_TON, "Amount received too low");
        self.Token_liquidity = self.Token_liquidity + msg.amount_sell;
        self.TON_liquidity = self.TON_liquidity - amount_out;
        send(SendParameters{
            to: wallet,
            value: ton("0.05"),
            mode: SendBounceIfActionFail,
            body: TokenTransfer{ // 0x178d4519
                query_id: 0,
                amount: msg.amount_sell,
                sender: myAddress(),
                response_destination: null,
                forward_ton_amount: 0,
                custom_payload: null,
                forward_payload:  beginCell().endCell().asSlice()
            }.toCell(),
        });
        dump(amount_out);
        send(SendParameters{
            to: ctx.sender,
            bounce: true,
            value: amount_out,
        });
        emit(SellEvent{token_amount: msg.amount_sell, ton_amount: amount_out, user: ctx.sender}.toCell());
    }

    bounced(rawMsg: Slice) {
        dump("Bounced :/");
    }
    
    receive("Owner: MintClose") {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        self.mintable = false;
    }

    receive() {

    }

    get fun get_liquidity(): Liquidity {
        return Liquidity{
            token_liquidity: self.Token_liquidity,
            TON_liquidity: self.TON_liquidity,
            constant_product: self.cp
        }
    }
}
