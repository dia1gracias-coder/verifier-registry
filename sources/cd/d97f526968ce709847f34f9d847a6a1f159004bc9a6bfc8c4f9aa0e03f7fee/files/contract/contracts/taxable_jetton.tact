import "@stdlib/deploy";
import "./jetton";
message Mint {
    amount: Int;
    receiver: Address;
}

contract TaxableJetton with Deployable, Jetton {
    owner: Address;
    total_supply: Int as coins;
    content: Cell;
    mintable: Bool;
    burnAble: Bool;
    mintTax: Int as int32 = 5;
    burnTax: Int as int32 = 4;
    max_supply: Int as coins;
    init(content: Cell){
        self.total_supply = 0;
        self.owner = sender();
        self.content = content;
        self.max_supply = 1000000000000000000000000;
        self.mintable = true;
        self.burnAble = true;
        self.mint(self.owner, 1000000000000000000, self.owner); // (to, amount, response_destination)
    }

    get fun balance(): Int {
        return myBalance();
    }

    receive(msg: Mint){
        // 0xfc708bd2
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        require(self.mintable, "Not mintable");
        require((self.total_supply + msg.amount) <= self.max_supply, "Max supply exceeded");
        let amountAfterTax = (msg.amount * self.mintTax) / 100;
        self.mint(msg.receiver, amountAfterTax, self.owner); // (to, amount, response_destination)
        emit("Minted".asComment());
    }

    receive("enableBurn"){
        require(sender() == self.owner, "Only owner can call this!");
        require(self.burnAble == false, "Burn Already enable");
        self.burnAble = true;
        emit("Burn Enabled".asComment());
    }

    receive("disableBurn"){
        require(sender() == self.owner, "Only owner can call this!");
        require(self.burnAble, "Burn Already Disabled");
        self.burnAble = false;
        emit("Burn disabled".asComment());
    }

    receive("enableMint"){
        require(sender() == self.owner, "Only owner can call this!");
        require(self.mintable == false, "Mint Already enable");
        self.mintable = true;
        emit("Mint Enabled".asComment());
    }

    receive("disableMint"){
        require(sender() == self.owner, "Only owner can call this!");
        require(self.mintable, "Mint Already Disabled");
        self.mintable = false;
        emit("Mint disabled".asComment());
    }
}