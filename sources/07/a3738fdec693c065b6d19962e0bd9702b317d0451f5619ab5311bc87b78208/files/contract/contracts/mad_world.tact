import "@stdlib/deploy";
import "./country_token.tact";
import "./library/events";


contract MadWorld with Deployable {
    owner: Address;

    min_fee: Int as coins = ton("0.02");
    burn_fee: Int as coins = ton("0.06");

    county_tokens: map<Int, Country>;
    processed_nonce: map<Int, Bool>;

    nonce: Int;

    init(owner: Address, nonce: Int){
        self.owner = owner;
        self.county_tokens = emptyMap();
        self.nonce = nonce; //to deploy different contract
    }

    receive(){
        // dump(myBalance());
    }

    // admin only messages

    receive(msg: AdminMint) {
        let ctx: Context = context();
        self._ownerOnly(ctx);
        self._hasEnoughFunds(ctx.value, self.min_fee);
        let country: Country = self._getCountry(msg.country);

        send(SendParameters{
            to: country.address,
            value: 0,
            mode: SendRemainingValue,
            body: Mint{
                amount: msg.amount,
                receiver: msg.receiver
            }.toCell()
        });
    }

    receive(msg: DeployCountryToken){
        let ctx: Context = context();
        self._ownerOnly(ctx);
        self._hasEnoughFunds(ctx.value, self.min_fee);
        require(self.county_tokens.get(msg.id) == null, "Country token already exists");
        let init: StateInit = initOf CountryToken(myAddress(), msg.content, msg.tx_fee, msg.fee_wallet);
        let token_address: Address = contractAddress(init);

        send(SendParameters{
                to: token_address, 
                bounce: true,
                value: 0,
                mode: SendRemainingValue,
                code: init.code,
                data: init.data
            }
        );
        self.county_tokens.set(msg.id,
            Country{country: msg.country, address: token_address, buyable: true, sellable: true}
        );
        emit(DeployCountryTokenEvent{
            id: msg.id, 
            country: msg.country,
            content: msg.content,
            tx_fee: msg.tx_fee,
            fee_wallet: msg.fee_wallet,
            timestamp: now()
        }.toCell());
    }

    receive(msg: RewardWinner) {
        let ctx: Context = context();
        // self._ownerOnly(ctx); // temp disable for testing
        
        require(self.processed_nonce.get(msg.nonce) == null, "Nonce already processed");

        let gas_required: Int = msg.length * self.min_fee;
        self._hasEnoughFunds(ctx.value, gas_required); // sender will shoulder gas for now
        let country: Country = self._getCountry(msg.country);
        let excess: Int = ctx.value - gas_required;
        let i: Int = 0;
        while(i < msg.length) {
            if (msg.user_amount.get(i) != null) {
                let data: UserAmount = msg.user_amount.get(i)!!;
                send(SendParameters{
                    to: country.address,
                    value: self.min_fee,
                    mode: SendIgnoreErrors,
                    body: Mint{
                        amount: data.amount * ONE_TON,
                        receiver: data.user
                    }.toCell()
                });
            }
            i += 1;
        }

        self.processed_nonce.set(msg.nonce, true);
        
        emit(RewardWinnerEvent{
            nonce: msg.nonce,
            country: msg.country,
            user_amount: msg.user_amount,
            timestamp: now()
        }.toCell());

        if (excess > 0) { // send excess
            send(SendParameters{
                to: ctx.sender,
                value: excess,
                mode: SendIgnoreErrors
            });
        }
    }

    receive(msg: PunishLoser) {
        let ctx: Context = context();
        // self._ownerOnly(ctx); // temp disable for testing
        
        require(self.processed_nonce.get(msg.nonce) == null, "Nonce already processed");

        let gas_required: Int = msg.length * self.burn_fee;
        self._hasEnoughFunds(ctx.value, gas_required); // sender will shoulder gas for now
        let country: Country = self._getCountry(msg.country);
        let excess: Int = ctx.value - gas_required;
        let i: Int = 0;
        while(i < msg.length) {
            if (msg.user_amount.get(i) != null) {
                let data: UserAmount = msg.user_amount.get(i)!!;
                send(SendParameters{
                        to: country.address,
                        value: self.burn_fee,
                        bounce: true,
                        mode: SendIgnoreErrors,
                        body: BurnTokenInternal{amount: data.amount, user: data.user}.toCell()
                    }
                );
            }
            i += 1;
        }

        self.processed_nonce.set(msg.nonce, true);

        emit(PunishLoserEvent{
            nonce: msg.nonce,
            country: msg.country,
            user_amount: msg.user_amount,
            timestamp: now()
        }.toCell());

        if (excess > 0) { // send excess
            send(SendParameters{
                to: ctx.sender,
                value: excess,
                mode: SendIgnoreErrors
            });
        }
    }

    

    receive(msg: ChangeTransactionFee) {
        let ctx: Context = context();
        self._ownerOnly(ctx);
        self._hasEnoughFunds(ctx.value, self.min_fee);
        let country: Country = self._getCountry(msg.country);

        send(SendParameters{
                to: country.address,
                value: 0,
                bounce: true,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: ChangeTransactionFeeInternal{tx_fee: msg.tx_fee}.toCell()
            }
        );
        
        emit(ChangeTransactionFeeEvent{
            country: msg.country,
            tx_fee: msg.tx_fee,
            timestamp: now()
        }.toCell());
    }

    receive(msg: ChangeFeeWallet) {
        let ctx: Context = context();
        self._ownerOnly(ctx);
        self._hasEnoughFunds(ctx.value, self.min_fee);
        let country: Country = self._getCountry(msg.country);

        send(SendParameters{
                to: country.address,
                value: 0,
                bounce: true,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: ChangeFeeWalletInternal{fee_wallet: msg.fee_wallet}.toCell()
            }
        );
        
        emit(ChangeFeeWalletEvent{
            country: msg.country,
            fee_wallet: msg.fee_wallet,
            timestamp: now()
        }.toCell());
    }
    
    // public messages

    receive(msg: BuyToken){
        let ctx: Context = context();
        self._hasEnoughFunds(ctx.value, self.min_fee);
        let country: Country = self._getCountry(msg.country);
        require(country.buyable, "Country token not buyable");

        send(SendParameters{
                to: country.address,
                value: 0,
                bounce: true,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: BuyTokenInternal{amount: msg.amount, receiver: ctx.sender}.toCell()
            }
        );
        
        emit(BuyTokenEvent{
            country: msg.country,
            amount: msg.amount,
            timestamp: now()
        }.toCell());
    }

    receive(msg: SellToken){
        let ctx: Context = context();
        self._hasEnoughFunds(ctx.value, self.burn_fee);
        let country: Country = self._getCountry(msg.country);
        require(country.sellable, "Country token not sellable");

        send(SendParameters{
                to: country.address,
                value: 0,
                bounce: true,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: SellTokenInternal{amount: msg.amount, seller: ctx.sender}.toCell()
            }
        );
        
        emit(SellTokenEvent{
            country: msg.country,
            amount: msg.amount,
            timestamp: now()
        }.toCell());
    }

    receive(msg: JettonExcesses) {
        // dump(myBalance());
    }

    fun _ownerOnly(ctx: Context) {
        require(ctx.sender == self.owner, "Not owner");
    }

    fun _hasEnoughFunds(value: Int, fee: Int) {
        require(value >= fee, "Insufficient funds to shoulder fee");
    }

    fun _getCountry(country: Int): Country {
        require(self.county_tokens.get(country) != null, "Country token not found");
        return self.county_tokens.get(country)!!;
    }

    get fun balance(): Int {
        return myBalance();
    }

    get fun country_address(id: Int): Address {
        let country: Country = self.county_tokens.get(id)!!;
        return country.address;
    }
}