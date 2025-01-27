import "@stdlib/deploy";
import "@stdlib/content";
import "./includes/constant";
import "./includes/messages";
import "./includes/events";
import "./library/access_control.tact";
import "./country_token.tact";
import "./custom_attack_nft.tact";
const GAME_ADMIN_ROLE: Int = 2;
const forwardeFee: Int = ton("0.002");

contract MadWorld with Deployable, AccessControl {
    // fee
    min_fee: Int;
    burn_fee: Int;
    // game vars
    tx_fee: Int as uint16;
    fee_wallet: Address;
    nonce: Int;
    // access control
    admin_initialized: Bool = false;
    user_roles: map<Address, UserRoles> = emptyMap();
    // country vars
    countries: map<Int as uint16, CountryData> = emptyMap();
    custom_attacks: map<Int as uint16, Address> = emptyMap();
    init(owner: Address, tx_fee: Int, fee_wallet: Address, nonce: Int){
        self.nonce = nonce; //to deploy different contract
        self.min_fee = ton("0.02");
        self.burn_fee = ton("0.06");
        self.tx_fee = tx_fee;
        self.fee_wallet = fee_wallet;
        self._init_admin(owner);
        self._grant_role(GAME_ADMIN_ROLE, owner);
    }

    receive(){
        // dump(myBalance());
    }

    // admin only messages

    receive(msg: AdminMint){
        let ctx: Context = context();
        self._only_role(DEFAULT_ADMIN_ROLE, sender());
        self._has_enough_funds(ctx.value, self.min_fee);
        let country_token_address: Address = self._get_country_token(msg.country);
        send(SendParameters{
                to: country_token_address,
                value: 0,
                mode: SendRemainingValue,
                body: Mint{amount: msg.amount, receiver: msg.receiver}.toCell()
            }
        );
    }

    receive(msg: BatchMint){
        let ctx: Context = context();
        self._only_role(DEFAULT_ADMIN_ROLE, sender());
        self._has_enough_funds(ctx.value, (self.min_fee + ctx.readForwardFee()) * msg.length);
        foreach (index, mint_info in msg.mints) {
            let country_token_address: Address = self._get_country_token(mint_info.country);
            send(SendParameters{
                    to: country_token_address,
                    value: self.min_fee,
                    bounce: false,
                    mode: SendIgnoreErrors,
                    body: Mint{amount: mint_info.amount, receiver: mint_info.receiver}.toCell()
                }
            );
        }
        send(SendParameters{to: sender(), value: 0, mode: SendRemainingValue});
    }

    receive(msg: DeployCountry){
        let ctx: Context = context();
        self._only_role(DEFAULT_ADMIN_ROLE, sender());
        let gasRequired: Int = (minTonsForStorage + gasConsumption) + forwardeFee;
        self._has_enough_funds(ctx.value, gasRequired * 2);
        let country_token_init: StateInit = initOf CountryToken(myAddress(), msg.jetton_content);
        let custom_attack_init: StateInit = initOf CustomAttackNftCollection(myAddress(),
            msg.nft_content,
            msg.royalty_params
        );
        let country_token_address: Address = contractAddress(country_token_init);
        let custom_attack_address: Address = contractAddress(custom_attack_init);
        self.countries.set(msg.id,
            CountryData{
                buyable: true,
                sellable: true,
                token_locked: true,
                asymptote: muldivr(81700000000000000000, FIXED_ONE, SCALE),
                scale_param: muldivr(40000000000000000000, FIXED_ONE, SCALE),
                growth_rate: muldivr(500129714662682, FIXED_ONE, SCALE),
                total_holding: 0,
                token_address: country_token_address
            }
        );
        self.custom_attacks.set(msg.id, custom_attack_address);
        send(SendParameters{
                to: country_token_address,
                bounce: true,
                value: gasRequired,
                mode: SendIgnoreErrors,
                code: country_token_init.code,
                data: country_token_init.data
            }
        );
        send(SendParameters{
                to: custom_attack_address,
                bounce: true,
                value: gasRequired,
                mode: SendIgnoreErrors,
                code: custom_attack_init.code,
                data: custom_attack_init.data
            }
        );
        emit(CountryDeployed{id: msg.id, token_address: country_token_address, timestamp: now()}.toCell());
        let excess: Int = ctx.value - ((gasRequired * 2) - (forwardeFee * 2));
        if (excess > 0) {
            send(SendParameters{to: sender(), bounce: false, value: excess, mode: SendIgnoreErrors});
        }
    }

    receive(msg: BatchDeployCountries){
        let ctx: Context = context();
        self._only_role(DEFAULT_ADMIN_ROLE, sender());
        let gasRequired: Int = (minTonsForStorage + gasConsumption) + forwardeFee;
        self._has_enough_funds(ctx.value, (gasRequired * 2) * msg.length);
        foreach (country, data in msg.countries) {
            let country_token_init: StateInit = initOf CountryToken(myAddress(), data.jetton_content);
            let custom_attack_init: StateInit = initOf CustomAttackNftCollection(myAddress(),
                data.nft_content,
                data.royalty_params
            );
            let country_token_address: Address = contractAddress(country_token_init);
            let custom_attack_address: Address = contractAddress(custom_attack_init);
            self.countries.set(data.id,
                CountryData{
                    buyable: true,
                    sellable: true,
                    token_locked: true,
                    asymptote: muldivr(81700000000000000000, FIXED_ONE, SCALE),
                    scale_param: muldivr(40000000000000000000, FIXED_ONE, SCALE),
                    growth_rate: muldivr(500129714662682, FIXED_ONE, SCALE),
                    total_holding: 0,
                    token_address: country_token_address
                }
            );
            self.custom_attacks.set(data.id, custom_attack_address);
            send(SendParameters{
                    to: country_token_address,
                    bounce: true,
                    value: gasRequired,
                    mode: SendIgnoreErrors,
                    code: country_token_init.code,
                    data: country_token_init.data
                }
            );
            send(SendParameters{
                    to: custom_attack_address,
                    bounce: true,
                    value: gasRequired,
                    mode: SendIgnoreErrors,
                    code: custom_attack_init.code,
                    data: custom_attack_init.data
                }
            );
            emit(CountryDeployed{id: data.id, token_address: country_token_address, timestamp: now()}.toCell());
            let excess: Int = ctx.value - (((gasRequired * 2) * msg.length) + ((forwardeFee * 2) * msg.length));
            if (excess > 0) {
                send(SendParameters{to: sender(), bounce: false, value: excess, mode: SendIgnoreErrors});
            }
        }
    }

    receive(msg: BatchAddUserHoldings){
        let ctx: Context = context();
        self._only_role(GAME_ADMIN_ROLE, sender());
        require(!msg.user_amount.isEmpty() && msg.length >= 0, "UserAmount is empty");
        self._has_enough_funds(ctx.value, self.min_fee);
        let countryData: CountryData = self._get_country(msg.country);
        let total_added: Int = 0;
        foreach (user, amount in msg.user_amount) {
            total_added += amount;
        }
        countryData.total_holding += total_added;
        self.countries.set(msg.country, countryData);
        emit(BatchAddedUserHoldings{country: msg.country, user_amount: msg.user_amount, timestamp: now()}.toCell());
        send(SendParameters{to: sender(), value: 0, mode: SendIgnoreErrors + SendRemainingValue});
    }

    receive(msg: BatchRemoveUserHoldings){
        let ctx: Context = context();
        self._only_role(GAME_ADMIN_ROLE, sender());
        require(!msg.user_amount.isEmpty(), "UserAmount is empty");
        self._has_enough_funds(ctx.value, self.min_fee);
        let countryData: CountryData = self._get_country(msg.country);
        let total_removed: Int = 0;
        foreach (user, amount in msg.user_amount) {
            total_removed += amount;
        }
        countryData.total_holding -= total_removed;
        require(countryData.total_holding >= 0, "Total holding cannot be negative");
        self.countries.set(msg.country, countryData);
        emit(BatchRemovedUserHoldings{country: msg.country, user_amount: msg.user_amount, timestamp: now()}.toCell());
        send(SendParameters{to: sender(), value: 0, mode: SendIgnoreErrors + SendRemainingValue});
    }

    receive(msg: ChangeTransactionFee){
        let ctx: Context = context();
        self._only_role(DEFAULT_ADMIN_ROLE, sender());
        self._has_enough_funds(ctx.value, self.min_fee);
        self._valid_value(msg.tx_fee, FEE_SCALE);
        self.tx_fee = msg.tx_fee;
        emit(TransactionFeeChanged{tx_fee: msg.tx_fee, timestamp: now()}.toCell());
        send(SendParameters{to: sender(), value: 0, mode: SendIgnoreErrors + SendRemainingValue});
    }

    receive(msg: ChangeFeeWallet){
        let ctx: Context = context();
        self._only_role(DEFAULT_ADMIN_ROLE, sender());
        self._has_enough_funds(ctx.value, self.min_fee);
        self._valid_address(msg.fee_wallet);
        self.fee_wallet = msg.fee_wallet;
        emit(FeeWalletChanged{fee_wallet: msg.fee_wallet, timestamp: now()}.toCell());
        send(SendParameters{to: sender(), value: 0, mode: SendIgnoreErrors + SendRemainingValue});
    }

    receive(msg: ChangeAsymptote){
        let ctx: Context = context();
        self._only_role(DEFAULT_ADMIN_ROLE, sender());
        self._has_enough_funds(ctx.value, self.min_fee);
        let country: CountryData = self._get_country(msg.country);
        country.asymptote = muldivr(msg.asymptote, FIXED_ONE, SCALE);
        self.countries.set(msg.country, country);
        emit(AsymptoteChanged{country: msg.country, asymptote: msg.asymptote, timestamp: now()}.toCell());
        send(SendParameters{to: sender(), value: 0, mode: SendIgnoreErrors + SendRemainingValue});
    }

    receive(msg: ChangeScaleParam){
        let ctx: Context = context();
        self._only_role(DEFAULT_ADMIN_ROLE, sender());
        self._has_enough_funds(ctx.value, self.min_fee);
        let country: CountryData = self._get_country(msg.country);
        country.scale_param = muldivr(msg.scale_param, FIXED_ONE, SCALE);
        self.countries.set(msg.country, country);
        emit(ScaleParamChanged{country: msg.country, scale_param: msg.scale_param, timestamp: now()}.toCell());
        send(SendParameters{to: sender(), value: 0, mode: SendIgnoreErrors + SendRemainingValue});
    }

    receive(msg: ChangeGrowthRate){
        let ctx: Context = context();
        self._only_role(DEFAULT_ADMIN_ROLE, sender());
        self._has_enough_funds(ctx.value, self.min_fee);
        let country: CountryData = self._get_country(msg.country);
        country.growth_rate = muldivr(msg.growth_rate, FIXED_ONE, SCALE);
        self.countries.set(msg.country, country);
        emit(GrowthRateChanged{country: msg.country, growth_rate: msg.growth_rate, timestamp: now()}.toCell());
        send(SendParameters{to: sender(), value: 0, mode: SendIgnoreErrors + SendRemainingValue});
    }

    receive(msg: ChangeTokenLockStatus){
        let ctx: Context = context();
        self._only_role(DEFAULT_ADMIN_ROLE, sender());
        self._has_enough_funds(ctx.value, self.min_fee);
        let country: CountryData = self._get_country(msg.country);
        country.token_locked = msg.status;
        self.countries.set(msg.country, country);
        emit(CountryTokenLockStatusChanged{country: msg.country, status: msg.status, timestamp: now()}.toCell());
        send(SendParameters{to: sender(), value: 0, mode: SendIgnoreErrors + SendRemainingValue});
    }

    receive(msg: RedeemTokens){
        let ctx: Context = context();
        self._only_role(GAME_ADMIN_ROLE, sender());
        self._has_enough_funds(ctx.value, self.min_fee + forwardeFee);
        let countryData: CountryData = self._get_country(msg.country);
        require(!countryData.token_locked, "Country token is locked");
        countryData.total_holding -= msg.amount;
        send(SendParameters{
                to: countryData.token_address,
                value: 0,
                mode: SendIgnoreErrors + SendRemainingValue,
                body: Mint{amount: msg.amount, receiver: msg.receiver}.toCell()
            }
        );
        self.countries.set(msg.country, countryData);
        emit(TokensRedeemed{country: msg.country, amount: msg.amount, receiver: msg.receiver, timestamp: now()}.toCell()
        );
    }

    receive(msg: RemoveCountryHolding){
        let ctx: Context = context();
        self._only_role(GAME_ADMIN_ROLE, sender());
        self._has_enough_funds(ctx.value, self.min_fee);
        let countryData: CountryData = self._get_country(msg.country);
        let amount = muldivr(countryData.total_holding, msg.percentage, FEE_SCALE);
        countryData.total_holding -= amount;
        require(countryData.total_holding >= 0, "Invalid amount");
        self.countries.set(msg.country, countryData);
        emit(CountryHoldingRemoved{country: msg.country, amount: amount, timestamp: now()}.toCell());
        send(SendParameters{to: sender(), value: 0, mode: SendIgnoreErrors + SendRemainingValue});
    }

    receive(msg: BatchRemoveCountryHolding){
        let ctx: Context = context();
        self._only_role(DEFAULT_ADMIN_ROLE, sender());
        self._has_enough_funds(ctx.value, ton("0.022"));
        let key: Int = 0;
        foreach (country, percentage in msg.country_percentage) {
            let countryData: CountryData = self._get_country(country);
            let amount = muldivr(countryData.total_holding, percentage, FEE_SCALE);
            countryData.total_holding -= amount;
            require(countryData.total_holding >= 0, "Invalid amount");
            self.countries.set(country, countryData);
        }
        emit(BatchCountryHoldingRemoved{
                query_id: msg.query_id,
                country_percentage: msg.country_percentage,
                timestamp: now()
            }.toCell()
        );
        send(SendParameters{to: sender(), value: 0, mode: SendIgnoreErrors + SendRemainingValue});
    }

    receive(msg: AddCountryHolding){
        let ctx: Context = context();
        self._only_role(GAME_ADMIN_ROLE, sender());
        self._has_enough_funds(ctx.value, self.min_fee);
        let countryData: CountryData = self._get_country(msg.country);
        require(countryData.sellable, "Country token not buyable");
        countryData.total_holding += msg.amount;
        self.countries.set(msg.country, countryData);
        emit(CountryHoldingAdded{country: msg.country, amount: msg.amount, timestamp: now()}.toCell());
        send(SendParameters{to: sender(), value: 0, mode: SendIgnoreErrors + SendRemainingValue});
    }

    receive(msg: BatchAddCountryHolding){
        let ctx: Context = context();
        self._only_role(DEFAULT_ADMIN_ROLE, sender());
        self._has_enough_funds(ctx.value, ton("0.022"));
        foreach (country, amount in msg.country_amount) {
            let countryData: CountryData = self._get_country(country);
            countryData.total_holding += amount;
            self.countries.set(country, countryData);
        }
        emit(BatchCountryHoldingAdded{
                query_id: msg.query_id,
                country_amount: msg.country_amount,
                timestamp: now()
            }.toCell()
        );
        send(SendParameters{to: sender(), value: 0, mode: SendIgnoreErrors + SendRemainingValue});
    }

    receive(msg: MintCustomAttack){
        let ctx: Context = context();
        self._only_role(GAME_ADMIN_ROLE, sender());
        let gasRequired: Int = (minTonsForStorage + gasConsumption) + forwardeFee;
        self._has_enough_funds(ctx.value, gasRequired);
        let custom_attack_address: Address = self._get_custom_attack(msg.country);
        send(SendParameters{
                to: custom_attack_address,
                value: 0,
                bounce: true,
                mode: SendIgnoreErrors + SendRemainingValue,
                body: MintCustomAttackInternal{query_id: msg.query_id, owner: msg.owner}.toCell()
            }
        );
    }

    receive(msg: WithdrawAllTon){
        let ctx: Context = context();
        self._only_role(GAME_ADMIN_ROLE, sender());
        let gasRequired: Int = (minTonsForStorage + gasConsumption) + forwardeFee;
        let total: Int = myBalance() - gasRequired;
        send(SendParameters{to: sender(), value: total, bounce: false, mode: SendIgnoreErrors + SendPayGasSeparately});
    }

    receive(msg: BatchUpdateAsymptote){
        let ctx: Context = context();
        self._only_role(DEFAULT_ADMIN_ROLE, sender());
        self._has_enough_funds(ctx.value, ton("0.004") * msg.length);
        foreach (country, asymptote in msg.country_asymptotes) {
            let countryData: CountryData = self._get_country(country);
            countryData.asymptote = muldivr(asymptote, FIXED_ONE, SCALE);
            self.countries.set(country, countryData);
        }
        send(SendParameters{to: sender(), value: 0, mode: SendIgnoreErrors + SendRemainingValue});
    }

    receive(msg: BatchUpdateScaleParam){
        let ctx: Context = context();
        self._only_role(DEFAULT_ADMIN_ROLE, sender());
        self._has_enough_funds(ctx.value, ton("0.004") * msg.length);
        let key: Int = 0;
        foreach (country, scale_param in msg.country_scale_params) {
            let countryData: CountryData = self._get_country(country);
            countryData.scale_param = muldivr(scale_param, FIXED_ONE, SCALE);
            self.countries.set(country, countryData);
        }
        send(SendParameters{to: sender(), value: 0, mode: SendIgnoreErrors + SendRemainingValue});
    }

    receive(msg: BatchUpdateGrowthRate){
        let ctx: Context = context();
        self._only_role(DEFAULT_ADMIN_ROLE, sender());
        self._has_enough_funds(ctx.value, ton("0.004") * msg.length);
        let key: Int = 0;
        foreach (country, growth_rate in msg.country_growth_rates) {
            let countryData: CountryData = self._get_country(country);
            countryData.growth_rate = muldivr(growth_rate, FIXED_ONE, SCALE);
            self.countries.set(country, countryData);
        }
        send(SendParameters{to: sender(), value: 0, mode: SendIgnoreErrors + SendRemainingValue});
    }

    // public messages

    receive(msg: BuyToken){
        let ctx: Context = context();
        let countryData: CountryData = self._get_country(msg.country);
        require(countryData.buyable, "Country token not buyable");
        let ton_amount: Int = self.buy_price(msg.country, msg.amount);
        let total_amount: Int = fixed248mul(ton_amount, self._ton_to_fixed248(msg.amount));
        let tx_fee_amount: Int = self.tx_fee_amount(total_amount);
        self._has_enough_funds(ctx.value, self._fixed248_to_ton(total_amount));
        let value: Int = self._ton_to_fixed248(ctx.value);
        send(SendParameters{
                to: self.fee_wallet,
                value: self._fixed248_to_ton(tx_fee_amount) + ctx.readForwardFee(),
                mode: SendIgnoreErrors
            }
        );
        let remaining: Int = self._fixed248_to_ton((value - total_amount) - tx_fee_amount);
        countryData.total_holding += msg.amount;
        self.countries.set(msg.country, countryData);
        emit(TokenBought{country: msg.country, amount: msg.amount, buyer: sender(), timestamp: now()}.toCell());
        if (remaining > 0) {
            send(SendParameters{to: sender(), value: remaining, mode: SendIgnoreErrors});
        }
    }

    receive(msg: StakeTokens){
        let ctx: Context = context();
        self._has_enough_funds(ctx.value, self.burn_fee + forwardeFee);
        let countryData: CountryData = self._get_country(msg.country);
        require(!countryData.token_locked, "Country token is locked");
        countryData.total_holding += msg.amount;
        send(SendParameters{
                to: countryData.token_address,
                value: 0,
                bounce: true,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: BurnTokenInternal{query_id: 0, amount: msg.amount, user: sender()}.toCell()
            }
        );
        self.countries.set(msg.country, countryData);
        emit(TokensStaked{country: msg.country, amount: msg.amount, staker: sender(), timestamp: now()}.toCell());
    }

    receive(msg: Excesses){
        // dump(myBalance());
    }

    fun _has_enough_funds(value: Int, fee: Int) {
        require(value >= fee, "Insufficient funds to shoulder fee");
    }

    fun _country_exists(country: Int) {
        require(self.countries.exists(country), "Country token not found");
    }

    fun _get_country_token(country: Int): Address {
        let data: CountryData = self._get_country(country);
        return data.token_address;
    }

    fun _get_custom_attack(country: Int): Address {
        self._country_exists(country);
        return self.custom_attacks.get(country)!!;
    }

    fun _get_country(country: Int): CountryData {
        self._country_exists(country);
        return self.countries.get(country)!!;
    }

    fun _valid_value(value: Int, max_value: Int) {
        require(value >= 0 && value <= max_value, "Invalid value");
    }

    fun _valid_address(value: Address) {
        require(value != newAddress(0, 0), "Invalid address");
    }

    fun _fixed248_to_ton(value: Int): Int {
        return muldivr(value, ONE_TON, FIXED_ONE);
    }

    fun _ton_to_fixed248(value: Int): Int {
        return muldivr(value, FIXED_ONE, ONE_TON);
    }

    // getter functions

    get fun balance(): Int {
        return myBalance();
    }

    get fun country(id: Int): CountryData {
        return self.countries.get(id)!!;
    }

    get fun country_custom_attack(id: Int): Address {
        return self.custom_attacks.get(id)!!;
    }

    get fun countries(): map<Int as uint16, CountryData> {
        return self.countries;
    }

    get fun total_holding(country: Int): Int {
        let countryData: CountryData = self._get_country(country);
        return countryData.total_holding;
    }

    get fun buy_price(country: Int, amount: Int): Int {
        let countryData: CountryData = self._get_country(country);
        let holdings: Int = countryData.total_holding + amount;
        let gR_S: Int = muldivr(-countryData.growth_rate, holdings, ONE_TON);
        let sP_gR_S: Int = fixed248mul(-countryData.scale_param, fixed248Exp(gR_S));
        return fixed248mul(countryData.asymptote, fixed248Exp(sP_gR_S));
    }

    get fun sell_price(country: Int, amount: Int): Int {
        let countryData: CountryData = self._get_country(country);
        let holdings: Int = countryData.total_holding - amount;
        require(holdings > 0, "Cannot sell more than the total holding");
        let gR_S: Int = muldivr(-countryData.growth_rate, holdings, ONE_TON);
        let sP_gR_S: Int = fixed248mul(-countryData.scale_param, fixed248Exp(gR_S));
        return fixed248mul(countryData.asymptote, fixed248Exp(sP_gR_S));
    }

    get fun tx_fee_amount(base_price: Int): Int {
        return muldivr(base_price, self.tx_fee, FEE_SCALE);
    }

    get fun current_price(country: Int): Int {
        let countryData: CountryData = self._get_country(country);
        let gR_S: Int = muldivr(-countryData.growth_rate, countryData.total_holding, ONE_TON);
        let sP_gR_S: Int = fixed248mul(-countryData.scale_param, fixed248Exp(gR_S));
        return fixed248mul(countryData.asymptote, fixed248Exp(sP_gR_S));
    }

    get fun tx_fee(): Int {
        return self.tx_fee;
    }

    get fun fee_wallet(): Address {
        return self.fee_wallet;
    }

    get fun from_string_to_cell(link: String): Cell {
        let builder: StringBuilder = beginStringFromBuilder(beginCell().storeUint(0x01, 8));
        builder.append(link);
        return builder.toCell();
    }
}