import "./jetton";

contract RubberDuckJetton with Jetton {
    total_supply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    max_supply: Int as coins;
	
    ocean_ducks: Int as coins;
    cool_down: Int as uint32;
    squeeze_reward_cap: Int as coins;
    squeeze_reward_floor: Int as coins;
    release_burn_threshold: Int as coins;

    init(owner: Address, content: Cell, max_supply: Int) {
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
        self.max_supply = max_supply;
        self.ocean_ducks = 0;
        self.cool_down = 0;
        self.squeeze_reward_cap = 0;
        self.squeeze_reward_floor = 0;
        self.release_burn_threshold = 0;
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
        self.release_burn_threshold = msg.release_burn_threshold;
        self.squeeze_reward_floor = msg.squeeze_reward_floor;
        self.squeeze_reward_cap = msg.squeeze_reward_cap;
        self.cool_down = msg.cool_down;
    }

    //Squeeze Duck
    receive(msg: SqueezeDuck) {
        require(self.ocean_ducks > 0, "Not enough rubber ducks in the ocean - SqueezeDuck");
    
        let ctx: Context = context();
        let fwd_fee: Int = ctx.readForwardFee(); // Gas checks
        require(ctx.value > 2 * fwd_fee +  2 * self.gasConsumption + self.minTonsForStorage, "Invalid value");

        let randomRewards: Int = random(self.squeeze_reward_floor, self.squeeze_reward_cap + 1); //Generate Rewards 
        randomRewards = self.ocean_ducks > randomRewards? randomRewards : self.ocean_ducks;

        self.ocean_ducks = self.ocean_ducks - randomRewards; // Update ocean
        require(self.ocean_ducks >= 0, "Invaild ocean ducks - SqueezeDuck");

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
    
    
    receive(msg: ReleaseDucksIntoOceanNotification) {

        let ctx: Context = context();
        let sinit: StateInit = initOf JettonDefaultWallet(msg.response_destination, myAddress());
        require(contractAddress(sinit) == ctx.sender, "Invalid sender!");

        let randomBurn :Int = 0;
        if(self.release_burn_threshold != 0 && msg.amount > self.release_burn_threshold){
            randomBurn = random(self.release_burn_threshold, msg.amount);
            msg.amount = (msg.amount - randomBurn);
            self.total_supply = (self.total_supply - randomBurn);
        }

        self.ocean_ducks = (self.ocean_ducks + msg.amount); // Update ocean
        require(self.ocean_ducks >= 0, "Invalid ocean ducks - ReleaseDucksIntoOcean"); 
        
        send(SendParameters{
            to: msg.response_destination, 
            value: 0,
            bounce: false,
            mode: SendRemainingValue,
            body: ReleaseDucksIntoOceanExcesses{ query_id: msg.query_id, release_ducks:msg.amount}.toCell()
        });
    
    }


    bounced(msg: bounced<SqueezeDuckNotification>) {
        self.ocean_ducks = self.ocean_ducks + msg.rewards;
    }

    // ====== Get Methods ====== //
    get fun get_jetton_data(): JettonData {
        return
            JettonData{
                total_supply: self.total_supply,
                mintable: self.mintable,
                owner: self.owner,
                content: self.content,
                wallet_code: initOf JettonDefaultWallet(self.owner, myAddress()).code
            };
    }

    get fun get_wallet_address(owner: Address): Address {
        return contractAddress(initOf JettonDefaultWallet(owner, myAddress()));
    }
    
    get fun get_duck_content(): GetDuckContent {
        return GetDuckContent{ 
            release_burn_threshold:self.release_burn_threshold,
            squeeze_reward_floor: self.squeeze_reward_floor, 
            squeeze_reward_cap: self.squeeze_reward_cap, 
            cool_down: self.cool_down,
            ocean_ducks: self.ocean_ducks
        };
    }

} 