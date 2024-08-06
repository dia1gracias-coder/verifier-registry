import "@stdlib/deploy";
import "./mem_jetton";
import "./imports/messages";

contract MempumpMaster with Deployable {
    const buyGasConsumption: Int = ton("0.08");
    deploy_cost: Int as coins = ton("1"); // TON paid to company for deployment
    deploy_fee: Int as coins = ton("1"); // TON for tx comissions
    tradable: Bool = true;
    fee_recipient: Address;
    total_supply: Int as coins;
    TON_min: Int as coins;
    TON_liquidity: Int as coins;
    TON_treshold: Int as coins;
    Token_liquidity: Int as coins;
    cp: Int as coins;
    owner: Address;
    wrapped: Address?;
    unwrapped: Address?;
    isInitialized: Bool = false;
    max_supply: Int as coins;

    init(owner: Address, fee_recipient: Address,  max_supply: Int, initialLiquidity: Int, TON_min: Int, ton_treshold: Int) {
        self.total_supply = 0;
        self.owner = owner;
        self.fee_recipient = fee_recipient;
        self.max_supply = max_supply;
        self.cp = initialLiquidity * TON_min;
        self.TON_liquidity = TON_min;
        self.Token_liquidity = initialLiquidity;
        self.TON_min = TON_min;
        self.TON_treshold = ton_treshold;
    }

    receive(msg: Init) {
        let ctx: Context = context(); // Check sender
        require(ctx.value >= self.deploy_cost + self.deploy_fee, "Not anough value for deploy");
        require(!self.isInitialized, "Allready initialized");
        let initWrapped: StateInit = initOf MemJetton(myAddress(), msg.content_wrapped, self.max_supply);
        let addressWrapped: Address = contractAddress(initWrapped);
        send(SendParameters{
            to: addressWrapped,
            value: ton("0.1"),
            mode: SendIgnoreErrors,
            code: initWrapped.code,
            data: initWrapped.data,
            body: Deploy{
                queryId:0
            }.toCell()
        });
        self.wrapped = addressWrapped;

        let initUnwrapped: StateInit = initOf MemJetton(myAddress(), msg.content_unwrapped, self.max_supply);
        let addressUnwrapped: Address = contractAddress(initUnwrapped);
        send(SendParameters{
            to: addressUnwrapped,
            value: ton("0.1"),
            mode: SendIgnoreErrors,
            code: initUnwrapped.code,
            data: initUnwrapped.data,
            body: Deploy{queryId:0}.toCell()
        });
        self.unwrapped = addressUnwrapped;
    }

    receive(msg: Buy) {
        require(self.tradable, "Trades on contract finished");
        let ctx: Context = context();
        let value = ctx.value;
        let amount_in = self.cp / (self.Token_liquidity - msg.amount_buy) - self.TON_liquidity;
        require(ctx.value >= amount_in + self.buyGasConsumption , "Insufficient value");
        require(amount_in <= msg.max_payment, "Payment amount exceeds allowed");
        require(self.TON_liquidity + amount_in <= self.TON_treshold, "Out of stock");
        self.Token_liquidity = self.Token_liquidity - msg.amount_buy;
        self.TON_liquidity = self.TON_liquidity + amount_in;
        send(SendParameters{
            to: self.wrapped!!,
            value: 0,
            mode: SendRemainingValue,
            body: Mint { // 0x178d4519
                amount: msg.amount_buy,
                receiver: ctx.sender
            }.toCell(),
        });
        emit(BuyEvent{token_amount: msg.amount_buy, ton_amount: amount_in, user: ctx.sender}.toCell());
    }

    receive(msg: Sell) {
        require(self.tradable, "Trades on contract finished");
        let ctx: Context = context();
        let wallet = self.get_wrapped_wallet(ctx.sender);
        let value = ctx.value;
        let amount_out = self.TON_liquidity - self.cp / (self.Token_liquidity + msg.amount_sell);
        require(amount_out >= msg.min_TON, "Amount received too low");
        self.Token_liquidity = self.Token_liquidity + msg.amount_sell;
        self.TON_liquidity = self.TON_liquidity - amount_out;
        send(SendParameters{
            to: self.wrapped!!,
            value: ton("0.08"),
            body: Burn { // 0x178d4519
                amount: msg.amount_sell,
                from: ctx.sender,
                response_destination: ctx.sender
            }.toCell(),
        });
        send(SendParameters{
            to: ctx.sender,
            bounce: true,
            value: amount_out,
        });
        emit(SellEvent{token_amount: msg.amount_sell, ton_amount: amount_out, user: ctx.sender}.toCell());
    }

    receive(msg: CreateDeposit) {
        self.tradable = false;
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        require(ctx.value >= msg.forward_value_token + msg.forward_value_vault + ton("0.03"), "Insufficient value");
        let tokens_amount = self.Token_liquidity * (self.TON_liquidity - self.TON_min) / self.TON_liquidity;
        send(SendParameters{
            to: msg.ton_vault,
            value: msg.forward_value_vault + self.TON_liquidity - self.TON_min,
            body: msg.forward_payload_vault.asCell()
        });
        send(SendParameters{
            to: self.unwrapped!!,
            value: msg.forward_value_token,
            mode: SendBounceIfActionFail,
            body: TokenTransfer{ // 0x178d4519
                query_id: 0,
                amount: tokens_amount,
                destination: msg.token_vault,
                response_destination: ctx.sender,
                forward_ton_amount: ton("0.4"),
                custom_payload: null,
                forward_payload:  msg.forward_payload_token
            }.toCell(),
        });
    }

    receive(msg: Unwrap) {
        require(!self.tradable, "Too early to unwrap");
    }

    receive(msg: DeployOk) {

    }

    receive(msg: TokenExcesses) {

    }

    receive() {

    }

    bounced(msg: bounced<TokenBurn>) {
        dump("TokenBurn bounced");
    }

    bounced(rawMsg: Slice) {
        dump("Bounced :/");
    }

    get fun get_wrapped_wallet(owner: Address): Address {
        return contractAddress(initOf JettonDefaultWallet(owner, self.wrapped!!));
    }

    get fun get_unwrapped_wallet(owner: Address): Address {
        return contractAddress(initOf JettonDefaultWallet(owner, self.unwrapped!!));
    }

    get fun get_wrapped_jetton(): Address {
        return self.wrapped!!;
    }

    get fun get_unwrapped_jetton(): Address {
        return self.unwrapped!!;
    }

    get fun get_ton_limit(): Int {
        return self.TON_treshold;
    }

    get fun get_liquidity(): Liquidity {
        return Liquidity{
            token_liquidity: self.Token_liquidity,
            TON_liquidity: self.TON_liquidity,
            constant_product: self.cp
        }
    }
}