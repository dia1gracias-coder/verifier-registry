import "./jetton";
//Update Marketing Wallet message
message UpdateMarketingWallet {
    marketing_wallet: Address;
}
//Update Marketing fee message
message UpdateMarketingFee {
    marketing_fee: Int;
}
//Mint message
message Mint {
    amount: Int;
    receiver: Address;
}

//main contract
contract SampleJetton with Jetton {
    total_supply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    //Extra fields
    marketing_fee: Int as int8;
    marketing_wallet: Address;
    //Init function
    init(owner: Address, content: Cell, marketing_fee: Int, marketing_wallet: Address){
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
        self.marketing_fee = marketing_fee;
        self.marketing_wallet = marketing_wallet;
    }

    //====== Operations ====== //
    receive(msg: Mint){
        // 0xfc708bd2
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        require(self.mintable, "Not mintable");
        self.mint(msg.receiver, msg.amount, self.owner); // (to, amount, response_destination)
    }

    receive("Mint: 100"){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        require(self.mintable, "Not mintable");
        self.mint(ctx.sender, 100, self.owner); //
    }

    receive(msg: UpdateMarketingWallet){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        require(msg.marketing_wallet != null, "Invalid marketing wallet");
        self.marketing_wallet = msg.marketing_wallet;
    }

    receive(msg: UpdateMarketingFee){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        // require(msg.marketing_fee > 0, "Invalid marketing fee");
        // dump(msg.marketing_fee);
        self.marketing_fee = msg.marketing_fee;
    }

    // ====== Get Methods ====== //
    get fun get_marketing_fee(): Int {
        return self.marketing_fee;
    }

    get fun get_marketing_wallet(): Address {
        return self.marketing_wallet;
    }
}