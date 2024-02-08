import "./jetton";
//Update Marketing Wallet message
message UpdateMarketingWallet {
    marketing_wallet: Address;
}
//Mint message
message Mint {
    amount: Int;
    receiver: Address;
}

contract SampleJetton with Jetton {
    total_supply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    //Extra fields
    transaction_fee: Int;
    marketing_wallet: Address;
    //Init function
    init(owner: Address, content: Cell, transaction_fee: Int, marketing_wallet: Address){
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
        self.transaction_fee = transaction_fee;
        self.marketing_wallet = marketing_wallet;
    }

    receive(msg: Mint){
        // 0xfc708bd2
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        require(self.mintable, "Not mintable");
        self.mint(msg.receiver, msg.amount, self.owner); // (to, amount, response_destination)
    }

    receive(msg: UpdateMarketingWallet){
        // 0xfc708bd2
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        require(msg.marketing_wallet != null, "Invalid marketing wallet");
        self.marketing_wallet = msg.marketing_wallet;
    }

    // ====== Get Methods ====== //
    get fun get_transaction_fee(): Int {
        return self.transaction_fee;
    }

    get fun get_marketing_wallet(): Address {
        return self.marketing_wallet;
    }
}