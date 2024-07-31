import "./jetton";

contract RubberDuck with Jetton {
    total_supply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    ocean: Int;
    squeeze_reward_floor: Int;
    squeeze_reward_cap: Int;
    cool_down: Int as uint32;

    init(owner: Address, content: Cell) {
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
        self.ocean = 0;
        self.squeeze_reward_floor = 0;
        self.squeeze_reward_cap = 0;
        self.cool_down = 0; 
    }

    receive(msg: Mint) { // 0xfc708bd2
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        require(self.mintable, "Not mintable");
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
               
        require(self.ocean > 0, "Not enough rubber ducks in the ocean - Squeeze");
    
        let ctx: Context = context();
        let fwd_fee: Int = ctx.readForwardFee(); // Gas checks
        require(ctx.value > 2 * fwd_fee +  2 * self.gasConsumption + self.minTonsForStorage, "Invalid value");

        let randomRewards: Int = random(self.squeeze_reward_floor, self.squeeze_reward_cap + 1); //Generate Rewards 
        randomRewards = self.ocean > randomRewards? randomRewards : self.ocean;

        self.ocean = self.ocean - randomRewards; // Update ocean
        require(self.ocean >= 0, "Invaild ocean ducks - Squeeze");

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
                response_destination: ctx.sender,
            }.toCell(),
            code: init.code,
            data: init.data
        });

    }

    bounced(msg: bounced<SqueezeDuckNotification>) {
        self.ocean = self.ocean + msg.rewards;
    }
    
}