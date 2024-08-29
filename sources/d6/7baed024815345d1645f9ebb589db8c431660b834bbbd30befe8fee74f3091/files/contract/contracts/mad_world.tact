import "@stdlib/deploy";
import "./country_token.tact";
import "./library/messages";
struct Country {
    country: String;
    address: Address;
    buyable: Bool;
    sellable: Bool;
}

contract MadWorld with Deployable {
    owner: Address;
    buy_rate: Int = 100; // 1
    sell_rate: Int = 90; // 0.9
    min_fee: Int = ton("0.02");
    burn_fee: Int = ton("0.152");
    county_tokens: map<Int, Country>;
    init(owner: Address){
        self.owner = owner;
        self.county_tokens = emptyMap();
    }

    receive(){
        dump(myBalance());
    }

    receive(msg: AdminMint) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        require(self.county_tokens.get(msg.country) != null, "Country token not found");
        let country: Country = self.county_tokens.get(msg.country)!!;
        send(SendParameters{
            to: country.address,
            value: 0,
            mode: SendRemainingValue,
            body: Mint{
                amount: msg.amount,
                receiver: msg.receiver
            }.toCell()
        })
    }

    receive(msg: DeployCountryToken){
        let ctx: Context = context();
        require(ctx.value >= self.min_fee, "Insufficient funds");
        require(ctx.sender == self.owner, "Not owner");
        let init: StateInit = initOf CountryToken(myAddress(), msg.content);
        let token_address: Address = contractAddress(init);
        require(self.county_tokens.get(msg.id) == null, "Country token already exists");
        send(SendParameters{to: token_address, value: 0, mode: SendRemainingValue, code: init.code, data: init.data});
        self.county_tokens.set(msg.id,
            Country{country: msg.country, address: token_address, buyable: true, sellable: true}
        );
        // self.reply(NewCountryToken{address: token_address}.toCell());
    }

    receive(msg: BuyToken){
        let ctx: Context = context();
        require(ctx.value >= self.min_fee, "Insufficient funds");
        require(self.county_tokens.get(msg.country) != null, "Country token not found");
        let country: Country = self.county_tokens.get(msg.country)!!;
        require(country.buyable, "Country token not buyable");
        let gross_value: Int = ctx.value - self.min_fee;
        let token_amount: Int = gross_value * self.buy_rate;
        require(gross_value > 0, "Insufficient funds");
        send(SendParameters{
                to: country.address,
                value: self.min_fee,
                mode: SendIgnoreErrors,
                body: Mint{amount: token_amount, receiver: ctx.sender}.toCell()
            }
        );
    }

    receive(msg: SellToken){
        let ctx: Context = context();
        require(ctx.value >= self.burn_fee, "Insufficient funds");
        require(self.county_tokens.get(msg.country) != null, "Country token not found");
        let country: Country = self.county_tokens.get(msg.country)!!;
        require(country.sellable, "Country token not sellable");
        let ton_amount: Int = (msg.amount * self.sell_rate * pow(10, 9)) / 100_000;
        require(ton_amount > 0, "Invalid amount");
        require(myBalance() > ton_amount, "Insufficient contract balance");

        send(SendParameters{
                to: country.address,
                value: self.burn_fee,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: SellTokenInternal{amount: msg.amount, seller: ctx.sender}.toCell()
            }
        );
        send(SendParameters{to: ctx.sender, value: ton_amount, mode: SendPayGasSeparately});
    }

    receive(msg: TokenExcesses) {
        dump(myBalance());
    }

    get fun balance(): Int {
        return myBalance();
    }

    get fun country_address(id: Int): Address {
        let country: Country = self.county_tokens.get(id)!!;
        return country.address;
    }
}