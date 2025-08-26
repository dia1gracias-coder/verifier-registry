import "@stdlib/ownable";
import "@stdlib/deploy";
import "./upgradeTrait.tact";

message(0x1) Increment {
    // empty message
}

message(0x2) Add {
    amount: Int as uint32;
}
message(0x3) Reduce {
    amount: Int as uint32;
}
message(0x4) Migrate {
    amount: Int as uint32;
}
message(0x5) Reset {
    // empty message
}

contract SampleTactContract with Deployable,Ownable, Upgradable  {
    owner: Address;
    version: Int = 1; // Updated version

    counter: Int = 0;

    init(owner: Address) {
        self.owner = owner;
        self.counter = 0;
    }

    fun add(v: Int) {
        // Check sender
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");
        
        // Update counter
        self.counter += v;
    }

    receive(msg: Add) {
        self.add(msg.amount);
    }

     receive(msg: Reduce) {
        self.reduce(msg.amount);
    }

    receive("increment") {
        self.add(1);
    }

    fun reduce(v: Int) {
         let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");
        self.counter -= v;
    }
    
    fun reset() {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");
        self.counter = 0;
    }

    receive(msg: Reset) {
        self.reset();
    }

    get fun counter(): Int {
        return self.counter;
    }

    receive(msg: Migrate) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");
        self.counter = msg.amount; // Set counter from old contract
    }
}