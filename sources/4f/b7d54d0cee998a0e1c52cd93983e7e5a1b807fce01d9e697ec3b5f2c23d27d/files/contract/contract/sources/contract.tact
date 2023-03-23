import "@stdlib/deploy";

message Add {
    amount: Int as uint32;
}

contract SampleTactContract with Deployable {

    owner: Address;
    counter: Int as uint32;

    init(owner: Address) {
        self.owner = owner;
        self.counter = 0;
    }

    fun add(v: Int) {
        
        // Check sender
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");
        
        // Update counter
        self.counter = (self.counter + 1);
    }

    // receive(msg: Add) {
    //     dump(self.counter);
    // }

    receive("increment") {
        dump(self.counter);
    }

    get fun counter(): Int {
        return self.counter;
    }
    
}