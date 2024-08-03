import "./jetton";

contract RubberDuck with Jetton{
    total_supply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    cool_down: Int as uint32;
    ocean: Int;
    squeeze_reward_floor: Int;
    squeeze_reward_cap: Int;
    max_supply: Int as coins; // Extract parameter we set here. The Jetton Standards doesn't have this parameter.

    init(owner: Address, content: Cell, max_supply: Int) {
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
        self.max_supply = max_supply;
        self.ocean = 0;
        self.squeeze_reward_floor = 0;
        self.squeeze_reward_cap = 0;
        self.cool_down = 0; 
    }

    receive(msg: Mint) { // 0xfc708bd2
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        require(self.mintable, "Not mintable");
        require(self.total_supply + msg.amount <= self.max_supply, "Max supply exceeded");
        self.mint(msg.receiver, msg.amount, self.owner); // (to, amount, response_destination)
    }


    receive("Owner: MintSwitch") {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        self.mintable = !self.mintable;
    }

    receive(msg: SetRewardParameters) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        self.squeeze_reward_floor = msg.squeeze_reward_floor;
        self.squeeze_reward_cap = msg.squeeze_reward_cap;
        self.cool_down = msg.cool_down;
    }

    //Squeeze Duck
    receive(msg: SqueezeDuck) {
        require(self.ocean > 0, "Not enough rubber ducks in the ocean - SqueezeDuck");
    
        let ctx: Context = context();
        let fwd_fee: Int = ctx.readForwardFee(); // Gas checks
        require(ctx.value > 2 * fwd_fee +  2 * self.gasConsumption + self.minTonsForStorage, "Invalid value");

        let randomRewards: Int = random(self.squeeze_reward_floor, self.squeeze_reward_cap + 1); //Generate Rewards 
        randomRewards = self.ocean > randomRewards? randomRewards : self.ocean;

        self.ocean = self.ocean - randomRewards; // Update ocean
        require(self.ocean >= 0, "Invaild ocean ducks - SqueezeDuck");

        let init: StateInit = initOf JettonDefaultWallet(ctx.sender, myAddress());  
        let wallet_address: Address = contractAddress(init);

        send(SendParameters{  
            to: wallet_address,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: SqueezeDuckNotification{
                query_id: msg.query_id,
                rewards: randomRewards,
                cool_down:self.cool_down,
                response_destination: ctx.sender
            }.toCell(),
            code: init.code,
            data: init.data
        });

    }
        
    receive(msg: DumpDucksIntoOceanNotification) {

        let ctx: Context = context();
        let sinit: StateInit = initOf JettonDefaultWallet(msg.response_destination, myAddress());
        require(contractAddress(sinit) == ctx.sender, "Invalid sender!");
  
        self.ocean = self.ocean + msg.amount; // Update ocean
        require(self.ocean >= 0, "Invalid ocean ducks - DumpDucksIntoOcean"); 
        
        send(SendParameters{
            to: msg.response_destination, 
            value: 0,
            bounce: false,
            mode: SendRemainingValue,
            body: TokenExcesses{ query_id: msg.query_id }.toCell()
        });
    
    }

    bounced(msg: bounced<SqueezeDuckNotification>) {
        self.ocean = self.ocean + msg.rewards;
    }

    // ====== Get Methods ====== //
    get fun get_jetton_data(): JettonData {
        return JettonData{ 
            total_supply: self.total_supply, 
            mintable: self.mintable, 
            owner: self.owner, 
            content: self.content, 
            cool_down: self.cool_down,
            ocean: self.ocean,
            squeeze_reward_floor: self.squeeze_reward_floor,
            squeeze_reward_cap: self.squeeze_reward_cap,
            wallet_code: initOf JettonDefaultWallet(self.owner, myAddress()).code
        };
    }


} 