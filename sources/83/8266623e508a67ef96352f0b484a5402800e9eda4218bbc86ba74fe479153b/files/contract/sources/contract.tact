import "@stdlib/deploy";

message Add {
    amount: Int as uint32;
}
message Minus {
    amount: Int as uint32;
}
message Mul {
    amount: Int as uint32;
}
message Div {
    amount: Int as uint32;
}
contract MyTactContract with Deployable {

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
        self.counter = (self.counter + v);
    }
    fun minus(v: Int) {
        
        // Check sender
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");
        
        // Update counter
        self.counter = (self.counter - v);
    }
    fun mul(v: Int) {
        
        // Check sender
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");
        
        // Update counter
        self.counter = (self.counter * v);
    }
    fun div(v: Int) {
        
        // Check sender
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");
        
        // Update counter
        self.counter = (self.counter / v);
    }

    receive(msg: Add) {
        self.add(msg.amount);
    }
    receive(msg: Minus) {
        self.minus(msg.amount);
    }
    receive(msg: Mul) {
        self.mul(msg.amount);
    }
    receive(msg: Div) {
        self.div(msg.amount);
    }

    receive("increment") {
        self.add(1);
        self.reply("incremented".asComment());
    }
    receive("decrement") {
         self.mul(1);
         self.reply("decremented".asComment());
     }

    get fun counter(): Int {
        return self.counter;
    }
    get fun getter(): Int {
        return self.counter;
    }
}