import "./country_token.tact";
import "./library/messages";


struct Country {
    country: String;
    address: Address;
    buyable: Bool;
    sellable: Bool;
}

contract MadWorld {
    owner: Address;
    buy_rate: Int = 100; // 1
    sell_rate: Int = 90; // 0.9
    min_fee: Int = ton("0.2");

    county_tokens: map<Int, Country>;

    init(owner: Address) {
        self.owner = owner;
        self.county_tokens = emptyMap();
    }

    receive(){}

    receive(msg: DeployCountryToken) { 
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        let init: StateInit = initOf CountryToken(myAddress(), msg.content);
        let tokenAddress: Address = contractAddress(init);
        require(self.county_tokens.get(msg.id) == null, "Country token already exists");
        send(SendParameters{
            to: tokenAddress,
            value: ton("0.2"),
            mode: SendIgnoreErrors, 
            code: init.code,
            data: init.data
        });
        self.county_tokens.set(msg.id, Country{ country: msg.country, address: tokenAddress, buyable: true, sellable: true});
        self.reply(NewCountryToken{address: tokenAddress}.toCell());
    }

    receive(msg: BuyToken) {
        let ctx: Context = context();
        require(self.min_fee < ctx.value, "Insufficient funds");
        require(self.county_tokens.get(msg.country) != null, "Country token not found");
        
        let country: Country = self.county_tokens.get(msg.country)!!;
        require(country.buyable, "Country token not buyable");
        let grossValue: Int = ctx.value - self.min_fee;
        let tokenAmount: Int = grossValue * self.buy_rate;

        send(SendParameters{
            to: country.address,
            value: ton("0.1"),
            mode: SendIgnoreErrors,
            body: Mint{
                amount: tokenAmount,
                receiver: ctx.sender
            }.toCell()
        });
    }

    get fun get_country_address(id: Int): Address {
        let country: Country = self.county_tokens.get(id)!!;
        return country.address;
    }
}