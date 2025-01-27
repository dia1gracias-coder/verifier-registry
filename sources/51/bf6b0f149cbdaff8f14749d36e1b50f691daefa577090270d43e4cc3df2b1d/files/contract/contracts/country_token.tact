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
    total_supply: Int as coins;
    owner: Address;
    jetton_content: Cell;
    mintable: Bool;
    init(owner: Address, content: Cell){
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.jetton_content = content;
    }

    receive(){}

    receive(msg: Mint){
        let ctx: Context = context();
        let internalMsg: JettonMint = JettonMint{
            origin: sender(),
            receiver: msg.receiver,
            amount: msg.amount,
            custom_payload: emptyCell(),
            forward_ton_amount: 0,
            forward_payload: emptySlice()
        };
        self._mint_validate(ctx, internalMsg);
        self._mint(ctx, internalMsg);
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
                body: JettonBurn{query_id: msg.query_id, amount: msg.amount, response_destination: msg.user}.toCell()
            }
        );
    }

    receive(msg: Excesses) {
        // dump(myBalance());
    }

    get fun balance(): Int {
        return myBalance(); // in nano-tons (like cents, just with 9 decimals)
    }

    override inline fun _mint_validate(ctx: Context, msg: JettonMint) {
        require(self.mintable, "JettonMaster: Jetton is not mintable");
    }

    override inline fun calculate_jetton_wallet_init(owner_address: Address): StateInit {
        return initOf MadWallet(owner_address, myAddress());
    }

    fun _ownerOnly(ctx: Context) {
        require(sender() == self.owner, "Not owner");
    }
}