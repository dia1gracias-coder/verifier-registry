import "./jetton_launch_master";


contract JettonLaunch with Jetton {
    total_supply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    max_supply: Int as coins; // Extract parameter we set here. The Jetton Standards doesn't have this parameter.

    transfer_fee: Int;
    lp_wallet: Address;
    marketing_wallet: Address;
    development_wallet: Address;
    core_team_wallet: Address;
    init(owner: Address,
        lp_wallet: Address,
        marketing_wallet: Address,
        development_wallet: Address,
        core_team_wallet: Address,
        content: Cell,
        transfer_fee : Int,
        max_supply: Int){
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
        self.max_supply = max_supply;
        self.transfer_fee = transfer_fee;
        self.lp_wallet = lp_wallet;
        self.marketing_wallet = marketing_wallet;
        self.development_wallet = development_wallet;
        self.core_team_wallet = core_team_wallet;
    }

    receive(msg: Mint){
        // 0xfc708bd2
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        require(self.mintable, "Not mintable");
        require((self.total_supply + msg.amount) <= self.max_supply, "Max supply exceeded");
        self.mint(msg.receiver, msg.amount, self.owner); // (to, amount, response_destination)
    }

    receive(msg: InitMint){
        // Public Minting
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        require(self.mintable, "Not mintable");
        require((self.total_supply + msg.amount ) <= self.max_supply, "Max supply exceeded");
        self.mint(self.lp_wallet, msg.amount * ( 20 / 100 ) , self.owner); // 🔴            //  20%
        self.mint(self.marketing_wallet, msg.amount * ( 10 / 100 ) , self.owner); // 🔴     //  10%
        self.mint(self.development_wallet, msg.amount * ( 6 / 100 ) , self.owner); // 🔴    //  6%
        self.mint(self.core_team_wallet, msg.amount * ( 4 / 100 ) , self.owner); // 🔴      //  4%
    }

    receive("Owner: MintClose"){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        self.mintable = false;
    }
}