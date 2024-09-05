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

@name(muldivr)
native muldivr(x: Int, y: Int, z: Int): Int;

const fixedOne: Int = 1 << 128;

contract CountryToken with Jetton {
    total_supply: Int as coins;
    owner: Address;
    jetton_content: Cell;
    mintable: Bool;
    slope: Int;
    initPrice: Int;
    min_fee: Int;
    burn_fee: Int;
    init(owner: Address, content: Cell){
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.jetton_content = content;
        self.slope = fixedOne / 100; // 0.01
        self.initPrice = fixedOne / 10; // 0.1
        self.min_fee = muldivr(2, fixedOne, 100); // 0.02
        self.burn_fee = muldivr(6, fixedOne, 100); // 0.06
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
        require(ctx.sender == self.owner, "Not owner");
        let ton_amount: Int = self.buy_price(msg.amount);
        let estimate_amount: Int = ton_amount + self.min_fee;
        let value: Int = self._tonToFixed128(ctx.value);
        require(value >= estimate_amount, "Insufficient funds");
        ctx.value = self._fixed128ToTon(value - ton_amount); // deduct the ton_amount from ctx.value
        let excess: Int = value - estimate_amount;
        let internalMsg: JettonMint = JettonMint{
            origin: ctx.sender,
            receiver: msg.receiver,
            amount: msg.amount * ton("1"),
            custom_payload: emptyCell(),
            forward_ton_amount: 0,
            forward_payload: emptySlice()
        };
        self._mint_validate(ctx, internalMsg);
        self._mint(ctx, internalMsg);
    }

    receive(msg: SellTokenInternal){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        let ton_amount: Int = self.sell_price(msg.amount);
        let estimate_amount: Int = ton_amount + self.burn_fee;
        let balance: Int = self._tonToFixed128(myBalance());
        require(balance >= estimate_amount, "Contract insufficient funds");
        let initCode: StateInit = self.calculate_jetton_wallet_init(msg.seller);
        send(SendParameters{
                to: contractAddress(initCode),
                value: 0,
                bounce: true,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: JettonBurn{query_id: 0, amount: msg.amount * ton("1"), response_destination: self.owner}.toCell()
            }
        );
        send(SendParameters{to: msg.seller, value: self._fixed128ToTon(ton_amount), mode: SendPayGasSeparately});
    }

    get fun balance(): Int {
        return myBalance(); // in nano-tons (like cents, just with 9 decimals)
    }

    get fun buy_price(amount: Int): Int {
        let supply: Int = self.total_supply + (amount * ton("1"));
        return muldivr(self.slope, self._tonToFixed128(supply), fixedOne) + self.initPrice;
    }

    get fun sell_price(amount: Int): Int {
        let supply: Int = self.total_supply - (amount * ton("1"));
        return muldivr(self.slope, self._tonToFixed128(supply), fixedOne) + self.initPrice;
    }

    override inline fun _mint_validate(ctx: Context, msg: JettonMint) {
        require(self.mintable, "JettonMaster: Jetton is not mintable");
    }

    override inline fun calculate_jetton_wallet_init(owner_address: Address): StateInit {
        return initOf MadWallet(owner_address, myAddress());
    }
    

    fun _fixed128ToTon(value: Int): Int {
        return muldivr(value, ton("1"), fixedOne);
    }

    fun _tonToFixed128(value: Int): Int {
        return muldivr(value, fixedOne, ton("1"));
    }
}