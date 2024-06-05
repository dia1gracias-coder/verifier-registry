import "@stdlib/deploy";
import "./jetton";
 
message Mint {
    amount: Int as coins;
    receiver: Address;
}

contract Lumber with Jetton, Deployable {
    total_supply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    initial_mint: Bool;
    max_supply: Int as coins;  

    init(owner: Address, content: Cell, max_supply: Int ) {
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
        self.max_supply = max_supply;
        self.initial_mint = false; 
    }
 
    receive("InitialMint"){
        require(!self.initial_mint, "Already initialized");

        let amount: Int = 0;
        //Token Distribution : Total 50%
        //50% Of tokens supply will be reamin in contract for player mint

        //Bonus to the most referrals 5%
        amount  = (self.max_supply * 5) / 100; 
        self.mint(address("UQArS7M6tAvCpKY136Rz3QTxPPNc5k-wQleTiug2zA-07D-E"), amount, self.owner);

        //Charity 1%
        amount  = (self.max_supply * 1) / 100; 
        self.mint(address("UQB5wm7S2-Hxv_0xO_LjSAsUxGQpl0Rk1zaRlLLBYvIyhkpG"), amount, self.owner);

        //MarketMaking 5%
        amount  = (self.max_supply * 5) / 100; 
        self.mint(address("UQCkx2wwZu-eKQ4WZkfXlUX2w8FuFjHx1SKzU2kW4DWRwzjA"), amount, self.owner);
        
        //Campaign 2%
        amount  = (self.max_supply * 2) / 100; 
        self.mint(address("UQBbs_EOJgL0u_OxvW1v3aBvjttGu400WpK-YwPp23B19Ajv"), amount, self.owner);
        
        //ADS 12%
        amount  = (self.max_supply * 12) / 100; 
        self.mint(address("UQDauq0a6xNX2kl2K3hqUlsY4HAIUTEeesKLlyNOPnCGurR5"), amount, self.owner);
  
        //Founders 10%
        amount  = (self.max_supply * 10) / 100; 
        self.mint(address("UQA6X0MTI3Uwei4tXNlzRAeMU1u3bz4ZPj9ff6n2Tuw9XC6D"), amount, self.owner);
        
        //Game Development 6%
        amount  = (self.max_supply * 6) / 100; 
        self.mint(address("UQAyggvWJ3T6oLKri5-9YervJAqyRrd967zh-jXgj4Nv5D7b"), amount, self.owner);
        
        //Staking Reward 9%
        amount  = (self.max_supply * 9) / 100; 
        self.mint(address("UQAyggvWJ3T6oLKri5-9YervJAqyRrd967zh-jXgj4Nv5D7b"), amount, self.owner);
        
        self.initial_mint = true;
    }

    receive(msg: Mint) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        require(self.mintable, "Not mintable");
        require(self.total_supply + msg.amount <= self.max_supply, "Max supply exceeded");
        self.mint(msg.receiver, msg.amount, self.owner);  
    } 
}
 