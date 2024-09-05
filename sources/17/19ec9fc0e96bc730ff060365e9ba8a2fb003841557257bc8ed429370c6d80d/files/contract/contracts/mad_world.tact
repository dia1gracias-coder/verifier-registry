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
    min_fee: Int as coins = ton("0.02");
    burn_fee: Int as coins = ton("0.06");
    county_tokens: map<Int, Country>;
    nonce: Int;

    init(owner: Address, nonce: Int){
        self.owner = owner;
        self.county_tokens = emptyMap();
        self.nonce = nonce; // to deploy different contract
    }

    receive(){
        // dump(myBalance());
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
        require(ctx.value >= self.min_fee, "Insufficient funds to shoulder fee");
        require(self.county_tokens.get(msg.country) != null, "Country token not found");
        let country: Country = self.county_tokens.get(msg.country)!!;
        require(country.buyable, "Country token not buyable");
        send(SendParameters{
                to: country.address,
                value: 0,
                bounce: true,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: BuyTokenInternal{amount: msg.amount, receiver: ctx.sender}.toCell()
            }
        );
    }

    receive(msg: SellToken){
        let ctx: Context = context();
        require(ctx.value >= self.burn_fee, "Insufficient funds to shoulder fee");
        require(self.county_tokens.get(msg.country) != null, "Country token not found");
        let country: Country = self.county_tokens.get(msg.country)!!;
        require(country.sellable, "Country token not sellable");
        send(SendParameters{
                to: country.address,
                value: 0,
                bounce: true,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: SellTokenInternal{amount: msg.amount, seller: ctx.sender}.toCell()
            }
        );
    }

    receive(msg: JettonExcesses) {
        // dump(myBalance());
    }

    get fun balance(): Int {
        return myBalance();
    }

    get fun country_address(id: Int): Address {
        let country: Country = self.county_tokens.get(id)!!;
        
        return country.address;
    }
}