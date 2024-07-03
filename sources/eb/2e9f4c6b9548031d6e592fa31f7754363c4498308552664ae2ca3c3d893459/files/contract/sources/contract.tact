import "@stdlib/deploy";

message Add {
    amount: Int as uint32;
}

message SetVersion {
    version: String;
}

contract SampleTactContract with Deployable {

    owner: Address;
    counter: Int as uint32;
    version: String;

    init(owner: Address) {
        self.owner = owner;
        self.counter = 0;
        self.version = "1.0";
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

    receive("increment") {
        self.add(1);
        self.reply("incremented".asComment());
    }

    receive(msg: SetVersion) {
        self.version = msg.version;
    }

    get fun counter(): Int {
        return self.counter;
    }

    get fun version(): String {
        return self.version;
    }
}

