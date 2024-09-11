import "./library/jetton";

contract MadWallet with JettonWallet {
    balance: Int as coins = 0;
    owner: Address;
    jetton_master: Address;
    init(owner: Address, jetton_master: Address){
        self.owner = owner;
        self.jetton_master = jetton_master;
    }

    override inline fun calculate_jetton_wallet_init(owner_address: Address): StateInit {
        return initOf MadWallet(owner_address, self.jetton_master);
    }
}

contract CountryToken with Jetton {
    // jetton standard
    total_supply: Int as coins;
    owner: Address;
    jetton_content: Cell;
    mintable: Bool;
    // fees
    min_fee: Int;
    burn_fee: Int;
    tx_fee: Int;
    // game variables
    slope: Int;
    init_price: Int;
    fee_wallet: Address;
    init(owner: Address, content: Cell, tx_fee: Int, fee_wallet: Address){
        require(tx_fee >= 0 && tx_fee <= MAX_FEE, "Invalid transaction fee.");
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.jetton_content = content;
        self.min_fee = muldivr(2, FIXED_ONE, 100); // 0.02
        self.burn_fee = muldivr(6, FIXED_ONE, 100); // 0.06
        self.tx_fee = tx_fee; // 0-10_000 (100%)

        self.slope = FIXED_ONE / 100; // 0.01
        self.init_price = FIXED_ONE / 10; // 0.1

        self.fee_wallet = fee_wallet;
    }

    receive(){}

    receive(msg: Mint){
        let ctx: Context = context();
        let internalMsg: JettonMint = JettonMint{
            origin: ctx.sender,
            receiver: msg.receiver,
            amount: msg.amount,
            custom_payload: emptyCell(),
            forward_ton_amount: 0,
            forward_payload: emptySlice()
        };
        self._mint_validate(ctx, internalMsg);
        self._mint(ctx, internalMsg);
    }

    receive(msg: BuyTokenInternal){
        let ctx: Context = context();
        self._ownerOnly(ctx);
        let ton_amount: Int = self.buy_price(msg.amount);
        let tx_fee_amount: Int = self.tx_fee_amount(msg.amount * ONE_TON);
        let token_amount: Int = msg.amount * ONE_TON - tx_fee_amount;
        let estimate_amount: Int = ton_amount + self.min_fee;
        let value: Int = self._tonToFixed128(ctx.value);
        self._hasEnoughFunds(value, estimate_amount);
        ctx.value = self._fixed128ToTon(value - ton_amount);
        let excess: Int = value - estimate_amount;
        let internalMsg: JettonMint = JettonMint{
            origin: ctx.sender,
            receiver: msg.receiver,
            amount: token_amount,
            custom_payload: emptyCell(),
            forward_ton_amount: 0,
            forward_payload: emptySlice()
        };
        self._mint_validate(ctx, internalMsg);
        self._mint(ctx, internalMsg);
        self._mintFee(tx_fee_amount);
    }

    receive(msg: SellTokenInternal){
        let ctx: Context = context();
        self._ownerOnly(ctx);
        let ton_amount: Int = self.sell_price(msg.amount);
        let estimate_amount: Int = ton_amount + self.burn_fee;
        let balance: Int = self._tonToFixed128(myBalance());
        self._hasEnoughFunds(balance, estimate_amount);
        let initCode: StateInit = self.calculate_jetton_wallet_init(msg.seller);
        send(SendParameters{
                to: contractAddress(initCode),
                value: 0,
                bounce: true,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: JettonBurn{query_id: 0, amount: msg.amount * ONE_TON, response_destination: self.owner}.toCell()
            }
        );
        send(SendParameters{to: msg.seller, value: self._fixed128ToTon(ton_amount), mode: SendPayGasSeparately});
    }

    receive(msg: BurnTokenInternal){
        let ctx: Context = context();
        self._ownerOnly(ctx);
        let initCode: StateInit = self.calculate_jetton_wallet_init(msg.user);
        send(SendParameters{
                to: contractAddress(initCode),
                value: 0,
                bounce: true,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: JettonBurn{query_id: 0, amount: msg.amount * ONE_TON, response_destination: self.owner}.toCell()
            }
        );
    }

    receive(msg: ChangeTransactionFeeInternal){
        let ctx: Context = context();
        self._ownerOnly(ctx);
        let value: Int = self._tonToFixed128(ctx.value);
        self._hasEnoughFunds(value, ton("0.01"));
        self._validFee(msg.tx_fee);
        self.tx_fee = msg.tx_fee;
        // send excess
        send(SendParameters{to: ctx.sender, value: 0, bounce: true, mode: SendRemainingValue + SendIgnoreErrors});
    }

    receive(msg: ChangeFeeWalletInternal){
        let ctx: Context = context();
        self._ownerOnly(ctx);
        let value: Int = self._tonToFixed128(ctx.value);
        self._hasEnoughFunds(value, ton("0.01"));
        self.fee_wallet = msg.fee_wallet;
        // send excess
        send(SendParameters{to: ctx.sender, value: 0, bounce: true, mode: SendRemainingValue + SendIgnoreErrors});
    }

    receive(msg: JettonExcesses) {
        // dump(myBalance());
    }

    get fun balance(): Int {
        return myBalance(); // in nano-tons (like cents, just with 9 decimals)
    }

    get fun buy_price(amount: Int): Int {
        let supply: Int = self.total_supply + (amount * ONE_TON);
        return muldivr(self.slope, self._tonToFixed128(supply), FIXED_ONE) + self.init_price;
    }

    get fun tx_fee_amount(base_price: Int): Int {
        return muldivr(base_price, self.tx_fee, MAX_FEE);
    }

    get fun sell_price(amount: Int): Int {
        let supply: Int = self.total_supply - (amount * ONE_TON);
        return muldivr(self.slope, self._tonToFixed128(supply), FIXED_ONE) + self.init_price;
    }

    get fun tx_fee(): Int {
        return self.tx_fee;
    }

    get fun fee_wallet(): Address {
        return self.fee_wallet;
    }

    override inline fun _mint_validate(ctx: Context, msg: JettonMint) {
        require(self.mintable, "JettonMaster: Jetton is not mintable");
    }

    override inline fun calculate_jetton_wallet_init(owner_address: Address): StateInit {
        return initOf MadWallet(owner_address, myAddress());
    }

    fun _fixed128ToTon(value: Int): Int {
        return muldivr(value, ONE_TON, FIXED_ONE);
    }

    fun _tonToFixed128(value: Int): Int {
        return muldivr(value, FIXED_ONE, ONE_TON);
    }

    fun _ownerOnly(ctx: Context) {
        require(ctx.sender == self.owner, "Not owner");
    }

    fun _hasEnoughFunds(value: Int, fee: Int) {
        require(value >= fee, "Insufficient funds to shoulder fee");
    }

    fun _validFee(value: Int) {
        require(value >= 0 && value <= MAX_FEE, "Invalid transaction fee.");
    }

    fun _mintFee(amount: Int) {
        let initCode: StateInit = self.calculate_jetton_wallet_init(self.fee_wallet);
        self.total_supply = self.total_supply + amount;
        send(SendParameters{
                to: contractAddress(initCode),
                value: ton("0.02"),
                bounce: true,
                mode: SendPayGasSeparately,
                body: JettonInternalTransfer{
                    query_id: 0,
                    amount: amount,
                    response_address: myAddress(),
                    from: myAddress(),
                    forward_ton_amount: 0,
                    forward_payload: emptySlice()
                }.toCell(),
                code: initCode.code,
                data: initCode.data
            }
        );
    }
}